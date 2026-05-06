global class ScheduleBulkSmsLead implements Schedulable{
    public String messageId='',url='',msgStatus='';
    public static SFSMS__c sms; 
    public String mobile, msg;
    
    public static Boolean isTestExecution=false;
    public Map<String, String> leadMob;
        
    global void execute(SchedulableContext sc) {
        
           callOut(url,msgStatus,messageId, mobile, msg, leadMob); 
        
        
    }
    @future(Callout=true)
    public static void callOut(string url,string msgStatus,string messageId, string mobile, 
        string msg, Map<String, String> leadMob){
        if(!isTestExecution){
            Map<String, String> httpCallOut = Utilitysmsforce.httpCallout(url);
            msgStatus = httpCallout.get('MessageStatus');
            messageId = httpCallout.get('MessageId');    
        }
        insertSMS(msgStatus,messageId, mobile, msg, leadMob);
    
    }
    
    public static void insertSMS(String msgStatus, String messageId, string mobile, string msg,
        Map<String, String> leadMob){
        
        List<SFSMS__c> lsms = new List<SFSMS__c>();            
        String[] mobNumArr = mobile.split(',');
        String smsMessage = msg;       
        
        for(Integer i=0;i<mobNumArr.size(); i++) { 
                sms = new SFSMS__c();               
                sms.Status__c = msgStatus;
                sms.Mobile_No__c = mobNumArr[i];
                sms.Lead_Name__c = leadMob.get(mobNumArr[i]);
                sms.Text_Message__c= msg;
                sms.MessageId__c=messageId;
                lsms.add(sms);
                        
        }
        insert lsms;
    }
    
    
   //Test Method
   public static  testMethod void ScheduleBulkSmsLead(){
        //callOut(url,msgStatus,messageId, mobile, msg, leadMob); 
        test.startTest();  
            String url='www.google.com';
            String msg='send';
            Lead l=new Lead(LastName='test',Company='RII',Status='Open', MobilePhone='911234567890');
            insert l;
            String mobile = l.MobilePhone;
            Map<String, String> leadMob = new Map<String, String>();
            leadMob.put(l.MobilePhone, l.id);
            
            String scheduletimedate =  System.now().addminutes(05).format('ss mm HH dd MM ? yyyy');     
            ScheduleBulkSmsLead sbsms = new ScheduleBulkSmsLead();        
            sbsms.url = url;
            sbsms.msg = msg;
            sbsms.mobile=mobile;
            sbsms.leadMob = leadMob;
            ScheduleBulkSmsLead.isTestExecution = true;
            system.schedule(UserInfo.getName()+' Bulk Lead SMS '+System.Now().format(), scheduletimedate,  sbsms);
            
            try{
                Utilitysmsforce.scheduleSmsLead(System.Now(), url, mobile, msg, leadMob);
            }catch(Exception e){} 
            
            test.stopTest();
   } 
}
/*

ScheduleBulkSmsLead sbsms= new ScheduleBulkSmsLead();
          
        ScheduleBulkSmsLead.isTestExecution=true; 
        sbsms.mobile='91923456788'; 
        Lead l=new Lead(LastName='test',Company='RII',Status='Open', MobilePhone=sbsms.mobile);
        insert l;
        List<Lead> listl =new List<Lead>();
        listl.add(l); 
                
        //sbsms.selLead= listl;
        string url='www.google.com';
        string msgStatus='test';
        string messageId='098709yhkjhbkj';
        string mobile='9797986868'; 
        string msg='send';
        Map<String, String> leadMob=new Map<String, String>{l.MobilePhone => l.id};
        //ScheduleBulkSmsLead.callOut( url, msgStatus, messageId,  mobile,msg,leadMob);
       
        SFSMS__c lsms = new SFSMS__c();
        lsms.Text_Message__c='test';
        insert lsms;
        //sbsms.sms = lsms;
        String schedule = '0 0 23 * * ?';
        system.schedule('Schedule Lead', schedule, sbsms);
 
        
        
        sbsms.callOut( url, msgStatus, messageId,  mobile, msg,  leadMob);
        */