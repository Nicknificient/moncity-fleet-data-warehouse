--Booking demand by faculty (bookings_by_faculty.csv)
select nvl(facultyid,'UNKNOWN') as facultyid, sum(num_booking_records) as total_bookings
from booking_fact
group by nvl(facultyid,'UNKNOWN')
order by total_bookings desc;

-- Booking demand by car body type (bookings_by_bodytypes.csv)
select carbodytype, sum(num_booking_records) as total_bookings
from booking_fact
group by carbodytype
order by total_bookings desc;

-- Accident severity distribution (accident_severity.csv)
select car_damage_severity, sum(num_accident_records) as total_accidents
from accident_fact
group by car_damage_severity
order by total_accidents desc;

select car_damage_severity,
       total_accidents,
       case car_damage_severity
           when 'No damage' then 1
           when 'Very minor damage' then 2
           when 'Minor damage' then 3
           when 'Moderate damage' then 4
           when 'Severe damage' then 5
       end as severity_rank
from (
    select car_damage_severity, sum(1) as total_accidents
    from accidentinfo
    group by car_damage_severity
)
order by severity_rank;

-- Which error code contributes most to accidents(Accidents by error code.csv)
select nvl(ecd.errorcode,'UNKNOWN') as errorcode,
       nvl(ecd.errormessage,'Unrecoverable Record') as errormessage,
       sum(af.num_accident_records) as total_accidents
from accident_fact af, error_code_dim ecd
where af.errorcode = ecd.errorcode(+)
group by nvl(ecd.errorcode,'UNKNOWN'), nvl(ecd.errormessage,'Unrecoverable Record')
order by total_accidents desc;

--more finding
-- Accident rate per booking not just raw accident count normalizes for exposure (accident_rate_by_bodytype.csv)
select bf.carbodytype,
       bf.total_bookings,
       af.weighted_accidents,
       round((af.weighted_accidents / bf.total_bookings) * 100, 2) as accident_rate_percent
from
  (select carbodytype, sum(num_booking_records) as total_bookings
   from booking_fact group by carbodytype) bf,
  (select cd.carbodytype, sum(afc.num_accident_records * awd.weight_factor) as weighted_accidents
   from accident_fact afc, accident_weight_dim awd, car_accident_bridge cab, car_dim cd
   where afc.accidentid = awd.accidentid
   and awd.accidentid = cab.accidentid
   and cab.registrationno = cd.registrationno
   group by cd.carbodytype) af
where bf.carbodytype = af.carbodytype
order by accident_rate_percent desc;

-- Maintenance cost per booking — normalizes cost against how much each body type is actually used(cost_per_booking_by_bodytype.csv)
select bf.carbodytype,
       mf.total_cost,
       bf.total_bookings,
       round(mf.total_cost / bf.total_bookings, 2) as cost_per_booking
from
  (select carbodytype, sum(num_booking_records) as total_bookings
   from booking_fact group by carbodytype) bf,
  (select carbodytype, sum(total_maintenance_cost) as total_cost
   from maintenance_fact group by carbodytype) mf
where bf.carbodytype = mf.carbodytype
order by cost_per_booking desc;





select count(*) from accident_fact;                 -- expect 993; 994 means stale
select count(*) from booking;                       -- cleaned count; should be 1 less than moncity.booking
select count(*) from moncity.booking;
select sum(num_booking_records) from booking_fact;  -- must equal cleaned booking count



select sum(maintenancecost) from maintenance;       -- must equal the next line
select sum(total_maintenance_cost) from maintenance_fact;



select * from ACCIDENT_WEIGHT_DIM where WEIGHT_FACTOR < 1;