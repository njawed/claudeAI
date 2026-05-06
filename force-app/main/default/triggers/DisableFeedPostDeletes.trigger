/**
 * Helper for Disable Chatter Deletes App
 * Author: Nasir jawed(nasir.jawed@in.ibm.com)
 */
trigger DisableFeedPostDeletes on FeedItem (before delete) {    
       
       DisableChatterDeleteDelegate.allowDelete(trigger.old) ;
    
}