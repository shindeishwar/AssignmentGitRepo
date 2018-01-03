/**
 * Name : DataCorrectionBatchTest
 * Description: DataCorrectionBatch test class
 * 				Due to salesforce limitation of creation/update of CustomMeta Data not able to cover all scenarios.
 * 				Created custom metadata specific for test class in org and used here.
 *  
 * Date             Version        Author           Summary of Changes
 * -----------      ----------  ---------------     ------------------------------------------------------
 * 2/1/2018			1.0			Ishwar Shinde		Initial Draft
 **/

@isTest
private class DataCorrectionBatchTest {
	
   
    /**
     * Name : crateAccountRecords
     * Parametrs :Integer
     * Return Type : List<Account> - created account record list
     * Description: This is generic method to create accounr records for test class
     * 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 2/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
    private static List<Account> crateAccountRecords(Integer noOfAccounts){
        List<Account> accList = new List<Account>();
        Id recordtypeId = getCustomerRecordType();
        for(Integer cnt= 0; cnt< noOfAccounts; cnt++){
        	Account acc= new Account(Name = 'Test Account' + cnt, Enterprise_Account_Status__c = null, NumberOfEmployees = 1, Type = '');
            if(String.isNotBlank(recordtypeId)){
                acc.RecordTypeId = recordtypeId;
            }
            accList.add(acc);
        }
        
        insert accList;
        return accList;
    }
    
     /**
     * Name : getCustomerRecordType
     * Parametrs: none
     * Return Type : Id
     * Description: get Customer record type if exists in org
     * 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 2/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
    private static Id getCustomerRecordType(){
        List<RecordType> recordTypeList = [Select id from RecordType where SobjectType = 'Account' and DeveloperName = 'Customer_Account'];
        if(recordTypeList != null && recordTypeList.size() > 0){
        	return recordTypeList[0].Id;    
        }
        
        return null;
    }
    
    /**
     * Name : createSystsemUser
     * Parametrs: none
     * Return Type : User
     * Description: System Admin user instance
     * 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 3/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
     private static User createSystsemUser(){
        
        String uniqueUserName = 'systemadmin' + DateTime.now().getTime() + '@testorg1.com';
        // This code runs as the system user
        Profile profile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User userRecord = new User(Alias = 'sysdm', Email='systemadmin@testorg1.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = profile.Id,
        TimeZoneSidKey='America/Los_Angeles',
         UserName=uniqueUserName);
        
        return userRecord;
        
    }
    /**
     * Name : testAccountUpdate
     * Parametrs: none
     * Return Type : void
     * Description: test method to check account update
     * 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 3/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
    private static testmethod void testAccountUpdate(){
        List<Account> accList = crateAccountRecords(1);
        System.assertEquals(1, accList.size());
        User admin = createSystsemUser();
		
        Test.StartTest();
            system.runAs(admin){
            	DataCorrectionBatch dataCorrectionBatch = new DataCorrectionBatch();
            	Id jobId = Database.executeBatch(dataCorrectionBatch);	    
            }
            
	    Test.StopTest();   
        Map<Id, Account> accountMap = new Map<Id, Account>([Select Id,Enterprise_Account_Status__c,NumberOfEmployees, Type from Account where Id =:accList[0].Id ]);        
        //Verify the Enterprise_Account_Status__c is updated as bronze
        System.assertEquals('Bronze', accountMap.get(accList[0].Id).Enterprise_Account_Status__c);
        System.assertEquals(200, accountMap.get(accList[0].Id).NumberOfEmployees);
        System.assertEquals('Prospect', accountMap.get(accList[0].Id).Type);
        
    }
    
    /**
     * Name : testAccountUpdate_BulkTest
     * Parametrs: none
     * Return Type : void
     * Description: test method to check account bulk update
     * 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 3/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
    private static testmethod void testAccountUpdate_BulkTest(){
        List<Account> accList = crateAccountRecords(10);
        System.assertEquals(10, accList.size());
        User admin = createSystsemUser();
		Test.StartTest();
            DataCorrectionBatch dataCorrectionBatch = new DataCorrectionBatch();
            Id jobId = Database.executeBatch(dataCorrectionBatch);
	    Test.StopTest();   
        List<Account> accountUpdateList = [Select Id,Enterprise_Account_Status__c,NumberOfEmployees, Type from Account where Enterprise_Account_Status__c = 'Bronze' and NumberOfEmployees = 200 and Type = 'Prospect' ];        
        //Verify the Enterprise_Account_Status__c is updated as bronze
        System.assertEquals(10, accountUpdateList.size());
        
    }
    
    /**
     * Name : testGetValueforDecimal
     * Parametrs: none
     * Return Type : void
     * Description: test method to check Decimal assignment
     * 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 3/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
    private static testmethod void testGetValueforDecimal(){
        
        List<DataCorrectionBatchFieldUpdateSetting__mdt> mdtList = [select 
                                                                       			id, Field_API_Name__c, Data_Type__c,Value_To_Be_Assigned__c 
                                                                       from 
                                                                       			DataCorrectionBatchFieldUpdateSetting__mdt 
                                                                       where 
                                                                       			DeveloperName = 'Test_Class_Data_Update_Decimal'];
        User admin = createSystsemUser();
        Decimal value;
		Test.StartTest();
            system.runAs(admin){
               value  = (Decimal) DataCorrectionBatchHelper.getValue(mdtList[0]);
            }
	    Test.StopTest();   
        
        System.assertEquals(20.10, value);
        
    }
    
    /**
     * Name : testGetValueforBooleanTrue
     * Parametrs: none
     * Return Type : void
     * Description: test method to check Boolean assignment with true value
     * 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 3/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
    private static testmethod void testGetValueforBooleanTrue(){
        
        List<DataCorrectionBatchFieldUpdateSetting__mdt> mdtList = [select 
                                                                       			id, Field_API_Name__c, Data_Type__c,Value_To_Be_Assigned__c 
                                                                       from 
                                                                       			DataCorrectionBatchFieldUpdateSetting__mdt 
                                                                       where 
                                                                       			DeveloperName = 'Test_Class_Data_Update_Boolean_True'];
        User admin = createSystsemUser();
        Boolean value;
		Test.StartTest();
        	system.runAs(admin){
            	value = (Boolean) DataCorrectionBatchHelper.getValue(mdtList[0]);
            }
	    Test.StopTest();   
        
        System.assertEquals(true, value);
        
    }
    
    /**
     * Name : testGetValueforBooleanFalse
     * Parametrs: none
     * Return Type : void
     * Description: test method to check Boolean assignment with false value
     * 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 3/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
    private static testmethod void testGetValueforBooleanFalse(){
        
        List<DataCorrectionBatchFieldUpdateSetting__mdt> mdtList = [select 
                                                                       			id, Field_API_Name__c, Data_Type__c,Value_To_Be_Assigned__c 
                                                                       from 
                                                                       			DataCorrectionBatchFieldUpdateSetting__mdt 
                                                                       where 
                                                                       			DeveloperName = 'Test_Class_Data_Update_Boolean_False'];
        User admin = createSystsemUser();
        Boolean value;
		Test.StartTest();
            system.runAs(admin){
                 value = (boolean) DataCorrectionBatchHelper.getValue(mdtList[0]);
            }
	    Test.StopTest();   
        
        System.assertEquals(false, value );
        
    }
    
    /**
     * Name : testGetValueforBooleanBlank
     * Parametrs: none
     * Return Type : void
     * Description: test method to check Boolean assignment with blank value
     * 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 3/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
    private static testmethod void testGetValueforBooleanBlank(){
        
        List<DataCorrectionBatchFieldUpdateSetting__mdt> mdtList = [select 
                                                                       			id, Field_API_Name__c, Data_Type__c,Value_To_Be_Assigned__c 
                                                                       from 
                                                                       			DataCorrectionBatchFieldUpdateSetting__mdt 
                                                                       where 
                                                                       			DeveloperName = 'Test_Class_Data_Update_Boolean_Blank'];
        User admin = createSystsemUser();
        Boolean value;
		Test.StartTest();
        	system.runAs(admin){
            	value = (boolean) DataCorrectionBatchHelper.getValue(mdtList[0]);
            }
	    Test.StopTest();   
        
        System.assertEquals(false, value );
        
    }
    
    /**
     * Name : testGetValueforDate
     * Parametrs: none
     * Return Type : void
     * Description: test method to check Boolean assignment with Date value as Today
     * 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 3/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
    private static testmethod void testGetValueforDate(){
        
        List<DataCorrectionBatchFieldUpdateSetting__mdt> mdtList = [select 
                                                                       			id, Field_API_Name__c, Data_Type__c,Value_To_Be_Assigned__c 
                                                                       from 
                                                                       			DataCorrectionBatchFieldUpdateSetting__mdt 
                                                                       where 
                                                                       			DeveloperName = 'Test_Class_Data_Update_Date_Today'];
        User admin = createSystsemUser();
        Date value;
		Test.StartTest();
        	system.runAs(admin){
            	value = (Date) DataCorrectionBatchHelper.getValue(mdtList[0]);
            }
	    Test.StopTest();   
        
        System.assertEquals(System.today(), value);
        
    }
    
    /**
     * Name : testGetValueforDateTime
     * Parametrs: none
     * Return Type : void
     * Description: test method to check Boolean assignment with Date value as Now
     * 
     * Date             Version        Author           Summary of Changes
     * -----------      ----------  ---------------     ------------------------------------------------------
     * 3/1/2018			1.0			Ishwar Shinde		Initial Draft
     **/
    private static testmethod void testGetValueforDateTime(){
        
        List<DataCorrectionBatchFieldUpdateSetting__mdt> mdtList = [select 
                                                                       			id, Field_API_Name__c, Data_Type__c,Value_To_Be_Assigned__c 
                                                                       from 
                                                                       			DataCorrectionBatchFieldUpdateSetting__mdt 
                                                                       where 
                                                                       			DeveloperName = 'Test_Class_Data_Update_DateTime_Now'];
        User admin = createSystsemUser();
        DateTime value;
		Test.StartTest();
        	system.runAs(admin){
            	value = (DateTime) DataCorrectionBatchHelper.getValue(mdtList[0]);
            }
	    Test.StopTest();   
        
        System.assert(System.now() > value);
        
    }
}