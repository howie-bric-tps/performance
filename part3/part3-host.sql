
-- when is it available ? 
-- Using road_event.created_on

-- Not so simple. Right now I have told GF we will use the roadEvent.created_on as 
-- the 'available at the host' time for AVIs. For IBTs its more complicate though 
-- we can start with that. The issue with IBTs is we need the transaction, the images 
-- and the OCR results and they all arrive at different times.
-- So for now, using roadEvent.created_on is a starting point for the first iteration of 
-- our SQLs - we can refine this in a later iteration working with GF and TCA.

select 

'TRANSCORE' as agency_name, rev.EVENT_REVENUE_DATE, 'unknown' as filename, rev.created_on as road_event_created, bev.created_on as billing_event_created

-- "minutes" defined as
, case when bev.created_on is null then
   -- interval since the file was first seen (interop_file.created_on)
       round(((current_date - date '1970-01-01')*24*60 
       - (cast(rev.created_on as date) - date '1970-01-01')*24*60))
  else 
   -- interval between the billing_event and when the file was first seen - interop_file.created_on
       round(((cast(bev.created_on as date) - date '1970-01-01')*24*60
     - (cast(rev.created_on as date) - date '1970-01-01')*24*60)) 
  END as minutes
, case when bev.created_on is null then
    current_date - rev.created_on
    else
    bev.created_on - rev.created_on 
    END AS time_interval

-- calculate penalty based on round((minutes - 240)/240)*0.01
, (case when bev.created_on is null then
   -- interval since the file was first seen (interop_file.created_on)
       round((((current_date - date '1970-01-01')*24*60 
       - (cast(rev.created_on as date) - date '1970-01-01')*24*60)-240)
       / 240)
  else 
   -- interval between the billing_event and when the file was first seen - interop_file.created_on
       round((((cast(bev.created_on as date) - date '1970-01-01')*24*60 
       - (cast(rev.created_on as date) - date '1970-01-01')*24*60)-240)
       / 240)
  END) * 0.01 as penalty
  
from road_event rev
    right outer join billing_event bev on bev.event_time = rev.event_time and bev.toll_location_id = rev.toll_location_id and bev.toll_lane_id = rev.toll_lane_id and bev.agency_event_id = rev.agency_event_id
    where rev.AVI_SOURCE_INTEROP_FILE_ID is null and rev.IBT_SOURCE_INTEROP_FILE_ID is null
    and rev.EVENT_REVENUE_DATE > '2021-12-15 00:00:00'
    -- order by rev.EVENT_REVENUE_DATE desc
FETCH FIRST 10 ROWS ONLY;
    
