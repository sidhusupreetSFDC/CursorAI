/**
 * Trigger Handler for Account object
 * Follows trigger handler pattern: Triggers → Handlers → Services
 * Orchestrates trigger logic and delegates to AccountService
 * 
 * @author Salesforce Developer
 * @date 2024
 */
public class AccountTriggerHandler {
    
    /**
     * Entry point for trigger - routes to appropriate handler method
     * Must be called from trigger context where Trigger variables are available
     */
    public static void handle() {
        try {
            if (Trigger.isBefore && Trigger.isInsert) {
                handleBeforeInsert(Trigger.new);
            }
            
            if (Trigger.isAfter && Trigger.isInsert) {
                handleAfterInsert(Trigger.new);
            }
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'AccountTriggerHandler.handle - Error: ' + e.getMessage());
            System.debug(LoggingLevel.ERROR, 'Stack trace: ' + e.getStackTraceString());
            throw new AccountServiceException('Error in AccountTriggerHandler: ' + e.getMessage(), e);
        }
    }
    
    /**
     * Handles before insert context
     * Sets default AnnualRevenue if null
     * @param newAccounts List of new Account records
     */
    private static void handleBeforeInsert(List<Account> newAccounts) {
        System.debug(LoggingLevel.DEBUG, 'AccountTriggerHandler.handleBeforeInsert - Processing ' + newAccounts.size() + ' accounts');
        
        AccountService.setDefaultAnnualRevenue(newAccounts);
    }
    
    /**
     * Handles after insert context
     * Creates follow-up tasks for new accounts
     * @param newAccounts List of newly inserted Account records
     */
    private static void handleAfterInsert(List<Account> newAccounts) {
        System.debug(LoggingLevel.DEBUG, 'AccountTriggerHandler.handleAfterInsert - Processing ' + newAccounts.size() + ' accounts');
        
        AccountService.createFollowUpTasks(newAccounts);
    }
}

