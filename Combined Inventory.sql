/*
Adds the following to the baseline from Combined Inventory 5.sql 
-- Revised list of Outbased Sites
*/
SELECT * FROM
(
WITH t_today AS
(
SELECT actual_date,
    ForeignCaseFlag,
    BENEFIT_CLAIM_STATUS_CODE,
	BENEFIT_CLAIM_STATUS_DESC,
	count(case_id) inventory,
	sum(CASE
                WHEN BENEFIT_CLAIM_STATUS_CODE = '001' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<60 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '002' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '003' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=365 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '004' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=730 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '006' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=545 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '005' THEN 
                    CASE when paid_date >= case_status_entry_date AND trunc(actual_date)-trunc(paid_date) > 270
                        THEN 0 ELSE 1 end
                WHEN BENEFIT_CLAIM_STATUS_CODE = '008' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 1 ELSE 0 END
                ELSE 0 
            END) total_active_caseload,
        sum(trunc(actual_date)-trunc(case_status_entry_date)) total_days_in_status,
	sum(CASE
                WHEN BENEFIT_CLAIM_STATUS_CODE = '001' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<60 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '002' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '003' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=365 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '004' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=730 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '006' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=545 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '005' THEN 
                    CASE when paid_date >= case_status_entry_date AND trunc(actual_date)-trunc(paid_date) > 270
                        THEN 1 ELSE 0 end
                WHEN BENEFIT_CLAIM_STATUS_CODE = '008' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 0 ELSE 1 END
                ELSE 0 
            END) total_aging_caseload,
	sum(CASE
                WHEN BENEFIT_CLAIM_STATUS_CODE = '001' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<60 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '002' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '003' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=365 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '004' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=730 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '006' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=545 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '005' THEN 
                    CASE when paid_date >= case_status_entry_date AND trunc(actual_date)-trunc(paid_date) > 270
                        THEN trunc(actual_date)-trunc(case_status_entry_date) ELSE 0 end
                WHEN BENEFIT_CLAIM_STATUS_CODE = '008' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                ELSE 0 
            END) total_days_in_status_aging
		FROM  
(select g.actual_date, a.case_id,
	D.BENEFIT_CLAIM_STATUS_DESC,
        D.BENEFIT_CLAIM_STATUS_CODE,
	D3.ACTUAL_DATE case_status_entry_date,
	D4.ACTUAL_DATE case_status_exit_date,
	p.paid_date,
    	CASE WHEN o.outbase_site_name in 
             ( 'Australia','China','Foreign Workload','Guam','Indonesia','Japan','Korea',
                'Kuala Lumpur, Malaysia','Kure Island','Laos','Manila','Manila RO',
                'Mayaguez','Micronesia','New Zealand','Okinawa','Palau','Saipan',
                'Samoa','Sepulveda','Sepulveda VA Clinic','Singapore','Taiwan','Thailand','Vancouver','Vietnam')
                 THEN 'Y' ELSE 'N' END ForeignCaseFlag,
--	case when b.SEROUS_EMPLMT_HNDCAP_IND = 'Y' THEN 'SEH' ELSE 'EH' END eh_seh_flag,
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
--inner join common_ss.ss_person b
--    on c.veteran_participant_id = b.ptcpnt_id
INNER JOIN DW_DIM.DATE_DIM D3 ON A.CASE_STATUS_ENTRY_DATE_SID = D3.DATE_DIM_SID
INNER JOIN DW_DIM.DATE_DIM D4 ON A.CASE_STATUS_CLOSE_DATE_SID = D4.DATE_DIM_SID
INNER JOIN DW_DIM.DATE_DIM G
	ON G.ACTUAL_DATE BETWEEN TRUNC(D3.ACTUAL_DATE) AND COALESCE(TRUNC(D4.ACTUAL_DATE),SYSDATE) 
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
GROUP BY actual_date,ForeignCaseFlag,BENEFIT_CLAIM_STATUS_CODE, BENEFIT_CLAIM_STATUS_DESC
), -- end of t_today
t_yesterday AS
(
SELECT actual_date,
    	ForeignCaseFlag,
	BENEFIT_CLAIM_STATUS_CODE,
	BENEFIT_CLAIM_STATUS_DESC,
	count(case_id) inventory,
	sum(CASE
                WHEN BENEFIT_CLAIM_STATUS_CODE = '001' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<60 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '002' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '003' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=365 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '004' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=730 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '006' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=545 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '005' THEN 
                    CASE when paid_date >= case_status_entry_date AND trunc(actual_date)-trunc(paid_date) > 270
                        THEN 0 ELSE 1 end
                WHEN BENEFIT_CLAIM_STATUS_CODE = '008' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 1 ELSE 0 END
                ELSE 0 
            END) total_active_caseload,
        sum(trunc(actual_date)-trunc(case_status_entry_date)) total_days_in_status,
	sum(CASE
                WHEN BENEFIT_CLAIM_STATUS_CODE = '001' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<60 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '002' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '003' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=365 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '004' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=730 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '006' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=545 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '005' THEN 
                    CASE when paid_date >= case_status_entry_date AND trunc(actual_date)-trunc(paid_date) > 270
                        THEN 1 ELSE 0 end
                WHEN BENEFIT_CLAIM_STATUS_CODE = '008' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 0 ELSE 1 END
                ELSE 0 
            END) total_aging_caseload,
	sum(CASE
                WHEN BENEFIT_CLAIM_STATUS_CODE = '001' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<60 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '002' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '003' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=365 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '004' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=730 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '006' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=545 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '005' THEN 
                    CASE when paid_date >= case_status_entry_date AND trunc(actual_date)-trunc(paid_date) > 270
                        THEN trunc(actual_date)-trunc(case_status_entry_date) ELSE 0 end
                WHEN BENEFIT_CLAIM_STATUS_CODE = '008' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                ELSE 0 
            END) total_days_in_status_aging
FROM  
(select g.actual_date, a.case_id,
	D.BENEFIT_CLAIM_STATUS_DESC,
        D.BENEFIT_CLAIM_STATUS_CODE,
	D3.ACTUAL_DATE case_status_entry_date,
	D4.ACTUAL_DATE case_status_exit_date,
	p.paid_date,
    	CASE WHEN o.outbase_site_name in 
             ( 'Australia','China','Foreign Workload','Guam','Indonesia','Japan','Korea',
                'Kuala Lumpur, Malaysia','Kure Island','Laos','Manila','Manila RO',
                'Mayaguez','Micronesia','New Zealand','Okinawa','Palau','Saipan',
                'Samoa','Sepulveda','Sepulveda VA Clinic','Singapore','Taiwan','Thailand','Vancouver','Vietnam')
                 THEN 'Y' ELSE 'N' END ForeignCaseFlag,
--	case when b.SEROUS_EMPLMT_HNDCAP_IND = 'Y' THEN 'SEH' ELSE 'EH' END eh_seh_flag,
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
--inner join common_ss.ss_person b
--    on c.veteran_participant_id = b.ptcpnt_id
INNER JOIN DW_DIM.DATE_DIM D3 ON A.CASE_STATUS_ENTRY_DATE_SID = D3.DATE_DIM_SID
INNER JOIN DW_DIM.DATE_DIM D4 ON A.CASE_STATUS_CLOSE_DATE_SID = D4.DATE_DIM_SID
INNER JOIN DW_DIM.DATE_DIM G
	ON G.ACTUAL_DATE BETWEEN TRUNC(D3.ACTUAL_DATE) AND COALESCE(TRUNC(D4.ACTUAL_DATE),SYSDATE) 
	AND trunc(G.ACTUAL_DATE) = trunc(SYSDATE-1)
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
LEFT OUTER join (select a.*, rank() over (partition by outbase_site_lctn_id order by begin_effective_date desc) as rn
                    from dw_vre_dim.outbase_site_dim a
                    where current_record_ind='Y') o
                    on o.rn = 1
                    and c.site_location_id=o.outbase_site_lctn_id
) where rn=1
GROUP BY actual_date,ForeignCaseFlag,BENEFIT_CLAIM_STATUS_CODE, BENEFIT_CLAIM_STATUS_DESC
), -- end of t_yesterday
t_one_month_ago AS
(
SELECT actual_date,
    	ForeignCaseFlag,
	BENEFIT_CLAIM_STATUS_CODE,
	BENEFIT_CLAIM_STATUS_DESC,
	count(case_id) inventory,
	sum(CASE
                WHEN BENEFIT_CLAIM_STATUS_CODE = '001' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<60 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '002' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '003' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=365 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '004' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=730 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '006' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=545 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '005' THEN 
                    CASE when paid_date >= case_status_entry_date AND trunc(actual_date)-trunc(paid_date) > 270
                        THEN 0 ELSE 1 end
                WHEN BENEFIT_CLAIM_STATUS_CODE = '008' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 1 ELSE 0 END
                ELSE 0 
            END) total_active_caseload,
        sum(trunc(actual_date)-trunc(case_status_entry_date)) total_days_in_status,
	sum(CASE
                WHEN BENEFIT_CLAIM_STATUS_CODE = '001' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<60 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '002' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '003' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=365 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '004' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=730 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '006' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=545 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '005' THEN 
                    CASE when paid_date >= case_status_entry_date AND trunc(actual_date)-trunc(paid_date) > 270
                        THEN 1 ELSE 0 end
                WHEN BENEFIT_CLAIM_STATUS_CODE = '008' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 0 ELSE 1 END
                ELSE 0 
            END) total_aging_caseload,
	sum(CASE
                WHEN BENEFIT_CLAIM_STATUS_CODE = '001' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<60 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '002' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '003' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=365 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '004' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=730 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '006' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=545 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '005' THEN 
                    CASE when paid_date >= case_status_entry_date AND trunc(actual_date)-trunc(paid_date) > 270
                        THEN trunc(actual_date)-trunc(case_status_entry_date) ELSE 0 end
                WHEN BENEFIT_CLAIM_STATUS_CODE = '008' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                ELSE 0 
            END) total_days_in_status_aging
FROM  
(select g.actual_date, a.case_id,
	D.BENEFIT_CLAIM_STATUS_DESC,
        D.BENEFIT_CLAIM_STATUS_CODE,
	D3.ACTUAL_DATE case_status_entry_date,
	D4.ACTUAL_DATE case_status_exit_date,
	p.paid_date,
    	CASE WHEN o.outbase_site_name in 
             ( 'Australia','China','Foreign Workload','Guam','Indonesia','Japan','Korea',
                'Kuala Lumpur, Malaysia','Kure Island','Laos','Manila','Manila RO',
                'Mayaguez','Micronesia','New Zealand','Okinawa','Palau','Saipan',
                'Samoa','Sepulveda','Sepulveda VA Clinic','Singapore','Taiwan','Thailand','Vancouver','Vietnam')
                 THEN 'Y' ELSE 'N' END ForeignCaseFlag,
--	case when b.SEROUS_EMPLMT_HNDCAP_IND = 'Y' THEN 'SEH' ELSE 'EH' END eh_seh_flag,
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
--inner join common_ss.ss_person b
--    on c.veteran_participant_id = b.ptcpnt_id
INNER JOIN DW_DIM.DATE_DIM D3 ON A.CASE_STATUS_ENTRY_DATE_SID = D3.DATE_DIM_SID
INNER JOIN DW_DIM.DATE_DIM D4 ON A.CASE_STATUS_CLOSE_DATE_SID = D4.DATE_DIM_SID
INNER JOIN DW_DIM.DATE_DIM G
	ON G.ACTUAL_DATE BETWEEN TRUNC(D3.ACTUAL_DATE) AND COALESCE(TRUNC(D4.ACTUAL_DATE),SYSDATE) 
	AND trunc(G.ACTUAL_DATE) = ADD_MONTHS(trunc(SYSDATE),-1)
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
LEFT OUTER join (select a.*, rank() over (partition by outbase_site_lctn_id order by begin_effective_date desc) as rn
                    from dw_vre_dim.outbase_site_dim a
                    where current_record_ind='Y') o
                    on o.rn = 1
                    and c.site_location_id=o.outbase_site_lctn_id
) where rn=1
GROUP BY actual_date,ForeignCaseFlag,BENEFIT_CLAIM_STATUS_CODE, BENEFIT_CLAIM_STATUS_DESC
), -- end of t_one_month_ago
t_completed AS
(
select CASE WHEN o.outbase_site_name in 
             ( 'Australia','China','Foreign Workload','Guam','Indonesia','Japan','Korea',
                'Kuala Lumpur, Malaysia','Kure Island','Laos','Manila','Manila RO',
                'Mayaguez','Micronesia','New Zealand','Okinawa','Palau','Saipan',
                'Samoa','Sepulveda','Sepulveda VA Clinic','Singapore','Taiwan','Thailand','Vancouver','Vietnam')
                 THEN 'Y' ELSE 'N' END ForeignCaseFlag,
	D.BENEFIT_CLAIM_STATUS_DESC,
        D.BENEFIT_CLAIM_STATUS_CODE,
        count(distinct a.case_id) cases_exiting_status,
	sum(trunc(D4.actual_date)-trunc(D3.actual_date)) total_days_in_status 
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
INNER JOIN DW_DIM.DATE_DIM D3 ON A.CASE_STATUS_ENTRY_DATE_SID = D3.DATE_DIM_SID
INNER JOIN DW_DIM.DATE_DIM D4 ON A.CASE_STATUS_CLOSE_DATE_SID = D4.DATE_DIM_SID
LEFT OUTER join (select a.*, rank() over (partition by outbase_site_lctn_id order by begin_effective_date desc) as rn
                    from dw_vre_dim.outbase_site_dim a
                    where current_record_ind='Y') o
                    on o.rn = 1
                    and c.site_location_id=o.outbase_site_lctn_id
WHERE D4.fiscal_year = (select distinct fiscal_year from dw_dim.date_dim where trunc(actual_date) = trunc(sysdate)) -- Current FY
GROUP BY CASE WHEN o.outbase_site_name in 
             ( 'Australia','China','Foreign Workload','Guam','Indonesia','Japan','Korea',
                'Kuala Lumpur, Malaysia','Kure Island','Laos','Manila','Manila RO',
                'Mayaguez','Micronesia','New Zealand','Okinawa','Palau','Saipan',
                'Samoa','Sepulveda','Sepulveda VA Clinic','Singapore','Taiwan','Thailand','Vancouver','Vietnam')
                 THEN 'Y' ELSE 'N' END,
		D.BENEFIT_CLAIM_STATUS_DESC, D.BENEFIT_CLAIM_STATUS_CODE
) -- end of t_completed
SELECT t.actual_date todays_date,
	y.actual_date yesterdays_date,
	oma.actual_date one_month_ago_date,
	t.foreigncaseflag,
	t.BENEFIT_CLAIM_STATUS_DESC,
        t.BENEFIT_CLAIM_STATUS_CODE,
        t.inventory inventory_today,
        y.inventory inventory_yesterday,
        oma.inventory inventory_one_month_ago,
        t.total_active_caseload total_active_caseload_today,
        y.total_active_caseload total_active_caseload_yesterday,
        oma.total_active_caseload total_active_caseload_one_month_ago,
        t.total_days_in_status total_days_in_pend_status,
	c.cases_exiting_status cases_completed_current_FY,
        c.total_days_in_status total_days_in_comp_status,
	t.total_aging_caseload total_aging_caseload_today,
	t.total_days_in_status_aging total_days_in_status_aging_today,
	y.total_aging_caseload total_aging_caseload_yesterday,
	y.total_days_in_status_aging total_days_in_status_aging_yesterday,
	oma.total_aging_caseload total_aging_caseload_one_month_ago,
	oma.total_days_in_status_aging total_days_in_status_aging_one_month_ago      
FROM t_today t
INNER JOIN t_yesterday y
    ON t.BENEFIT_CLAIM_STATUS_DESC = y.BENEFIT_CLAIM_STATUS_DESC
    AND t.BENEFIT_CLAIM_STATUS_CODE = y.BENEFIT_CLAIM_STATUS_CODE
	AND t.foreigncaseflag = y.foreigncaseflag
INNER JOIN t_completed c
    ON t.BENEFIT_CLAIM_STATUS_DESC = c.BENEFIT_CLAIM_STATUS_DESC
    AND t.BENEFIT_CLAIM_STATUS_CODE = c.BENEFIT_CLAIM_STATUS_CODE
	AND t.foreigncaseflag = c.foreigncaseflag
INNER JOIN t_one_month_ago oma
    ON t.BENEFIT_CLAIM_STATUS_DESC = oma.BENEFIT_CLAIM_STATUS_DESC
    AND t.BENEFIT_CLAIM_STATUS_CODE = oma.BENEFIT_CLAIM_STATUS_CODE
	AND t.foreigncaseflag = oma.foreigncaseflag
)
UNION --joining main query and 005 sub-status query
select * from
(
WITH t_005_today AS
(
SELECT actual_date,foreigncaseflag,BENEFIT_CLAIM_STATUS_CODE,
	BENEFIT_CLAIM_STATUS_DESC,
	eh_seh_flag,
	count(case_id) inventory,
	sum(CASE
                WHEN BENEFIT_CLAIM_STATUS_CODE = '001' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<60 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '002' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '003' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=365 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '004' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=730 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '006' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=545 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '005' THEN 
                    CASE when paid_date >= case_status_entry_date AND trunc(actual_date)-trunc(paid_date) > 270
                        THEN 0 ELSE 1 end
                WHEN BENEFIT_CLAIM_STATUS_CODE = '008' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 1 ELSE 0 END
                ELSE 0 
            END) total_active_caseload,
        sum(trunc(actual_date)-trunc(case_status_entry_date)) total_days_in_status,
	sum(CASE
                WHEN BENEFIT_CLAIM_STATUS_CODE = '001' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<60 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '002' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '003' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=365 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '004' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=730 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '006' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=545 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '005' THEN 
                    CASE when paid_date >= case_status_entry_date AND trunc(actual_date)-trunc(paid_date) > 270
                        THEN 1 ELSE 0 end
                WHEN BENEFIT_CLAIM_STATUS_CODE = '008' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 0 ELSE 1 END
                ELSE 0 
            END) total_aging_caseload,
	sum(CASE
                WHEN BENEFIT_CLAIM_STATUS_CODE = '001' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<60 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '002' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '003' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=365 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '004' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=730 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '006' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=545 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '005' THEN 
                    CASE when paid_date >= case_status_entry_date AND trunc(actual_date)-trunc(paid_date) > 270
                        THEN trunc(actual_date)-trunc(case_status_entry_date) ELSE 0 end
                WHEN BENEFIT_CLAIM_STATUS_CODE = '008' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                ELSE 0 
            END) total_days_in_status_aging
FROM  
(select  g.actual_date, a.case_id,
	D.BENEFIT_CLAIM_STATUS_DESC,
        D.BENEFIT_CLAIM_STATUS_CODE,
	D3.ACTUAL_DATE case_status_entry_date,
	D4.ACTUAL_DATE case_status_exit_date,
	p.paid_date,
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
INNER JOIN DW_DIM.DATE_DIM D3 ON A.CASE_STATUS_ENTRY_DATE_SID = D3.DATE_DIM_SID
INNER JOIN DW_DIM.DATE_DIM D4 ON A.CASE_STATUS_CLOSE_DATE_SID = D4.DATE_DIM_SID
INNER JOIN DW_DIM.DATE_DIM G
	ON G.ACTUAL_DATE BETWEEN TRUNC(D3.ACTUAL_DATE) AND COALESCE(TRUNC(D4.ACTUAL_DATE),SYSDATE) 
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
LEFT OUTER join (select a.*, rank() over (partition by outbase_site_lctn_id order by begin_effective_date desc) as rn
                    from dw_vre_dim.outbase_site_dim a
                    where current_record_ind='Y') o
                    on o.rn = 1
                    and c.site_location_id=o.outbase_site_lctn_id
) where rn=1 and  BENEFIT_CLAIM_STATUS_CODE = '005'
GROUP BY actual_date,foreigncaseflag,BENEFIT_CLAIM_STATUS_CODE, BENEFIT_CLAIM_STATUS_DESC, eh_seh_flag
), -- t_005_today
t_005_yesterday AS
(
SELECT actual_date,foreigncaseflag,BENEFIT_CLAIM_STATUS_CODE,
	BENEFIT_CLAIM_STATUS_DESC,
	eh_seh_flag,
	count(case_id) inventory,
	sum(CASE
                WHEN BENEFIT_CLAIM_STATUS_CODE = '001' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<60 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '002' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '003' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=365 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '004' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=730 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '006' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=545 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '005' THEN 
                    CASE when paid_date >= case_status_entry_date AND trunc(actual_date)-trunc(paid_date) > 270
                        THEN 0 ELSE 1 end
                WHEN BENEFIT_CLAIM_STATUS_CODE = '008' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 1 ELSE 0 END
                ELSE 0 
            END) total_active_caseload,
        sum(trunc(actual_date)-trunc(case_status_entry_date)) total_days_in_status,
        sum(trunc(actual_date)-trunc(case_status_entry_date))/count(case_id) avg_days_in_status,   
        (sum(trunc(actual_date)-trunc(case_status_entry_date))/count(case_id))/30.4375 AMP,
	sum(CASE
                WHEN BENEFIT_CLAIM_STATUS_CODE = '001' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<60 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '002' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '003' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=365 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '004' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=730 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '006' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=545 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '005' THEN 
                    CASE when paid_date >= case_status_entry_date AND trunc(actual_date)-trunc(paid_date) > 270
                        THEN 1 ELSE 0 end
                WHEN BENEFIT_CLAIM_STATUS_CODE = '008' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 0 ELSE 1 END
                ELSE 0 
            END) total_aging_caseload,
	sum(CASE
                WHEN BENEFIT_CLAIM_STATUS_CODE = '001' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<60 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '002' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '003' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=365 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '004' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=730 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '006' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=545 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '005' THEN 
                    CASE when paid_date >= case_status_entry_date AND trunc(actual_date)-trunc(paid_date) > 270
                        THEN trunc(actual_date)-trunc(case_status_entry_date) ELSE 0 end
                WHEN BENEFIT_CLAIM_STATUS_CODE = '008' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                ELSE 0 
            END) total_days_in_status_aging
FROM  
(select g.actual_date, a.case_id,
	D.BENEFIT_CLAIM_STATUS_DESC,
        D.BENEFIT_CLAIM_STATUS_CODE,
	D3.ACTUAL_DATE case_status_entry_date,
	D4.ACTUAL_DATE case_status_exit_date,
	p.paid_date,
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
INNER JOIN DW_DIM.DATE_DIM D3 ON A.CASE_STATUS_ENTRY_DATE_SID = D3.DATE_DIM_SID
INNER JOIN DW_DIM.DATE_DIM D4 ON A.CASE_STATUS_CLOSE_DATE_SID = D4.DATE_DIM_SID
INNER JOIN DW_DIM.DATE_DIM G
	ON G.ACTUAL_DATE BETWEEN TRUNC(D3.ACTUAL_DATE) AND COALESCE(TRUNC(D4.ACTUAL_DATE),SYSDATE) 
	AND trunc(G.ACTUAL_DATE) = trunc(SYSDATE-1)
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
LEFT OUTER join (select a.*, rank() over (partition by outbase_site_lctn_id order by begin_effective_date desc) as rn
                    from dw_vre_dim.outbase_site_dim a
                    where current_record_ind='Y') o
                    on o.rn = 1
                    and c.site_location_id=o.outbase_site_lctn_id
) where rn=1 and  BENEFIT_CLAIM_STATUS_CODE = '005'
GROUP BY actual_date,ForeignCaseFlag,BENEFIT_CLAIM_STATUS_CODE, BENEFIT_CLAIM_STATUS_DESC, eh_seh_flag
), -- End of t_005_yesterday
t_005_one_month_ago AS
(
SELECT actual_date,foreigncaseflag,BENEFIT_CLAIM_STATUS_CODE,
	BENEFIT_CLAIM_STATUS_DESC,
	eh_seh_flag,
	count(case_id) inventory,
	sum(CASE
                WHEN BENEFIT_CLAIM_STATUS_CODE = '001' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<60 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '002' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '003' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=365 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '004' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=730 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '006' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=545 THEN 1 ELSE 0 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '005' THEN 
                    CASE when paid_date >= case_status_entry_date AND trunc(actual_date)-trunc(paid_date) > 270
                        THEN 0 ELSE 1 end
                WHEN BENEFIT_CLAIM_STATUS_CODE = '008' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 1 ELSE 0 END
                ELSE 0 
            END) total_active_caseload,
        sum(trunc(actual_date)-trunc(case_status_entry_date)) total_days_in_status,
	sum(CASE
                WHEN BENEFIT_CLAIM_STATUS_CODE = '001' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<60 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '002' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '003' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=365 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '004' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=730 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '006' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=545 THEN 0 ELSE 1 END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '005' THEN 
                    CASE when paid_date >= case_status_entry_date AND trunc(actual_date)-trunc(paid_date) > 270
                        THEN 1 ELSE 0 end
                WHEN BENEFIT_CLAIM_STATUS_CODE = '008' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 0 ELSE 1 END
                ELSE 0 
            END) total_aging_caseload,
	sum(CASE
                WHEN BENEFIT_CLAIM_STATUS_CODE = '001' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<60 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '002' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '003' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=365 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '004' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=730 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '006' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=545 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                WHEN BENEFIT_CLAIM_STATUS_CODE = '005' THEN 
                    CASE when paid_date >= case_status_entry_date AND trunc(actual_date)-trunc(paid_date) > 270
                        THEN trunc(actual_date)-trunc(case_status_entry_date) ELSE 0 end
                WHEN BENEFIT_CLAIM_STATUS_CODE = '008' THEN CASE WHEN TRUNC(actual_date)-TRUNC(case_status_entry_date)<=180 THEN 0 ELSE trunc(actual_date)-trunc(case_status_entry_date) END
                ELSE 0 
            END) total_days_in_status_aging
FROM  
(select g.actual_date, a.case_id,
	D.BENEFIT_CLAIM_STATUS_DESC,
        D.BENEFIT_CLAIM_STATUS_CODE,
	D3.ACTUAL_DATE case_status_entry_date,
	D4.ACTUAL_DATE case_status_exit_date,
	p.paid_date,
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
INNER JOIN DW_DIM.DATE_DIM D3 ON A.CASE_STATUS_ENTRY_DATE_SID = D3.DATE_DIM_SID
INNER JOIN DW_DIM.DATE_DIM D4 ON A.CASE_STATUS_CLOSE_DATE_SID = D4.DATE_DIM_SID
INNER JOIN DW_DIM.DATE_DIM G
	ON G.ACTUAL_DATE BETWEEN TRUNC(D3.ACTUAL_DATE) AND COALESCE(TRUNC(D4.ACTUAL_DATE),SYSDATE) 
	AND trunc(G.ACTUAL_DATE) = ADD_MONTHS(trunc(SYSDATE),-1)
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
LEFT OUTER join (select a.*, rank() over (partition by outbase_site_lctn_id order by begin_effective_date desc) as rn
                    from dw_vre_dim.outbase_site_dim a
                    where current_record_ind='Y') o
                    on o.rn = 1
                    and c.site_location_id=o.outbase_site_lctn_id
) where rn=1 and  BENEFIT_CLAIM_STATUS_CODE = '005'
GROUP BY actual_date,ForeignCaseFlag,BENEFIT_CLAIM_STATUS_CODE, BENEFIT_CLAIM_STATUS_DESC, eh_seh_flag
), -- End of t_005_one_month_ago
t_005_compl AS 
(
select CASE WHEN o.outbase_site_name in 
             ( 'Australia','China','Foreign Workload','Guam','Indonesia','Japan','Korea',
                'Kuala Lumpur, Malaysia','Kure Island','Laos','Manila','Manila RO',
                'Mayaguez','Micronesia','New Zealand','Okinawa','Palau','Saipan',
                'Samoa','Sepulveda','Sepulveda VA Clinic','Singapore','Taiwan','Thailand','Vancouver','Vietnam')
                 THEN 'Y' ELSE 'N' END ForeignCaseFlag,
	D.BENEFIT_CLAIM_STATUS_DESC,
        D.BENEFIT_CLAIM_STATUS_CODE,
        case when b.SEROUS_EMPLMT_HNDCAP_IND = 'Y' THEN 'SEH' ELSE 'EH' END eh_seh_flag,
        count(distinct a.case_id) cases_exiting_status,
	sum(trunc(D4.actual_date)-trunc(D3.actual_date)) total_days_in_status
from DW_VRE.VRE_CASE_STATUS_FACT a
INNER JOIN dw_vre_dim.case_dim c
    ON a.case_dim_sid = c.case_dim_sid
    AND C.PROGRAM_TYPE_CODE in ('CH31','CH35','CH18')
INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM D 
    ON  A.CASE_STATUS_CODE_DIM_SID = D.BENEFIT_CLAIM_STATUS_DIM_SID
    AND  D.BENEFIT_CLAIM_STATUS_CODE = '005'
inner join common_ss.ss_person b
    on c.veteran_participant_id = b.ptcpnt_id
INNER JOIN DW_DIM.EFFECTIVE_STATUS_INDICATOR_DIM E
    ON  A.EFFECTIVE_STATUS_IND_DIM_SID = E.EFFECTIVE_STATUS_IND_DIM_SID
    AND  E.EFFECTIVE_STATUS_IND_CODE <> 'D' -- SHOULD NOT BE 'Record has been deleted at source'
INNER JOIN DW_DIM.VA_STATION_DIM F
    ON  A.CASE_MANAGER_VA_STATION_SID = F.VA_STATION_DIM_SID
INNER JOIN DW_DIM.DATE_DIM D3 ON A.CASE_STATUS_ENTRY_DATE_SID = D3.DATE_DIM_SID
INNER JOIN DW_DIM.DATE_DIM D4 ON A.CASE_STATUS_CLOSE_DATE_SID = D4.DATE_DIM_SID
LEFT OUTER join (select a.*, rank() over (partition by outbase_site_lctn_id order by begin_effective_date desc) as rn
                    from dw_vre_dim.outbase_site_dim a
                    where current_record_ind='Y') o
                    on o.rn = 1
                    and c.site_location_id=o.outbase_site_lctn_id
WHERE D4.fiscal_year = (select distinct fiscal_year from dw_dim.date_dim where trunc(actual_date) = trunc(sysdate)) -- Current FY
GROUP BY CASE WHEN o.outbase_site_name in 
             ( 'Australia','China','Foreign Workload','Guam','Indonesia','Japan','Korea',
                'Kuala Lumpur, Malaysia','Kure Island','Laos','Manila','Manila RO',
                'Mayaguez','Micronesia','New Zealand','Okinawa','Palau','Saipan',
                'Samoa','Sepulveda','Sepulveda VA Clinic','Singapore','Taiwan','Thailand','Vancouver','Vietnam')
                 THEN 'Y' ELSE 'N' END,
		D.BENEFIT_CLAIM_STATUS_DESC,  D.BENEFIT_CLAIM_STATUS_CODE, case when b.SEROUS_EMPLMT_HNDCAP_IND = 'Y' THEN 'SEH' ELSE 'EH' END
)
SELECT a.actual_date todays_date,
	b.actual_date yesterdays_date,
	oma.actual_date one_month_ago_date,
	a.foreigncaseflag,
	a.BENEFIT_CLAIM_STATUS_DESC||' - '||a.eh_seh_flag BENEFIT_CLAIM_STATUS_DESC,
	case when a.eh_seh_flag = 'EH' then a.BENEFIT_CLAIM_STATUS_CODE||'-EH' else a.BENEFIT_CLAIM_STATUS_CODE||'-SEH' end BENEFIT_CLAIM_STATUS_CODE,
        a.inventory inventory_today,
        b.inventory inventory_yesterday,
        oma.inventory inventory_one_month_ago,
        a.total_active_caseload total_active_caseload_today,
        b.total_active_caseload total_active_caseload_yesterday,
        oma.total_active_caseload total_active_caseload_one_month_ago,
	a.total_DAYS_IN_STATUS total_days_in_pend_status,
	c.cases_exiting_status cases_completed_current_FY,
	c.total_DAYS_IN_STATUS total_days_in_comp_status,
	a.total_aging_caseload total_aging_caseload_today,
	a.total_days_in_status_aging total_days_in_status_aging_today,
	b.total_aging_caseload total_aging_caseload_yesterday,
	b.total_days_in_status_aging total_days_in_status_aging_yesterday,
	oma.total_aging_caseload total_aging_caseload_one_month_ago,
	oma.total_days_in_status_aging total_days_in_status_aging_one_month_ago  
FROM t_005_today a
INNER JOIN t_005_yesterday b
    ON a.BENEFIT_CLAIM_STATUS_DESC = b.BENEFIT_CLAIM_STATUS_DESC
    AND a.BENEFIT_CLAIM_STATUS_CODE = b.BENEFIT_CLAIM_STATUS_CODE
    AND a.eh_seh_flag = b.eh_seh_flag
	AND a.foreigncaseflag = b.foreigncaseflag
INNER JOIN t_005_compl c
    ON a.BENEFIT_CLAIM_STATUS_DESC = c.BENEFIT_CLAIM_STATUS_DESC
    AND a.BENEFIT_CLAIM_STATUS_CODE = c.BENEFIT_CLAIM_STATUS_CODE
    AND a.eh_seh_flag = c.eh_seh_flag
	AND a.foreigncaseflag = c.foreigncaseflag
INNER JOIN t_005_one_month_ago oma
    ON a.BENEFIT_CLAIM_STATUS_DESC = oma.BENEFIT_CLAIM_STATUS_DESC
    AND a.BENEFIT_CLAIM_STATUS_CODE = oma.BENEFIT_CLAIM_STATUS_CODE
    AND a.eh_seh_flag = oma.eh_seh_flag
	AND a.foreigncaseflag = oma.foreigncaseflag
)
;
                       
