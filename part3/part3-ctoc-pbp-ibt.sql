
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


    