-- COMP9311 17s1 Project 1
--
-- MyMyUNSW Solution Template


-- Q1: buildings that have more than 30 rooms
create or replace view Q1(unswid, name)
as
--... SQL statements, possibly using other views/functions defined by you ...
select unswid,name from buildings where buildings.id in (select building from rooms group by building having count(building) >= 30);



-- Q2: get details of the current Deans of Faculty
create or replace view Q2(name, faculty, phone, starting)
as
--... SQL statements, possibly using other views/functions defined by you ...
with A as (select a.staff,a.orgunit,a.starting from affiliations a,staff_roles sr,orgunits o,orgunit_types ot 
where a.role = sr.id and sr.name ='Dean' and a.orgunit = o.id and o.utype = ot.id and ot.name = 'Faculty' and a.ending is null) 
select p.name,o.longname,s.phone,A.starting from 
people p,staff s,orgunits o,A where p.id = A.staff and s.id = A.staff and o.id = A.orgunit;



-- Q3: get details of the longest-serving and shortest-serving current Deans of Faculty
create or replace view Q3(status, name, faculty, starting)
as
--... SQL statements, possibly using other views/functions defined by you ...
select 'Longest serving' as status,name,faculty,starting from q2 where starting <= all(select starting from q2) union 
select 'Shortest serving' as status,name,faculty,starting from q2 where starting >= all(select starting from q2);




-- Q4 UOC/ETFS ratio
create or replace view Q4(ratio,nsubjects)
as
--... SQL statements, possibly using other views/functions defined by you ...
with R as (select (uoc/eftsload)::numeric(4,1) as ratio from subjects where eftsload!=0) select ratio,count(ratio) as nsubjects from R group by ratio;






