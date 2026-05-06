@isTest
private class LeadConvertToContact {
/* Test method class for all the triggers in the virtual realty*/

     static testMethod void b2cLeadConvert() {
       Lead l = new Lead(LastName='Bathula', Status='Followup(FWP)',Company='Rixy');
       insert l;
       Contact c = new Contact(LastName='test');
       insert c;
       SFSMS__c ca1 = new  SFSMS__c(Lead_Name__c=l.id);
       SFSMS__c ca2 = new  SFSMS__c(Lead_Name__c=l.id);
       
       insert ca1; insert ca2;
       
       // convert the lead
       Database.LeadConvert lc =
       new database.LeadConvert();        
       lc.setLeadId(l.Id);        
       LeadStatus convertstatus = [select Id, MasterLabel from LeadStatus where IsConverted=
       true limit 1];        
       lc.setConvertedStatus(convertStatus.MasterLabel);        
       Database.LeadConvert[] lcArray =
       new Database.LeadConvert[] {lc};        
       Database.LeadConvertResult[] results = Database.convertLead(lcArray);        
       System.assert(results[0].IsSuccess());              
   
   }
}