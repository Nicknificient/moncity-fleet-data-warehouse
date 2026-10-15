
-- DIMENSION TABLES

-- TIME_DIM 
create table TIME_DIM as
select distinct
    to_char(bookingdate,'MON') || to_char(bookingdate,'YYYY') as TimeID,
    to_char(bookingdate,'MON') as Month,
    to_char(bookingdate,'YYYY') as Year
from booking;

-- FACULTY_DIM
create table FACULTY_DIM as
select distinct FACULTYID, FACULTYNAME, ZONE
from moncity.faculty;

-- PASSENGER_AGE_GROUP_DIM (manual dimension)
create table PASSENGER_AGE_GROUP_DIM
(AgeGroupID varchar2(10), AgeGroupDesc varchar2(30));

insert into PASSENGER_AGE_GROUP_DIM values ('YOUNG','Young Adults (18-35)');
insert into PASSENGER_AGE_GROUP_DIM values ('MIDDLE','Middle-aged (36-59)');
insert into PASSENGER_AGE_GROUP_DIM values ('OLD','Old-aged (60+)');

-- CAR_BODY_TYPE_DIM 
create table CAR_BODY_TYPE_DIM as
select distinct CARBODYTYPE, NUMSEATS
from moncity.car;

-- MAINTENANCE_TYPE_DIM
create table MAINTENANCE_TYPE_DIM as
select distinct MAINTENANCETYPE, MAINTENANCEDESCRIPTION
from moncity.maintenancetype;

-- TEAM_DIM
create table TEAM_DIM as
select distinct TEAMID, TEAMLEADER, PHONE
from moncity.maintenanceteam;

-- RESEARCH_CENTRE_DIM
create table RESEARCH_CENTRE_DIM as
select distinct CENTERID, CENTERNAME, PHONE, OPENINGHOUR
from moncity.researchcenter;

-- ACCIDENT_ZONE_DIM (from cleaned ACCIDENTINFO copy)
create table ACCIDENT_ZONE_DIM as
select distinct ACCIDENTZONE
from accidentinfo;

-- ERROR_CODE_DIM
create table ERROR_CODE_DIM as
select distinct ERRORCODE, ERRORMESSAGE
from moncity.error;

-- CAR_DAMAGE_SEVERITY_DIM (from cleaned ACCIDENTINFO copy)
create table CAR_DAMAGE_SEVERITY_DIM as
select distinct CAR_DAMAGE_SEVERITY
from accidentinfo;

-- CAR_DIM (individual-car grain, needed for the accident bridge)
create table CAR_DIM as
select distinct REGISTRATIONNO, CARBODYTYPE, NUMSEATS
from moncity.car;


-- STEP 2: BRIDGE TABLES (with weight factor)

---- TEAM_CENTRE_BRIDGE
create table TEAM_DIM as
select
    T.TEAMID, T.TEAMLEADER, T.PHONE,
    1 / NVL(CNT.NUM_CENTRES, 1) as WEIGHT_FACTOR
from moncity.maintenanceteam T,
     (select TEAMID, count(*) as NUM_CENTRES
      from moncity.belongto
      group by TEAMID) CNT
where T.TEAMID = CNT.TEAMID (+);


create table TEAM_CENTRE_BRIDGE as
select distinct TEAMID, CENTERID
from moncity.belongto;

-- CAR_ACCIDENT_BRIDGE:
create table ACCIDENT_WEIGHT_DIM as
select
    A.ACCIDENTID,
    1 / NVL(CNT.NUM_CARS, 1) as WEIGHT_FACTOR
from accidentinfo A,
     (select ACCIDENTID, count(*) as NUM_CARS
      from moncity.caraccident
      group by ACCIDENTID) CNT
where A.ACCIDENTID = CNT.ACCIDENTID (+);

create table CAR_ACCIDENT_BRIDGE as
select distinct ACCIDENTID, REGISTRATIONNO
from moncity.caraccident;


-- ============================================================
-- STEP 3: FACT TABLES
-- ============================================================

-- BOOKING_FACT: build a temp fact first (joins + age bucketing), then aggregate
create table BOOKING_TEMPFACT as
select
    to_char(BK.BOOKINGDATE,'MON') || to_char(BK.BOOKINGDATE,'YYYY') as TimeID,
    P.FACULTYID,
    C.CARBODYTYPE,
    case
        when P.PASSENGERAGE between 18 and 35 then 'YOUNG'
        when P.PASSENGERAGE between 36 and 59 then 'MIDDLE'
        else 'OLD'
    end as AGEGROUPID,
    BK.BOOKINGID
from booking BK, passenger P, moncity.car C
where BK.PASSENGERID = P.PASSENGERID
and BK.REGISTRATIONNO = C.REGISTRATIONNO;

create table BOOKING_FACT as
select
    TimeID,
    FACULTYID,
    AGEGROUPID,
    CARBODYTYPE,
    count(BOOKINGID) as NUM_BOOKING_RECORDS
from BOOKING_TEMPFACT
group by TimeID, FACULTYID, AGEGROUPID, CARBODYTYPE;

-- MAINTENANCE_FACT: TeamID kept un-aggregated so the bridge join still works
create table MAINTENANCE_FACT as
select
    M.MAINTENANCETYPE,
    C.CARBODYTYPE,
    M.TEAMID,
    sum(M.MAINTENANCECOST) as TOTAL_MAINTENANCE_COST,
    count(M.MAINTENANCEID) as NUM_MAINTENANCE_RECORDS
from maintenance M, moncity.car C
where M.REGISTRATIONNO = C.REGISTRATIONNO
group by M.MAINTENANCETYPE, C.CARBODYTYPE, M.TEAMID;

-- ACCIDENT_FACT: AccidentID retained (see note above on why this cannot be aggregated away)
create table ACCIDENT_FACT as
select
    ACCIDENTID,
    ACCIDENTZONE,
    ERRORCODE,
    CAR_DAMAGE_SEVERITY,
    1 as NUM_ACCIDENT_RECORDS
from accidentinfo;

