-- COMP9311 17s1 Project 1
--
-- MyMyUNSW Solution Template

-- Q5: program enrolment information from 10s1
create or replace view Q5a(num)
as
--... SQL statements, possibly using other views/functions defined by you ...
select count(distinct student) from program_enrolments pe 
where pe.student in (select students.id from students where students.stype='intl') and 
pe.semester in (select semesters.id from semesters where semesters.year = 2010 and semesters.term = 'S1') 
and pe.id in (select partof from stream_enrolments where 
stream_enrolments.stream in (select streams.id from streams where streams.code = 'SENGA1'));

create or replace view Q5b(num)
as
--... SQL statements, possibly using other views/functions defined by you ...
select count(distinct student) from program_enrolments pe 
where pe.student in (select students.id from students where students.stype='local') and 
pe.semester in (select semesters.id from semesters where semesters.year = 2010 and semesters.term = 'S1') 
and pe.program in (select id from programs where code = '3978');

create or replace view Q5c(num)
as
--... SQL statements, possibly using other views/functions defined by you ...
select count(distinct student) from program_enrolments pe, semesters,programs,orgunits 
where pe.semester = semesters.id and semesters.year=2010 and semesters.term = 'S1' and 
pe.program = programs.id and programs.offeredby = orgunits.id 
and orgunits.name = 'Faculty of Engineering';



-- Q6: course CodeName
create or replace function
	Q6(text) returns text
as
$$
--... SQL statements, possibly using other views/functions defined by you ...
select code||' '||name from subjects where code = $1;
$$ language sql;



-- Q7: Percentage of growth of students enrolled in Database Systems
create or replace view Q7(year, term, perc_growth)
as
--... SQL statements, possibly using other views/functions defined by you ...
with B as ( 
with A as (
select sem.year,sem.term,sem.starting,(count(distinct ce.student))::float as num 
from courses c,subjects sub,semesters sem ,course_enrolments ce 
where sub.name='Database Systems' and c.subject = sub.id and c.semester = sem.id and ce.course=c.id 
group by c.semester,sem.year,sem.term,sem.starting) 
select A.year,A.term,(A.num/lag(A.num) over(order by A.starting)) ::numeric(4,2) as perc_growth from A) 
select * from B where B.perc_growth is not null;



-- Q8: Least popular subjects

--... SQL statements, possibly using other views/functions defined by you ...
create  or replace view course_order 
as select c.id,c.subject,sem.starting 
from courses c,semesters sem 
where sem.id = c.semester order by c.subject,sem.starting;

create or replace view subject_at_least_20_course as 
with A as (with course_num as (
select count(id) as course_num,subject 
from course_order group by subject having count(id)>=20) 
select course_order.*,row_number() over(partition by course_order.subject order by starting desc) 
from course_order,course_num 
where course_num.subject = course_order.subject) 
select * from A where A.row_number<= 20;

create or replace view sub20_studentnum as 
with num_student as (
select count(distinct student) as num,course 
from course_enrolments group by course) 
select sub20.*,num_student.num 
from subject_at_least_20_course sub20 
left join num_student on (num_student.course=sub20.id);

create or replace view Q8(subject) as 
with C as (
with B as (select distinct ss.subject from sub20_studentnum ss where ss.num >=20) 
select distinct ss.subject from sub20_studentnum ss except select * from B) 
select subjects.code||' '||subjects.name as subject from subjects,C 
where subjects.id=C.subject;


-- Q9: Database Systems pass rate for both semester in each year

--... SQL statements, possibly using other views/functions defined by you ...
create or replace view course_two_sem as 
with A as (
select c.id,sem.year,sem.term 
from courses c,semesters sem,subjects s 
where c.semester=sem.id and s.id=c.subject and s.name = 'Database Systems') 
select * from A where A.term ='S1' or A.term = 'S2';

create or replace view term_num as 
with C as (with B as (with pass_studentnum as ( 
select count(distinct student) as passnum,course from course_enrolments 
where mark >=50 
group by course ), 
 course_studentnum as ( 
select count(distinct student) as num,course from course_enrolments 
where mark >=0 
group by course ) 
select c_s.*,p.passnum from course_studentnum c_s 
join pass_studentnum p
on (c_s.course=p.course))
select cts.year,cts.term,B.num,B.passnum   
from course_two_sem cts  
join B 
on (cts.id=B.course)
) select year,term,sum(num) as sum_num,sum(passnum) as sum_passnum from C 
group by year,term;

create or replace view Q9(year, s1_pass_rate, s2_pass_rate) as 
with S1 as (select year,(sum_passnum/sum_num)::numeric(4,2) as s1_pass_rate 
from term_num 
where term = 'S1'),
S2 as (select year,(sum_passnum/sum_num)::numeric(4,2) as s2_pass_rate 
from term_num
where term ='S2') 
select right((S1.year)::text,2),S1.s1_pass_rate,S2.s2_pass_rate from 
S1 join S2 on 
(S1.year=S2.year) order by S1.year;

-- Q10: find all students who failed all black series subjects

--... SQL statements, possibly using other views/functions defined by you ...
create or replace view term_year as 
with B as (select id,term,year from semesters where year>=2002 and year<=2013) 
select id,year,term from B where term='S1' or term='S2';

create or replace view sub_term as 
select c.id,c.subject,t_y.year,t_y.term from courses c join term_year t_y 
on (c.semester = t_y.id) where subject in (select id from subjects 
where code like 'COMP93%') order by subject,year,term;

create or replace view Q10(zid, name) as
select 'z'||unswid,name from people where id in (
with A as (
with aim_course as (
select c.id,c.subject from courses c where subject in (
select subject from sub_term 
group by subject having count(id)=24)) 
select distinct ce.student,ac.subject 
from course_enrolments ce join 
aim_course ac 
on (ce.course=ac.id)
where ce.mark<50
) 
select A.student from A 
group by student having count(subject)=2
);
 




