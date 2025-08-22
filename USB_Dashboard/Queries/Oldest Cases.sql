/* Total current cases
-- Details - Top 5 Oldest Total Time in Program OR Oldest Current Participation in Program
-- Added logic to exclude CASES FROM PREVIOUS STATUS WHERE "07 REHABILITATED" IMMEDIATELY PRECEDES "02 EVALUATION/PLANNING"
-- Revised list of Outbased Sites
-- Foreign Cases = "N"
*/
select 'N' ForeignCaseFlag,
	k.district_display,
        f.station_number,
        f.station_name,
--        a.case_dim_sid,
--        c.case_id,
--        veteran_person_sid,
        H.first_name veteran_first_name,
        H.last_name veteran_last_name,
        H.first_name claimant_first_name,
        H.last_name claimant_last_name,
        D.BENEFIT_CLAIM_STATUS_DESC current_status,
	L.BENEFIT_CLAIM_STATUS_DESC prior_status,
        D3.ACTUAL_DATE current_status_entry_date,
        g.latest_applicant_status_entry_date date_when_last_in_applicant_status,
        g.earliest_applicant_status_entry_date original_application_date,
        trunc(sysdate - D3.ACTUAL_DATE) num_days_in_current_status,
        trunc(sysdate - g.latest_applicant_status_entry_date) days_since_last_application,
        trunc(sysdate - g.earliest_applicant_status_entry_date) days_since_original_application,
        g.num_times_applicant
from DW_VRE.VRE_CASE_STATUS_FACT a
INNER JOIN dw_vre_dim.case_dim c
    ON a.case_dim_sid = c.case_dim_sid
    AND C.PROGRAM_TYPE_CODE in ('CH31','CH35','CH18')
INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM D
    ON  A.CASE_STATUS_CODE_DIM_SID = D.BENEFIT_CLAIM_STATUS_DIM_SID -- Current Case Status
    AND  D.BENEFIT_CLAIM_STATUS_CODE IN ('001','002','003','004','005','006','008')
INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM L  -- Prior Case Status
    ON  A.PREVIOUS_CASE_STATUS_CODE_SID = L.BENEFIT_CLAIM_STATUS_DIM_SID
INNER JOIN DW_DIM.EFFECTIVE_STATUS_INDICATOR_DIM E
    ON  A.EFFECTIVE_STATUS_IND_DIM_SID = E.EFFECTIVE_STATUS_IND_DIM_SID
    AND  E.EFFECTIVE_STATUS_IND_CODE <> 'D' -- SHOULD NOT BE 'Record has been deleted at source'
INNER JOIN DW_DIM.VA_STATION_DIM F
    ON  A.CASE_MANAGER_VA_STATION_SID = F.VA_STATION_DIM_SID
INNER JOIN DW_DIM.PERSON_DIM H
    ON A.veteran_person_sid = H.PERSON_DIM_SID
INNER JOIN DW_DIM.PERSON_DIM K
    ON A.claimant_person_sid = K.PERSON_DIM_SID
INNER JOIN DW_DIM.VA_STATION_DIM F
    ON  A.CASE_MANAGER_VA_STATION_SID = F.VA_STATION_DIM_SID
INNER JOIN EDW.GEOGRAPHY_DIM K
    ON F.STATION_NUMBER = K.STATION_NUMBER
INNER JOIN DW_DIM.DATE_DIM D3 ON A.CASE_STATUS_ENTRY_DATE_SID = D3.DATE_DIM_SID
INNER JOIN DW_DIM.DATE_DIM D4 ON A.CASE_STATUS_CLOSE_DATE_SID = D4.DATE_DIM_SID
INNER JOIN (SELECT a.CASE_DIM_SID,
                    max(D3.ACTUAL_DATE) latest_applicant_status_entry_date,
                    min(D3.ACTUAL_DATE) earliest_applicant_status_entry_date,
                    count(*) num_times_applicant
            FROM DW_VRE.VRE_CASE_STATUS_FACT a
            INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM D 
                ON  A.CASE_STATUS_CODE_DIM_SID = D.BENEFIT_CLAIM_STATUS_DIM_SID
                AND  D.BENEFIT_CLAIM_STATUS_CODE = '001'
            INNER JOIN DW_DIM.DATE_DIM D3 ON A.CASE_STATUS_ENTRY_DATE_SID = D3.DATE_DIM_SID
            group by a.CASE_DIM_SID) G
    ON A.CASE_DIM_SID = G.CASE_DIM_SID
WHERE trunc(D4.ACTUAL_DATE) = '31-DEC-9999'
AND NOT (D.BENEFIT_CLAIM_STATUS_CODE = '002' and L.BENEFIT_CLAIM_STATUS_CODE = '007')
AND NOT EXISTS (SELECT 1 FROM dw_vre_dim.outbase_site_dim o
		where o.current_record_ind='Y'
		AND o.outbase_site_name in 
             			( 'Australia','China','Foreign Workload','Guam','Indonesia','Japan','Korea',
                		'Kuala Lumpur, Malaysia','Kure Island','Laos','Manila','Manila RO',
                		'Mayaguez','Micronesia','New Zealand','Okinawa','Palau','Saipan',
                		'Samoa','Sepulveda','Sepulveda VA Clinic','Singapore','Taiwan','Thailand','Vancouver','Vietnam')
		and o.outbase_site_lctn_id = c.site_location_id)
--ORDER BY trunc(sysdate - g.earliest_applicant_status_entry_date) DESC
ORDER BY trunc(sysdate - g.latest_applicant_status_entry_date) DESC
FETCH FIRST 5 ROWS ONLY;

/* Total current cases
-- Details - Top 5 Oldest Total Time in Program OR Oldest Current Participation in Program
-- Add logic to exclude CASES FROM PREVIOUS STATUS WHERE "07 REHABILITATED" IMMEDIATELY PRECEDES "02 EVALUATION/PLANNING"
-- Revised list of Outbased Sites
-- Foreign Cases = "Y"
*/              
select 'Y' ForeignCaseFlag,
	k.district_display,
        f.station_number,
        f.station_name,
--        a.case_dim_sid,
--        c.case_id,
--        veteran_person_sid,
        H.first_name veteran_first_name,
        H.last_name veteran_last_name,
        H.first_name claimant_first_name,
        H.last_name claimant_last_name,
        D.BENEFIT_CLAIM_STATUS_DESC current_status,
    L.BENEFIT_CLAIM_STATUS_DESC prior_status,
        D3.ACTUAL_DATE current_status_entry_date,
        g.latest_applicant_status_entry_date date_when_last_in_applicant_status,
        g.earliest_applicant_status_entry_date original_application_date,
        trunc(sysdate - D3.ACTUAL_DATE) num_days_in_current_status,
        trunc(sysdate - g.latest_applicant_status_entry_date) days_since_last_application,
        trunc(sysdate - g.earliest_applicant_status_entry_date) days_since_original_application,
        g.num_times_applicant
from DW_VRE.VRE_CASE_STATUS_FACT a
INNER JOIN dw_vre_dim.case_dim c
    ON a.case_dim_sid = c.case_dim_sid
    AND C.PROGRAM_TYPE_CODE in ('CH31','CH35','CH18')
INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM D 
    ON  A.CASE_STATUS_CODE_DIM_SID = D.BENEFIT_CLAIM_STATUS_DIM_SID
    AND  D.BENEFIT_CLAIM_STATUS_CODE IN ('001','002','003','004','005','006','008')
INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM L  -- Prior Case Status
    ON  A.PREVIOUS_CASE_STATUS_CODE_SID = L.BENEFIT_CLAIM_STATUS_DIM_SID
INNER JOIN DW_DIM.EFFECTIVE_STATUS_INDICATOR_DIM E
    ON  A.EFFECTIVE_STATUS_IND_DIM_SID = E.EFFECTIVE_STATUS_IND_DIM_SID
    AND  E.EFFECTIVE_STATUS_IND_CODE <> 'D' -- SHOULD NOT BE 'Record has been deleted at source'
INNER JOIN DW_DIM.VA_STATION_DIM F
    ON  A.CASE_MANAGER_VA_STATION_SID = F.VA_STATION_DIM_SID
INNER JOIN DW_DIM.PERSON_DIM H
    ON A.veteran_person_sid = H.PERSON_DIM_SID
INNER JOIN DW_DIM.PERSON_DIM K
    ON A.claimant_person_sid = K.PERSON_DIM_SID
INNER JOIN DW_DIM.VA_STATION_DIM F
    ON  A.CASE_MANAGER_VA_STATION_SID = F.VA_STATION_DIM_SID
INNER JOIN EDW.GEOGRAPHY_DIM K
    ON F.STATION_NUMBER = K.STATION_NUMBER
INNER JOIN DW_DIM.DATE_DIM D3 ON A.CASE_STATUS_ENTRY_DATE_SID = D3.DATE_DIM_SID
INNER JOIN DW_DIM.DATE_DIM D4 ON A.CASE_STATUS_CLOSE_DATE_SID = D4.DATE_DIM_SID
INNER JOIN (SELECT a.CASE_DIM_SID,
                    max(D3.ACTUAL_DATE) latest_applicant_status_entry_date,
                    min(D3.ACTUAL_DATE) earliest_applicant_status_entry_date,
                    count(*) num_times_applicant
            FROM DW_VRE.VRE_CASE_STATUS_FACT a
            INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM D 
                ON  A.CASE_STATUS_CODE_DIM_SID = D.BENEFIT_CLAIM_STATUS_DIM_SID
                AND  D.BENEFIT_CLAIM_STATUS_CODE = '001'
            INNER JOIN DW_DIM.DATE_DIM D3 ON A.CASE_STATUS_ENTRY_DATE_SID = D3.DATE_DIM_SID
            group by a.CASE_DIM_SID) G
    ON A.CASE_DIM_SID = G.CASE_DIM_SID
INNER JOIN (select a.*, rank() over (partition by outbase_site_lctn_id order by begin_effective_date desc) as rn
                    from dw_vre_dim.outbase_site_dim a
                    where current_record_ind='Y') o
                    on o.rn = 1
                    and c.site_location_id=o.outbase_site_lctn_id
			AND o.outbase_site_name in 
             			( 'Australia','China','Foreign Workload','Guam','Indonesia','Japan','Korea',
                		'Kuala Lumpur, Malaysia','Kure Island','Laos','Manila','Manila RO',
                		'Mayaguez','Micronesia','New Zealand','Okinawa','Palau','Saipan',
                		'Samoa','Sepulveda','Sepulveda VA Clinic','Singapore','Taiwan','Thailand','Vancouver','Vietnam')
AND NOT (D.BENEFIT_CLAIM_STATUS_CODE = '002' and L.BENEFIT_CLAIM_STATUS_CODE = '007')
WHERE trunc(D4.ACTUAL_DATE) = '31-DEC-9999'
--ORDER BY trunc(sysdate - g.earliest_applicant_status_entry_date) DESC
ORDER BY trunc(sysdate - g.latest_applicant_status_entry_date) DESC
FETCH FIRST 5 ROWS ONLY;

/* Total current cases
-- USE ONLY FOR VALIDATION
-- Details - Top 5 Oldest Total Time in Program OR Oldest Current Participation in Program
-- Does NOT consider Foreign Case Flag
*/
select 	k.district_display,
        f.station_number,
        f.station_name,
--        a.case_dim_sid,
--        c.case_id,
--        veteran_person_sid,
        H.first_name veteran_first_name,
        H.last_name veteran_last_name,
        H.first_name claimant_first_name,
        H.last_name claimant_last_name,
        D.BENEFIT_CLAIM_STATUS_DESC current_status,
	L.BENEFIT_CLAIM_STATUS_DESC prior_status,
        D3.ACTUAL_DATE current_status_entry_date,
        g.latest_applicant_status_entry_date date_when_last_in_applicant_status,
        g.earliest_applicant_status_entry_date original_application_date,
        trunc(sysdate - D3.ACTUAL_DATE) num_days_in_current_status,
        trunc(sysdate - g.latest_applicant_status_entry_date) days_since_last_application,
        trunc(sysdate - g.earliest_applicant_status_entry_date) days_since_original_application,
        g.num_times_applicant
from DW_VRE.VRE_CASE_STATUS_FACT a
INNER JOIN dw_vre_dim.case_dim c
    ON a.case_dim_sid = c.case_dim_sid
    AND C.PROGRAM_TYPE_CODE in ('CH31','CH35','CH18')
INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM D
    ON  A.CASE_STATUS_CODE_DIM_SID = D.BENEFIT_CLAIM_STATUS_DIM_SID -- Current Case Status
    AND  D.BENEFIT_CLAIM_STATUS_CODE IN ('001','002','003','004','005','006','008')
INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM L  -- Prior Case Status
    ON  A.PREVIOUS_CASE_STATUS_CODE_SID = L.BENEFIT_CLAIM_STATUS_DIM_SID
INNER JOIN DW_DIM.EFFECTIVE_STATUS_INDICATOR_DIM E
    ON  A.EFFECTIVE_STATUS_IND_DIM_SID = E.EFFECTIVE_STATUS_IND_DIM_SID
    AND  E.EFFECTIVE_STATUS_IND_CODE <> 'D' -- SHOULD NOT BE 'Record has been deleted at source'
INNER JOIN DW_DIM.VA_STATION_DIM F
    ON  A.CASE_MANAGER_VA_STATION_SID = F.VA_STATION_DIM_SID
INNER JOIN DW_DIM.PERSON_DIM H
    ON A.veteran_person_sid = H.PERSON_DIM_SID
INNER JOIN DW_DIM.PERSON_DIM K
    ON A.claimant_person_sid = K.PERSON_DIM_SID
INNER JOIN DW_DIM.VA_STATION_DIM F
    ON  A.CASE_MANAGER_VA_STATION_SID = F.VA_STATION_DIM_SID
INNER JOIN EDW.GEOGRAPHY_DIM K
    ON F.STATION_NUMBER = K.STATION_NUMBER
INNER JOIN DW_DIM.DATE_DIM D3 ON A.CASE_STATUS_ENTRY_DATE_SID = D3.DATE_DIM_SID
INNER JOIN DW_DIM.DATE_DIM D4 ON A.CASE_STATUS_CLOSE_DATE_SID = D4.DATE_DIM_SID
INNER JOIN (SELECT a.CASE_DIM_SID,
                    max(D3.ACTUAL_DATE) latest_applicant_status_entry_date,
                    min(D3.ACTUAL_DATE) earliest_applicant_status_entry_date,
                    count(*) num_times_applicant
            FROM DW_VRE.VRE_CASE_STATUS_FACT a
            INNER JOIN DW_DIM.BENEFIT_CLAIM_STATUS_DIM D 
                ON  A.CASE_STATUS_CODE_DIM_SID = D.BENEFIT_CLAIM_STATUS_DIM_SID
                AND  D.BENEFIT_CLAIM_STATUS_CODE = '001'
            INNER JOIN DW_DIM.DATE_DIM D3 ON A.CASE_STATUS_ENTRY_DATE_SID = D3.DATE_DIM_SID
            group by a.CASE_DIM_SID) G
    ON A.CASE_DIM_SID = G.CASE_DIM_SID
WHERE trunc(D4.ACTUAL_DATE) = '31-DEC-9999'
AND NOT (D.BENEFIT_CLAIM_STATUS_CODE = '002' and L.BENEFIT_CLAIM_STATUS_CODE = '007')
--ORDER BY trunc(sysdate - g.earliest_applicant_status_entry_date) DESC
ORDER BY trunc(sysdate - g.latest_applicant_status_entry_date) DESC
FETCH FIRST 5 ROWS ONLY;
