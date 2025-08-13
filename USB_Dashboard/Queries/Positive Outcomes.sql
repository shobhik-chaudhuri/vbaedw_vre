/* Positive Outcomes FYTD - Add Foreign Case Flag */
select trunc(sysdate) date_this_query_ran,
 --   D3.ACTUAL_DATE,
 --   C.PROGRAM_TYPE_CODE,
 --   A.CASE_MANAGER_VA_STATION_SID,
    CASE  
            WHEN G.REASON_CODE = '17' THEN 'IL REHAB' 
            WHEN G.REASON_CODE IN ('22', '23') THEN 'EMP REHAB' 
            WHEN G.REASON_CODE =  '25' THEN 'EDU REHAB'
            WHEN G.REASON_CODE IN ('34','35','37') THEN 'MRG' 
            ELSE G.REASON_CODE
    END Rehab_Type,
CASE WHEN o.outbase_site_name in 
             ( 'Australia','China','Foreign Workload','Guam','Indonesia','Japan','Korea',
                'Kuala Lumpur','Kure Island','Laos','Malaysia' ,'Manila','Manila RO',
                'Mayaguez','Micronesia','New Zealand','Okinawa','Palau','Saipan',
                'Samoa','Sepulveda','Sepulveda VA Clinic','Singapore','Taiwan','Thailand','Vancouver','Vietnam')
                    THEN 'Y' ELSE 'N' END ForeignCaseFlag,
--    C.PROGRAM_TYPE_CODE,
    count(distinct c.case_id) Num_Positive_Outcomes
from DW_VRE.VRE_CASE_STATUS_FACT a
INNER JOIN dw_vre_dim.case_dim c
    ON a.case_dim_sid = c.case_dim_sid
    AND C.PROGRAM_TYPE_CODE in ('CH31','CH35','CH18')
INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM D  -- Current case status
    ON  A.CASE_STATUS_CODE_DIM_SID = D.BENEFIT_CLAIM_STATUS_DIM_SID
INNER JOIN DW_DIM.EFFECTIVE_STATUS_INDICATOR_DIM E
    ON  A.EFFECTIVE_STATUS_IND_DIM_SID = E.EFFECTIVE_STATUS_IND_DIM_SID
    AND  E.EFFECTIVE_STATUS_IND_CODE <> 'D' -- SHOULD NOT BE 'Record has been deleted at source'
INNER JOIN DW_DIM.DATE_DIM D4 
    ON  A.CASE_STATUS_CLOSE_DATE_SID = D4.DATE_DIM_SID
    AND  COALESCE(TRUNC(D4.ACTUAL_DATE),SYSDATE) >= '01-OCT-2013' -- STATUS CLOSED DATE DURING FY21 ONWARD
INNER JOIN DW_DIM.DATE_DIM D3 ON A.CASE_STATUS_ENTRY_DATE_SID = D3.DATE_DIM_SID
--    AND D3.ACTUAL_DATE between '01-OCT-2024' and '20-JAN-2025'
	AND D3.fiscal_year = (select distinct fiscal_year from dw_dim.date_dim where trunc(actual_date) = trunc(sysdate)) -- Current FY
--    AND D3.fiscal_year IN (select distinct fiscal_year from dw_dim.date_dim where actual_date between add_months(trunc(sysdate),-24) AND trunc(sysdate))
--INNER JOIN DW_DIM.VA_STATION_DIM F
--   ON  A.CASE_MANAGER_VA_STATION_SID = F.VA_STATION_DIM_SID
INNER JOIN DW_VRE_DIM.STATUS_ENTRY_REASON_DIM G
    ON A.STATUS_ENTRY_REASON_DIM_SID = G.STATUS_ENTRY_REASON_DIM_SID
LEFT OUTER join (select a.*, rank() over (partition by outbase_site_lctn_id order by begin_effective_date desc) as rn
                    from dw_vre_dim.outbase_site_dim a
                    where current_record_ind='Y') o
                    on o.rn = 1
                    and c.site_location_id=o.outbase_site_lctn_id
WHERE (D.BENEFIT_CLAIM_STATUS_DESC IN ('Discontinued') AND G.REASON_CODE IN ('34','35','37')) OR (D.BENEFIT_CLAIM_STATUS_DESC IN ('Rehabilitated') AND G.REASON_CODE IN ('17','22','23','25'))
group by trunc(sysdate),
--    D3.ACTUAL_DATE,
--    C.PROGRAM_TYPE_CODE,
--    A.CASE_MANAGER_VA_STATION_SID,
    CASE  
            WHEN G.REASON_CODE = '17' THEN 'IL REHAB' 
            WHEN G.REASON_CODE IN ('22', '23') THEN 'EMP REHAB' 
            WHEN G.REASON_CODE =  '25' THEN 'EDU REHAB'
            WHEN G.REASON_CODE IN ('34','35','37') THEN 'MRG' 
            ELSE G.REASON_CODE
    END,
	CASE WHEN o.outbase_site_name in 
             ( 'Australia','China','Foreign Workload','Guam','Indonesia','Japan','Korea',
                'Kuala Lumpur','Kure Island','Laos','Malaysia' ,'Manila','Manila RO',
                'Mayaguez','Micronesia','New Zealand','Okinawa','Palau','Saipan',
                'Samoa','Sepulveda','Sepulveda VA Clinic','Singapore','Taiwan','Thailand','Vancouver','Vietnam')
                    THEN 'Y' ELSE 'N' END
    ;
