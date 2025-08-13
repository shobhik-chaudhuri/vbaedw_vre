/* Discontinued FYTD - Added Foreign Case Flag */
select --C.program_type_code,
        D.BENEFIT_CLAIM_STATUS_CODE,
	CASE WHEN o.outbase_site_name in 
             ( 'Australia','China','Foreign Workload','Guam','Indonesia','Japan','Korea',
                'Kuala Lumpur','Kure Island','Laos','Malaysia' ,'Manila','Manila RO',
                'Mayaguez','Micronesia','New Zealand','Okinawa','Palau','Saipan',
                'Samoa','Sepulveda','Sepulveda VA Clinic','Singapore','Taiwan','Thailand','Vancouver','Vietnam')
                    THEN 'Y' ELSE 'N' END ForeignCaseFlag,
--        F.VA_STATION_DIM_SID,
        count(C.case_id) num_cases_ytd
from DW_VRE.VRE_CASE_STATUS_FACT A
INNER JOIN dw_vre_dim.case_dim C
    ON A.case_dim_sid = C.case_dim_sid
    AND C.PROGRAM_TYPE_CODE IN ('CH18', 'CH31', 'CH35')
    AND c.EFFECTIVE_STATUS_INDICATOR != 'D'
INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM D 
    ON  A.CASE_STATUS_CODE_DIM_SID = D.BENEFIT_CLAIM_STATUS_DIM_SID
    AND  D.BENEFIT_CLAIM_STATUS_CODE ='009'
INNER JOIN DW_DIM.EFFECTIVE_STATUS_INDICATOR_DIM E
    ON  A.EFFECTIVE_STATUS_IND_DIM_SID = E.EFFECTIVE_STATUS_IND_DIM_SID
    AND  E.EFFECTIVE_STATUS_IND_CODE <> 'D' -- SHOULD NOT BE 'Record has been deleted at source'
INNER JOIN DW_DIM.DATE_DIM D3 ON A.CASE_STATUS_ENTRY_DATE_SID = D3.DATE_DIM_SID
--    AND D3.ACTUAL_DATE between '01-OCT-2024' and '20-JAN-2025'
	AND D3.fiscal_year = (select distinct fiscal_year from dw_dim.date_dim where trunc(actual_date) = trunc(sysdate)) -- Current FY
INNER JOIN DW_DIM.DATE_DIM D4 ON A.CASE_STATUS_CLOSE_DATE_SID = D4.DATE_DIM_SID
INNER JOIN DW_DIM.VA_STATION_DIM F
    ON  A.CASE_MANAGER_VA_STATION_SID = F.VA_STATION_DIM_SID
LEFT OUTER join (select a.*, rank() over (partition by outbase_site_lctn_id order by begin_effective_date desc) as rn
                    from dw_vre_dim.outbase_site_dim a
                    where current_record_ind='Y') o
                    on o.rn = 1
                    and c.site_location_id=o.outbase_site_lctn_id
group by --C.program_type_code, 
	D.BENEFIT_CLAIM_STATUS_CODE,
	CASE WHEN o.outbase_site_name in 
             ( 'Australia','China','Foreign Workload','Guam','Indonesia','Japan','Korea',
                'Kuala Lumpur','Kure Island','Laos','Malaysia' ,'Manila','Manila RO',
                'Mayaguez','Micronesia','New Zealand','Okinawa','Palau','Saipan',
                'Samoa','Sepulveda','Sepulveda VA Clinic','Singapore','Taiwan','Thailand','Vancouver','Vietnam')
                    THEN 'Y' ELSE 'N' END
-- F.VA_STATION_DIM_SID
;