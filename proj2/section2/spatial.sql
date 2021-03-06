-- COMP3311 17s1 Project 2
--
-- Section 2 Template
create or replace function table_exists(tname text) 
    returns boolean
as $$
declare
    status integer := 0;
begin
    select count(*) into status from pg_class
    where relname=tname and relkind='r';
    return (status = 1);
end;
$$ language plpgsql;
--------------------------------------------------------------------------------
-- Q4
--------------------------------------------------------------------------------

drop function if exists skyline_naive(text) cascade;

create or replace function skyline_naive(dataset text)
    returns integer
as $$
declare
		num int;
begin
    if(not table_exists(dataset)) then
        return -1;
    end if;
    
		execute 'create or replace view '||dataset||'_skyline_naive(x, y) as
						 select A.x, A.y from '||dataset||' A
						 where (select count(*) from '||dataset||' B
						        where (B.x>A.x and B.y>=A.y) or (B.x>=A.x and B.y>A.y))=0';
		execute 'select count(*) from '||dataset||'_skyline_naive' into num;
		return num;
end;
$$ language plpgsql;

--------------------------------------------------------------------------------
-- Q5
--------------------------------------------------------------------------------

drop function if exists skyline(text) cascade;

create or replace function skyline(dataset text)
    returns integer
as $$
declare
	p record;
	last_x int;
	first int := 0;
	num int;
begin
	if(not table_exists(dataset)) then
     return -1;
  end if;
  
	execute 'drop view if exists '||dataset||'_skyline cascade';
	execute 'drop table if exists '||dataset||'_skyline_temp cascade';
	execute 'create table '||dataset||'_skyline_temp(x int,y int)';
	for p in execute 'select * from '||dataset||' order by y desc,x desc'
	loop
			if(first = 0 or p.x > last_x)
			then
				first := 1;
				last_x := p.x;
				execute 'insert into '||dataset||'_skyline_temp
								 values('||p.x||','||p.y||')';
			end if;
	end loop;
	execute 'create or replace view '||dataset||'_skyline(x, y) as
					 select * from '||dataset||'_skyline_temp order by x asc,y desc';
	execute 'select count(*) from '||dataset||'_skyline_temp' into num;
	return num;
end;
$$ language plpgsql;

--------------------------------------------------------------------------------
-- Q6
--------------------------------------------------------------------------------

drop function if exists skyband_naive(text) cascade;

create or replace function skyband_naive(dataset text, k integer)
    returns integer
as $$
declare
		num int;
begin
		if(not table_exists(dataset)) then
        return -1;
    end if;
    
		execute 'create or replace view '||dataset||'_skyband_naive(x, y) as
						select A.x, A.y from '||dataset||' A
						where (select count(*) from '||dataset||' B
						where (B.x>A.x and B.y>=A.y) or (B.x>=A.x and B.y>A.y)) <'||k;
		execute 'select count(*) from '||dataset||'_skyband_naive' into num;
		return num;
end;
$$ language plpgsql;

--------------------------------------------------------------------------------
-- Q7
--------------------------------------------------------------------------------

drop function if exists skyband(text, integer) cascade;

create or replace function skyband(dataset text, k integer)
    returns integer
as $$
declare
	num int;
	temp int;
	p record;
	last_x int;
	first int;
begin
	if(not table_exists(dataset)) then
      return -1;
  end if;
  
	execute 'drop view if exists '||dataset||'_skyband cascade';
	execute 'drop table if exists '||dataset||'_skyband_temp cascade';
	execute 'drop table if exists '||dataset||'_skyband_temp2 cascade';
	execute 'create table '||dataset||'_skyband_temp(x int,y int)';
	execute 'create table '||dataset||'_skyband_temp2 as 
					 select * from '||dataset||' order by y desc, x desc';	
	for temp in 1..k 
	loop
			first := 0;
			for p in execute 'select * from '||dataset||'_skyband_temp2 order by y desc,x desc'
			loop
					if(first =0 or p.x > last_x)
					then
						first := 1;
						last_x := p.x;
						execute 'insert into '||dataset||'_skyband_temp
								 		 values('||p.x||','||p.y||')';
						execute 'delete from '||dataset||'_skyband_temp2 b 
										 where b.x = '||p.x||' and b.y = '||p.y;
					end if;
			end loop;
	end loop;
	execute 'create or replace view '||dataset||'_skyband(x, y) as
					 select A.x, A.y from '||dataset||'_skyband_temp A 
					 where (select count(*) from '||dataset||'_skyband_temp B 
					 				where (B.x > A.x and B.y >= A.y) or (B.x >= A.x and B.y > A.y)) <'||k;
	execute 'select count(*) from '||dataset||'_skyband' into num;
	return num;
end;	
$$ language plpgsql;

