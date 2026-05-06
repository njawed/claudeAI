public class newOpportunityController {

    Account account;
    Contact contact;
    Opportunity opportunity;
    OpportunityContactRole role;
    Product2 products;
    public List<OpportunityLineItem> lineItem{get;set;}
    public List<OpportunityLineItem> oli {get; set;}
    public List<OpportunityLineItem> olitem {get; set;}
    
    public PriceBookEntry p { get; set; }
    public List<PriceBookEntry> pbe {get;set;}
    public List<PriceBookEntry> pbeSelect {get;set;}
    public List<PriceBookEntry> selectedPbe {get; set;}
    public Double totalPrice {get; set;}    
   
    
    public Account getAccount() {
      if(account == null) account = new Account();
      return account;
    }
    
    public Contact getContact() {
      if(contact == null) contact = new Contact();
      return contact;
    }
    
    public Opportunity getOpportunity() {
        if(opportunity == null) opportunity = new Opportunity();
        opportunity.Status__c='Confirm';
        opportunity.StageName='Closed Won';
        opportunity.CloseDate=system.Today();
        opportunity.Name=account.Name;
        return opportunity;
    }

    public OpportunityContactRole getRole() {
        if(role == null) role = new OpportunityContactRole();
        return role;
    }
   
    public PageReference step1() {
        return Page.opptyStep1;
    }
    
    public PageReference step2() {
        return Page.opptyStep2;
    }
    
   
   
    public PageReference step4() {
        
        PriceBook2 pb =[Select Name, Id from PriceBook2 where Name='Standard Price Book'];        
        pbe =[Select Product2.Name,product2.Checkbox__c,product2.ProductCode
            ,product2.IsActive,product2.Description,product2.Family,
             UnitPrice,product2.Unit_Price__c,product2.Quantity__c from PriceBookEntry where Pricebook2Id=:pb.Id];
      
             
        for(PriceBookEntry p: pbe){
            p.product2.Quantity__c=1;
            p.product2.Tax__c=12.36;
            p.product2.Unit_Price__c = p.UnitPrice;
            p.product2.Total_Price__c=p.product2.Quantity__c * p.product2.Unit_Price__c;
        }  
       
         
        return Page.oppty3;
   }
   
    public PageReference step3() {        
        OpportunityLineItem ol; 
        oli = new List<OpportunityLineItem>();
        totalPrice=0;
        selectedPbe= new List<PriceBookEntry>();
        
            for(PriceBookEntry p : pbe){
            
                if(p.product2.Checkbox__c==true){
                    selectedPbe.add(p);
                    ol = new OpportunityLineItem();
                    ol.Quantity =p.product2.Quantity__c;
                    ol.PriceBookEntry = p;
                    ol.PriceBookEntryId = p.id;                   
                    ol.UnitPrice = p.product2.Unit_Price__c;                   
                    ol.TotalPrice=(p.product2.Quantity__c * p.product2.Unit_Price__c)+((p.product2.Tax__c)*(p.product2.Quantity__c * p.product2.Unit_Price__c))/100 ;
                    totalPrice += ol.TotalPrice;
                    ol.Total__c=totalPrice;                    
                    oli.add(ol);
                    system.debug('nasir:'+ ol.Total__c +'------------'+totalprice);
                }
               
            }
           
        
        return Page.oppty4;
    }
    
    public PageReference cancel() {
        PageReference opportunityPage = new PageReference('https://ap1.salesforce.com/006/o');
        opportunityPage.setRedirect(true);
        return opportunityPage; 
    }
   
    public PageReference step5() {      
         
        OpportunityLineItem ol; 
        oli.clear(); // = new List<OpportunityLineItem>();
        
        selectedPbe= new List<PriceBookEntry>();
        
            for(PriceBookEntry p : pbe){
            
                if(p.product2.Checkbox__c==true){
                    selectedPbe.add(p);
                    ol = new OpportunityLineItem();
                    ol.Quantity =p.product2.Quantity__c;
                    ol.PriceBookEntry = p;
                    ol.PriceBookEntryId = p.id;                   
                    ol.UnitPrice = p.product2.Unit_Price__c;
                    oli.add(ol);
                    system.debug('nasir:'+ selectedPbe);
                }
            }
       
            
        return save();
    }
    
   

    public PageReference save() {
    
    
        account.phone = contact.phone;
        insert account;     
        
        contact.accountId = account.id;
        insert contact;        
     
        opportunity.accountId = account.id;
        insert opportunity;     
    
        role.opportunityId = opportunity.id;
        role.contactId = contact.id;
        insert role;
        List<OpportunityLineItem> olTemp = new List<OpportunityLineItem>();
        
        for(OpportunityLineItem oliTemp: oli){
            oliTemp.OpportunityId=opportunity.id;
            olTemp.add(oliTemp);
        }
        
        oli = olTemp;
        insert oli;

        PageReference opptyPage = new ApexPages.StandardController(opportunity).view();
        opptyPage.setRedirect(true);
        return opptyPage;
   }

}