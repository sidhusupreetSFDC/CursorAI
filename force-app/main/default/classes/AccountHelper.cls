/**
 * @description Helper class for Account-related operations
 * @author Salesforce Developer
 * @date 2024
 */
public class AccountHelper {
    
    /**
     * @description Updates Annual Revenue for a list of Account records
     * @param accountIds List of Account IDs to update
     * @throws DmlException if update operation fails
     */
    public static void updateAccounts(List<Id> accountIds) {
        // Validate input
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }
        
        // Check object-level access
        if (!Schema.sObjectType.Account.isUpdateable()) {
            throw new SecurityException('Insufficient permissions to update Account records');
        }
        
        // Check field-level access
        if (!Schema.sObjectType.Account.fields.AnnualRevenue.isUpdateable()) {
            throw new SecurityException('Insufficient permissions to update AnnualRevenue field');
        }
        
        try {
            // Bulkify SOQL query - fetch all accounts in a single query
            List<Account> accountsToUpdate = [
                SELECT Id, Name, AnnualRevenue 
                FROM Account 
                WHERE Id IN :accountIds
                WITH SECURITY_ENFORCED
            ];
            
            // Update accounts in bulk
            for (Account acc : accountsToUpdate) {
                acc.AnnualRevenue = 1000000;
            }
            
            // Bulk DML operation
            if (!accountsToUpdate.isEmpty()) {
                update accountsToUpdate;
            }
        } catch (DmlException e) {
            // Log error and rethrow
            System.debug(LoggingLevel.ERROR, 'Error updating Accounts: ' + e.getMessage());
            throw e;
        } catch (QueryException e) {
            // Log error and rethrow
            System.debug(LoggingLevel.ERROR, 'Error querying Accounts: ' + e.getMessage());
            throw e;
        }
    }
}