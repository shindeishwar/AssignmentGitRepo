/**
 * Name : DataCorrectionBatchHelper
 * Description: This is helper class of DataCorrectionBatch. Contains the different methods used for batch processing
 * 
 * Date             Version        Author           Summary of Changes
 * -----------      ----------  ---------------     ------------------------------------------------------
 * 2/1/2018			1.0			Ishwar Shinde		Initial Draft
 **/
public class DataCorrectionBatchHelper {
    
    //To flag the failure limit reach 
    public static boolean logFailure= true;
    
	/**
     * Name : getBatchQueryLocator
     * Parametrs : DataCorrectionBatchSetting__mdt
     * return Type: Database.QueryLocator
     * Description: generate the query locator for the batch using DataCorrectionBatchSetting.BatchQuery custom metadata
     * 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 2/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
    public static Database.QueryLocator getBatchQueryLocator(DataCorrectionBatchSetting__mdt dataCorrectionSetting){
        
        if(dataCorrectionSetting != null && String.isNotBlank(dataCorrectionSetting.BatchQuery__c) ){
            return Database.getQueryLocator(dataCorrectionSetting.BatchQuery__c);
        }
        
        return null;
    }
    
    
    /**
     * Name : fetchActiveDataCorrectionSetting
     * Parametrs : None
     * return Type : DataCorrectionBatchSetting__mdt
     * Description: Get the active Data Correction Batch setting instance to process. If mutiple records are active, batch will select any one of them.
     * 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 2/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
    public static DataCorrectionBatchSetting__mdt fetchActiveDataCorrectionSetting(){
        //fetch active Data correction Batch Setting along with Fields to updates
        List<DataCorrectionBatchSetting__mdt> dataCorrectionSettingList = [Select 
                                                                           			isActive__c, 
                                                                           			Object_API_Name__c, 
                                                                           			Id, 
                                                                           			BatchQuery__c, 
                                                                           			Notification_Emails__c,
                                                                           			(Select Id, 
                                                                                     		Field_API_Name__c, 
                                                                                     		Data_Type__c, 
                                                                                     		Value_To_Be_Assigned__c 
                                                                                     From DataCorrectionBatchFieldUpdateSettings__r) 
                                                                           From 
                                                                           		DataCorrectionBatchSetting__mdt
                                                                           Where 
                                                                           		isActive__c = true 
                                                                           Limit 1 ];
        
        if( dataCorrectionSettingList != null && dataCorrectionSettingList.size() > 0){
            return dataCorrectionSettingList[0];
        }
        
        return null;
    }
    
    /**
     * Name : executeBatch
     * Parametrs : DataCorrectionBatchSetting__mdt, List<Sobject>, Set<String>
     * return Type: Integer - number of records successfully saved 
     * Description: This method will perform the data correction logic as metioned in custom metadata settings
     * 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 2/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
    public static Integer executeBatch(DataCorrectionBatchSetting__mdt dataCorrectionSetting,List<Sobject> sobjectList,Set<String> errorsOccured){
        //Capture intial few errors(200) to avoid heap size issue on batch with large data
        //Scope of Improvement: Error handling using custom object to log each/simillar failure in details.
        logFailure = (errorsOccured.size() >= GlobalConstants.MAX_ERROR_LOG_COUNT ? false : true );
        
        
        List<sObject> sobjectToUpadteList = new List<sObject>();
        //If no active setting present, it will return 0 and skip the processing
        if(dataCorrectionSetting == null && dataCorrectionSetting.DataCorrectionBatchFieldUpdateSettings__r == null && dataCorrectionSetting.DataCorrectionBatchFieldUpdateSettings__r.size() <= 0){
            return 0;
        }
        //process each sobject record
        for(Sobject sobj: sobjectList){
            if(processSobject(dataCorrectionSetting,sobj, errorsOccured)){
                sobjectToUpadteList.add(sobj);
            }
        }
        //save the processed records and return the sucessful saved record count 
        return saveSobjects(sobjectToUpadteList,errorsOccured);
    }
    
    /**
     * Name : processSobject
     * Parametrs : 
     * Description: This method will populate the data on records as per the configuration. Currently supportd types are Integer, Decimal, Boolean, Date (with Today function), DateTime (with Now function), Text - Piclist , Text , Text Area etc.
     * 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 2/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
    private static boolean processSobject(DataCorrectionBatchSetting__mdt dataCorrectionSetting,Sobject obj,Set<String> errorsOccured){
        try{
        	//perform mutilple operations depening on configuration 
            for(DataCorrectionBatchFieldUpdateSetting__mdt fieldUpdateRecord: dataCorrectionSetting.DataCorrectionBatchFieldUpdateSettings__r){
                obj.put( fieldUpdateRecord.Field_API_Name__c, getValue(fieldUpdateRecord));
            }
            return true;
        }catch(Exception ex){//error handling scenarios
            System.debug(LoggingLevel.ERROR, 'Error Message : ' + ex.getMessage());
            System.debug(LoggingLevel.ERROR, 'Error StackTrace : ' + ex.getStackTraceString());
            //Document failure
    		if(logFailure){
    			errorsOccured.add(GlobalConstants.RECORD_ID + obj.Id + GlobalConstants.ERR_OCCURED_IN_PROCESSING + ex.getMessage() + GlobalConstants.NEW_LINE + GlobalConstants.STACK_TRACE + ex.getStackTraceString() );
    		}
            return false;
        }
    }
    
    /**
     * Name : getValue
     * Parametrs :DataCorrectionBatchFieldUpdateSetting__mdt
     * Return Type : Object - converted values depending of data type
     * Description: This is generic method to get value from DataCorrectionBatchFieldUpdateSetting__mdt record. Depending on datatype call diffirent method to convert the value
     * 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 2/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
    public static Object getValue(DataCorrectionBatchFieldUpdateSetting__mdt fieldUpdateRecord){
        
        if(String.isBlank( fieldUpdateRecord.Value_To_Be_Assigned__c)){ //handle the scenario when value is not present 
            if(fieldUpdateRecord.Data_Type__c.equalsIgnoreCase(GlobalConstants.BOOLEAN_STR)){ //for boolean, null value will be traeted as false
                return false;
            }
            return null; //other blank value will be trated as null
        }
        
        String dataType = (String.isBlank(fieldUpdateRecord.Data_Type__c)? '' : fieldUpdateRecord.Data_Type__c );
        
        //Integer values
        if(dataType.equalsIgnoreCase(GlobalConstants.INTEGER_STR)){
            return getIntegerValue(fieldUpdateRecord.Value_To_Be_Assigned__c);
        //Decimal values 
        }if(dataType.equalsIgnoreCase(GlobalConstants.DECIMAL_STR)){
            return getDecimalValue(fieldUpdateRecord.Value_To_Be_Assigned__c);
        //Boolean values    
        }else if(dataType.equalsIgnoreCase(GlobalConstants.BOOLEAN_STR)){
            return getBooleanValue(fieldUpdateRecord.Value_To_Be_Assigned__c);
        //Date values        
        }else if(dataType.equalsIgnoreCase(GlobalConstants.DATE_STR)){
            return getDateValue(fieldUpdateRecord.Value_To_Be_Assigned__c);
        //DateTime Values    
        }else if(dataType.equalsIgnoreCase(GlobalConstants.DATETIME_STR)){
            return getDateTimeValue(fieldUpdateRecord.Value_To_Be_Assigned__c);
        }
        //String values
        return fieldUpdateRecord.Value_To_Be_Assigned__c;
        
    }
    
    /**
     * Name : getIntegerValue
     * Parametrs :String
     * Return Type : Integer - converted value 
     * Description: This method to convert string value in Integer
     * 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 2/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
    private static Integer getIntegerValue(String value){
        return Integer.valueOf(value);
    }
    
    /**
     * Name : getDecimalValue
     * Parametrs :String
     * Return Type : Decimal - converted value 
     * Description: This method to convert string value in Decimal
     * 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 2/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
    private static Decimal getDecimalValue(String value){
        return Decimal.valueOf(value);
    }
    
    /**
     * Name : getBooleanValue
     * Parametrs :String
     * Return Type : Boolean - converted value 
     * Description: This method to convert string value in boolean
     * 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 2/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
    private static Boolean getBooleanValue(String value){
        return Boolean.valueOf(value);
    }
    
    /**
     * Name : getDateValue
     * Parametrs :String
     * Return Type : Date - converted value 
     * Description: This method to convert string value in Date. Handled special case for Today function. 
     * 				The format of the String depends on the local date format.
     * 				//Scope of improvement : Can handle different date function and formats 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 2/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
    private static Date getDateValue(String value){
        if( value.equalsIgnoreCase(GlobalConstants.TODAY_STR)){
            return Date.Today();
        }
        return Date.parse(value);
    }
    
    /**
     * Name : getDateTimeValue
     * Parametrs :String
     * Return Type : DateTime - converted value 
     * Description: This method to convert string value in DateTime. Handled special case for Now function.
     * 				The format of the String depends on the local date format. 
     * 				//Scope of improvement : Can handle different datetime functions and formats 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 2/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
    private static DateTime getDateTimeValue(String value){
        if( value.equalsIgnoreCase(GlobalConstants.NOW_STR)){
            return DateTime.Now();
        }
        return DateTime.parse(value);
    }
    
    /**
     * Name : saveSobjects
     * Parametrs : sobjectToUpadteList, errorsOccured
     * Description: This will update the proccessed records in DB.
     * 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 2/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
    private static Integer saveSobjects(List<Sobject> sobjectToUpadteList, Set<String> errorsOccured){
        Integer successfulRecordCount = 0;
        //perform partial update on records. failures will be informed to user
        Database.SaveResult[] dbResults = Database.update(sobjectToUpadteList, false);
        
        for(Database.SaveResult saveResult: dbResults){
        	if(saveResult.isSuccess()){
        		successfulRecordCount ++;
        	}else{
        		//Document failure
        		if(logFailure){
        			errorsOccured.add(GlobalConstants.RECORD_ID + saveResult.getId() + GlobalConstants.ERR_OCCURED_IN_SAVE + saveResult.getErrors() );
        		}
        	}
        }
        
        return successfulRecordCount;
    }
    
    /**
     * Name : sendBatchCompletionNotification
     * Parametrs : Database.BatchableContext, DataCorrectionBatchSetting__mdt, Integer, Integer
     * Description: Send Batch Completion Notification.
     * 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 2/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
    public static void sendBatchCompletionNotification(Database.BatchableContext batchContext, DataCorrectionBatchSetting__mdt dataCorrectionSetting, Integer totalRecords, Integer successfulRecordsCount, Set<String> errorOccured ){
        //Added limit check to avoid batch failure due to emiail limit exceed.
        
       	String body ='';
        try{
            
            if( String.isNotBlank( dataCorrectionSetting.Notification_Emails__c) ){
                String[] emailAddressList =  dataCorrectionSetting.Notification_Emails__c.split(',');
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();	
                //set email address
                mail.toAddresses = emailAddressList;
                //set subject
                mail.setSubject(Label.DCB_EMAIL_SUBJECT + batchContext.getJobID());
                String recordCnt =  successfulRecordsCount + GlobalConstants.FWD_SLASH +totalRecords;
                //set body	
                body = GlobalConstants.NEW_LINE + String.format(Label.DCB_BODY_1, new List<String> { recordCnt });
                //if errors are occured then add in mail
                if(totalRecords != successfulRecordsCount && errorOccured != null){
                    body += GlobalConstants.NEW_LINE + GlobalConstants.NEW_LINE+ Label.DCB_BODY_2;
                    for( string err : errorOccured){
                        body += GlobalConstants.NEW_LINE + err;    
                    }
                    
                }
                
                body += GlobalConstants.NEW_LINE + GlobalConstants.NEW_LINE + LABEL.EMAIL_SIGN;
                mail.setPlainTextBody(body);
                
                //send email
                if(! Test.isRunningTest()){ //skip for test class
                    Messaging.reserveSingleEmailCapacity( GlobalConstants.EMAIL_CAPACITY) ; //addd workaround method to catach email governor limits in advance
                    Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });     
                     
                }
            }
        }catch(Exception ex){
            System.debug( LoggingLevel.ERROR, 'Email message failure. '+ex.getMessage());
            System.debug( LoggingLevel.ERROR, 'Email Body - '+ body);
        } 
    }
    
}