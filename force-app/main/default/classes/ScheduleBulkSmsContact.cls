global class ScheduleBulkSmsContact implements Schedulable{
    public String messageId='',url='',msgStatus='';
    public static SFSMS__c sms; 
    public String mobile,msg;
    public List<Contact> selContact;
    private STATIC Boolean isTestExecution=false;
    public Map<String, String> contactMob;
       
    
    global void execute(SchedulableContext sc) {        
        callOut(url,msgStatus,messageId, mobile, msg, contactMob);  
        
    }
   // fn is making future callouts for scheduling sms
    @future(Callout=true)
    public static void callOut(string url,string msgStatus,string messageId, string mobile, 
        String msg, Map<String, String> contactMob){
        if(!isTestExecution){
            Map<String, String> httpCallOut = Utilitysmsforce.httpCallout(url);
            msgStatus = httpCallout.get('MessageStatus');
            messageId = httpCallout.get('MessageId');    
        }
        insertSMS(msgStatus,messageId, mobile, msg, contactMob);
    
    }
    
    //this fn is inserting the sms record
    public static void insertSMS(String msgStatus, String messageId, string mobile, string msg,
        Map<String, String> contactMob){
        
        List<SFSMS__c> lsms = new List<SFSMS__c>();            
        String[] mobNumArr = mobile.split(',');
        String smsMessage = msg;       
        
        for(Integer i=0;i<mobNumArr.size(); i++) { 
                sms = new SFSMS__c();               
                sms.Status__c = msgStatus;
                sms.Mobile_No__c = mobNumArr[i];
                sms.Contact_Name__c = contactMob.get(mobNumArr[i]);
                sms.Text_Message__c= msg;
                sms.MessageId__c=messageId;
                lsms.add(sms);                        
        }
        insert lsms;
    }
    
   //Test Method
   public static  testMethod void ScheduleBulkSmsContact(){
       
        test.startTest(); 
         String url='www.google.com';
            String msg='send';
            Contact c=new Contact(LastName='test', MobilePhone='911234567890');
            insert c;
            String mobile = c.MobilePhone;
            Map<String, String> contactMob = new Map<String, String>();
            contactMob.put(c.MobilePhone, c.id);
            
            String scheduletimedate =  System.now().addminutes(05).format('ss mm HH dd MM ? yyyy');     
            ScheduleBulkSmsContact sbsms = new ScheduleBulkSmsContact();        
            sbsms.url = url;
            sbsms.msg = msg;
            sbsms.mobile=mobile;
            sbsms.contactMob = contactMob;
            ScheduleBulkSmsContact.isTestExecution = true;
            system.schedule(UserInfo.getName()+' Bulk Contact SMS '+System.Now().format(), scheduletimedate,  sbsms);  
       
        
        test.stopTest();
   } 
}
/*

 ScheduleBulkSmsContact sbsms= new ScheduleBulkSmsContact();  
        ScheduleBulkSmsContact.isTestExecution=true; 
        Contact c=new Contact(LastName='test');
        insert c;
        List<Contact> listc =new List<Contact>();
        listc.add(c); 
        sbsms.mobile='91923456788';         
        sbsms.selContact= listc;
        SFSMS__c csms = new SFSMS__c();
        csms.Text_Message__c='test';
       // sbsms.sms = csms;   
        String schedule = '0 0 23 * * ?';
        system.schedule('Schedule Contact', schedule, sbsms);
        ScheduleBulkSmsContact.isTestExecution=true;
8888888888888
List<SFSMS__c> csms = new List<SFSMS__c>();            
        String[] mobNumArr = mobile.split(',');
        String smsMessage =sms.Text_Message__c;       
        
        for(Integer i=0;i<mobNumArr.size(); i++) { 
                sms = new SFSMS__c();               
                sms.Status__c = msgStatus;
                sms.Mobile_No__c = mobNumArr[i];
                sms.Contact_Name__c = selContact[i].Id;
                sms.Text_Message__c=smsMessage;
                sms.MessageId__c=messageId;
                csms.add(sms);
                        
        }
        insert csms;*/