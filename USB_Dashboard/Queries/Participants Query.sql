/* USB Dashboard - Participants Query - include Foreign Cases */
select G.ACTUAL_DATE,
        CASE WHEN o.outbase_site_name in 
             ( 'Australia','China','Foreign Workload','Guam','Indonesia','Japan','Korea',
                'Kuala Lumpur','Kure Island','Laos','Malaysia' ,'Manila','Manila RO',
                'Mayaguez','Micronesia','New Zealand','Okinawa','Palau','Saipan',
                'Samoa','Sepulveda','Sepulveda VA Clinic','Singapore','Taiwan','Thailand','Vancouver','Vietnam')
                    THEN 'Y' ELSE 'N' END ForeignCaseFlag,
       case when trunc(g.actual_date) = trunc(sysdate) THEN 'Number of Participants - today'
                when trunc(g.actual_date) = trunc(sysdate-1) THEN 'Number of Participants - yesterday'
                when trunc(g.actual_date) = ADD_MONTHS(trunc(SYSDATE),-1) THEN 'Number of Participants - last month (30 days ago)'
        else NULL end Day_Label,
--        count(A.vre_case_status_fact_sid),
        count(distinct C.case_id)  num_participants
from DW_VRE.VRE_CASE_STATUS_FACT A
INNER JOIN dw_vre_dim.case_dim C
    ON A.case_dim_sid = C.case_dim_sid
    AND C.PROGRAM_TYPE_CODE IN ('CH18', 'CH31', 'CH35')
INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM D 
    ON  A.CASE_STATUS_CODE_DIM_SID = D.BENEFIT_CLAIM_STATUS_DIM_SID
    AND  D.BENEFIT_CLAIM_STATUS_CODE IN ('001','002','003','004','005','006','008')
INNER JOIN DW_DIM.EFFECTIVE_STATUS_INDICATOR_DIM E
    ON  A.EFFECTIVE_STATUS_IND_DIM_SID = E.EFFECTIVE_STATUS_IND_DIM_SID
    AND  E.EFFECTIVE_STATUS_IND_CODE <> 'D' -- SHOULD NOT BE 'Record has been deleted at source'
INNER JOIN DW_DIM.DATE_DIM D3 ON A.CASE_STATUS_ENTRY_DATE_SID = D3.DATE_DIM_SID
INNER JOIN DW_DIM.DATE_DIM D4 
    ON  A.CASE_STATUS_CLOSE_DATE_SID = D4.DATE_DIM_SID
    AND  COALESCE(TRUNC(D4.ACTUAL_DATE),SYSDATE) >= '01-OCT-2013' -- STATUS CLOSED DATE DURING FY21 ONWARD
INNER JOIN DW_DIM.VA_STATION_DIM F
    ON  A.CASE_MANAGER_VA_STATION_SID = F.VA_STATION_DIM_SID
INNER JOIN DW_DIM.DATE_DIM G 
    ON G.ACTUAL_DATE BETWEEN TRUNC(D3.ACTUAL_DATE) AND COALESCE(TRUNC(D4.ACTUAL_DATE),SYSDATE) 
       AND trunc(G.ACTUAL_DATE) IN (trunc(SYSDATE),trunc(sysdate-1),ADD_MONTHS(trunc(SYSDATE),-1))
-- AND trunc(G.ACTUAL_DATE) between trunc(sysdate-60) and sysdate
--WHERE  a.EFFECTIVE_STATUS_IND_DIM_SID = 1
LEFT OUTER join (select a.*, rank() over (partition by outbase_site_lctn_id order by begin_effective_date desc) as rn
                    from dw_vre_dim.outbase_site_dim a
                    where current_record_ind='Y') o
                    on o.rn = 1
                    and c.site_location_id=o.outbase_site_lctn_id
group by G.ACTUAL_DATE,
            CASE WHEN o.outbase_site_name in 
             ( 'Australia','China','Foreign Workload','Guam','Indonesia','Japan','Korea',
                'Kuala Lumpur','Kure Island','Laos','Malaysia' ,'Manila','Manila RO',
                'Mayaguez','Micronesia','New Zealand','Okinawa','Palau','Saipan',
                'Samoa','Sepulveda','Sepulveda VA Clinic','Singapore','Taiwan','Thailand','Vancouver','Vietnam')
            THEN 'Y' ELSE 'N' END,
    case when trunc(g.actual_date) = trunc(sysdate) THEN 'Number of Participants - today'
                when trunc(g.actual_date) = trunc(sysdate-1) THEN 'Number of Participants - yesterday'
                when trunc(g.actual_date) = ADD_MONTHS(trunc(SYSDATE),-1) THEN 'Number of Participants - last month (30 days ago)'
        else NULL end;
