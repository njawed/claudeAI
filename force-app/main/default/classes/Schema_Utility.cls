public with sharing class Schema_Utility {
    static final Map<String, String> sObjectKeyPrefixCache = new Map<String, String>();
    
    public static String getSObjectNameFromKeyPrefix(String idString){
        if (String.isBlank(idString) || idString.length() < 3) return null;
        String kpx = idString.substring(0, 3);
        Map<String, Schema.SObjectType> gsm = Schema_Utility.getGlobalSchemaMap();
        
        String objectKpx;
        for (String oName : gsm.keySet()) {
        objectKpx = Schema_Utility.getSObjectKeyPrefix(oName);
        if (kpx.equals(objectKpx))  return oName;
        }
        return null;
    }
    
    public static String getSObjectKeyPrefix(String objectName)    {
        if (String.isBlank(objectName)) return null;
        objectName = objectName.normalizeSpace();
        
        String keyPrefix = sObjectKeyPrefixCache.get(objectName.toLowerCase());
        if (keyPrefix == null) {
          Schema.SObjectType sot = getGlobalSchemaMap().get(objectName.toLowerCase());
          if (sot == null) return null;
          keyPrefix = sot.getDescribe().getKeyPrefix();
          sObjectKeyPrefixCache.put(objectName.toLowerCase(), keyPrefix);
        }
        return keyPrefix;
    }
    static Map<String, Schema.SObjectType> globalSchemaMap = null;
    public static Map<String, Schema.SObjectType> getGlobalSchemaMap(){
        if (globalSchemaMap == null) {
            globalSchemaMap = Schema.getGlobalDescribe();
        }
        
        return globalSchemaMap;
    }
    

}