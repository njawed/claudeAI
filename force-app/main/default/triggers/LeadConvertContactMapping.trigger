trigger LeadConvertContactMapping on Lead (after update) {
    Lead ld;
    List<SFSMS__c> sms = new List<SFSMS__c>();
   
    for(Lead l: Trigger.New){
        ld=l;
    }
   
    if(ld.isConverted == true){
        for (SFSMS__c s : [Select Id, Contact_Name__c from SFSMS__c where Lead_Name__c=:ld.id]){
            s.Contact_Name__c =ld.ConvertedContactId;
            s.Lead_Name__c=null;
            sms.add(s);  
        }
   }
   update sms;
}