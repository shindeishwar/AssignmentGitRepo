<?xml version="1.0" encoding="UTF-8"?>
<CustomMetadata xmlns="http://soap.sforce.com/2006/04/metadata" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <label>Account Data Update 1</label>
    <protected>false</protected>
    <values>
        <field>BatchQuery__c</field>
        <value xsi:type="xsd:string">Select Id,Enterprise_Account_Status__c from Account where Enterprise_Account_Status__c = null and RecordType.DeveloperName = &apos;Customer_Account&apos; Order by CreatedDate DESC</value>
    </values>
    <values>
        <field>Notification_Emails__c</field>
        <value xsi:type="xsd:string">connecttoishwar@gmail.com</value>
    </values>
    <values>
        <field>Object_API_Name__c</field>
        <value xsi:type="xsd:string">Account</value>
    </values>
    <values>
        <field>isActive__c</field>
        <value xsi:type="xsd:boolean">true</value>
    </values>
</CustomMetadata>
