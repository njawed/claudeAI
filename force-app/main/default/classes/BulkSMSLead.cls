/*
 * Author: Nasir Jawed
 */ 
public with sharing class BulkSMSLead {
    public List<Lead> selLead;
    public List<Lead> ld;
    public List<Leads> leads {get; set;}
    
    public SFSMS__c sms {get;set;}
    public List<SFSMS__c> listsms;
    public Integer countMobiles=0;
    private ApexCallouts apexcall;
    
    public String myErrMsg='',errorMsg='',messageId='',url='',msgStatus='', status='', mobile=''; 
    public static DateTime tempSch;
    public Static DateTime stem;
    public List<SelectOption> deliveryOption {get; set;}  
    public String selectedDeliveryOption { get; set;}
    public String scheduleTimeZone { get; set;}
    public String currentUserTimeZone='';
    private Boolean isTestExecution=false;

    public static SFSMS__c schSms; 
    public static List<Lead> listLead;
            
      
    
    // this is bulk sms Lead constructor
    public BulkSMSLead(ApexPages.StandardSetController controller) {        
        sms=new SFSMS__c();
        selectedDeliveryOption= 'Send Now'; // This is to make "send now" radio button default!
                
        sms.Schedule_Time__c=System.now(); //sets the default timezone of the current user
        currentUserTimeZone = Utilitysmsforce.getUserTimeZoneKey(UserInfo.getUserId()); 
        scheduleTimeZone = currentUserTimeZone;
        deliveryOption = Utilitysmsforce.getRadioItems();        
        
        ld= controller.getSelected();        
        initialize(ld);  
        fieldValidations(selLead);       
            
    } 
    
    public List<SelectOption> getTimeZones(){
        return Utilitysmsforce.getPickValues(new User(), 'TimeZoneSidKey');
    }    
     
     
    //Here all the variable initialization is done ! 
    private void initialize(List<Lead> lds) {
        apexcall = new ApexCallouts();    
        msgStatus = '';
        countMobiles=0;              
        myErrMsg = '';   
        
        leads = new List<Leads>();
        for(Lead l: getLead(lds)){
            Leads lTemp = new Leads();
            lTemp.innerLead= l;
            lTemp.selectLead = true;
            
            leads.add(lTemp);
        }
        
    }
    
    // This is to reset the sms selection in VF Page.
    public void reset(){
        initialize(ld);
        fieldValidations(selLead);
    }
    
    //This is for sms opt out!
    public void selectLeads(){
        List<Leads> lTemp = new List<Leads>();
        List<Lead> lSel = new List<Lead>();
        for(Leads l: leads){
            if(l.selectLead==true){
                lTemp.add(l);
                lSel.add(l.innerLead);
            }
        }
        leads.clear();
        leads=lTemp;
        fieldValidations(lSel);     
    }
    
    
    //Here all the field validation is done!
    public void fieldValidations(List<Lead> sl){
        if(sl != null && sl.size() != 0) {
            
            countMobiles=0;
            for(Lead l:sl) {
                /* For each recipients selected(from the list view), extract the ID and mobile number */
                if(l.MobilePhone == null || l.MobilePhone.length()<=0) {
                    Utilitysmsforce.throwPageError('Mobile: You must enter a value ');                       
                }
                else {
                    countMobiles++;                  
                }
            }                
           
           if(countMobiles > 99) {
                Utilitysmsforce.throwPageError('The maximum bulk sms is 99 per Transaction');
                
            }
            
        
        }else {
            Utilitysmsforce.throwPageError('No recipients selected');
            
        }
    }     
    
    
    // This method is to capture all the leads which gets selected!
    public List<Lead> getlead(List<Lead> l){       
        selLead=[select id,Name,Phone,MobilePhone, DoNotCall, HasOptedOutOfEmail  from Lead where id IN:l];      
        return selLead;
    }
    
    
    // This method captures all the body of template and puts it in text message!
    public void setTemplate(){
        SFTemplates__c tem = [Select Name,SMS_Body__c from SFTemplates__c  where id=:sms.SFTemplates__c];
         sms.Text_Message__c=tem.SMS_Body__c;
    }
    
    
    /*
     * This method is used to send BULK SMS to lead
     */
    public Pagereference sendSMS(){ 
        fieldValidations(selLead); 
        
        if(ld.size() > 99){
            Utilitysmsforce.throwPageError('You cannot send sms to more then 99 records per Transaction');
            return null;
        }
        
        
        if(sms.Text_Message__c ==null){
            Utilitysmsforce.throwPageError('Text Message: You must enter a value');
            return null;
        }
        
            
        for(Leads l :leads){           
            mobile= mobile +','+l.innerLead.MobilePhone;
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
            insertSmsRecord();
            
        }else if(selectedDeliveryOption=='Schedule for delivery on'){
            if(sms.Schedule_Time__c<=System.Now()){
                Utilitysmsforce.throwPageError('Schedule Time: Please enter time ahead of current time '); 
                return null;        
            }
            schSms= sms;
            tempSch=schSms.Schedule_Time__c;
            listLead = selLead;
            scheduleSms();
        }    
        
        PageReference back2Lead = new pageReference('/home/home.jsp');
        back2Lead.setRedirect(true);
        
        return back2Lead;
    }
    
    
    public void insertSmsRecord(){
        List<SFSMS__c> lsms = new List<SFSMS__c>();            
        String[] mobNumArr = mobile.split(',');         
        String[] smsstatus = msgStatus.split(',');  
        String smsMessage =sms.Text_Message__c;       
        
        for(Integer i=0;i<mobNumArr.size(); i++) { 
                sms = new SFSMS__c();               
                sms.Status__c = msgStatus;
                sms.Mobile_No__c = mobNumArr[i];
                sms.Lead_Name__c = selLead[i].Id;
                sms.Text_Message__c=smsMessage;
                sms.MessageId__c=messageId;
                lsms.add(sms);
                        
        }
        insert lsms;        
    }
   

    public void scheduleSms(){
        Map<String, String> leadMob = new Map<String, String>();
        for(Lead l: selLead){
            leadMob.put(l.MobilePhone, l.id);
        }      
        Utilitysmsforce.scheduleSmsLead(sms.Schedule_Time__c, url, mobile, sms.Text_Message__c, 
        leadMob);
       
        
    }
    
    public class Leads{
        public Lead innerLead {get; set;}        
        public Boolean selectLead {get; set;}
        
        public Leads(){
            innerLead = new Lead();
        }
    
    }
    
    
    public static testMethod void  BulkSmsLead(){
        List<lead> lList=new List<lead>();
        
        SFTemplates__c t = new SFTemplates__c(Name='test',SMS_Body__c ='Hello');
        insert t;
        SFSMS__c sms = new SFSMS__c(Mobile_No__c='+919876543212',Text_Message__c='test',SFTemplates__c =t.id);      
        insert sms;
        
        Lead l = new Lead(LastName='test',Status='Open',Company='Rixyncs'); 
        lList.add(l);
        insert lList;
        Leads lds = new Leads();
        
        
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(lList);
        sc.setSelected(lList);
        BulkSmsLead bsl = new BulkSmsLead(sc);
        bsl.getTimeZones();
        bsl.reset();
        bsl.selectLeads();
        bsl.fieldValidations(lList);
       
        
        bsl.sms=sms;
        bsl.setTemplate();
        bsl.isTestExecution = true;                
        bsl.sendSMS();
        
        ApexPages.StandardSetController sc1 = new ApexPages.StandardSetController(lList);
        
        BulkSmsLead bsl2 = new BulkSmsLead(sc1);
        bsl2.isTestExecution = true;                
        bsl2.sendSMS();
        
        List<lead> lList1=new List<lead>();
        for(Integer i=0; i<=100; i++){
            Lead lTemp = new Lead(LastName='test',MobilePhone='+919876543212', Status='Open',Company='Rixyncs');
            lList1.add(lTemp);
        }
        insert lList1;
        ApexPages.StandardSetController sc2 = new ApexPages.StandardSetController(lList1);
        sc2.setSelected(lList1);
        BulkSmsLead bsl3 = new BulkSmsLead(sc2);
        bsl3.isTestExecution = true;                
        bsl3.sendSMS();
        
    }
    
    
    public static testMethod void  bulkSmsLeadSchedule(){
        List<lead> lList=new List<lead>();
        Lead l = new Lead(LastName='test',MobilePhone='+919876543212', Status='Open',Company='Rixyncs'); 
        lList.add(l);
        insert lList;  
        
        SFTemplates__c t = new SFTemplates__c(Name='test',SMS_Body__c ='Hello');
        insert t;
        SFSMS__c sms = new SFSMS__c(Text_Message__c='test',SFTemplates__c =t.id);      
        insert sms;
        
              
        
        ApexPages.StandardSetController sc1 = new ApexPages.StandardSetController(lList);
        sc1.setSelected(lList);
        BulkSmsLead bsl1 = new BulkSmsLead(sc1);
        bsl1.sms.Schedule_Time__c=System.Now().AddMinutes(-1); 
        bsl1.sms.Text_Message__c='test';
        bsl1.isTestExecution = true; 
        bsl1.selectedDeliveryOption = 'Schedule for delivery on';
         
        
        bsl1.sendSMS();
        bsl1.sms.Schedule_Time__c=System.Now().AddMinutes(2);
        bsl1.sendSMS();
        bsl1.sms.Text_Message__c=null;
        bsl1.sendSMS();
    
    }

}