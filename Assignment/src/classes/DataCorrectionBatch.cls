/**
 * Name : DataCorrectionBatch
 * Description: This is generic batch to perform the data correction. Using DataCorrectionBatchSetting setting you can configure the batch 
 * 				- define records to processs, notification emails, fields to update with values etc. 
 * 
 * Date             Version        Author           Summary of Changes
 * -----------      ----------  ---------------     ------------------------------------------------------
 * 2/1/2018			1.0			Ishwar Shinde		Initial Draft
 **/

public class DataCorrectionBatch implements Database.Batchable<sObject>,  Database.Stateful {
	//DataCorrectionBatch Setting to perform the update operation during batch execution
    public DataCorrectionBatchSetting__mdt dataCorrectionSetting;
    //To capture the error occured during execution
    public Set<String> errorsOccured = new Set<String>();
    //count the records successfully saved
    public Integer sucessfullySavedRecords = 0;
    //count the total number of records proccessed 
    public Integer totalRecords = 0;
    
    /**
     * Name : start
     * Parametrs :
     * Description: This is the start method of batch. Define the query locator here
     * 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 2/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
    public Database.QueryLocator start(Database.BatchableContext batchContext){
        //get active data correction batch setting with fields to update
        dataCorrectionSetting = DataCorrectionBatchHelper.fetchActiveDataCorrectionSetting();
        //get query locator using the dataCorrectionSetting.BatchQuery field
        return DataCorrectionBatchHelper.getBatchQueryLocator(dataCorrectionSetting);
    }
    
    /**
     * Name : execute
     * Parametrs : Database.BatchableContext , List<sObject> 
     * Description: This will perform the actual logic on processing and updating the records
     * 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 2/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
    
    public void execute(Database.BatchableContext batchContext, List<sObject> sobjectList){
        //count the total no of records
        totalRecords += totalRecords + sobjectList.size();
        //process the records
    	sucessfullySavedRecords += DataCorrectionBatchHelper.executeBatch(dataCorrectionSetting, sobjectList, errorsOccured);
        
    }
    
    /**
     * Name : finish
     * Parametrs : Database.BatchableContext
     * Return Type : void
     * Description: This will perform the post execution logic. It will inform users after completion of batch
     * 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 2/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
    public void finish(Database.BatchableContext batchContext){
        DataCorrectionBatchHelper.sendBatchCompletionNotification(batchContext, dataCorrectionSetting, totalRecords,sucessfullySavedRecords,errorsOccured );
    }
}