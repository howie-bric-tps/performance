select distinct ftp_file_type_code from interop_file ifile;

select * from interop_file ifile 
    inner join road_event rev on rev.IBT_SOURCE_INTEROP_FILE_ID = ifile.interop_file_id
    where ifile.ftp_file_type_code in ('FLEET_TOLL', 'FLEET_PLATE_TAG') 
    -- and ftp_file_subtype_code in ('RECEIVED', 'RECEIVEDPENDING')
    
    
    -- and ifile.requested_ftp_status_code = 'RETRIEVED'
;

--        inner join interop_file_exchange exch on exch.RECEIVED_INTEROP_FILE_ID = ifile.interop_file_id
--        inner join agency a on a.agency_id = ifile.source_agency_id
--        inner join road_event rev on rev.IBT_SOURCE_INTEROP_FILE_ID = ifile.interop_file_id
--        right outer join billing_event bev on bev.event_time = rev.event_time and bev.toll_location_id = rev.toll_location_id and bev.toll_lane_id = rev.toll_lane_id and bev.agency_event_id = rev.agency_event_id
        
-- final columns:
-- sums
-- Top Level Report for Posting Date 1/6/2022
-- SR91             1/6/22     srtc20220106.tol      3 records posted late       $0.04 penalty due
-- SR91             1/6/22      srtc20220106.pbp   0 records posted late
-- SANDAG      1/6/22      sdtc20220106.tol     0 records posted late

-- only those with penalties
-- Summary Report for Posting Data 1/6/2022
-- SR91   1/6/2022    srtc20220106.tol  2021-01-06 01:00:00   2021-01-06 03:27:13   148  $0.01 penalty
-- SR91   1/6/2022    srtc20220106.tol  2021-01-06 01:00:00   2021-01-06 03:29:13   150  $0.01 penalty
-- SR91   1/6/2022    srtc20220106.tol  2021-01-06 01:00:00   2021-01-06 15:27:13   948  $0.02 penalty

-- all rows
-- Detail Report for Posting Date 1/6/2022
-- SR91   1/6/2022    srtc20220106.tol  2021-01-06 12:00:00   2021-01-06 12:42:13   42  $0.00 penalty
-- SR91   1/6/2022    srtc20220106.tol  2021-01-06 01:00:00   2021-01-06 03:27:13   148  $0.01 penalty
-- SR91   1/6/2022    srtc20220106.tol  2021-01-06 01:00:00   2021-01-06 03:29:13   150  $0.01 penalty
-- SR91   1/6/2022    srtc20220106.tol  2021-01-06 01:00:00   2021-01-06 15:27:13   948  $0.02 penalty (edited) 

-- time difference for ctoc files == time a toll posts (billing_event.created_on ?)
--                                   minus time available on ftp server (interop_file.created_on is the closest we have)

-- file first known to us is interop_file.created_on
-- select * from (


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


-- , ifile.requested_ftp_status_code, ifile.current_ftp_status_code
     
    from interop_file ifile 
        inner join interop_file_exchange exch on exch.RECEIVED_INTEROP_FILE_ID = ifile.interop_file_id
        inner join agency a on a.agency_id = ifile.source_agency_id
        inner join road_event rev on rev.IBT_SOURCE_INTEROP_FILE_ID = ifile.interop_file_id
        right outer join billing_event bev on bev.event_time = rev.event_time and bev.toll_location_id = rev.toll_location_id and bev.toll_lane_id = rev.toll_lane_id and bev.agency_event_id = rev.agency_event_id
    where ifile.ftp_file_type_code in ('FLEET_TOLL', 'FLEET_PLATE_TAG') 
    -- and ftp_file_subtype_code in ('RECEIVED', 'RECEIVEDPENDING')
    
    
    and ifile.requested_ftp_status_code = 'RETRIEVED'
       -- covers FtpGetCommand and FtpFetchCommand, but possibly redundant with exch.RECEIVED_INTEROP_FILE_ID = ifile.interop_file_id
       -- requested_ftp_status_code can be null shortly for outgoing files, but not for incoming.  
       --  Either way it's probably safe to remove this "and" completely since it already queries all incoming toll/pbp files
                                                       

  order by ifile.revenue_date desc --, a.agency_code desc -- , ifile.name desc
    FETCH FIRST 2000 ROWS ONLY
    ;


    
    ) a
    -- where penalty != 0.01;
    -- order by a.revenue_date asc, a.filename desc
    ;

select revenue_date, interop_file_id from interop_file where ftp_file_type_code in ('CTOC_TOLL', 'CTOC_PAY_BY_PLATE') 
and requested_ftp_status_code = 'RETRIEVED' -- covers FtpGetCommand and FtpFetchCommand
and revenue_date = ' 2021-12-20 00:00:00'
order by revenue_date desc;



select distinct revenue_date from interop_file where ftp_file_type_code in ('CTOC_TOLL', 'CTOC_PAY_BY_PLATE') 
and requested_ftp_status_code = 'RETRIEVED' -- covers FtpGetCommand and FtpFetchCommand
order by revenue_date desc;
-- select to_char(cast(sysdate as date),'DD-MM-YYYY') from dual;

-- in prefs/NLS

-- timestamp tz: DD-MON-RR HH.MI.SSXFF AM TZR
-- timestamp : SYYYY-MM-DD HH24:MI:SSXFF9
--              2021-05-13 22:32:09.344000000
-- date: SYYYY-MM-DD HH24:MI:SS
--        2021-05-13 00:00:00

-- revenue_date is a date, created_on is a timestamp(3)

-- need a row count - RECEIVED PENDING signifies what?

-- when any incoming ctoc pbp/tol interop_file records for ctoc are first created, they're set to 
--   ftp_file_subtype_code RECEIVED_PENDING
-- how to tell when ALL have been loaded?
-- when the response prc/trc is created, it sets ftp_file_subtype_code to RECEIVED


-- select * from interop_file_exchange;

--interop_file_exchange.RECEIVED_FILE_HEADER does not have row count, but the footer does

its set when... interop_file_exchange.RECEIVED_FILE_HEADER




--         if ((ftpCommand.direction == FtpCommandDirection.INCOMING) &&
--             (ftpCommand.partnerTypeCode == InteropPartnerType.Value.CTOC.code) &&
--             ([FtpFileType.Value.CTOC_PAY_BY_PLATE.code, FtpFileType.Value.CTOC_TOLL.code].contains(ftpCommand.ftpFileTypeCode))) {
--                 return FtpFileSubtype.Value.RECEIVEDPENDING.code
--         }
--         FtpFileSubtype.Value.RECEIVED.code


-- SENT_FILE_HEADER
--SENT_INTEROP_FILE_ID
--RECEIVED_FILE_HEADER
--RECEIVED_INTEROP_FILE_ID




cast(created_on as date)

select 
--    exch.*
    exch.RECEIVED_FILE_HEADER
    , ifile.created_on, ifile.revenue_date
--    , TO_CHAR(created_on, 'SYYYY-MM-DD HH24:MI:SSXFF3') as non_9
--    , TO_CHAR(created_on, 'DD-MON-YYYY HH24:MI:SSxFF') as one
--    , interop_file_id, to_char(created_on, 'DD-MM-YYYY:HH:mm:ss') as cre_on, created_on, to_char(cast(revenue_date as date),'DD-MM-YYYY')as rev_date, name
--    , ftp_file_type_code, ftp_file_subtype_code, requested_ftp_status_code, current_ftp_status_code
    
   --, TO_CHAR(created_on, 'DD-MON-YYYY HH24:MI:SSxFF TZH:TZM') as two
    -- , to_char(cast(revenue_date as date),'DD-MM-YYYY') as r_d, to_char(cast(created_on as date),'DD-MM-YYYY') as c_on
    from interop_file ifile inner join interop_file_exchange exch 
            on exch.RECEIVED_INTEROP_FILE_ID = ifile.interop_file_id
    where ifile.ftp_file_type_code in ('CTOC_TOLL', 'CTOC_PAY_BY_PLATE') 
    -- and ftp_file_subtype_code in ('RECEIVED', 'RECEIVEDPENDING')
    and ifile.requested_ftp_status_code = 'RETRIEVED' -- covers FtpGetCommand and FtpFetchCommand
    and rownum < 20
    -- and to_char(revenue_date,'DD-MM-YYYY') != to_char(cast(created_on as date),'DD-MM-YYYY')
    -- and revenue_date != cast(created_on as date)
    order by ifile.revenue_date asc;

-- get
--     static final List<String> CHAIN = [
--             FtpStatus.Value.LOCAL.code,
--             FtpStatus.Value.SCANNED.code,
--             FtpStatus.Value.RETRIEVED.code
--     ]
-- fetch:    
--     static final List<String> CHAIN = [
--             FtpStatus.Value.REMOTE.code,
--             FtpStatus.Value.TRANSFERRED.code,
--             FtpStatus.Value.SCANNED.code,
--             FtpStatus.Value.RETRIEVED.code
--     ]    


-- what about these?
select 
    requested_ftp_status_code, current_ftp_status_code, interop_file_id, created_on, revenue_date, name, ftp_file_type_code, ftp_file_subtype_code
    -- , to_char(cast(revenue_date as date),'DD-MM-YYYY') as r_d, to_char(cast(created_on as date),'DD-MM-YYYY') as c_on
    from interop_file
    where ftp_file_type_code in ('CTOC_TOLL', 'CTOC_PAY_BY_PLATE') 
    -- and ftp_file_subtype_code not in ('RECEIVED', 'RECEIVEDPENDING', 'SENT')
    and ftp_file_subtype_code in ('RECEIVED', 'RECEIVEDPENDING')
    and current_ftp_status_code != 'RETRIEVED'
    and rownum < 20
    -- and to_char(cast(revenue_date as date),'DD-MM-YYYY')!= to_char(cast(created_on as date),'DD-MM-YYYY')
    order by revenue_date desc;




select 
    distinct ftp_file_subtype_code, current_ftp_status_code
    from interop_file
    where ftp_file_type_code in ('CTOC_TOLL', 'CTOC_PAY_BY_PLATE') 
    order by ftp_file_subtype_code, current_ftp_status_code
    ;
    
def interopFiles = InteropFile.findAllByFtpFileSubtypeAndFtpFileTypeInListAndCurrentFtpStatus(
                FtpFileSubtype.Value.RECEIVEDPENDING.type, tollAndPbpTypes, FtpStatus.Value.RETRIEVED.type)

-- interop row count, road_event.IBT_SOURCE_INTEROP_FILE_ID

    
    
    select created_on, interop_file_id, name, revenue_date 
    from interop_file 
    where ftp_file_type_code in ('CTOC_TOLL', 'CTOC_PAY_BY_PLATE') 
    and revenue_date !=  '2021-05-13 00:00:00'
    order by revenue_date, name;
    
select distinct revenue_date 
    from interop_file
    where ftp_file_type_code in ('CTOC_TOLL', 'CTOC_PAY_BY_PLATE') 
    order by revenue_date desc;    




select 
    IBT_SOURCE_INTEROP_FILE_ID, source_type_code, source_subtype1code, 
    EVENT_TIME, TOLL_LOCATION_ID, TOLL_LANE_ID, AGENCY_EVENT_ID
    from road_event 
    where IBT_SOURCE_INTEROP_FILE_ID is not null 
    and source_type_code = 'INTEROP' 
    and rownum < 10;


select * from interop_file where interop_file_id = 106;

-- 19783
select count(*) from interop_file;
-- 14316
select count(*) from interop_file where ftp_file_type_code not in ('RENTAL_PLATE_TAG', 'FLEET_PLATE_TAG');
-- older ones have same revenue date 2021-05-13 00:00:00
select name, revenue_date, ftp_file_type_code from interop_file where ftp_file_type_code not in ('RENTAL_PLATE_TAG', 'FLEET_PLATE_TAG') and rownum < 10;
select distinct ftp_file_type_code from interop_file;
select distinct ftp_file_type_code from interop_file where ftp_file_type_code not in ('RENTAL_PLATE_TAG', 'FLEET_PLATE_TAG');

-- 6765
select count(*) from interop_file where ftp_file_type_code in ('CTOC_TOLL', 'CTOC_PAY_BY_PLATE');


-- AVI_SOURCE_INTEROP_FILE_ID
select distinct revenue_date from interop_file where ftp_file_type_code in ('CTOC_TOLL', 'CTOC_PAY_BY_PLATE');

select * from interop_file ifile right outer join road_event re
    on ifile.interop_file_id = re.AVI_SOURCE_INTEROP_FILE_ID
    
    
    where AVI_SOURCE_INTEROP_FILE_ID is not null
IBT_SOURCE_INTEROP_FILE_ID