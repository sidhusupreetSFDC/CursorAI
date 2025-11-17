/**
 * @description Helper class for Account-related operations
 * Provides methods to update account ratings with proper validation and error handling
 * @author Salesforce Dev Team
 * @date 2025
 */
public with sharing class AccountHelper {
    
    // Valid rating values for Account.Rating field
    private static final Set<String> VALID_RATINGS = new Set<String>{'Hot', 'Warm', 'Cold'};
    private static final Integer MAX_BULK_RECORDS = 200;
    
    /**
     * @description Updates a single account's rating with validation
     * @param accountId The ID of the account to update
     * @param rating The new rating value (Hot, Warm, or Cold)
     * @return Boolean True if update successful, false otherwise
     */
    public static Boolean updateAccountRating(Id accountId, String rating) {
        // Validate inputs
        if (accountId == null) {
            return false;
        }
        
        if (String.isBlank(rating)) {
            return false;
        }
        
        if (!isValidRating(rating)) {
            return false;
        }
        
        try {
            List<Account> accounts = [
                SELECT Id, Rating
                FROM Account
                WHERE Id = :accountId
                WITH SECURITY_ENFORCED
                LIMIT 1
            ];

            if (accounts.isEmpty()) {
                return false;
            }

            Account acc = accounts[0];
            acc.Rating = rating;
            update acc;

            return true;
        } catch (Exception e) {
            // Log error and return false
            System.debug(LoggingLevel.ERROR, 'Error updating account rating: ' + e.getMessage());
            return false;
        }
    }
    
    /**
     * @description Updates multiple accounts' ratings in a bulkified manner
     * @param accountRatingMap Map of Account IDs to new rating values
     * @return Map<Id, String> Map of Account IDs to result messages ('Success' or error message)
     * @throws AccountHelperException if input exceeds maximum record limit
     */
    public static Map<Id, String> updateAccountRatings(Map<Id, String> accountRatingMap) {
        Map<Id, String> results = new Map<Id, String>();
        
        // Validate inputs
        if (accountRatingMap == null || accountRatingMap.isEmpty()) {
            return results;
        }
        
        // Check record limit
        if (accountRatingMap.size() > MAX_BULK_RECORDS) {
            throw new AccountHelperException(
                'Cannot process more than ' + MAX_BULK_RECORDS + ' records at once. ' +
                'Provided: ' + accountRatingMap.size()
            );
        }

        // Pre-validate all ratings
        Map<Id, String> validatedMap = new Map<Id, String>();
        for (Id accountId : accountRatingMap.keySet()) {
            String rating = accountRatingMap.get(accountId);
            
            if (String.isBlank(rating)) {
                results.put(accountId, 'Error: Rating cannot be blank');
                continue;
            }
            
            if (!isValidRating(rating)) {
                results.put(accountId, 'Error: Invalid rating value: ' + rating);
                continue;
            }
            
            validatedMap.put(accountId, rating);
        }
        
        // If no valid records, return early
        if (validatedMap.isEmpty()) {
            return results;
        }
        
        // Query existing accounts
        Map<Id, Account> accountsToUpdate = new Map<Id, Account>();
        try {
            List<Account> queriedAccounts = [
                SELECT Id, Rating
                FROM Account
                WHERE Id IN :validatedMap.keySet()
                WITH SECURITY_ENFORCED
            ];

            for (Account acc : queriedAccounts) {
                accountsToUpdate.put(acc.Id, acc);
            }

            // Check for non-existent accounts
            for (Id accountId : validatedMap.keySet()) {
                if (!accountsToUpdate.containsKey(accountId)) {
                    results.put(accountId, 'Error: Account not found');
                }
            }

        } catch (Exception e) {
            for (Id accountId : validatedMap.keySet()) {
                results.put(accountId, 'Error: ' + e.getMessage());
            }
            return results;
        }
        
        // Update ratings
        List<Account> accountsToUpdateList = new List<Account>();
        for (Id accountId : accountsToUpdate.keySet()) {
            Account acc = accountsToUpdate.get(accountId);
            acc.Rating = validatedMap.get(accountId);
            accountsToUpdateList.add(acc);
        }
        
        // Perform DML with partial success handling
        if (!accountsToUpdateList.isEmpty()) {
            Database.SaveResult[] saveResults = Database.update(accountsToUpdateList, false);
            
            for (Integer i = 0; i < saveResults.size(); i++) {
                Database.SaveResult sr = saveResults[i];
                Account acc = accountsToUpdateList[i];
                
                if (sr.isSuccess()) {
                    results.put(acc.Id, 'Success');
                } else {
                    String errorMsg = 'Error: ';
                    for (Database.Error err : sr.getErrors()) {
                        errorMsg += err.getMessage() + '; ';
                    }
                    results.put(acc.Id, errorMsg.trim());
                }
            }
        }
        
        return results;
    }
    
    /**
     * @description Updates ratings for a list of accounts with the same rating value
     * @param accounts List of accounts to update
     * @param rating The rating value to apply to all accounts
     * @return Map<Id, String> Map of Account IDs to result messages
     */
    public static Map<Id, String> updateAccountRatingsForList(List<Account> accounts, String rating) {
        Map<Id, String> results = new Map<Id, String>();
        
        // Validate inputs
        if (accounts == null || accounts.isEmpty() || String.isBlank(rating)) {
            return results;
        }
        
        // Convert list to map
        Map<Id, String> accountRatingMap = new Map<Id, String>();
        for (Account acc : accounts) {
            if (acc.Id != null) {
                accountRatingMap.put(acc.Id, rating);
            }
        }
        
        // Delegate to bulk method
        return updateAccountRatings(accountRatingMap);
    }
    
    /**
     * @description Validates if a rating value is one of the accepted values
     * @param rating The rating value to validate
     * @return Boolean True if rating is valid (Hot, Warm, or Cold)
     */
    private static Boolean isValidRating(String rating) {
        return String.isNotBlank(rating) && VALID_RATINGS.contains(rating);
    }
    
    /**
     * @description Custom exception class for AccountHelper errors
     */
    public class AccountHelperException extends Exception {}
}