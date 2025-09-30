/* Script 0: Drop Materialized View */
-- Drop materialized view if it exists
DROP MATERIALIZED VIEW MV_INVENTORY_DETAILS;

/* Script 1: Materialized View Creation */
-- Creates the materialized view for the Inventory Details for the USB Dashboard
CREATE MATERIALIZED VIEW MV_INVENTORY_DETAILS
REFRESH COMPLETE
ON DEMAND
START WITH sysdate
NEXT TRUNC(sysdate+1)+6.5/24 
AS
select /*+ PARALLEL(AUTO) */ actual_date,
	case_id,
	PROGRAM_TYPE_CODE,
	first_nm,
	last_nm,
	ssn_nbr, 
	station_number,
	station_name,
	station_display,
	district_description,
	district_display,
	BENEFIT_CLAIM_STATUS_DESC,
        BENEFIT_CLAIM_STATUS_CODE,
	case_status_entry_date,
	case_status_exit_date,
	case_manager_last_name,
	case_manager_first_name,
	last_paid_date award_end_date,
	paid_date,
    	ForeignCaseFlag,
	eh_seh_flag,
	trunc(actual_date)-trunc(case_status_entry_date) days_in_status,
	CASE
                WHEN BENEFIT_CLAIM_STATUS_CODE = '001' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<60 THEN 'Y' ELSE 'N' END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '002' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 'Y' ELSE 'N' END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '003' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=365 THEN 'Y' ELSE 'N' END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '004' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=730 THEN 'Y' ELSE 'N' END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '006' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=545 THEN 'Y' ELSE 'N' END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '005' THEN 
                    CASE when paid_date >= case_status_entry_date AND trunc(actual_date)-trunc(paid_date) > 270
                        THEN 'N' ELSE 'Y' end
                WHEN BENEFIT_CLAIM_STATUS_CODE = '008' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 'Y' ELSE 'N' END
                ELSE 'N' 
	END active_flag,
	CASE
                WHEN BENEFIT_CLAIM_STATUS_CODE = '001' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<60 THEN 'N' ELSE 'Y' END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '002' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 'N' ELSE 'Y' END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '003' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=365 THEN 'N' ELSE 'Y' END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '004' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=730 THEN 'N' ELSE 'Y' END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '006' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=545 THEN 'N' ELSE 'Y' END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '005' THEN 
                    CASE when paid_date >= case_status_entry_date AND trunc(actual_date)-trunc(paid_date) > 270
                        THEN 'Y' ELSE 'N' end
                WHEN BENEFIT_CLAIM_STATUS_CODE = '008' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 'N' ELSE 'Y' END
                ELSE 'N' 
	END aging_flag
FROM 
(select g.actual_date,
	C.PROGRAM_TYPE_CODE,
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
	p.paid_date,
	pd.first_name case_manager_first_name,
	pd.last_name case_manager_last_name,
    	CASE WHEN o.outbase_site_name in 
             ( 'Australia','China','Foreign Workload','Guam','Indonesia','Japan','Korea',
                'Kuala Lumpur, Malaysia','Kure Island','Laos','Manila','Manila RO',
                'Mayaguez','Micronesia','New Zealand','Okinawa','Palau','Saipan',
                'Samoa','Sepulveda','Sepulveda VA Clinic','Singapore','Taiwan','Thailand','Vancouver','Vietnam')
                 THEN 'Y' ELSE 'N' END ForeignCaseFlag,
	case when b.SEROUS_EMPLMT_HNDCAP_IND = 'Y' THEN 'SEH' ELSE 'EH' END eh_seh_flag,
	rank() over (partition by a.case_id order by d4.actual_date desc, d3.actual_date desc, a.vre_case_status_fact_sid desc) rn
from DW_VRE.VRE_CASE_STATUS_FACT a
INNER JOIN dw_vre_dim.case_dim c
    ON a.case_dim_sid = c.case_dim_sid
    AND C.PROGRAM_TYPE_CODE in ('CH31','CH35','CH18')
INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM D 
    ON  A.CASE_STATUS_CODE_DIM_SID = D.BENEFIT_CLAIM_STATUS_DIM_SID
    AND  D.BENEFIT_CLAIM_STATUS_CODE IN ('001','002','003','004','005','006','008')
INNER JOIN DW_DIM.EFFECTIVE_STATUS_INDICATOR_DIM E
    ON  A.EFFECTIVE_STATUS_IND_DIM_SID = E.EFFECTIVE_STATUS_IND_DIM_SID
    AND  E.EFFECTIVE_STATUS_IND_CODE <> 'D' -- SHOULD NOT BE 'Record has been deleted at source'
INNER JOIN DW_DIM.VA_STATION_DIM F
    ON  A.CASE_MANAGER_VA_STATION_SID = F.VA_STATION_DIM_SID
inner join common_ss.ss_person b
    on c.veteran_participant_id = b.ptcpnt_id
inner join dw_dim.person_dim pd
	ON case_manager_employee_sid = pd.person_dim_sid
INNER JOIN DW_DIM.DATE_DIM D3 ON A.CASE_STATUS_ENTRY_DATE_SID = D3.DATE_DIM_SID
INNER JOIN DW_DIM.DATE_DIM D4 ON A.CASE_STATUS_CLOSE_DATE_SID = D4.DATE_DIM_SID
INNER JOIN DW_DIM.DATE_DIM G
--	ON G.ACTUAL_DATE BETWEEN TRUNC(D3.ACTUAL_DATE) AND COALESCE(TRUNC(D4.ACTUAL_DATE),SYSDATE) 
	ON G.ACTUAL_DATE BETWEEN TRUNC(D3.ACTUAL_DATE) AND TRUNC(D4.ACTUAL_DATE)
	AND trunc(G.ACTUAL_DATE) = trunc(SYSDATE)
LEFT OUTER JOIN (SELECT * FROM(
            SELECT
                F.CASE_DIM_SID,
                D.ACTUAL_DATE AS PAID_DATE,
                ROW_NUMBER() OVER(PARTITION BY F.CASE_DIM_SID ORDER BY D.ACTUAL_DATE DESC) AS RN
            FROM DW_VRE.VRE_BENEFICIARY_PYMNT_FACT F
            INNER JOIN DW_VRE_DIM.CASE_EXPENSE_TYPE_DIM E
                ON E.CASE_EXPENSE_TYPE_DIM_SID = F.CASE_EXPENSE_TYPE_DIM_SID
                AND E.CASE_EXPENSE_TYPE = 'Subsistence'
            INNER JOIN DW_DIM.DATE_DIM D
                ON D.DATE_DIM_SID = F.PAID_DATE_SID
                AND D.ACTUAL_DATE IS NOT NULL
            WHERE F.EFFECTIVE_STATUS_IND_DIM_SID = 1
            ) WHERE RN = 1) P
    ON A.CASE_DIM_SID = P.CASE_DIM_SID
LEFT OUTER JOIN (select a.*, rank() over (partition by outbase_site_lctn_id order by begin_effective_date desc) as rn
                    from dw_vre_dim.outbase_site_dim a
                    where current_record_ind='Y') o
                    on o.rn = 1
                    and c.site_location_id=o.outbase_site_lctn_id
) where rn=1
;

/* Script 2: Create Indexes on materialized view */

CREATE INDEX IX1_MV_INVENTORY_DETAILS ON MV_INVENTORY_DETAILS
(STATION_DISPLAY);

CREATE INDEX IX2_MV_INVENTORY_DETAILS ON MV_INVENTORY_DETAILS
(DISTRICT_DISPLAY);

CREATE INDEX IX3_MV_INVENTORY_DETAILS ON MV_INVENTORY_DETAILS
(BENEFIT_CLAIM_STATUS_DESC);

CREATE INDEX IX4_MV_INVENTORY_DETAILS ON MV_INVENTORY_DETAILS
(BENEFIT_CLAIM_STATUS_CODE);

CREATE INDEX IX5_MV_INVENTORY_DETAILS ON MV_INVENTORY_DETAILS
(FOREIGNCASEFLAG);

CREATE INDEX IX6_MV_INVENTORY_DETAILS ON MV_INVENTORY_DETAILS
(PROGRAM_TYPE_CODE);

CREATE INDEX IX7_MV_INVENTORY_DETAILS ON MV_INVENTORY_DETAILS
(AGING_FLAG);

CREATE INDEX IX8_MV_INVENTORY_DETAILS ON MV_INVENTORY_DETAILS
(EH_SEH_FLAG);



/* Script 3: Grant access */
GRANT SELECT ON MV_INVENTORY_DETAILS TO EDW_WALLBOARD;


