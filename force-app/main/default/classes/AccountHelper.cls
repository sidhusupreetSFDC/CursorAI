/**
 * @description Helper class for Account operations
 * @author Salesforce Developer
 * @date 2024
 */
public class AccountHelper {
    
    /**
     * @description Updates AnnualRevenue for the provided Account records
     * @param accountIds List of Account Ids to update
     * @throws DmlException if DML operation fails
     */
    public static void updateAccounts(List<Id> accountIds) {
        // Validate input
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }
        
        try {
            // Bulkify SOQL query - query all accounts in a single query
            List<Account> accountsToUpdate = [
                SELECT Id, Name, AnnualRevenue 
                FROM Account 
                WHERE Id IN :accountIds
                WITH SECURITY_ENFORCED
            ];
            
            // Check if we have records to update
            if (accountsToUpdate.isEmpty()) {
                return;
            }
            
            // Check field-level security for AnnualRevenue field
            if (!Schema.sObjectType.Account.fields.AnnualRevenue.isUpdateable()) {
                throw new SecurityException('Insufficient permissions to update AnnualRevenue field');
            }
            
            // Bulkify DML operation - update all records in a single DML call
            for (Account acc : accountsToUpdate) {
                acc.AnnualRevenue = 1000000;
            }
            
            update accountsToUpdate;
            
        } catch (DmlException e) {
            // Log error and rethrow for caller to handle
            System.debug(LoggingLevel.ERROR, 'Error updating Accounts: ' + e.getMessage());
            throw e;
        } catch (SecurityException e) {
            // Log security exception
            System.debug(LoggingLevel.ERROR, 'Security error: ' + e.getMessage());
            throw e;
        } catch (Exception e) {
            // Catch any other unexpected exceptions
            System.debug(LoggingLevel.ERROR, 'Unexpected error updating Accounts: ' + e.getMessage());
            throw new AccountHelperException('An error occurred while updating Accounts: ' + e.getMessage(), e);
        }
    }
    
    /**
     * @description Custom exception class for AccountHelper operations
     */
    public class AccountHelperException extends Exception {}
}