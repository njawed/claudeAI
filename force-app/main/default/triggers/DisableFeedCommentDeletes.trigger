/**
 * Helper for Disable Chatter Deletes App
 * Author: Nasir jawed(nasir.jawed@in.ibm.com)
 */
trigger DisableFeedCommentDeletes on FeedComment (before delete) 
{
     DisableChatterDeleteDelegateComment.allowDeleteComment(trigger.old) ;
}