public with sharing class Utilitysmsforce{

    // This fn is fetching the information like SmsURL and SenderId from StaticResource file smsforce
    
    public static Map<String, String> getProperties(){
        StaticResource sr = [select id,body from StaticResource Where Name = 'smsforce'];
        String contents = sr.body.toString();
        String smsUrlArg='', userNameArg='', passwordArg='';
        String toArg='', senderIdArg='', msgArg='', suffixArg='';
        Map<String, String> prop = new Map<String, String>();    
        for(String line:contents.split('\n')) {
            smsUrlArg= (line.contains('smsUrlArg')) ? line.substring(11) : smsUrlArg;
            senderIdArg = (line.contains('senderIdArg')) ? line.substring(13) : senderIdArg;
            userNameArg = (line.contains('userNameArg')) ? line.substring(13) : userNameArg;
            passwordArg = (line.contains('passwordArg')) ? line.substring(13) : passwordArg;
            toArg = (line.contains('toArg')) ? line.substring(7) : toArg;
            msgArg= (line.contains('msgArg')) ? line.substring(8) : msgArg;
            suffixArg= (line.contains('suffixArg')) ? line.substring(11) : suffixArg;
        }
        prop.put('smsUrlArg',smsUrlArg);
        prop.put('senderIdArg', senderIdArg);
        prop.put('userNameArg',userNameArg);
        prop.put('passwordArg', passwordArg);
        prop.put('toArg',toArg); 
        prop.put('msgArg',msgArg);
        prop.put('suffixArg', suffixArg);
        return prop;
    }
    
    // This fn is making Http callouts to return a Map containing MessageStatus and MessageId
    
    public static Map<String, String> httpCallout(String smsurl){
        Map<String, String> callOutResponse = new Map<String, String>();
        ApexCallouts apexCallOut = new ApexCallouts();
        String messageId='', msgStatus='';    
        try{           
            Http h = new Http();
            
            HttpRequest req = apexCallOut.buildWebServiceRequest(smsurl);
           
            HttpResponse res = apexCallOut.invokeWebService(h,req);
            
            msgStatus = res.getStatusCode()+'-'+res.getStatus();
            
            callOutResponse.put('MessageStatus', msgStatus);  
            
            messageId= apexCallOut.handleWebServiceResponse(res);                      
            
            messageId = (messageId.length()<=14)? messageId : '-';
            
            callOutResponse.put('MessageId', messageId);
            
            return callOutResponse;
        }catch(Exception e){
            System.debug('RII Error'+e.getMessage());
            return null;
        }
    }
    
    // fn that inserts an sms record for a given Lead
    public static void insertSmsRecord(Lead ld, String txtMsg, String msgStatus, String messageId){
        SFSMS__c sms;sms=new SFSMS__c(); 
        sms.Mobile_No__c =ld.MobilePhone;
        sms.Text_Message__c = txtMsg;
        sms.MessageId__c=messageId;
        sms.Status__c=msgStatus;  
        sms.Lead_Name__c = ld.Id;      
        insert sms;
    }
    
   
    //fn used to set the selectoption values in VF page of bulk lead/contact 
    
    public static List<SelectOption> getRadioItems() {
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('Send Now','Send Now')); 
        options.add(new SelectOption('Schedule for delivery on','Schedule for delivery on')); 
        
        return options; 
    }
    
    //fn used set the select option of timezone in bulk lead/contact VF page
    
    public static List<selectOption> getPickValues(Sobject object_name, String field_name) {
        List<selectOption> options = new List<selectOption>(); //new list for holding all of the picklist options
        
        Schema.sObjectType sobject_type = object_name.getSObjectType(); //grab the sobject that was passed
        Schema.DescribeSObjectResult sobject_describe = sobject_type.getDescribe(); //describe the sobject
        Map<String, Schema.SObjectField> field_map = sobject_describe.fields.getMap(); //get a map of fields for the passed sobject
        List<Schema.PicklistEntry> pick_list_values = field_map.get(field_name).getDescribe().getPickListValues(); //grab the list of picklist values for the passed field on the sobject
        for (Schema.PicklistEntry a : pick_list_values) { //for all values in the picklist list
            options.add(new selectOption(a.getValue(), a.getLabel())); //add the value and label to our final list
        }
        return options; //return the List
    }
   
    //fn used to fetch the time zone of a particular user.  Used in bulk lead/contact vf page
    
    public static String getUserTimeZoneKey(Id userId){
       User u=[Select TimeZoneSidKey from User where id=:userId];
       return u.TimeZoneSidKey;
    }
    
   
    //fn used to throw error message in vf page
    
    public static void throwPageError(String errorMsg){
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR, errorMsg);
        ApexPages.addMessage(myMsg);
    }
   
     
   /*returns the cron expression for a scheduleDtTime     
    *in apex scheduler date time cron format
    */
   
    public static void scheduleSmsLead(DateTime schedulDateTime, String url, String mobile, String msg,
                                        Map<String, String> leadMob){
        
        String scheduletimedate =  schedulDateTime.format('ss mm HH dd MM ? yyyy');     
        ScheduleBulkSmsLead sbsms = new ScheduleBulkSmsLead();        
        sbsms.url = url;
        sbsms.msg = msg;
        sbsms.mobile=mobile;
        sbsms.leadMob = leadMob;
        system.schedule(UserInfo.getName()+' Bulk Lead SMS '+System.Now().format(), scheduletimedate,  sbsms); 
        
    }
    
    //fn used to schedule a bulk sms on contact
    
    public static void scheduleSmsContact(DateTime schedulDateTime, String url, String mobile, String msg, 
                                                Map<String, String> contactMob){
   
        String scheduletimedate =  schedulDateTime.format('ss mm HH dd MM ? yyyy');     
        ScheduleBulkSmsContact sbsms = new ScheduleBulkSmsContact();        
        sbsms.url = url;
        sbsms.msg = msg;
        sbsms.mobile=mobile;        
        sbsms.contactMob = contactMob;
        system.schedule(UserInfo.getName()+' Bulk Contact SMS '+System.Now().format(), scheduletimedate,  sbsms); 
        
    }
}