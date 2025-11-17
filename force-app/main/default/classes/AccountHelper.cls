/**
 * @description Helper class for Account-related operations
 * @author Salesforce Dev Team
 * @date 2025
 */
public class AccountHelper {
    
    // Custom exception for AccountHelper operations
    public class AccountHelperException extends Exception {}
    
    /**
     * @description Updates the rating for multiple accounts (bulkified)
     * @param accountRatingMap Map of Account IDs to Rating values
     * @return Map of Account IDs to success/failure status
     */
    public static Map<Id, String> updateAccountRatings(Map<Id, String> accountRatingMap) {
        // Result map to track success/failure for each account
        Map<Id, String> resultMap = new Map<Id, String>();
        
        // Null and empty check
        if (accountRatingMap == null || accountRatingMap.isEmpty()) {
            System.debug('AccountHelper.updateAccountRatings: No accounts provided');
            return resultMap;
        }
        
        // Validate input size for governor limits
        if (accountRatingMap.size() > 200) {
            throw new AccountHelperException('Cannot process more than 200 accounts at once. Received: ' + accountRatingMap.size());
        }
        
        try {
            // Bulkified SOQL query - retrieve all accounts in one query
            Set<Id> accountIds = accountRatingMap.keySet();
            Map<Id, Account> accountsToUpdate = new Map<Id, Account>(
                [SELECT Id, Rating FROM Account WHERE Id IN :accountIds]
            );
            
            // Validate that all requested accounts exist
            for (Id accountId : accountIds) {
                if (!accountsToUpdate.containsKey(accountId)) {
                    resultMap.put(accountId, 'Error: Account not found');
                    System.debug('Account not found: ' + accountId);
                }
            }
            
            // Prepare accounts for update
            List<Account> accountsForUpdate = new List<Account>();
            for (Id accountId : accountsToUpdate.keySet()) {
                String newRating = accountRatingMap.get(accountId);
                
                // Validate rating value
                if (String.isBlank(newRating)) {
                    resultMap.put(accountId, 'Error: Rating cannot be blank');
                    continue;
                }
                
                // Validate rating is a valid picklist value
                if (!isValidRating(newRating)) {
                    resultMap.put(accountId, 'Error: Invalid rating value - ' + newRating);
                    continue;
                }
                
                Account acc = accountsToUpdate.get(accountId);
                acc.Rating = newRating;
                accountsForUpdate.add(acc);
            }
            
            // Bulkified DML operation with error handling
            if (!accountsForUpdate.isEmpty()) {
                Database.SaveResult[] saveResults = Database.update(accountsForUpdate, false);
                
                // Process save results
                for (Integer i = 0; i < saveResults.size(); i++) {
                    Database.SaveResult sr = saveResults[i];
                    Id accountId = accountsForUpdate[i].Id;
                    
                    if (sr.isSuccess()) {
                        resultMap.put(accountId, 'Success');
                    } else {
                        // Collect all error messages
                        String errorMsg = 'Error: ';
                        for (Database.Error err : sr.getErrors()) {
                            errorMsg += err.getMessage() + '; ';
                        }
                        resultMap.put(accountId, errorMsg);
                        System.debug('Failed to update Account ' + accountId + ': ' + errorMsg);
                    }
                }
            }
            
        } catch (QueryException qe) {
            System.debug(LoggingLevel.ERROR, 'Query Exception in updateAccountRatings: ' + qe.getMessage());
            throw new AccountHelperException('Database query failed: ' + qe.getMessage());
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'Exception in updateAccountRatings: ' + e.getMessage() + ' | Stack Trace: ' + e.getStackTraceString());
            throw new AccountHelperException('Failed to update accounts: ' + e.getMessage());
        }
        
        return resultMap;
    }
    
    /**
     * @description Convenience method to update a single account rating
     * @param accountId The Account ID to update
     * @param rating The new rating value
     * @return Boolean indicating success or failure
     */
    public static Boolean updateAccountRating(Id accountId, String rating) {
        // Null checks
        if (accountId == null) {
            System.debug('AccountHelper.updateAccountRating: Account ID cannot be null');
            return false;
        }
        
        if (String.isBlank(rating)) {
            System.debug('AccountHelper.updateAccountRating: Rating cannot be blank');
            return false;
        }
        
        // Use the bulkified method
        Map<Id, String> accountRatingMap = new Map<Id, String>();
        accountRatingMap.put(accountId, rating);
        
        Map<Id, String> results = updateAccountRatings(accountRatingMap);
        
        // Return true if the result is "Success"
        return results.containsKey(accountId) && results.get(accountId) == 'Success';
    }
    
    /**
     * @description Validates if the rating is a valid picklist value
     * @param rating The rating value to validate
     * @return Boolean indicating if the rating is valid
     */
    @TestVisible
    private static Boolean isValidRating(String rating) {
        // Valid Account Rating picklist values
        Set<String> validRatings = new Set<String>{
            'Hot', 'Warm', 'Cold'
        };
        
        return validRatings.contains(rating);
    }
    
    /**
     * @description Bulk update account ratings with list of accounts
     * @param accounts List of accounts to update with rating
     * @param rating The rating to apply to all accounts
     * @return Map of Account IDs to success/failure status
     */
    public static Map<Id, String> updateAccountRatingsForList(List<Account> accounts, String rating) {
        Map<Id, String> resultMap = new Map<Id, String>();
        
        // Null and empty checks
        if (accounts == null || accounts.isEmpty()) {
            System.debug('AccountHelper.updateAccountRatingsForList: No accounts provided');
            return resultMap;
        }
        
        if (String.isBlank(rating)) {
            System.debug('AccountHelper.updateAccountRatingsForList: Rating cannot be blank');
            return resultMap;
        }
        
        // Build map for bulkified processing
        Map<Id, String> accountRatingMap = new Map<Id, String>();
        for (Account acc : accounts) {
            if (acc.Id != null) {
                accountRatingMap.put(acc.Id, rating);
            }
        }
        
        // Use the bulkified method
        return updateAccountRatings(accountRatingMap);
    }
}