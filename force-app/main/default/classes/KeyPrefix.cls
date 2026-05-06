/**
 * Helper for Disable Chatter Deletes App
 * Author: Nasir jawed(nasir.jawed@in.ibm.com)
 */

public class KeyPrefix{
    
    private static Map<String,Schema.SObjectType> gd;
    
    
    private static Map<String, String> keyPrefixMap;

    
    private static Set<String> keyPrefixSet;
    
    private static void init() {
        
        gd = Schema.getGlobalDescribe();
        
        
        keyPrefixMap = new Map<String, String>{};
        
        
        keyPrefixSet = gd.keySet();
        
        
        for(String sObj : keyPrefixSet)
        {
            Schema.DescribeSObjectResult r =  gd.get(sObj).getDescribe();
            String tempName = r.getName();
            String tempPrefix = r.getKeyPrefix();
            keyPrefixMap.put(tempPrefix, tempName);
        }
    }
    
    public static String GetKeyPrefix(String ObjId)
    {
        init() ;
        String tPrefix = ObjId;
        tPrefix = tPrefix.subString(0,3);
        
        
        String objectType = keyPrefixMap.get(tPrefix);
        return objectType;
    }
}