/**
 * Name : GlobalConstants
 * Description: Use to define the constant variables accross the application. Provide better control in managing the change. 
 * 
 * Date             Version        Author           Summary of Changes
 * -----------      ----------  ---------------     ------------------------------------------------------
 * 2/1/2018			1.0			Ishwar Shinde		Initial Draft
 **/
public with sharing class GlobalConstants {
 	//Datatypes
 	public static final string INTEGER_STR = 'Integer';
 	public static final string DECIMAL_STR = 'Decimal';
 	public static final string BOOLEAN_STR = 'Boolean';
 	public static final string DATE_STR = 'Date';
 	public static final string DATETIME_STR = 'DateTime';
    
    //special functions
 	public static final string TODAY_STR = 'Today';
 	public static final string NOW_STR = 'NOW';  
    
    //Debug constants
    public static final string RECORD_ID = 'Record Id -';
    public static final string ERR_OCCURED_IN_PROCESSING = ' Error occured during processing :';
    public static final string ERR_OCCURED_IN_SAVE = ' Error occured during save :';
    public static final string STACK_TRACE = 'Stack Trace';
    public static final string FWD_SLASH = '/';
    public static final string NEW_LINE = '\r\n';  
    
    //limit constants
    public static final Integer MAX_ERROR_LOG_COUNT = 200;

}