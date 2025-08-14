/* Total */
select position_cd,--station, 
count(distinct emp_id) number_of_counselors
from tableau_bi_read.tblu_wit_db
where costcenter_cd = 'VRE'
and record_status = 'Active'
and enddt=(select max(enddt) from tableau_bi_read.tblu_wit_db)
and position_cd in ('VREC','VREVC','VRS')
group by position_cd;

/* Denominator */
select 
count(distinct emp_id) number_of_counselors
from tableau_bi_read.tblu_wit_db
where costcenter_cd = 'VRE'
and record_status = 'Active'
and enddt=(select max(enddt) from tableau_bi_read.tblu_wit_db)
and position_cd in ('VREC','VRS');

/* Part of Numerator */
select count(distinct emp_id) number_of_counselors
from tableau_bi_read.tblu_wit_db
where costcenter_cd = 'VRE'
and record_status = 'Active'
and enddt=(select max(enddt) from tableau_bi_read.tblu_wit_db)
and position_cd in ('VREVC');