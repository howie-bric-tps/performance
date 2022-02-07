
-- when is it available ? 
-- Using road_event.created_on

-- Not so simple. Right now I have told GF we will use the roadEvent.created_on as 
-- the 'available at the host' time for AVIs. For IBTs its more complicate though 
-- we can start with that. The issue with IBTs is we need the transaction, the images 
-- and the OCR results and they all arrive at different times.
-- So for now, using roadEvent.created_on is a starting point for the first iteration of 
-- our SQLs - we can refine this in a later iteration working with GF and TCA.

select 
-- "minutes" defined as
case when bev.created_on is null then
   -- interval since the file was first seen (interop_file.created_on)
       round(((current_date - date '1970-01-01')*24*60 
       - (cast(rev.created_on as date) - date '1970-01-01')*24*60))
  else 
   -- interval between the billing_event and when the file was first seen - interop_file.created_on
       round(((cast(bev.created_on as date) - date '1970-01-01')*24*60
     - (cast(rev.created_on as date) - date '1970-01-01')*24*60)) 
  END as minutes

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
    
where source_subtype1code = '';
select * from road_event where AVI_SOURCE_INTEROP_FILE_ID is null and IBT_SOURCE_INTEROP_FILE_ID is null
FETCH FIRST 10 ROWS ONLY;



select
a.agency_name, ifile.revenue_date, ifile.name as filename, ifile.created_on as file_first_seen, bev.created_on as billing_event_created

-- "minutes" defined as
, case when bev.created_on is null then
   -- interval since the file was first seen (interop_file.created_on)
       round(((current_date - date '1970-01-01')*24*60 
       - (cast(ifile.created_on as date) - date '1970-01-01')*24*60))
  else 
   -- interval between the billing_event and when the file was first seen - interop_file.created_on
       round(((cast(bev.created_on as date) - date '1970-01-01')*24*60
     - (cast(ifile.created_on as date) - date '1970-01-01')*24*60)) 
  END as minutes
   
   
-- calculate penalty based on round((minutes - 240)/240)*0.01
, (case when bev.created_on is null then
   -- interval since the file was first seen (interop_file.created_on)
       round((((current_date - date '1970-01-01')*24*60 
       - (cast(ifile.created_on as date) - date '1970-01-01')*24*60)-240)
       / 240)
  else 
   -- interval between the billing_event and when the file was first seen - interop_file.created_on
       round((((cast(bev.created_on as date) - date '1970-01-01')*24*60 
       - (cast(ifile.created_on as date) - date '1970-01-01')*24*60)-240)
       / 240)
  END) * 0.01 as penalty
   
   
   
   

, bev.created_on - ifile.created_on as time_interval
     
    from interop_file ifile 
        inner join interop_file_exchange exch on exch.RECEIVED_INTEROP_FILE_ID = ifile.interop_file_id
        inner join agency a on a.agency_id = ifile.source_agency_id
        inner join road_event rev on rev.IBT_SOURCE_INTEROP_FILE_ID = ifile.interop_file_id
        right outer join billing_event bev on bev.event_time = rev.event_time and bev.toll_location_id = rev.toll_location_id and bev.toll_lane_id = rev.toll_lane_id and bev.agency_event_id = rev.agency_event_id
    where ifile.ftp_file_type_code = 'CTOC_PAY_BY_PLATE'
    -- and ftp_file_subtype_code in ('RECEIVED', 'RECEIVEDPENDING')
    
    
    and ifile.requested_ftp_status_code = 'RETRIEVED'
       -- covers FtpGetCommand and FtpFetchCommand, but possibly redundant with exch.RECEIVED_INTEROP_FILE_ID = ifile.interop_file_id
       -- requested_ftp_status_code can be null shortly for outgoing files, but not for incoming.  
       --  Either way it's probably safe to remove this "and" completely since it already queries all incoming toll/pbp files
                                                       

  order by ifile.revenue_date desc --, a.agency_code desc -- , ifile.name desc
    FETCH FIRST 2000 ROWS ONLY
    ;


    