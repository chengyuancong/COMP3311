-- COMP3311 21T3 Ass2 ... extra database definitions
-- add any views or functions you need into this file
-- note: it must load without error into a freshly created mymyunsw database
-- you must submit this even if you add nothing to it

create or replace function
     transcript(zid integer) returns setof transcriptrecord
as $$
declare info transcriptrecord; tuple record;
begin
    for tuple in
        select s.code as courseCode, t.code as term, s.name as name,
               e.mark as mark, e.grade as grade, s.uoc as uoc
        from course_enrolments e
        join courses c on c.id = e.course
        join subjects s on s.id = c.subject
        join terms t on t.id = c.term
        where e.student = zid
        order by t.id, courseCode
    loop
        info.code := tuple.courseCode;
        info.term := tuple.term;
        info.name := tuple.name;
        info.mark := tuple.mark;
        info.grade := tuple.grade;
        info.uoc := tuple.uoc;
        return next info;
    end loop;
end;
$$
language plpgsql;