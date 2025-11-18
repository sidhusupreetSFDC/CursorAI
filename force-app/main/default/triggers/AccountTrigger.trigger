/**
 * Trigger for Account object
 * Delegates all logic to AccountTriggerHandler following trigger handler pattern
 * 
 * @author Salesforce Developer
 * @date 2024
 */
trigger AccountTrigger on Account (before insert, after insert) {
    AccountTriggerHandler.handle();
}