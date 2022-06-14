-- COMP3311 21T3 Assignment 1
-- Checking order of outputs in Q12

create or replace function
    ass1_table_exists(tname text) returns boolean
as $$
declare
    _check integer := 0;
begin
    select count(*) into _check from pg_class
    where relname=tname and relkind='r';
    return (_check = 1);
end;
$$ language plpgsql;

drop type if exists Q12TestingResult cascade;
create type Q12TestingResult as (test text, result text);

create or replace function
	ass1_q12_check() returns setof Q12TestingResult
as $$
declare
	i integer;
	qry text;
	tests text[] := array['b','c','d','e'];
	args text[] := array['goat','moon','ale','oun'];
	res boolean;
	rec Q12TestingResult;
begin
	if not ass1_table_exists('q12a_expected') then
		rec := ('Q12','Have you loaded check.sql?');
		return next rec;
		return;
	end if;
	for i in 1..4
	loop
		qry := 'select '
		       || '(select string_agg(q12,''|'') from q12'||tests[i]||'_expected)'
		       || ' = '
		       || '(select string_agg(q12,''|'') from q12('''|| args[i]||'''))';
		--rec := ('q12'||tests[i], qry);
		--return next rec;
		execute qry into res;
		if res then
			rec := ('q12'||tests[i], 'correct');
		else
			rec := ('q12'||tests[i], 'incorrect');
		end if;
		return next rec;
	end loop;
end;
$$ language plpgsql;
