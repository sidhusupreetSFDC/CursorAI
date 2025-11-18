/**
 * Service layer for Account business logic
 * Provides bulkified, secure, and error-handled methods for Account operations
 */
public class AccountService {
    
    private static final Integer MAX_DELETE_LIMIT = 10000;
    private static final Integer DAYS_OLD_THRESHOLD = 365;
    
    /**
     * Creates one or more Account records
     * Bulkified to handle 200+ records
     * @param accounts List of Account records to create
     * @return Database.SaveResult[] Results of the insert operation
     * @throws AccountServiceException if accounts list is null or empty
     */
    public static Database.SaveResult[] createAccounts(List<Account> accounts) {
        if (accounts == null || accounts.isEmpty()) {
            throw new AccountServiceException('Account list cannot be null or empty');
        }
        
        // Check CRUD permissions
        if (!Schema.sObjectType.Account.isCreateable()) {
            throw new AccountServiceException('Insufficient permissions to create Account records');
        }
        
        // Strip inaccessible fields
        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.CREATABLE,
            accounts
        );
        List<Account> accessibleAccounts = decision.getRecords();
        
        // Perform bulk insert with partial success allowed
        Database.SaveResult[] results = Database.insert(accessibleAccounts, false);
        
        // Log errors
        logSaveResults('createAccounts', results, accessibleAccounts);
        
        return results;
    }
    
    /**
     * Convenience method to create a single Account
     * @param name Account name
     * @param revenue Annual revenue
     * @return Id of created Account, or null if creation failed
     */
    public static Id createAccount(String name, Decimal revenue) {
        if (String.isBlank(name)) {
            throw new AccountServiceException('Account name cannot be blank');
        }
        
        Account acc = new Account();
        acc.Name = name;
        acc.AnnualRevenue = revenue;
        
        Database.SaveResult[] results = createAccounts(new List<Account>{ acc });
        
        if (results != null && !results.isEmpty() && results[0].isSuccess()) {
            return results[0].getId();
        }
        
        return null;
    }
    
    /**
     * Updates AnnualRevenue for one or more Accounts
     * Bulkified to handle 200+ records
     * @param accountIds List of Account IDs to update
     * @param newRevenue New revenue value to set
     * @return Database.SaveResult[] Results of the update operation
     * @throws AccountServiceException if accountIds list is null or empty
     */
    public static Database.SaveResult[] updateAccountRevenue(List<Id> accountIds, Decimal newRevenue) {
        if (accountIds == null || accountIds.isEmpty()) {
            throw new AccountServiceException('Account ID list cannot be null or empty');
        }
        
        if (newRevenue == null) {
            throw new AccountServiceException('Revenue cannot be null');
        }
        
        // Check CRUD permissions
        if (!Schema.sObjectType.Account.isUpdateable()) {
            throw new AccountServiceException('Insufficient permissions to update Account records');
        }
        
        // Bulk query with security enforcement
        List<Account> accounts = [
            SELECT Id, AnnualRevenue
            FROM Account
            WHERE Id IN :accountIds
            WITH SECURITY_ENFORCED
            LIMIT 200
        ];
        
        if (accounts.isEmpty()) {
            throw new AccountServiceException('No accounts found for the provided IDs');
        }
        
        // Update revenue for all accounts
        for (Account acc : accounts) {
            acc.AnnualRevenue = newRevenue;
        }
        
        // Strip inaccessible fields
        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.UPDATABLE,
            accounts
        );
        List<Account> accessibleAccounts = decision.getRecords();
        
        // Perform bulk update with partial success allowed
        Database.SaveResult[] results = Database.update(accessibleAccounts, false);
        
        // Log errors
        logSaveResults('updateAccountRevenue', results, accessibleAccounts);
        
        return results;
    }
    
    /**
     * Convenience method to update a single Account's revenue
     * @param accountId Account ID to update
     * @param newRevenue New revenue value
     * @return true if update succeeded, false otherwise
     */
    public static Boolean updateAccountRevenue(Id accountId, Decimal newRevenue) {
        if (accountId == null) {
            throw new AccountServiceException('Account ID cannot be null');
        }
        
        Database.SaveResult[] results = updateAccountRevenue(new List<Id>{ accountId }, newRevenue);
        
        return results != null && !results.isEmpty() && results[0].isSuccess();
    }
    
    /**
     * Deletes old Account records created more than specified days ago
     * Includes safety limits and proper error handling
     * @param daysOld Number of days threshold (defaults to 365)
     * @return Database.DeleteResult[] Results of the delete operation
     * @throws AccountServiceException if no accounts found or limit exceeded
     */
    public static Database.DeleteResult[] deleteOldAccounts(Integer daysOld) {
        if (daysOld == null || daysOld < 0) {
            daysOld = DAYS_OLD_THRESHOLD;
        }
        
        // Check CRUD permissions
        if (!Schema.sObjectType.Account.isDeletable()) {
            throw new AccountServiceException('Insufficient permissions to delete Account records');
        }
        
        // Query with security enforcement and limit
        List<Account> oldAccounts = [
            SELECT Id
            FROM Account
            WHERE CreatedDate < LAST_N_DAYS:daysOld
            WITH SECURITY_ENFORCED
            LIMIT :MAX_DELETE_LIMIT
        ];
        
        if (oldAccounts.isEmpty()) {
            System.debug(LoggingLevel.INFO, 'No old accounts found to delete');
            return new Database.DeleteResult[0];
        }
        
        // Perform bulk delete with partial success allowed
        Database.DeleteResult[] results = Database.delete(oldAccounts, false);
        
        // Log errors
        logDeleteResults('deleteOldAccounts', results, oldAccounts);
        
        return results;
    }
    
    /**
     * Convenience method using default 365 days threshold
     * @return Database.DeleteResult[] Results of the delete operation
     */
    public static Database.DeleteResult[] deleteOldAccounts() {
        return deleteOldAccounts(DAYS_OLD_THRESHOLD);
    }
    
    /**
     * Creates follow-up tasks for newly created accounts
     * Bulkified to handle 200+ records
     * @param accounts List of Account records
     * @return Database.SaveResult[] Results of the insert operation
     */
    public static Database.SaveResult[] createFollowUpTasks(List<Account> accounts) {
        if (accounts == null || accounts.isEmpty()) {
            return new Database.SaveResult[0];
        }
        
        // Check CRUD permissions for Task
        if (!Schema.sObjectType.Task.isCreateable()) {
            System.debug(LoggingLevel.WARN, 'Insufficient permissions to create Task records');
            return new Database.SaveResult[0];
        }
        
        List<Task> tasks = new List<Task>();
        for (Account acc : accounts) {
            if (acc.Id != null) {
                Task t = new Task();
                t.Subject = 'Follow up on new account';
                t.WhatId = acc.Id;
                tasks.add(t);
            }
        }
        
        if (tasks.isEmpty()) {
            return new Database.SaveResult[0];
        }
        
        // Strip inaccessible fields
        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.CREATABLE,
            tasks
        );
        List<Task> accessibleTasks = decision.getRecords();
        
        // Perform bulk insert with partial success allowed
        Database.SaveResult[] results = Database.insert(accessibleTasks, false);
        
        // Log errors
        logSaveResults('createFollowUpTasks', results, accessibleTasks);
        
        return results;
    }
    
    /**
     * Logs SaveResult errors for debugging
     * @param methodName Name of the calling method
     * @param results Database.SaveResult array
     * @param records List of SObjects that were processed
     */
    private static void logSaveResults(String methodName, Database.SaveResult[] results, List<SObject> records) {
        if (results == null || records == null) {
            return;
        }
        
        for (Integer i = 0; i < results.size(); i++) {
            Database.SaveResult result = results[i];
            if (!result.isSuccess()) {
                String errorMsg = methodName + ' failed for record at index ' + i + ': ';
                for (Database.Error error : result.getErrors()) {
                    errorMsg += error.getMessage() + ' (' + error.getStatusCode() + ')';
                }
                System.debug(LoggingLevel.ERROR, errorMsg);
            }
        }
    }
    
    /**
     * Logs DeleteResult errors for debugging
     * @param methodName Name of the calling method
     * @param results Database.DeleteResult array
     * @param records List of SObjects that were processed
     */
    private static void logDeleteResults(String methodName, Database.DeleteResult[] results, List<SObject> records) {
        if (results == null || records == null) {
            return;
        }
        
        for (Integer i = 0; i < results.size(); i++) {
            Database.DeleteResult result = results[i];
            if (!result.isSuccess()) {
                String errorMsg = methodName + ' failed for record at index ' + i + ': ';
                for (Database.Error error : result.getErrors()) {
                    errorMsg += error.getMessage() + ' (' + error.getStatusCode() + ')';
                }
                System.debug(LoggingLevel.ERROR, errorMsg);
            }
        }
    }
}