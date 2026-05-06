/**
 * Helper for Disable Chatter Deletes App
 * Author: Nasir jawed(nasir.jawed@in.ibm.com)
 */
public class DisableChatterDeleteDelegateComment{
    public static void allowDeleteComment(List<FeedComment> trigerold){
        
        set<string> sobj= new set<string>();        
        Map<String, Config_Object__c> mcs = Config_Object__c.getAll();
        system.debug('mcs:'+ mcs);
        for(Config_Object__c co: mcs.Values()){
            string obj=co.nasirLightning__Object_Name__c;            
            system.debug('obj:'+ obj);
            sobj.add(obj);
            
        }
        system.debug('sobj:'+ sobj);            
      
        if(sobj== null) {
        //no action          
        }
        else {
            String profileId= UserInfo.getProfileId();
            profile profileName=[select id ,name from Profile where id=:profileId]; 
            system.debug('profileName:'+ profileName.Name);                  
            for(FeedComment feedRec: trigerold){
                
                string obj=KeyPrefix.GetKeyPrefix(feedRec.ParentId);  
                system.debug('obj:'+obj);  
                for(Config_Object__c co: mcs.Values()){
                    if(co.nasirLightning__Object_Name__c==obj && co.nasirLightning__Profile__c==null){
                        system.debug('nasir:');
                        feedRec.addError('Your administrator has disabled feed post and comment deletions.'); 
                    }
                    if(co.nasirLightning__Object_Name__c==obj && co.nasirLightning__Profile__c!=profileName.Name){
                        system.debug('nasirjawed:');
                        feedRec.addError('Your administrator has disabled feed post and comment deletions.'); 
                    }
                    if(co.nasirLightning__Object_Name__c==obj && co.nasirLightning__Profile__c==profileName.Name){
                        //no action
                        system.debug('jawed:');                           
                    }
                }
            }         
        }     
    }
}