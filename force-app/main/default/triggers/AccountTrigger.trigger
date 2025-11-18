/**
 * Trigger for Account object
 * Delegates all logic to AccountTriggerHandler following Trigger Handler pattern
 * 
 * @author Salesforce Developer
 * @date 2024
 */
trigger AccountTrigger on Account (before insert, after insert) {
    AccountTriggerHandler handler = new AccountTriggerHandler();
    
    if (Trigger.isBefore && Trigger.isInsert) {
        handler.handleBeforeInsert(Trigger.new);
    }
    
    if (Trigger.isAfter && Trigger.isInsert) {
        handler.handleAfterInsert(Trigger.new);
    }
}