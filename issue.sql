
--Student Name: [Nicholas Wong Wei Junn]


--Copy table into my working space.
create table passenger as
select * from moncity.passenger;

create table accidentinfo as
select * from moncity.accidentinfo;

create table booking as
select * from moncity.booking;

create table maintenance as
select * from moncity.maintenance;


--C2
-- ISSUE 1: PASSENGER U163 — invalid FK value in FACULTYID

-- STEP 1 (EXPLORE): check referential integrity between PASSENGER and FACULTY
select * from moncity.passenger
where facultyid not in (select facultyid from moncity.faculty);
-- FOUND: passenger U163 has FACULTYID = 'Alienware'

-- STEP 2 (TRACE): confirm this value truly doesn't exist anywhere in FACULTY,
-- including checking for a possible typomismatch
select * from moncity.faculty;
select * from moncity.faculty
where upper(trim(facultyid)) like '%ALIEN%';
-- TRACE RESULT: FACULTY only contains FIT, BUS, ENG, ART, SCI — 'Alienware' is not
-- a typo of any valid faculty; it is a completely invalid value with
-- no other table available to cross-reference and recover the true faculty.

-- STEP 3 (CLEAN): 
-- Remove the NOT NULL constraint on FACULTYID so we can represent "unknown"
alter table passenger modify (facultyid null);

--BEFORE
select * from passenger where passengerid = 'U163';

update passenger
set facultyid = NULL
where passengerid = 'U163';

--AFTER
select * from passenger where passengerid = 'U163';


-- ISSUE 2: ACCIDENTINFO A2000 — invalid FK value in ERRORCODE

-- STEP 1 (EXPLORE): check referential integrity between ACCIDENTINFO and ERROR
select * from moncity.accidentinfo
where errorcode not in (select errorcode from moncity.error);
-- FOUND: accident A2000 has ERRORCODE = 'Error010'

-- STEP 2 (TRACE): confirm this doesn't exist under different formatting
select * from moncity.error;
select * from moncity.error
where upper(replace(errorcode,' ','')) like '%010%';
-- TRACE RESULT: ERROR only contains Error001-Error005 — 'Error010' is not a
-- formatting variant of any valid code; it is invalid with no other table
-- available to recover the true error code.

-- STEP 3 (CLEAN):
-- Remove the NOT NULL constraint on ERRORCODE so we can represent "unknown"
alter table accidentinfo modify (errorcode null);

-- BEFORE:
select * from accidentinfo where accidentid = 'A2000';

update accidentinfo
set errorcode = NULL
where accidentid = 'A2000';

-- AFTER:
select * from accidentinfo where accidentid = 'A2000';



-- ISSUE 3: BOOKING T1218 — duplicate record
-- STEP 1 (EXPLORE): check for duplicate BOOKINGID values
select bookingid, count(*) from booking
group by bookingid having count(*) > 1;
-- FOUND: BOOKINGID 'T1218' appears twice

-- STEP 2 (TRACE): inspect both rows to determine if they are a true duplicate
select * from booking where bookingid = 'T1218';
-- TRACE RESULT: both rows are 100% identical across REGISTRATIONNO, BOOKINGDATE,
-- DEPARTUREZONE, DESTINATIONZONE and PASSENGERID — confirmed a true duplicate.

-- STEP 3 (CLEAN):
-- BEFORE:
select * from booking where bookingid = 'T1218';

-- Rebuild the table using DISTINCT, which automatically collapses the
create table booking_clean as
select distinct * from booking;

drop table booking;

rename booking_clean to booking;

-- AFTER:
select * from booking where bookingid = 'T1218';


-- ISSUE 4: MAINTENANCE M2000 — invalid value, negative MAINTENANCECOST

-- STEP 1 (EXPLORE): check for illogical (negative/zero) maintenance costs
select * from maintenance
where maintenancecost <= 0;
-- FOUND: MAINTENANCEID 'M2000' has MAINTENANCECOST = -200

-- STEP 2 (TRACE): inspect the full row to judge plausibility
select * from maintenance where maintenanceid = 'M2000';
-- TRACE RESULT: aside from the sign, the row is otherwise complete and the
-- magnitude (200) is consistent with plausible maintenance costs elsewhere
-- in the table — indicating a data-entry sign error rather than garbage data.

-- STEP 3 (CLEAN):
-- BEFORE:
select * from maintenance where maintenanceid = 'M2000';

update maintenance
set maintenancecost = abs(maintenancecost)
where maintenanceid = 'M2000';

-- AFTER:
select * from maintenance where maintenanceid = 'M2000';


-- ISSUE 5: ACCIDENTINFO — missing primary key (NULL ACCIDENTID)

-- STEP 1 (EXPLORE): check for NULLs in the ACCIDENTINFO primary key column
select * from accidentinfo
where accidentid is null;
-- FOUND: one row with ACCIDENTZONE = 'ZoneC', CAR_DAMAGE_SEVERITY = 'Severe damage',
-- ERRORCODE = 'Error005', but ACCIDENTID is NULL

-- STEP 2 (TRACE): check whether this broken record isolated or a wider pattern
select count(*) from accidentinfo where accidentid is null;
-- TRACE RESULT: no CARACCIDENT rows reference a null accident, and only this
-- single row is affected — confirmed isolated and unreferenced, safe to remove.

-- STEP 3 (CLEAN):
-- BEFORE:
select * from accidentinfo where accidentid is null;

delete from accidentinfo
where accidentid is null;

-- AFTER:
select * from accidentinfo where accidentid is null;


-- Confirm the full ACCIDENTINFO column list (looking specifically for any date/time column)
select * from moncity.accidentinfo where rownum <= 5;

-- Also check CARACCIDENT, in case the date lives on the bridge relationship instead
select * from moncity.caraccident where rownum <= 5;

-- Confirm AccidentID is genuinely unique (safe to use as a degenerate dimension)
select accidentid, count(*) from moncity.accidentinfo
group by accidentid having count(*) > 1;







