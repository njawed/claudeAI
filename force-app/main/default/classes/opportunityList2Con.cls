public class opportunityList2Con {
public ApexPages.StandardSetController setCon {
get {
if(setCon == null) {
setCon = new ApexPages.StandardSetController(Database.getQueryLocator([select
name,closedate from Opportunity]));
}
return setCon;
}
set;
}
public List<Opportunity> getOpportunities() {
return (List<Opportunity>) setCon.getRecords();
}
}