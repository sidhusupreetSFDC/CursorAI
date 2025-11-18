/**
 * Trigger for Account object
 * Delegates all business logic to AccountTriggerHandler
 * Follows Trigger Handler pattern: one trigger per object
 */
trigger AccountTrigger on Account (before insert, after insert) {
    AccountTriggerHandler handler = new AccountTriggerHandler();
    
    if (Trigger.isBefore && Trigger.isInsert) {
        handler.onBeforeInsert(Trigger.new);
    }
    
    if (Trigger.isAfter && Trigger.isInsert) {
        handler.onAfterInsert(Trigger.new);
    }
}