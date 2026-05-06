/*
 * Author: Nasir Jawed
 */ 
public with sharing class BulkSMSContact {
    public List<Contact> selContact;
    public List<Contact> contact;
    public List<Contacts> contacts {get; set;}
    
    public SFSMS__c sms {get;set;}
    public Integer countMobiles;
    private Integer  errFlg=0;
    private ApexCallouts apexCall;
    
    public String url='',myErrMsg='',errorMsg='',status='',msgStatus='',messageId='',mobile='';
    public List<SelectOption> deliveryOption {get; set;}  
    public String selectedDeliveryOption { get; set;}
    public String scheduleTimeZone { get; set;}
    public String currentUserTimeZone='';
    private Boolean isTestExecution=false;
    
  
    // this is bulk sms contact constructor
    public BulkSMSContact(ApexPages.StandardSetController controller) {        
        sms=new SFSMS__c();
        selectedDeliveryOption='Send Now';// This is to make "send now" radio button default!
        
        sms.Schedule_Time__c=System.now(); //sets the default timezone of the current user
        currentUserTimeZone = Utilitysmsforce.getUserTimeZoneKey(UserInfo.getUserId()); 
        scheduleTimeZone = currentUserTimeZone;
        deliveryOption = Utilitysmsforce.getRadioItems();
        
        contact= controller.getSelected();
        initialize(contact);  
        fieldValidations(selContact);       
            
    } 
    
    //fn which is getting the user timezone
    public List<SelectOption> getTimeZones(){
        return Utilitysmsforce.getPickValues(new User(), 'TimeZoneSidKey');
    }  
      
    //All the variable initialization is done!
    private void initialize(List<Contact> con) {
        
        msgStatus = '';
        countMobiles=0;
        errFlg=0;      
        apexCall = new ApexCallouts(); 
        myErrMsg = ''; 
        
        contacts = new List<Contacts>();
        for(Contact c: getContact(con)){
            Contacts cTemp = new Contacts();
            cTemp.innerContact= c;
            cTemp.selectContact= true;
            
            contacts.add(cTemp);
        }  
    }
    
    // This is to reset the sms selection in VF Page.
    public void reset(){
        initialize(contact);
        fieldValidations(selContact);
    }
    
    // This is to reset the sms opt out.   
    public void selectContacts(){
        List<Contacts> cTemp = new List<Contacts>();
        List<Contact> lcon = new List<Contact>();
        for(Contacts cs: contacts){
            if(cs.selectContact==true){
                cTemp.add(cs);
                lcon.add(cs.innerContact);
            }
        }
        contacts.clear();
        contacts=cTemp;
        fieldValidations(lcon);         
    
    }
    
    //All the field validation are carried here
    public void fieldValidations(List<Contact> c){
        
  
        if(c!= null && c.size() != 0) {
            
                countMobiles=0;
                for(Contact cont:c) {
                /* For each recipients selected(from the list view), extract the ID and mobile number */
                    if(cont.MobilePhone == null) {
                        Utilitysmsforce.throwPageError('Mobile: You must enter a value');                       
                    }
                    else {
                        countMobiles++;                  
                    }
                } 
                               
               
                if(countMobiles < 1) {
                    Utilitysmsforce.throwPageError('No recipients selected ');
                    
                }else if(countMobiles > 99) {
                    Utilitysmsforce.throwPageError('The maximum bulk sms is 99 per Transaction!!');
                    
                }
            
        
        }else {
            Utilitysmsforce.throwPageError('No recipients selected !!');
            
        }
    
    
    }     
    
    // Here all the contact which is selected are captured and put is variable selContact!
    public List<Contact> getContact(List<Contact> cont){       
        selContact=[select id,Name,Phone,MobilePhone,DoNotCall from Contact where id IN:cont];
        
        return selContact;
    }
    
    //This code is to select template in text body!
    public void setTemplate(){
        SFTemplates__c tem = [Select Name,SMS_Body__c
                             from SFTemplates__c
                             where id=:sms.SFTemplates__c];
         sms.Text_Message__c=tem.SMS_Body__c;
    }
    
    
    /*
     * This method is used to send BULK SMS to contact
     */
    public Pagereference sendSMS(){ 
        fieldValidations(selContact) ;  
        
         if(contact.size() > 99){
            Utilitysmsforce.throwPageError('You cannot send sms to more then 99 records per Transaction');
            return null;
        }
          
        if(sms.Text_Message__c ==null ||sms.Text_Message__c ==''){
            Utilitysmsforce.throwPageError('Text Message: You must enter a value');
            return null;
        }
        
       
        for(Contacts c :contacts){           
            mobile= mobile +','+c.innerContact.MobilePhone;
        }
        
        mobile = mobile.substring(1,mobile.length());
        
        if(sms.Text_Message__c !=null){
            Map<String, String> prop = Utilitysmsforce.getProperties();         
            url= prop.get('smsUrlArg')+prop.get('userNameArg')+prop.get('passwordArg')+prop.get('toArg')+
                    mobile+prop.get('msgArg')+ EncodingUtil.urlEncode(sms.Text_Message__c, 'UTF-8')+
                    prop.get('senderIdArg')+prop.get('suffixArg');
        }
        
        if(selectedDeliveryOption=='Send Now'){
            if(!isTestExecution){
                Map<String, String> httpCallOut = Utilitysmsforce.httpCallout(url);
                msgStatus = httpCallout.get('MessageStatus');
                messageId = httpCallout.get('MessageId');  
            }
            insertSmsRecord(mobile);
        
        }else if(selectedDeliveryOption=='Schedule for delivery on'){
        
            if(sms.Schedule_Time__c<=System.Now()){
                Utilitysmsforce.throwPageError('Schedule Time: Please enter time ahead of current time '); 
                return null;        
            }
            scheduleSms();
        }          
            
        PageReference back2contact = new pageReference('/home/home.jsp');
        back2contact.setRedirect(true);        
        return back2contact;
    }
    
    
    //fn insert the contact record into data base
    public void insertSmsRecord(String mobileArr){
        List<SFSMS__c> csms = new List<SFSMS__c>();            
        String[] mobNumArr = mobileArr.split(',');         
        String[] smsstatus = msgStatus.split(',');  
        String smsMessage =sms.Text_Message__c;              
        
        for(Integer i=0;i<mobNumArr.size(); i++) { 
                sms = new SFSMS__c();               
                sms.Status__c = msgStatus;
                sms.Mobile_No__c = mobNumArr[i];
                System.debug('RII '+i+' '+mobNumArr[i]);
                sms.Contact_Name__c = selContact[i].Id;
                sms.Text_Message__c=smsMessage;
                sms.MessageId__c=messageId;
                csms.add(sms);
                        
        }
        insert csms;        
    }
    
    // This is for sms Opt out!
    public class Contacts{
        public Contact innerContact {get; set;}        
        public Boolean selectContact {get; set;}
        
        public Contacts(){
            innerContact = new Contact();
        }
    
    }
    
    //This function is for scheduling
    public void scheduleSms(){
    
        Map<String, String> contactMob = new Map<String, String>();
        
        for(Contact c: selContact){            
            contactMob.put(c.MobilePhone, c.id);
        }  
            
        Utilitysmsforce.scheduleSmsContact(sms.Schedule_Time__c, url, mobile, sms.Text_Message__c,contactMob);
         
        
    }
    
    //Test Method
    public static testMethod void  BulkSmsContact(){
        List<Contact> cList=new List<Contact>();
        
        SFTemplates__c t = new SFTemplates__c(Name='test',SMS_Body__c ='Hello');
        insert t;
        SFSMS__c sms = new SFSMS__c(Mobile_No__c='+919876543212',Text_Message__c='test',SFTemplates__c =t.id);      
        insert sms;
        Account acc = new Account(Name='Rixyncs India Inc');
        insert acc;
        Contact c = new Contact(LastName='Muddassar', MobilePhone='91123456789', AccountId=acc.Id);
        cList.add(c);
        insert cList;
        Contacts cds = new Contacts();
        
              
        
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(cList);
        sc.setSelected(cList);
        BulkSmsContact bsc = new BulkSmsContact(sc);
       
        bsc.sms.Schedule_Time__c=System.Now().AddMinutes(-1); 
        bsc.getTimeZones();
        bsc.reset();
        bsc.selectContacts();
        bsc.fieldValidations(cList);
        Contact cs= new Contact(LastName='Test');
        cs.MobilePhone=null;
        insert cs;
        update cs;
        
        bsc.sms=sms;
        bsc.setTemplate();
        bsc.isTestExecution = true;   
       
        bsc.sendSMS();
        bsc.selectedDeliveryOption = 'Schedule for delivery on';    
        
        
        List<Contact> con=new List<Contact>();
        insert con;
       
        
        ApexPages.StandardSetController sc1 = new ApexPages.StandardSetController(con);
        BulkSmsContact bsc1 = new BulkSmsContact(sc1);
        sms.Schedule_Time__c = System.Now().addminutes(05);
               
        bsc1.sendSMS();
        bsc1.selectedDeliveryOption = 'Schedule for delivery on'; 
        bsc1.sendSMS();
        bsc1.sms = sms;       
        bsc1.scheduleSms();
       
    }
    
     public static testMethod void  bulkSmsLeadSchedule(){
        List<Contact> cList=new List<Contact>();
        Contact c = new Contact(LastName='test',MobilePhone=null); 
        cList.add(c);
        insert cList;  
        
        SFTemplates__c t = new SFTemplates__c(Name='test',SMS_Body__c ='Hello');
        insert t;
        SFSMS__c sms = new SFSMS__c(Text_Message__c='test',SFTemplates__c =t.id);      
        insert sms;
        
              
        
        ApexPages.StandardSetController sc1 = new ApexPages.StandardSetController(cList);
        sc1.setSelected(cList);
        BulkSmsContact bsc1 = new BulkSmsContact(sc1);
        bsc1.sms.Schedule_Time__c=System.Now().AddMinutes(-1); 
        bsc1.sms.Text_Message__c='test';
             
        bsc1.selectedDeliveryOption = 'Schedule for delivery on';
         
        
        bsc1.sendSMS();
        bsc1.sms.Schedule_Time__c=System.Now().AddMinutes(2);
        bsc1.sendSMS();
        bsc1.sms.Text_Message__c=null;
        bsc1.sendSMS();
    
    }
    

   
}