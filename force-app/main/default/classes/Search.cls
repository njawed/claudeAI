public with sharing class Search {

    public Search(ApexPages.StandardController controller) {

    }
Public Mercedes__c mer {get; set;} 
public string CarSrch;
Public list <Mercedes__c> merList {get; set;}

    public Search() {
    CarSrch = ApexPages.currentPage().getParameters().get('Regid');
    if(CarSrch != null && CarSrch.startsWith ('M')){
    mer = new Mercedes__c();
    merList = [Select m.Feul_Capacity__c,m.Feul_type__c,m.Height__c,m.Aerodynamics__c,m.Central_Locking__c,m.CC__c,m.Brakes__c,m.Number_of_Seats__c,m.Model__c,m.Mileage__c,m.Lenght__c,m.Width__c,m.Wheel_Base__c,Weight__c,m.Torque__c,m.Production_year__c,m.Price_on_Road__c,m.Price_in_showroom__c,m.Power__c From Mercedes__c m where Aerodynamics__c =:CarSrch limit 1 ];
    if(merList.size()>0)mer = merList.get(0);
    }
    }


}