public class Vehicle {
	public Vehicle__c  Vehicle2{get; set;}

    public Vehicle(ApexPages.StandardController stdcontroller) {
    	this.Vehicle2 = (Vehicle__c)stdController.getRecord();

    }

}