-- COMP9311 17s1 Project 2
--
-- Section 1 Template

--Q1: ...
--drop type if exists IncorrectRecord cascade;
--drop function if exists Q1(int,int);
create type IncorrectRecord as (pattern_number integer, uoc_number integer);
create or replace function Q1(pattern text, uoc_threshold integer) 
	returns IncorrectRecord
as $$
declare
	A1 int;
	A2 int;
	B1 int;
	B2 int;
begin
	select count(id) into A1 from subjects where uoc is not null and eftsload is not null and code like pattern and eftsload!= 0 and (uoc/eftsload)::int!= 48;
	select count(id) into A2 from subjects where uoc is not null and eftsload is not null and code like pattern and eftsload = 0 and uoc != 0;
	select count(id) into B1 from subjects where uoc is not null and eftsload is not null and code like pattern and eftsload!= 0 and (uoc/eftsload)::int!= 48 and uoc>uoc_threshold;
	select count(id) into B2 from subjects where uoc is not null and eftsload is not null and code like pattern and eftsload = 0 and uoc != 0 and uoc>uoc_threshold;
	return (A1+A2, B1+B2);
end;
--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;


-- Q2: ...
--drop type if exists TranscriptRecord cascade;
--drop function if exists Q2(int);
--drop function if exists q2s1(int);

create or replace function q2s1(stu_unswid int)
	returns table(cid integer, term char(4), code char(8), name text, uoc integer, mark integer, grade char(2), rank integer, totalEnrols integer)
as $$
	with A as (
	(select ce.course as cid,right(se.year::text,2)||lower(se.term) as term,sub.code,sub.name,sub.uoc,ce.mark,ce.grade 
	 from course_enrolments ce,people p,semesters se,courses co,subjects sub 
	 where ce.student = p.id and p.unswid = $1 and se.id=co.semester and ce.course = co.id and co.subject = sub.id and ce.grade in ('SY', 'RS', 'PT', 'PC', 'PS', 'CR', 'DN', 'HD', 'A', 'B', 'C', 'D', 'E')) 
	 union 
	 (select ce.course as cid,right(se.year::text,2)||lower(se.term) as term,sub.code,sub.name,0 as uoc,ce.mark,ce.grade 
	 from course_enrolments ce,people p,semesters se,courses co,subjects sub 
	 where ce.student = p.id and p.unswid = $1 and se.id=co.semester and ce.course = co.id and co.subject = sub.id and ce.grade not in ('SY', 'RS', 'PT', 'PC', 'PS', 'CR', 'DN', 'HD', 'A', 'B', 'C', 'D', 'E'))
	), 
	B as (
	(select ce.course as cid, p.unswid, rank() over(partition by ce.course order by ce.mark desc) as rank 
	 from course_enrolments ce, people p
	 where ce.student = p.id and ce.mark is not null)
	 union
	 (select ce.course as cid, p.unswid, (null)::int as rank 
	 from course_enrolments ce, people p
	 where ce.student = p.id and ce.mark is null) 
	), 
	C as (
	select ce.course as cid, count(mark) as totalEnrols 
	 from course_enrolments ce 
	 group by course
	) 
	select A.*,(B.rank)::int,(C.totalEnrols)::int from A,B,C where A.cid = B.cid and B.cid = C.cid and B.unswid = $1 order by A.cid;
$$ language sql;

create type TranscriptRecord as (cid integer, term char(4), code char(8), name text, uoc integer, mark integer, grade char(2), rank integer, totalEnrols integer);
create or replace function Q2(stu_unswid integer)
	returns setof TranscriptRecord
as $$
begin
	 return query select cid,(term)::char(4),(code)::char(8),name,uoc,mark,(grade)::char(2),rank,totalEnrols from q2s1(stu_unswid);
end;
--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;


-- Q3: ...
create or replace function q3s1(org_id integer, num_sub integer, num_times integer)
	returns table(unswid integer, staff_name text, teaching_records text)
as $$
	with q3_answer as (
	with q3s1 as (
	with all_orgunits as (
	with recursive q as (
	select owner,member from orgunit_groups 
	where owner = $1 
	union 
	select m.owner, m.member from 
	orgunit_groups m join q on q.member = m.owner
	) 
	select * from q union select $1 as owner,$1 as member 
	) 
	select distinct c_s.course,c.subject,sub.code,p.unswid,p.name as staff_name,o.name,a_o.member from 
	all_orgunits a_o,subjects sub,courses c,course_staff c_s,people p,staff s,orgunits o   
	where sub.offeredby = a_o.member
	and sub.id = c.subject 
	and c.id = c_s.course 
	and c_s.staff = s.id 
	and s.id = p.id
	and o.id = a_o.member 
	and c_s.role in (select id from staff_roles where name != 'Course Tutor')
	),
	q3s2 as (
	with A as (select count(distinct subject),unswid from q3s1 group by unswid) 
	select q3s1.course,q3s1.subject,q3s1.code,q3s1.unswid,q3s1.staff_name,q3s1.name,A.count as num_sub  
	from q3s1,A 
	where A.unswid = q3s1.unswid and A.count > $2
	) 
	select subject,unswid,staff_name,code||', '||count(course)||', '||name as teaching_records from 
	q3s2 group by subject,code,unswid,name,staff_name 
	having count(course) > $3 order by unswid,subject
	)
	select unswid,staff_name,string_agg(teaching_records,chr(10)) as teaching_records 
  from q3_answer group by unswid,staff_name;
		
$$ language sql;


create type TeachingRecord as (unswid integer, staff_name text, teaching_records text);
create or replace function Q3(org_id integer, num_sub integer, num_times integer) 
	returns setof TeachingRecord 
as $$
begin
	return query select unswid,staff_name,teaching_records||chr(10) from q3s1($1,$2,$3) order by staff_name;
end;
--... SQL statements, possibly using other views/functions defined by you ...
$$ language plpgsql;

