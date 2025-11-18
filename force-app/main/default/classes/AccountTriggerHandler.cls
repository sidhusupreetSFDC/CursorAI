/**
 * Trigger Handler for Account object
 * Follows the Trigger Handler pattern: Triggers → Handlers → Services
 * Orchestrates trigger logic and delegates to service layer
 */
public class AccountTriggerHandler {
    
    /**
     * Handles before insert trigger context
     * Sets default AnnualRevenue to 0 if null
     * @param newAccounts List of new Account records
     */
    public void onBeforeInsert(List<Account> newAccounts) {
        if (newAccounts == null || newAccounts.isEmpty()) {
            return;
        }
        
        for (Account acc : newAccounts) {
            if (acc.AnnualRevenue == null) {
                acc.AnnualRevenue = 0;
            }
        }
    }
    
    /**
     * Handles after insert trigger context
     * Creates follow-up tasks for new accounts
     * @param newAccounts List of newly inserted Account records
     */
    public void onAfterInsert(List<Account> newAccounts) {
        if (newAccounts == null || newAccounts.isEmpty()) {
            return;
        }
        
        AccountService.createFollowUpTasks(newAccounts);
    }
}

