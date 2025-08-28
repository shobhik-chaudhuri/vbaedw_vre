/* Days to entitlement - last 30 days
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
        sum(D.ACTUAL_DATE - D2.ACTUAL_DATE)/nullif(count(f.case_id),0) AS AVG_DAYS_TO_ENTITLEMENT -- Do not use within Power BI. Create a calculated column for Avg Days to Entilement.
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