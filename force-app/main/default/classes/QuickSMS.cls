/*
* Created by Anil B
* Controller to hand quick sms used during tradeshows or exhibits booths
*/
public with sharing Class QuickSMS{
    public Lead ld {get; set;}    

    public String errMessage='', messageId='' ,url='', msgStatus='' ;
    public String message {get; set;}
    private Boolean isTestExecution=false;
  
    //This is quick sms Constructor
    public QuickSMS(ApexPages.StandardController controller) {
        ld=(Lead)controller.getRecord();
        message =  getMessageFromTemplate(); 
    }
     
    // This is used to send sms   
    public PageReference send() { 
        PageReference pageRef = smsRoutine();
        return pageRef;
    }
    
    //This is used to send sms and again redirect to quicksms page
    public PageReference sendAndNew(){
        smsRoutine();
        PageReference pageRef = new PageReference('/apex/QuickSMS');
        pageRef.setRedirect(true); 
        return pageRef;
    }
    
    //This code check the mandatory field and makes HHTP call outs
    private PageReference smsRoutine(){
        
        if(ld.MobilePhone==null){
            errMessage='Mobile: You must enter a value!!' ;
            Utilitysmsforce.throwPageError(errMessage);
            return null; 
        }        
       
        
        if(ld.MobilePhone !=null){
            Map<String, String> prop = Utilitysmsforce.getProperties();         
            url=prop.get('smsUrlArg')+prop.get('userNameArg')+prop.get('passwordArg')+prop.get('toArg')+
                    ld.MobilePhone+prop.get('msgArg')+ EncodingUtil.urlEncode(message, 'UTF-8')+
                    prop.get('senderIdArg')+prop.get('suffixArg');
           
        }
        
        //http callouts are made here
        if(!isTestExecution){ 
            Map<String, String> httpCallOut = Utilitysmsforce.httpCallout(url);
            msgStatus = httpCallout.get('MessageStatus');
            messageId = httpCallout.get('MessageId');    
        }
        
        insert ld;
        
        //message decoded to record on sms tracker and later get inserted
        message = EncodingUtil.urlDecode(message, 'UTF-8');
        Utilitysmsforce.insertSmsRecord(ld, message, msgStatus, messageId);
        
        PageReference pageRef = new PageReference('/'+ld.Id); 
        return pageRef;
    }
    
    // fn to get the latest QuickSMS message from template
    public String getMessageFromTemplate(){
        SFTemplates__c template;
        try{
            template = [Select Name, SMS_Body__c, Available_For_Use__c 
                from SFTemplates__c where Name='QuickSMS' and Available_For_Use__c=true order by CreatedDate Desc 
                  Limit 1];
            if(template!=null){
                message = template.SMS_Body__c;
            }
        }Catch(QueryException e){
            ApexPages.Message infoMsg = new ApexPages.Message(ApexPages.Severity.INFO, 
            'Tip: Create a SMS Template from Templates tab with Template Name as QuickSMS (<-copy this name) to automatically populate Message !');
            ApexPages.addMessage(infoMsg); 
        }
        
        return message;
            
    }
    
    //This is test method for Quicksms
    public static testMethod void QuickSms(){
    
        SFTemplates__c template = new SFTemplates__c(Name='QuickSMS', SMS_Body__c='Test');
        insert template;
        Lead l= new Lead(LastName='Test',Company='Rixyncs',Status='Open');    
     
        ApexPages.StandardController sc = new ApexPages.StandardController(l);
        QuickSms qs= new QuickSms(sc);        
        qs.isTestExecution = true; 
        qs.send();
             
        
        delete template;
        
        Lead l1= new Lead(LastName='Test', MobilePhone='91123456789',Status='Open');    
        
        ApexPages.StandardController sc1 = new ApexPages.StandardController(l1);
        QuickSms qs1= new QuickSms(sc1);
        qs1.isTestExecution = true; 
        try{
            qs1.sendAndNew(); 
        }catch(Exception e){}
        
        undelete template;
        

        Lead l2= new Lead(LastName='Test', MobilePhone='91123456789', Company='Rii',Status='Open'); 
        ApexPages.StandardController sc2 = new ApexPages.StandardController(l2);
        QuickSms qs2= new QuickSms(sc2);
        qs2.isTestExecution = true;
        qs2.sendAndNew(); 
        
    }
}