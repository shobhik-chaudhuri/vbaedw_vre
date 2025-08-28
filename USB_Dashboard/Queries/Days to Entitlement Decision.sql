/* Query 1 - Applicants pending or in current FY - DO NOT USE*/
SELECT /*count(a.case_id),
        sum(case when trunc(D4.ACTUAL_DATE) = '31-DEC-9999' THEN
                    trunc(sysdate) - trunc(D3.ACTUAL_DATE)
                ELSE
                    trunc(c.ENTLMT_DETERMINATION_DT) - trunc(D3.ACTUAL_DATE)
                END)/count(a.case_id) avg_entitlement_days*/
    a.case_id,
    D3.ACTUAL_DATE case_status_entry_date,
    D4.ACTUAL_DATE case_status_exit_date,
    b.procd_dt,
    c.ENTLMT_DETERMINATION_DT,
    case when trunc(D4.ACTUAL_DATE) = '31-DEC-9999' THEN
                    trunc(sysdate) - trunc(D3.ACTUAL_DATE)
                ELSE
                    trunc(c.ENTLMT_DETERMINATION_DT) - trunc(b.procd_dt)
                END entitlement_days
from DW_VRE.VRE_CASE_STATUS_FACT a
INNER JOIN dw_vre_dim.case_dim c
    ON a.case_dim_sid = c.case_dim_sid
    AND C.PROGRAM_TYPE_CODE = 'CH31'
INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM D 
    ON  A.CASE_STATUS_CODE_DIM_SID = D.BENEFIT_CLAIM_STATUS_DIM_SID
    AND  D.BENEFIT_CLAIM_STATUS_CODE  ='001'
INNER JOIN DW_DIM.EFFECTIVE_STATUS_INDICATOR_DIM E
    ON  A.EFFECTIVE_STATUS_IND_DIM_SID = E.EFFECTIVE_STATUS_IND_DIM_SID
    AND  E.EFFECTIVE_STATUS_IND_CODE <> 'D' -- SHOULD NOT BE 'Record has been deleted at source'
INNER JOIN DW_DIM.VA_STATION_DIM F
    ON  A.CASE_MANAGER_VA_STATION_SID = F.VA_STATION_DIM_SID
INNER JOIN DW_DIM.DATE_DIM D3 ON A.CASE_STATUS_ENTRY_DATE_SID = D3.DATE_DIM_SID
INNER JOIN DW_DIM.DATE_DIM D4 ON A.CASE_STATUS_CLOSE_DATE_SID = D4.DATE_DIM_SID
inner join dw_vre_dim.CH31_INTRFC_GED_TRAN_DIM b
    on c.veteran_participant_id = b.ptcpnt_vet_id
    and b.current_record_ind='Y'
WHERE (trunc(D4.ACTUAL_DATE) = '31-DEC-9999' AND a.EFFECTIVE_STATUS_IND_DIM_SID = 1)
OR (trunc(D3.ACTUAL_DATE) >= '01-OCT-2024' and trunc(D4.ACTUAL_DATE) != '31-DEC-9999');

/* Query 2 - Entitlement Determination in current FY - DO NOT USE */
SELECT count(a.case_id),
        round(sum(trunc(c.ENTLMT_DETERMINATION_DT) - trunc(b.procd_dt))/count(a.case_id),2) avg_entitlement_days
/*    a.case_id,
    D.BENEFIT_CLAIM_STATUS_CODE,
    D3.ACTUAL_DATE case_status_entry_date,
    b.procd_dt,
    c.ENTLMT_DETERMINATION_DT,
    trunc(c.ENTLMT_DETERMINATION_DT) - trunc(b.procd_dt) entitlement_days*/
from DW_VRE.VRE_CASE_STATUS_FACT a
INNER JOIN dw_vre_dim.case_dim c
    ON a.case_dim_sid = c.case_dim_sid
    AND C.PROGRAM_TYPE_CODE = 'CH31'
INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM D 
    ON  A.CASE_STATUS_CODE_DIM_SID = D.BENEFIT_CLAIM_STATUS_DIM_SID
INNER JOIN DW_DIM.EFFECTIVE_STATUS_INDICATOR_DIM E
    ON  A.EFFECTIVE_STATUS_IND_DIM_SID = E.EFFECTIVE_STATUS_IND_DIM_SID
    AND  E.EFFECTIVE_STATUS_IND_CODE <> 'D' -- SHOULD NOT BE 'Record has been deleted at source'
INNER JOIN DW_DIM.VA_STATION_DIM F
    ON  A.CASE_MANAGER_VA_STATION_SID = F.VA_STATION_DIM_SID
INNER JOIN DW_DIM.DATE_DIM D3 ON A.CASE_STATUS_ENTRY_DATE_SID = D3.DATE_DIM_SID
INNER JOIN DW_DIM.DATE_DIM D4 ON A.CASE_STATUS_CLOSE_DATE_SID = D4.DATE_DIM_SID
inner join dw_vre_dim.CH31_INTRFC_GED_TRAN_DIM b
    on c.veteran_participant_id = b.ptcpnt_vet_id
    and b.current_record_ind='Y'
WHERE trunc(D4.ACTUAL_DATE) = '31-DEC-9999' -- Current Status
AND c.ENTLMT_DETERMINATION_DT BETWEEN
        (select fiscal_year_begin_date
        from dw_dim.date_dim
        where trunc(actual_date)=trunc(sysdate))
        AND
        trunc(sysdate);
        
/* Query 3 - Luke's query */
SELECT
    F.CASE_ID,
    D2.ACTUAL_DATE AS APP_DATE,
    S.BENEFIT_CLAIM_STATUS_DESC AS STATUS,
    D.ACTUAL_DATE AS EVAL_ENTRY_DATE,
    D1.ACTUAL_DATE AS EVAL_EXIT_DATE,
    S1.BENEFIT_CLAIM_STATUS_CODE PREVIOUS_STATUS, -- Added by Shobhik
    D.MONTH_BEGIN_DATE,
    D.ACTUAL_DATE - D2.ACTUAL_DATE AS DAYS_TO_ENTITLEMENT,
    V.STATION_DISPLAY AS REGIONAL_OFFICE,
    V.DISTRICT_DESCRIPTION AS DISTRICT
FROM DW_VRE.VRE_CASE_STATUS_FACT F 
INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM S 
ON S.BENEFIT_CLAIM_STATUS_DIM_SID = F.CASE_STATUS_CODE_DIM_SID
AND S.BENEFIT_CLAIM_STATUS_CODE IN ('002')
INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM S1
ON S1.BENEFIT_CLAIM_STATUS_DIM_SID = F.PREVIOUS_CASE_STATUS_CODE_SID
--AND S1.BENEFIT_CLAIM_STATUS_CODE = '001'
INNER JOIN DW_DIM.DATE_DIM D 
ON D.DATE_DIM_SID = F.CASE_STATUS_ENTRY_DATE_SID
--AND D.FISCAL_YEAR = '2025'
INNER JOIN DW_DIM.DATE_DIM D1 
ON D1.DATE_DIM_SID = F.CASE_STATUS_CLOSE_DATE_SID
INNER JOIN DW_DIM.DATE_DIM D2
ON D2.DATE_DIM_SID = F.PREV_CASE_STATUS_ENTRY_DT_SID
INNER JOIN DW_VRE_DIM.CASE_DIM C
ON C.CASE_DIM_SID = F.CASE_DIM_SID
AND C.PROGRAM_TYPE_CODE IN ('CH31', 'NDAA')
INNER JOIN DW_DIM.VA_STATION_DIM V
ON V.VA_STATION_DIM_SID = F.CASE_ASGNMT_STATUS_VA_STN_SID
WHERE
    F.EFFECTIVE_STATUS_IND_DIM_SID <> 3
    AND D.FISCAL_YEAR = '2025'
;

/* Query 4 - Days to entitlement - current FY 
-- Only cases that went from Applicant to Eval
*/
SELECT count(f.case_id) num_cases_eval_curr_fy,
        sum(case when C.PROGRAM_TYPE_CODE = 'CH18' THEN 1 ELSE 0 END) num_cases_eval_curr_fy_CH18,
        sum(case when C.PROGRAM_TYPE_CODE = 'CH31' THEN 1 ELSE 0 END) num_cases_eval_curr_fy_CH31,
        sum(case when C.PROGRAM_TYPE_CODE = 'CH35' THEN 1 ELSE 0 END) num_cases_eval_curr_fy_CH35,
        round(avg(D.ACTUAL_DATE - D2.ACTUAL_DATE),2) AS AVG_DAYS_TO_ENTITLEMENT
FROM DW_VRE.VRE_CASE_STATUS_FACT F 
INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM S 
    ON S.BENEFIT_CLAIM_STATUS_DIM_SID = F.CASE_STATUS_CODE_DIM_SID
    AND S.BENEFIT_CLAIM_STATUS_CODE = '002'
INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM S1
    ON S1.BENEFIT_CLAIM_STATUS_DIM_SID = F.PREVIOUS_CASE_STATUS_CODE_SID
    AND S1.BENEFIT_CLAIM_STATUS_CODE = '001'
INNER JOIN DW_DIM.DATE_DIM D 
    ON D.DATE_DIM_SID = F.CASE_STATUS_ENTRY_DATE_SID
INNER JOIN DW_DIM.DATE_DIM D1 
    ON D1.DATE_DIM_SID = F.CASE_STATUS_CLOSE_DATE_SID
INNER JOIN DW_DIM.DATE_DIM D2
    ON D2.DATE_DIM_SID = F.PREV_CASE_STATUS_ENTRY_DT_SID
INNER JOIN DW_VRE_DIM.CASE_DIM C
    ON C.CASE_DIM_SID = F.CASE_DIM_SID
--AND C.PROGRAM_TYPE_CODE IN ('CH31', 'NDAA')
    AND C.PROGRAM_TYPE_CODE IN ('CH18','CH31','CH35') -- Match USB VRE Dashboard
INNER JOIN DW_DIM.VA_STATION_DIM V
    ON V.VA_STATION_DIM_SID = F.CASE_ASGNMT_STATUS_VA_STN_SID
WHERE
    F.EFFECTIVE_STATUS_IND_DIM_SID <> 3
    AND D.FISCAL_YEAR = (SELECT fiscal_year FROM dw_dim.date_dim WHERE trunc(actual_date)=trunc(sysdate))
;

/* Query 5 : Days to entitlement - current FY 
-- Adding Foreign Case Flag
-- Adding Total Days to Entitlement
*/
SELECT CASE WHEN o.outbase_site_name in 
             ( 'Australia','China','Foreign Workload','Guam','Indonesia','Japan','Korea',
                'Kuala Lumpur, Malaysia','Kure Island','Laos','Manila','Manila RO',
                'Mayaguez','Micronesia','New Zealand','Okinawa','Palau','Saipan',
                'Samoa','Sepulveda','Sepulveda VA Clinic','Singapore','Taiwan','Thailand','Vancouver','Vietnam')
                    THEN 'Y' ELSE 'N' END ForeignCaseFlag,
        count(f.case_id) num_cases_eval_curr_fy,
        sum(D.ACTUAL_DATE - D2.ACTUAL_DATE) AS TOTAL_DAYS_TO_ENTITLEMENT,
        round(avg(D.ACTUAL_DATE - D2.ACTUAL_DATE),2) AS AVG_DAYS_TO_ENTITLEMENT
FROM DW_VRE.VRE_CASE_STATUS_FACT F 
INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM S 
    ON S.BENEFIT_CLAIM_STATUS_DIM_SID = F.CASE_STATUS_CODE_DIM_SID
    AND S.BENEFIT_CLAIM_STATUS_CODE = '002'
INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM S1
    ON S1.BENEFIT_CLAIM_STATUS_DIM_SID = F.PREVIOUS_CASE_STATUS_CODE_SID
    AND S1.BENEFIT_CLAIM_STATUS_CODE = '001'
INNER JOIN DW_DIM.DATE_DIM D 
    ON D.DATE_DIM_SID = F.CASE_STATUS_ENTRY_DATE_SID
INNER JOIN DW_DIM.DATE_DIM D1 
    ON D1.DATE_DIM_SID = F.CASE_STATUS_CLOSE_DATE_SID
INNER JOIN DW_DIM.DATE_DIM D2
    ON D2.DATE_DIM_SID = F.PREV_CASE_STATUS_ENTRY_DT_SID
INNER JOIN DW_VRE_DIM.CASE_DIM C
    ON C.CASE_DIM_SID = F.CASE_DIM_SID
--AND C.PROGRAM_TYPE_CODE IN ('CH31', 'NDAA')
    AND C.PROGRAM_TYPE_CODE IN ('CH18','CH31','CH35') -- Match USB VRE Dashboard
INNER JOIN DW_DIM.VA_STATION_DIM V
    ON V.VA_STATION_DIM_SID = F.CASE_ASGNMT_STATUS_VA_STN_SID
LEFT OUTER join (select a.*, rank() over (partition by outbase_site_lctn_id order by begin_effective_date desc) as rn
                    from dw_vre_dim.outbase_site_dim a
                    where current_record_ind='Y') o
                    on o.rn = 1
                    and c.site_location_id=o.outbase_site_lctn_id
WHERE
    F.EFFECTIVE_STATUS_IND_DIM_SID <> 3
    AND D.FISCAL_YEAR = (SELECT fiscal_year FROM dw_dim.date_dim WHERE trunc(actual_date)=trunc(sysdate))
GROUP BY CASE WHEN o.outbase_site_name in 
             ( 'Australia','China','Foreign Workload','Guam','Indonesia','Japan','Korea',
                'Kuala Lumpur, Malaysia','Kure Island','Laos','Manila','Manila RO',
                'Mayaguez','Micronesia','New Zealand','Okinawa','Palau','Saipan',
                'Samoa','Sepulveda','Sepulveda VA Clinic','Singapore','Taiwan','Thailand','Vancouver','Vietnam')
                    THEN 'Y' ELSE 'N' END
;

/* Query 6 : Days to entitlement - last 30 days
-- Adding Foreign Case Flag
-- Adding Total Days to Entitlement
*/
SELECT CASE WHEN o.outbase_site_name in 
             ( 'Australia','China','Foreign Workload','Guam','Indonesia','Japan','Korea',
                'Kuala Lumpur, Malaysia','Kure Island','Laos','Manila','Manila RO',
                'Mayaguez','Micronesia','New Zealand','Okinawa','Palau','Saipan',
                'Samoa','Sepulveda','Sepulveda VA Clinic','Singapore','Taiwan','Thailand','Vancouver','Vietnam')
                    THEN 'Y' ELSE 'N' END ForeignCaseFlag,
        count(f.case_id) num_cases_eval_last_30_days,
        sum(D.ACTUAL_DATE - D2.ACTUAL_DATE) AS TOTAL_DAYS_TO_ENTITLEMENT,
        avg(D.ACTUAL_DATE - D2.ACTUAL_DATE) AS AVG_DAYS_TO_ENTITLEMENT
FROM DW_VRE.VRE_CASE_STATUS_FACT F 
INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM S 
    ON S.BENEFIT_CLAIM_STATUS_DIM_SID = F.CASE_STATUS_CODE_DIM_SID
    AND S.BENEFIT_CLAIM_STATUS_CODE = '002'
INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM S1
    ON S1.BENEFIT_CLAIM_STATUS_DIM_SID = F.PREVIOUS_CASE_STATUS_CODE_SID
    AND S1.BENEFIT_CLAIM_STATUS_CODE = '001'
INNER JOIN DW_DIM.DATE_DIM D 
    ON D.DATE_DIM_SID = F.CASE_STATUS_ENTRY_DATE_SID
INNER JOIN DW_DIM.DATE_DIM D1 
    ON D1.DATE_DIM_SID = F.CASE_STATUS_CLOSE_DATE_SID
INNER JOIN DW_DIM.DATE_DIM D2
    ON D2.DATE_DIM_SID = F.PREV_CASE_STATUS_ENTRY_DT_SID
INNER JOIN DW_VRE_DIM.CASE_DIM C
    ON C.CASE_DIM_SID = F.CASE_DIM_SID
--AND C.PROGRAM_TYPE_CODE IN ('CH31', 'NDAA')
    AND C.PROGRAM_TYPE_CODE IN ('CH18','CH31','CH35') -- Match USB VRE Dashboard
INNER JOIN DW_DIM.VA_STATION_DIM V
    ON V.VA_STATION_DIM_SID = F.CASE_ASGNMT_STATUS_VA_STN_SID
LEFT OUTER join (select a.*, rank() over (partition by outbase_site_lctn_id order by begin_effective_date desc) as rn
                    from dw_vre_dim.outbase_site_dim a
                    where current_record_ind='Y') o
                    on o.rn = 1
                    and c.site_location_id=o.outbase_site_lctn_id
WHERE
    F.EFFECTIVE_STATUS_IND_DIM_SID <> 3
	AND trunc(d.actual_date) between trunc(sysdate-30) and trunc(sysdate)
GROUP BY CASE WHEN o.outbase_site_name in 
             ( 'Australia','China','Foreign Workload','Guam','Indonesia','Japan','Korea',
                'Kuala Lumpur, Malaysia','Kure Island','Laos','Manila','Manila RO',
                'Mayaguez','Micronesia','New Zealand','Okinawa','Palau','Saipan',
                'Samoa','Sepulveda','Sepulveda VA Clinic','Singapore','Taiwan','Thailand','Vancouver','Vietnam')
                    THEN 'Y' ELSE 'N' END
;


/* Query 7: Days to entitlement - last 30 days
-- WITHOUT Foreign Case Flag
-- Adding Total Days to Entitlement
-- Use for VALIDATION ONLY
*/
SELECT count(f.case_id) num_cases_eval_last_30_days,
        sum(D.ACTUAL_DATE - D2.ACTUAL_DATE) AS TOTAL_DAYS_TO_ENTITLEMENT,
        round(avg(D.ACTUAL_DATE - D2.ACTUAL_DATE),2) AS AVG_DAYS_TO_ENTITLEMENT
FROM DW_VRE.VRE_CASE_STATUS_FACT F 
INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM S 
    ON S.BENEFIT_CLAIM_STATUS_DIM_SID = F.CASE_STATUS_CODE_DIM_SID
    AND S.BENEFIT_CLAIM_STATUS_CODE = '002'
INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM S1
    ON S1.BENEFIT_CLAIM_STATUS_DIM_SID = F.PREVIOUS_CASE_STATUS_CODE_SID
    AND S1.BENEFIT_CLAIM_STATUS_CODE = '001'
INNER JOIN DW_DIM.DATE_DIM D 
    ON D.DATE_DIM_SID = F.CASE_STATUS_ENTRY_DATE_SID
INNER JOIN DW_DIM.DATE_DIM D1 
    ON D1.DATE_DIM_SID = F.CASE_STATUS_CLOSE_DATE_SID
INNER JOIN DW_DIM.DATE_DIM D2
    ON D2.DATE_DIM_SID = F.PREV_CASE_STATUS_ENTRY_DT_SID
INNER JOIN DW_VRE_DIM.CASE_DIM C
    ON C.CASE_DIM_SID = F.CASE_DIM_SID
--AND C.PROGRAM_TYPE_CODE IN ('CH31', 'NDAA')
    AND C.PROGRAM_TYPE_CODE IN ('CH18','CH31','CH35') -- Match USB VRE Dashboard
INNER JOIN DW_DIM.VA_STATION_DIM V
    ON V.VA_STATION_DIM_SID = F.CASE_ASGNMT_STATUS_VA_STN_SID
WHERE
    F.EFFECTIVE_STATUS_IND_DIM_SID <> 3
	AND trunc(d.actual_date) between trunc(sysdate-30) and trunc(sysdate)
;