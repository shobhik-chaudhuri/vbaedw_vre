/* Script 0: Drop Materialized View */
-- Drop materialized view if it exists
DROP MATERIALIZED VIEW MV_POS_OUTCOMES_DETAILS;

/* Script 1: Materialized View Creation */
-- Creates the materialized view for the Positive Outcomes for the VRE NextGen Data Mart
CREATE MATERIALIZED VIEW MV_POS_OUTCOMES_DETAILS
REFRESH COMPLETE
ON DEMAND
START WITH sysdate
NEXT TRUNC(sysdate+1)+6.5/24 
AS
select 	C.PROGRAM_TYPE_CODE,
	a.case_id,
	b.first_nm,
	b.last_nm,
	b.ssn_nbr,
	f.station_number,
	f.station_name,
	f.station_display,
	f.district_description,
	f.district_display,
	D.BENEFIT_CLAIM_STATUS_DESC,
        D.BENEFIT_CLAIM_STATUS_CODE,
	D3.ACTUAL_DATE case_status_entry_date,
	D4.ACTUAL_DATE case_status_exit_date,
	c.last_paid_date,
	pd.first_name case_manager_first_name,
	pd.last_name case_manager_last_name,
    	CASE WHEN o.outbase_site_name in 
             ( 'Australia','China','Foreign Workload','Guam','Indonesia','Japan','Korea',
                'Kuala Lumpur, Malaysia','Kure Island','Laos','Manila','Manila RO',
                'Mayaguez','Micronesia','New Zealand','Okinawa','Palau','Saipan',
                'Samoa','Sepulveda','Sepulveda VA Clinic','Singapore','Taiwan','Thailand','Vancouver','Vietnam')
                 THEN 'Y' ELSE 'N' END ForeignCaseFlag,
	case when b.SEROUS_EMPLMT_HNDCAP_IND = 'Y' THEN 'SEH' ELSE 'EH' END eh_seh_flag,
	CASE  
            WHEN G.REASON_CODE = '17' THEN 'IL REHAB' 
            WHEN G.REASON_CODE IN ('22', '23') THEN 'EMP REHAB' 
            WHEN G.REASON_CODE =  '25' THEN 'EDU REHAB'
            WHEN G.REASON_CODE IN ('34','35','37') THEN 'MRG' 
            ELSE G.REASON_CODE
    	END Rehab_Type
from DW_VRE.VRE_CASE_STATUS_FACT a
INNER JOIN dw_vre_dim.case_dim c
    ON a.case_dim_sid = c.case_dim_sid
--    AND C.PROGRAM_TYPE_CODE in ('CH31','CH35','CH18')
inner join common_ss.ss_person b
    on c.veteran_participant_id = b.ptcpnt_id
inner join dw_dim.person_dim pd
	ON case_manager_employee_sid = pd.person_dim_sid
INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM D  -- Current case status
    ON  A.CASE_STATUS_CODE_DIM_SID = D.BENEFIT_CLAIM_STATUS_DIM_SID
INNER JOIN DW_DIM.EFFECTIVE_STATUS_INDICATOR_DIM E
    ON  A.EFFECTIVE_STATUS_IND_DIM_SID = E.EFFECTIVE_STATUS_IND_DIM_SID
    AND  E.EFFECTIVE_STATUS_IND_CODE <> 'D' -- SHOULD NOT BE 'Record has been deleted at source'
INNER JOIN DW_DIM.DATE_DIM D4 
    ON  A.CASE_STATUS_CLOSE_DATE_SID = D4.DATE_DIM_SID
    AND  COALESCE(TRUNC(D4.ACTUAL_DATE),SYSDATE) >= '01-OCT-2013' -- STATUS CLOSED DATE DURING FY21 ONWARD
INNER JOIN DW_DIM.DATE_DIM D3 ON A.CASE_STATUS_ENTRY_DATE_SID = D3.DATE_DIM_SID
--	AND D3.fiscal_year = (select distinct fiscal_year from dw_dim.date_dim where trunc(actual_date) = trunc(sysdate)) -- Current FY
INNER JOIN DW_DIM.VA_STATION_DIM F
   ON  A.CASE_MANAGER_VA_STATION_SID = F.VA_STATION_DIM_SID
INNER JOIN DW_VRE_DIM.STATUS_ENTRY_REASON_DIM G
    ON A.STATUS_ENTRY_REASON_DIM_SID = G.STATUS_ENTRY_REASON_DIM_SID
LEFT OUTER join (select a.*, rank() over (partition by outbase_site_lctn_id order by begin_effective_date desc) as rn
                    from dw_vre_dim.outbase_site_dim a
                    where current_record_ind='Y') o
                    on o.rn = 1
                    and c.site_location_id=o.outbase_site_lctn_id
WHERE (D.BENEFIT_CLAIM_STATUS_DESC IN ('Discontinued') AND G.REASON_CODE IN ('34','35','37')) OR (D.BENEFIT_CLAIM_STATUS_DESC IN ('Rehabilitated') AND G.REASON_CODE IN ('17','22','23','25'))
;


/* Script 2: Create Indexes on materialized view */

CREATE INDEX IX1_MV_INVENTORY_DETAILS ON MV_POS_OUTCOMES_DETAILS
(STATION_DISPLAY);

CREATE INDEX IX2_MV_INVENTORY_DETAILS ON MV_POS_OUTCOMES_DETAILS
(DISTRICT_DISPLAY);

CREATE INDEX IX3_MV_INVENTORY_DETAILS ON MV_POS_OUTCOMES_DETAILS
(BENEFIT_CLAIM_STATUS_DESC);

CREATE INDEX IX4_MV_INVENTORY_DETAILS ON MV_POS_OUTCOMES_DETAILS
(BENEFIT_CLAIM_STATUS_CODE);

CREATE INDEX IX5_MV_INVENTORY_DETAILS ON MV_POS_OUTCOMES_DETAILS
(FOREIGNCASEFLAG);

CREATE INDEX IX6_MV_INVENTORY_DETAILS ON MV_POS_OUTCOMES_DETAILS
(PROGRAM_TYPE_CODE);

CREATE INDEX IX7_MV_INVENTORY_DETAILS ON MV_POS_OUTCOMES_DETAILS
(AGING_FLAG);

CREATE INDEX IX8_MV_INVENTORY_DETAILS ON MV_POS_OUTCOMES_DETAILS
(EH_SEH_FLAG);



/* Script 3: Grant access */
GRANT SELECT ON MV_POS_OUTCOMES_DETAILS TO EDW_WALLBOARD;


