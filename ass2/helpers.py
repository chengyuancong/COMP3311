# COMP3311 21T3 Ass2 ... Python helper functions
# add here any functions to share between Python scripts 
# you must submit this even if you add nothing


def getProgram(db, code):
    cur = db.cursor()
    cur.execute("select * from Programs where code = %s", [code])
    info = cur.fetchone()
    cur.close()
    if not info:
        return None
    else:
        return info


def getStream(db, code):
    cur = db.cursor()
    cur.execute("select * from Streams where code = %s", [code])
    info = cur.fetchone()
    cur.close()
    if not info:
        return None
    else:
        return info


def getStudent(db, zid):
    cur = db.cursor()
    qry = """
    select p.*, c.name
    from   People p
         join Students s on s.id = p.id
         join Countries c on p.origin = c.id
    where  p.id = %s
    """
    cur.execute(qry, [zid])
    info = cur.fetchone()
    cur.close()
    if not info:
        return None
    else:
        return info


# get transcript record tuple from zid
# (courseCode, term, name, mark, grade, uoc)
def getTranscriptRecord(db, zid):
    cur = db.cursor()
    cur.execute("select * from transcript(%s)", [zid])
    info = cur.fetchall()
    cur.close()
    return info

# get program rule tuple program code
# (programName, type, min_req, max_req, aogType, courseCodes)
def getProgramRule(db, program):
    cur = db.cursor()
    qry = """
    select r.name, r.type, r.min_req, r.max_req, aog.defby, aog.definition
    from program_rules pr
    join rules r on pr.rule = r.id
    join academic_object_groups aog on r.ao_group = aog.id
    where pr.program = %s"""
    cur.execute(qry, [program])
    info = cur.fetchall()
    cur.close()
    return info


# get program orgUnit from program id
def getProgramOrg(db, program):
    cur = db.cursor()
    qry = """
    select longname
    from orgunits
    where id = (select offeredby
                from programs
                where id = %s)
    """
    cur.execute(qry, [program])
    info = cur.fetchone()
    cur.close()
    return info


# get stream rule from stream from stream code
# (ruleName, type, min_req, max_req, aogType, courseCodes)
def getStreamRule(db, stream):
    cur = db.cursor()
    qry = """
    select r.name, r.type, r.min_req, r.max_req, aog.defby, aog.definition
    from stream_rules pr
    join rules r on pr.rule = r.id
    join academic_object_groups aog on r.ao_group = aog.id
    where pr.stream = (select id
                       from streams
                       where code = %s)"""
    cur.execute(qry, [stream])
    info = cur.fetchall()
    cur.close()
    return info


# get stream OrgUnit from stream code
def getStreamOrg(db, stream):
    cur = db.cursor()
    qry = """
    select longname
    from orgunits
    where id = (select offeredby
                from streams
                where code = %s)
    """
    cur.execute(qry, [stream])
    info = cur.fetchone()
    cur.close()
    return info

# get course name from course code
def getCourseName(db, code):
    cur = db.cursor()
    cur.execute("select name from subjects where code = %s", [code])
    info = cur.fetchone()
    cur.close()
    if not info:
        return None
    else:
        return info

# get most recent program and stream from student's zid
# (program code, stream code, term id)
def getRecentProgramAndStream(db, zid):
    cur = db.cursor()
    qry = """
    select pe.program, s.code, pe.term
    from program_enrolments pe
    join stream_enrolments se on pe.id = se.partof
    join streams s on se.stream = s.id
    where pe.student = %s
    order by pe.term desc
    """
    cur.execute(qry, [zid])
    info = cur.fetchone()
    return info


# get all courses' code that matches given pattern
def getMatchCourse(db, pattern):
    cur = db.cursor()
    pattern = pattern.replace('#', '_')
    cur.execute("select code from subjects where code like %s", [pattern])
    return [tup[0] for tup in cur.fetchall()]
