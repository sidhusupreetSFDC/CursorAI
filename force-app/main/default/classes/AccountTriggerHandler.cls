/**
 * Trigger Handler for Account object
 * Follows Trigger Handler pattern: Triggers → Handlers → Services
 * Orchestrates trigger logic and delegates to service layer
 * 
 * @author Salesforce Developer
 * @date 2024
 */
public class AccountTriggerHandler {
    
    /**
     * Handles before insert trigger context
     * @param newAccounts List of new Account records
     */
    public void handleBeforeInsert(List<Account> newAccounts) {
        try {
            AccountService.setDefaultRevenue(newAccounts);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'AccountTriggerHandler.handleBeforeInsert error: ' + e.getMessage());
            throw new AccountServiceException('Error in before insert handler: ' + e.getMessage());
        }
    }
    
    /**
     * Handles after insert trigger context
     * @param newAccounts List of new Account records
     */
    public void handleAfterInsert(List<Account> newAccounts) {
        try {
            AccountService.createFollowUpTasks(newAccounts);
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'AccountTriggerHandler.handleAfterInsert error: ' + e.getMessage());
            // Log error but don't fail the transaction for after insert
            // Tasks are non-critical follow-up items
        }
    }
}

