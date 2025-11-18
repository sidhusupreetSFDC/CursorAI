/**
 * @description Service class for Account business logic
 * Implements Service Layer pattern with bulkification and error handling
 * 
 * @author Salesforce Developer
 * @date 2024
 */
public with sharing class AccountService {
    
    private static final Decimal DEFAULT_ANNUAL_REVENUE = 0;
    private static final String FOLLOW_UP_TASK_SUBJECT = 'Follow up on new account';
    private static final Integer MAX_RECORDS_PER_BATCH = 10000;
    
    /**
     * @description Sets default AnnualRevenue for accounts where it is null
     * Called from trigger handler before insert
     * @param accounts List of Account records to process
     */
    public static void setDefaultAnnualRevenue(List<Account> accounts) {
        if (accounts == null || accounts.isEmpty()) {
            System.debug(LoggingLevel.DEBUG, 'AccountService.setDefaultAnnualRevenue - No accounts to process');
            return;
        }
        
        System.debug(LoggingLevel.DEBUG, 'AccountService.setDefaultAnnualRevenue - Processing ' + accounts.size() + ' accounts');
        
        Integer updatedCount = 0;
        for (Account acc : accounts) {
            if (acc.AnnualRevenue == null) {
                acc.AnnualRevenue = DEFAULT_ANNUAL_REVENUE;
                updatedCount++;
            }
        }
        
        System.debug(LoggingLevel.DEBUG, 'AccountService.setDefaultAnnualRevenue - Updated ' + updatedCount + ' accounts with default revenue');
    }
    
    /**
     * @description Creates follow-up tasks for newly inserted accounts
     * Called from trigger handler after insert
     * @param accounts List of newly inserted Account records
     */
    public static void createFollowUpTasks(List<Account> accounts) {
        if (accounts == null || accounts.isEmpty()) {
            System.debug(LoggingLevel.DEBUG, 'AccountService.createFollowUpTasks - No accounts to process');
            return;
        }
        
        System.debug(LoggingLevel.DEBUG, 'AccountService.createFollowUpTasks - Processing ' + accounts.size() + ' accounts');
        
        // Check CRUD permissions before creating tasks
        if (!Schema.sObjectType.Task.isCreateable()) {
            throw new AccountServiceException('Insufficient permissions to create Task records');
        }
        
        List<Task> tasksToInsert = new List<Task>();
        for (Account acc : accounts) {
            Task t = new Task();
            t.Subject = FOLLOW_UP_TASK_SUBJECT;
            t.WhatId = acc.Id;
            tasksToInsert.add(t);
        }
        
        if (!tasksToInsert.isEmpty()) {
            Database.SaveResult[] results = Database.insert(tasksToInsert, false);
            handleDmlResults(results, 'AccountService.createFollowUpTasks');
        }
    }
    
    /**
     * @description Creates accounts in bulk with error handling
     * @param accounts List of Account records to create
     * @return Database.SaveResult[] Results of the insert operation
     */
    public static Database.SaveResult[] createAccounts(List<Account> accounts) {
        if (accounts == null || accounts.isEmpty()) {
            throw new AccountServiceException('Account list cannot be null or empty');
        }
        
        if (accounts.size() > Limits.getLimitDmlRows()) {
            throw new AccountServiceException('Cannot process more than ' + Limits.getLimitDmlRows() + ' accounts in a single transaction');
        }
        
        System.debug(LoggingLevel.DEBUG, 'AccountService.createAccounts - Creating ' + accounts.size() + ' accounts');
        
        // Check CRUD permissions
        if (!Schema.sObjectType.Account.isCreateable()) {
            throw new AccountServiceException('Insufficient permissions to create Account records');
        }
        
        // Apply field-level security
        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.CREATABLE,
            accounts
        );
        
        List<Account> accessibleAccounts = new List<Account>();
        for (SObject acc : decision.getRecords()) {
            accessibleAccounts.add((Account) acc);
        }
        
        Database.SaveResult[] results = Database.insert(accessibleAccounts, false);
        handleDmlResults(results, 'AccountService.createAccounts');
        
        return results;
    }
    
    /**
     * @description Updates account revenue in bulk
     * @param accountIds List of Account IDs to update
     * @param newRevenue New revenue value to set
     * @return Database.SaveResult[] Results of the update operation
     */
    public static Database.SaveResult[] updateAccountRevenue(List<Id> accountIds, Decimal newRevenue) {
        if (accountIds == null || accountIds.isEmpty()) {
            throw new AccountServiceException('Account ID list cannot be null or empty');
        }
        
        if (newRevenue == null) {
            throw new AccountServiceException('Revenue value cannot be null');
        }
        
        System.debug(LoggingLevel.DEBUG, 'AccountService.updateAccountRevenue - Updating ' + accountIds.size() + ' accounts');
        
        // Check CRUD permissions
        if (!Schema.sObjectType.Account.isUpdateable()) {
            throw new AccountServiceException('Insufficient permissions to update Account records');
        }
        
        // Query accounts with security enforced
        List<Account> accounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            WHERE Id IN :accountIds 
            WITH SECURITY_ENFORCED
            LIMIT :MAX_RECORDS_PER_BATCH
        ];
        
        if (accounts.size() != accountIds.size()) {
            System.debug(LoggingLevel.WARN, 'AccountService.updateAccountRevenue - Some accounts were not found or not accessible');
        }
        
        for (Account acc : accounts) {
        acc.AnnualRevenue = newRevenue;
        }
        
        // Apply field-level security
        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.UPDATABLE,
            accounts
        );
        
        List<Account> accessibleAccounts = new List<Account>();
        for (SObject acc : decision.getRecords()) {
            accessibleAccounts.add((Account) acc);
        }
        
        Database.SaveResult[] results = Database.update(accessibleAccounts, false);
        handleDmlResults(results, 'AccountService.updateAccountRevenue');
        
        return results;
    }
    
    /**
     * @description Deletes old accounts created more than specified days ago
     * Uses SOQL FOR loop for large datasets
     * @param daysOld Number of days old (default 365)
     * @return Integer Number of accounts deleted
     */
    public static Integer deleteOldAccounts(Integer daysOld) {
        if (daysOld == null || daysOld < 0) {
            daysOld = 365;
        }
        
        System.debug(LoggingLevel.DEBUG, 'AccountService.deleteOldAccounts - Deleting accounts older than ' + daysOld + ' days');
        
        // Check CRUD permissions
        if (!Schema.sObjectType.Account.isDeletable()) {
            throw new AccountServiceException('Insufficient permissions to delete Account records');
        }
        
        Integer deletedCount = 0;
        List<Account> accountsToDelete = new List<Account>();
        
        // Collect accounts to delete using SOQL FOR loop for large datasets
        for (Account acc : [
            SELECT Id 
            FROM Account 
            WHERE CreatedDate < :Date.today().addDays(-daysOld)
            WITH SECURITY_ENFORCED
            LIMIT :MAX_RECORDS_PER_BATCH
        ]) {
            accountsToDelete.add(acc);
        }
        
        // Delete in batches outside the loop to avoid OperationWithLimitsInLoop
        if (!accountsToDelete.isEmpty()) {
            Integer batchSize = 200;
            Integer totalRecords = accountsToDelete.size();
            
            for (Integer i = 0; i < totalRecords; i += batchSize) {
                Integer endIndex = Math.min(i + batchSize, totalRecords);
                List<Account> batch = new List<Account>();
                
                for (Integer j = i; j < endIndex; j++) {
                    batch.add(accountsToDelete[j]);
                }
                
                Database.DeleteResult[] results = Database.delete(batch, false);
                deletedCount += handleDmlResults(results, 'AccountService.deleteOldAccounts');
            }
        }
        
        System.debug(LoggingLevel.DEBUG, 'AccountService.deleteOldAccounts - Deleted ' + deletedCount + ' accounts');
        return deletedCount;
    }
    
    /**
     * @description Handles DML operation results and logs errors
     * @param results Database operation results
     * @param context Context string for logging
     * @return Integer Number of successful operations
     */
    private static Integer handleDmlResults(Database.SaveResult[] results, String context) {
        Integer successCount = 0;
        Integer failureCount = 0;
        
        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            } else {
                failureCount++;
                String errorMsg = context + ' - DML Error: ';
                for (Database.Error error : result.getErrors()) {
                    errorMsg += error.getMessage() + ' (' + error.getStatusCode() + '); ';
                }
                System.debug(LoggingLevel.ERROR, errorMsg);
            }
        }
        
        if (failureCount > 0) {
            System.debug(LoggingLevel.WARN, context + ' - ' + successCount + ' succeeded, ' + failureCount + ' failed');
        }
        
        return successCount;
    }
    
    /**
     * @description Handles delete operation results and logs errors
     * @param results Database delete results
     * @param context Context string for logging
     * @return Integer Number of successful operations
     */
    private static Integer handleDmlResults(Database.DeleteResult[] results, String context) {
        Integer successCount = 0;
        Integer failureCount = 0;
        
        for (Database.DeleteResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            } else {
                failureCount++;
                String errorMsg = context + ' - Delete Error: ';
                for (Database.Error error : result.getErrors()) {
                    errorMsg += error.getMessage() + ' (' + error.getStatusCode() + '); ';
                }
                System.debug(LoggingLevel.ERROR, errorMsg);
            }
        }
        
        if (failureCount > 0) {
            System.debug(LoggingLevel.WARN, context + ' - ' + successCount + ' succeeded, ' + failureCount + ' failed');
        }
        
        return successCount;
    }
}