public with sharing class SingleSMS {

    public SFSMS__c sms {get;set;}
    public Lead lead {get;set;}
    public Contact contact {get;set;}
    public Id id;
    Public String msgStatus='', smsurl='', status='',mobileNumber='', errorMsg='', senderId='',messageId='';
    private ApexCallouts apexcall;
    public Boolean isTabView {get; set;}
    public Map<String, String> statusCode;
    private Boolean isTestExecution=false;    
   
    // This is single sms constructor!
    public SingleSMS(ApexPages.StandardController controller) {
        sms=(SFSMS__c)controller.getRecord();
        lead = new Lead();
        apexcall = new ApexCallouts();
        statusCode = new Map<String, String>();
       
        
        if(sms.Lead_Name__c==null && sms.Contact_Name__c==null){
            isTabView=true;
            ApexPages.Message infoMsg = new ApexPages.Message(ApexPages.Severity.INFO, 'To send SMS, follow the instruction as per the link below!');
            ApexPages.addMessage(infoMsg);        
        }       
       
            //When sending sms from Lead
            if(sms.Lead_Name__c!=null){
                lead =[select id,Name,MobilePhone, DoNotCall from Lead where id=:sms.Lead_Name__c];             
                sms.Mobile_No__c=lead.MobilePhone;
                sms.Sms_Opt_Out__c=lead.DoNotCall;
            
            //When sending sms from Contact
            }else if(sms.Contact_Name__c!=null){
                contact =[select id,Name,MobilePhone,DoNotCall from Contact where id=:sms.Contact_Name__c];
                sms.Mobile_No__c=Contact.MobilePhone;
                sms.Sms_Opt_Out__c=contact.DoNotCall;
            }  
            
            
            if((sms.Mobile_No__c==null || sms.Mobile_No__c=='') && !(sms.Lead_Name__c==null && sms.Contact_Name__c==null) ){
                sms.addError('Mobile: You must enter a value');
            }
           
    }
    
    // This code tell how to send single and mass sms to lead and contact!
    public PageReference stepsToSendSMS(){
        PageReference page = new PageReference('/apex/StepsToSendSMS');
        return page;
    } 
    
    // This code captures the body of the template and puts it in text message!
    public void setTemplate(){
        SFTemplates__c tem = [Select Name,SMS_Body__c from SFTemplates__c  where id=:sms.SFTemplates__c];
        sms.Text_Message__c=tem.SMS_Body__c;
    }
    
    //For the redirection of page to lead record when back button is clicked!
    public PageReference back2lead(){    
        PageReference back2page = new ApexPages.StandardController(lead).view();
        back2page.setRedirect(true); 
        return back2page;       
    }
    
    //For the redirection of page to contact record when back button is clicked!
    public PageReference back2contact(){  
        PageReference back2page = new ApexPages.StandardController(contact).view();
        back2page.setRedirect(true); 
        return back2page;       
    }
    
    // This method is used to send sms to lead and contact
    public PageReference Send(){        
        
        //Validation for Text message
        if(sms.Text_Message__c ==null ||sms.Text_Message__c ==''){           
            Utilitysmsforce.throwPageError('Text Message: You must enter a value '); 
            return null;           
         }   
       
        // Validation for Mobile number  
        if(sms.Mobile_No__c ==null ){
             Utilitysmsforce.throwPageError('Text Message: You must enter a value '); 
             return null;               
        }
        else if(sms.Text_Message__c !=null){
            Map<String, String> prop = Utilitysmsforce.getProperties();         
            smsurl= prop.get('smsUrlArg')+prop.get('userNameArg')+prop.get('passwordArg')+prop.get('toArg')+
                    sms.Mobile_No__c+prop.get('msgArg')+ EncodingUtil.urlEncode(sms.Text_Message__c, 'UTF-8')+
                    prop.get('senderIdArg')+prop.get('suffixArg');                    
        }
        
    
        if(!isTestExecution){
            Map<String, String> httpCallOut = Utilitysmsforce.httpCallout(smsurl);
            msgStatus = httpCallout.get('MessageStatus');
            messageId = httpCallout.get('MessageId');         
        }
        return insertSmsRecord(); 
      
    }
   
    
    // this code insert sms record for lead and contact !
    public PageReference insertSmsRecord(){
        //When lead is selected to send the sms,this captures the mobilephone and status field value and store in SMS record.
        if(sms.Lead_Name__c!=null){
            sms.Mobile_No__c =lead.MobilePhone;
            sms.Status__c=msgStatus;
            if(status.length()<=14)  // as messsage id is 14 digits
                sms.MessageId__c=messageId;
            insert sms;
            
            return getPageReference(sms.Lead_Name__c);
            
        //When contact is selected to send the sms,this captures the mobilephone and status field value and store in SMS record.
        }else if(sms.Contact_Name__c!=null){
            sms.Mobile_No__c =contact.MobilePhone;
            sms.Status__c=msgStatus;
            if(status.length()<=14) // as messsage id is 14 digits
               sms.MessageId__c=messageId;
            insert sms;
            
            return getPageReference(sms.Contact_Name__c);
        }else{
            return new PageReference('/home/home.jsp');
        }
         
    
    }
    
    public PageReference getPageReference(Id recordId){
        PageReference pageRef = new PageReference('/'+recordId);
        pageRef.setRedirect(true);
        return pageRef;
    }
    
     
    
    
    
    
    //Test methos for SingleSMS class!
    public static testMethod void singleSMS(){
        Lead l=new Lead(LastName='Test', Company='RII', MobilePhone='+919876543212');
        insert l;        
        
        SFTemplates__c t = new SFTemplates__c(Name='test',SMS_Body__c ='Hello');
        insert t;
        SFSMS__c sms = new SFSMS__c(Mobile_No__c='+919876543212',Text_Message__c='test',SFTemplates__c =t.id);      
        sms.Lead_Name__c=l.id;
        sms.Contact_Name__c=null;
               
        ApexPages.StandardController sc = new ApexPages.standardController(sms);
        SingleSMS singleSMS = new SingleSMS(sc); 
    
        singleSMS.stepsToSendSMS();       
        singleSMS.setTemplate(); 
        singleSMS.isTestExecution = true;
        singleSMS.send();
        singleSMS.back2lead();
    
        
        
    }
    
    public static testMethod void singleSMSLeadValidation(){
        Lead l=new Lead(LastName='Test', Company='RII');
        insert l;        
    
        SFSMS__c sms2 = new SFSMS__c();      
        sms2.Lead_Name__c=l.id;
        sms2.Contact_Name__c=null;
               
        ApexPages.StandardController sc2 = new ApexPages.standardController(sms2);
        SingleSMS singleSMS2 = new SingleSMS(sc2); 
        singleSMS2.isTestExecution = true;
        singleSMS2.send();
        singleSMS2.sms.Mobile_No__c =null;
        singleSMS2.send();
    }
    
    public static testMethod void singleSMSContact(){
        SFTemplates__c t = new SFTemplates__c(Name='test',SMS_Body__c ='Hello');
        insert t;
        Account a= new Account(Name='test');
        insert a;
        Contact c= new Contact(LastName='Test',MobilePhone='+919876543212',Accountid=a.id);
        insert c;
        
        SFSMS__c sms = new SFSMS__c(Mobile_No__c='+919876543212',Text_Message__c='test',SFTemplates__c =t.id);      
        sms.Lead_Name__c=null;      
        sms.Contact_Name__c=c.id;
        
        ApexPages.StandardController sc1 = new ApexPages.standardController(sms);        
        SingleSMS singleSMS1 = new SingleSMS(sc1);
        singleSMS1.isTestExecution = true;
        singleSMS1.send();
        singleSMS1.sms.Mobile_No__c =null;
        singleSMS1.send();
        singleSMS1.back2contact();
        
    }
    
    public static testMethod void singleSMSTabView(){
        
        SFSMS__c sms = new SFSMS__c(Mobile_No__c='',Text_Message__c='test');      
        sms.Lead_Name__c=null;      
        sms.Contact_Name__c=null;
        
        ApexPages.StandardController sc1 = new ApexPages.standardController(sms);        
        SingleSMS singleSMS1 = new SingleSMS(sc1);
        singleSMS1.isTestExecution = true;
        singleSMS1.send();
        
    }
}