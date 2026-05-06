Global class SMSToSObject implements Messaging.inboundEmailHandler{
    Lead lead;
    public String mobilePhone='', smsMessage='';
    
    //This is parsing the content of the email message and getting the Mobilephone and Message!
    global  void parsePlainTextBody(String ptb){
        
        //loop that parses the incoming email and picks up MobilePhone and Message
        for(String line:ptb.split('\n')) {
            if(line.Contains('MobilePhone')){
                mobilePhone=line.substring(12).trim();
                
            }
            if(line.Contains('Message')){
                smsMessage=line.subString(8).trim();   
               
            }     
       } 
          
    }
    
    //fn that converts an html into plain text
    
    public String htmlToPlainText(String html){
    
         //first replace all <BR> tags with \n to support new lines
        string result = '';
        result= html.replaceAll('<br/>', '\n');
        result = result.replaceAll('<br />', '\n');
        
        //regular expression to match all HTML/XML tags
        string HTML_TAG_PATTERN = '<.*?>';
        
        // compile the pattern     
        pattern myPattern = pattern.compile(HTML_TAG_PATTERN);
        
        // get your matcher instance
        matcher myMatcher = myPattern.matcher(result);
        
        //remove the tags     
        result = myMatcher.replaceAll('');
        
        return result;
    }
    
    
    //fn that handles inbound email
    
    Global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email,Messaging.InboundEnvelope env){
    
        // Create an InboundEmailResult object for returning the result of the Apex Email Service
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        
        String strEmailId = email.fromAddress;
        String strSubject = email.subject;
        String emailBody=email.PlainTextBody;
        String fromName='No Name';
        emailBody = (emailBody==null)? htmlToPlainText(email.htmlBody): emailBody;
        
        parsePlainTextBody(emailBody);        

        
        //This SOSL is retrieving the MobilePhone field from Lead and contact!
        try{
            Database.DMLOptions dmo = new Database.DMLOptions();            
            dmo.allowFieldTruncation = true;
            List<List<sObject>> leadContact=[FIND :mobilePhone IN ALL FIELDS RETURNING  Lead(id, MobilePhone, CreatedDate 
                                                where MobilePhone Like: '%'+mobilePhone+'%' ORDER BY CreatedDate )
                                                , Contact(id, MobilePhone, CreatedDate where MobilePhone Like: 
                                                '%'+mobilePhone+'%' 
                                                ORDER BY CreatedDate)];
            
            Lead[] leads = ((List<Lead>)leadContact[0]);            
            Contact[] contacts = ((List<Contact>)leadContact[1]);
            
            //If there is lead and contact both, insert sms record to either of lead or contact whichever is created earlier!
            if(leads.size()>0 && contacts.size()>0){
                if(leads[0].CreatedDate > contacts[0].CreatedDate){
                    createLeadSmsRecord(leads[0]);                    
                }else{
                    createContactSmsRecord(contacts[0]);
                }
              
             // If there is only lead record and no contact record, insert and SMS record in Lead!   
            }else if(leads.size()>0 && contacts.size()==0){
                createLeadSmsRecord(leads[0]); 
                
            //if there is contact record and no lead record then insert a SMS record in contact!               
            }else if(contacts.size()>0 && leads.size()==0){
                createContactSmsRecord(contacts[0]);     
                 
            //if there is no lead and contact record the insert a lead record and insert an SMS record to the same lead!          
            }else{
                lead = new Lead(LastName=fromName, Status='Open', Company='No Name', LeadSource='SMS',
                    MobilePhone=mobilePhone);
                lead.setOptions(dmo); 
                insert lead;
                createLeadSmsRecord(lead);  
            }
        }catch(Exception e){
            System.debug('Error:While creating Record '+e.getMessage());
        }
    
      
        result.success = true;        
        return result;
    }  
    //This method is called to create an SMS record in lead!
    private void createLeadSmsRecord(Lead tmpLead){
        SFSMS__c s= new SFSMS__c();
        s.Lead_Name__c=  tmpLead.id;
        s.Mobile_No__c=mobilePhone ;
        s.Type__c='InBound';
        s.Text_Message__c=smsMessage;  
        insert s;
    }
    
    //This method is called to create an SMS record in contact!
    private void createContactSmsRecord(Contact tmpContact){
        SFSMS__c s= new SFSMS__c();
        s.Contact_Name__c=  tmpContact.id;
        s.Mobile_No__c=mobilePhone ;
        s.Type__c='InBound';
        s.Text_Message__c=smsMessage;  
        insert s;  
    }
    
    /* Only for test case */

    // Test method to ensure you have enough code coverage
    static testMethod void testEmailToLead() {
    
        // Create a new email and envelope object
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
        Messaging.InboundEnvelope env    = new Messaging.InboundEnvelope();
        
        email.subject = 'test subject ';
        email.fromName = 'Nasir Jawed';
        email.fromAddress = 'nasir.j@rixyncs.co.in';       
        email.plainTextBody='MobilePhone: 91922213223 /n Message :Test Email Body';
        
        
        Lead l = new lead(firstName='Rasmus',
            lastName='abc',
            Company='Salesforce',
            Email='nasir.j@rixyncs.co.in', MobilePhone='91922213223',LeadSource='Online Email Enquiry',Description='Test Description'
        );
        
        Contact c = new Contact(firstName='Rasmus',
            lastName='abc', MobilePhone='91922213223',           
            Email='nasir.j@rixyncs.co.in',Description='Test Description'
        );        
        insert c;
        string html='Mobilphone: 917795075145 <br />Message: RII Hi nasir good morning.today sms force is released:( <br />To your longcode: 918082000222';
        // call the class and test it with the data in the testMethod
        SMSToSObject sts = new SMSToSObject();
        sts.handleInboundEmail(email,env);
        sts.htmlToPlainText(html);
        sts.createContactSmsRecord(c);
       
        
    } 
                           
}