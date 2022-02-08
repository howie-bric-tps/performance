-- ctoc road_event via transcore, end time ftp file history placed or sent?



-- when is it available ? 
-- Using road_event.created_on in part 3, maybe fin_tx.created_on or updated_on?


select * from interop_file ifile where ifile.ftp_file_type_code in ('CTOC_TOLL', 'CTOC_PAY_BY_PLATE') and ifile.ftp_file_subtype_code = 'SENT' order by revenue_date desc;
--for outgoing tol/pbp, how to relate road_event to interopFile?
select rev.*
-- rev.road_event_id, bev.billing_event_id, tx.financial_transaction_id, agency.agency_code, agency.agency_type_code, account.account_id as interop_account_id
    from agency 
    inner join account on agency.account_id = account.account_id
    inner join financial_transaction tx on tx.customer_account_id = account.account_id
    inner join billing_event bev on tx.record_id = bev.billing_event_id
    inner join road_event rev on bev.event_time = rev.event_time and bev.toll_location_id = rev.toll_location_id and bev.toll_lane_id = rev.toll_lane_id and bev.agency_event_id = rev.agency_event_id
    -- on rev.AVI_SOURCE_INTEROP_FILE_ID = ifile.interop_file_id
    
    where 
    agency.agency_type_code = 'INTEROP_CUSTOMER' -- agency_id and agency_code are indexed
    
    
    -- this is just like the code used to fetch transactions when creating an outgoing tol/pbp file
    -- but maybe doesn't included enough.  e.g. maybe status other than COMPLETED should be included
    and tx.RECORD_TYPE_CODE = 'BILLING_EVENT'
--            recordType == TransactionRecordType.Value.BILLING_EVENT.type
    and tx.TRANSACTION_TYPE_CODE = 'TOLL_RECEIVABLE'
--            transactionType == TollTransactionType.Value.TOLL_RECEIVABLE.type
    and tx.TRANSACTION_STATUS_CODE = 'COMPLETED'
--            transactionStatus == TransactionStatus.Value.COMPLETED.type
--            revenueDate == Date.valueOf(revenueDate)
    and tx.trx_amount > 0
--            trxAmount > BigDecimal.ZERO
--            id > startId
    
    FETCH FIRST 20 ROWS ONLY
    ;
    
--   Agency.findAll {
--            agencyType == AgencyType.Value.INTEROP_CUSTOMER.type
--        }?.each { agency ->
--            interopAccount = Account.getById(agency.accountId)
--
--       select * from financial_transaction tx
--       where 
--       
--            customer.account == interopAccount
--            recordType == TransactionRecordType.Value.BILLING_EVENT.type
--            transactionType == TollTransactionType.Value.TOLL_RECEIVABLE.type
--            transactionStatus == TransactionStatus.Value.COMPLETED.type
--            revenueDate == Date.valueOf(revenueDate)
--            trxAmount > BigDecimal.ZERO
--            id > startId
            
    















select 
a.agency_name
, rev.event_revenue_date
, ifile.name as filename
--, ifile.created_on as file_first_seen
, bev.created_on as ftp_file_delivered

from road_event rev
    right outer join billing_event bev on bev.event_time = rev.event_time and bev.toll_location_id = rev.toll_location_id and bev.toll_lane_id = rev.toll_lane_id and bev.agency_event_id = rev.agency_event_id
    
    -- not sure this is correct
    where rev.AVI_SOURCE_INTEROP_FILE_ID is null and rev.IBT_SOURCE_INTEROP_FILE_ID is null
    FETCH FIRST 2000 ROWS ONLY
    ;
    
    

    def findCandidates(Long startId, LocalDate revenueDate) {
        log.debug("findCandidates with revenueDate $revenueDate")

        FinancialTransaction.findAll([max: batchSize, sort: ['id': 'asc']]) {
            customer.account == interopAccount
            recordType == TransactionRecordType.Value.BILLING_EVENT.type
            transactionType == TollTransactionType.Value.TOLL_RECEIVABLE.type
            transactionStatus == TransactionStatus.Value.COMPLETED.type
            revenueDate == Date.valueOf(revenueDate)
            trxAmount > BigDecimal.ZERO
            id > startId
        }
        
        
        it.recordId is financial_transaction.recordId
        
                BillingEvent billingEvent = BillingEvent.getById(it.recordId)
                if ((billingEvent.sourceSubtype.code == RoadEventSourceSubtype.Value.AVI.code) &&
                     billingEvent.tagRead?.ctocValue) {
                    makeTollRecord(billingEvent, it, writerToll)
                } else {
                    makePbpRecord(billingEvent, it, writerPbp)
                }
                8889882800
                m-f 7-7
                specialty services
    }    
    
select     
    AGENCY_ID
, REVENUE_DATE
, STATUS_ID
, STATUS_CODE
, RECORD_TYPE_ID
, RECORD_TYPE_CODE
, SOURCE_TYPE_ID
, SOURCE_TYPE_CODE
, SOURCE_SUBTYPE1_ID
, SOURCE_SUBTYPE1CODE
, SOURCE_SUBTYPE2_ID
, SOURCE_SUBTYPE2CODE
, TOLL_ROAD_ID
, TOLL_LOCATION_ID
, TOLL_LANE_ID
, AGENCY_EVENT_ID
, TC_PLAZA
, TC_PLAZA_SEQUENCE_NO
, TC_LANE
, TC_LANE_SEQUENCE_NO
, TC_HOST_SEQUENCE_NO
, TC_VIOLATION_ID
, TC_VIOLATION_CODE
, TC_VEHICLE_CLASS
, TC_BO_OCR
, TC_OR_OCR
, TC_NUMBER_OF_IMAGES
, PLATE_STATE
, PLATE_NUMBER
, PLATE_PLATE_TYPE_ID
, PLATE_PLATE_TYPE_CODE
, REVIEW_RESULT_TYPE_ID
, REVIEW_RESULT_TYPE_CODE
, EVENT_TIME
, EVENT_REVENUE_DATE
, TRIP_ID
, TRAFFIC_COUNT
, ROAD_AMOUNT
, TC_IBT_CODE
, TAG_READ_PROTOCOL_TYPE_ID
, TAG_READ_PROTOCOL_TYPE_CODE
, TAG_READ_CTOC_VALUE
, TAG_READ_TRANSMITTED_VALUE
, TAG_READ_INTERNAL_NUMBER
, AVI_RESPONSE_INTEROP_FILE_ID
, AVI_SOURCE_INTEROP_FILE_ID
, IBT_RESPONSE_INTEROP_FILE_ID
, IBT_SOURCE_INTEROP_FILE_ID
, TCR_POSTED_TIME


from road_event rev
where rev.AVI_SOURCE_INTEROP_FILE_ID is null and rev.IBT_SOURCE_INTEROP_FILE_ID is null
and rev.tag_read_protocol_type_code is null -- pbp
and rev.ibt_response_interop_file_id is not null
--and rev.avi_response_interop_file_id is not null
    FETCH FIRST 20 ROWS ONLY;
    
select agency_id, agency_code, agency_type_code from agency 
where agency_code not like '%_CUSTOMER' and agency_type_code = 'INTEROP_CUSTOMER'
order by agency_type_code;
select * from agency where agency_code like '%_CUSTOMER';

