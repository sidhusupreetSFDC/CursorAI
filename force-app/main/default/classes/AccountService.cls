/**
 * Service class for Account business logic
 * Implements Service Layer pattern with bulkified methods
 * Handles all Account-related business operations
 * 
 * @author Salesforce Developer
 * @date 2024
 */
public with sharing class AccountService {
    
    private static final Integer MAX_QUERY_LIMIT = 10000;
    private static final Decimal DEFAULT_REVENUE = 0;
    
    /**
     * Creates multiple Account records in bulk
     * @param accounts List of Account records to create
     * @return Database.SaveResult[] Results of the insert operation
     * @throws AccountServiceException if validation fails or DML operation fails
     */
    public static Database.SaveResult[] createAccounts(List<Account> accounts) {
        if (accounts == null || accounts.isEmpty()) {
            throw new AccountServiceException('Account list cannot be null or empty');
        }
        
        if (accounts.size() > Limits.getLimitDmlRows()) {
            throw new AccountServiceException('Cannot process more than ' + Limits.getLimitDmlRows() + ' records');
        }
        
        try {
            // Check CRUD permissions
            if (!Schema.sObjectType.Account.isCreateable()) {
                throw new AccountServiceException('User does not have permission to create Account records');
            }
            
            // Apply field-level security
            SObjectAccessDecision decision = Security.stripInaccessible(
                AccessType.CREATABLE,
                accounts
            );
            
            List<Account> accessibleAccounts = decision.getRecords();
            
            System.debug(LoggingLevel.INFO, 'AccountService.createAccounts: Processing ' + accessibleAccounts.size() + ' accounts');
            
            // Use Database method for partial success handling
            Database.SaveResult[] results = Database.insert(accessibleAccounts, false);
            
            // Log errors
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    String errorMsg = 'Failed to create account: ';
                    for (Database.Error error : results[i].getErrors()) {
                        errorMsg += error.getMessage() + ' ';
                    }
                    System.debug(LoggingLevel.ERROR, errorMsg);
                }
            }
            
            return results;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'AccountService.createAccounts error: ' + e.getMessage());
            throw new AccountServiceException('Error creating accounts: ' + e.getMessage());
        }
    }
    
    /**
     * Updates AnnualRevenue for multiple Account records in bulk
     * @param accountIds List of Account IDs to update
     * @param newRevenue New revenue value to set
     * @return Database.SaveResult[] Results of the update operation
     * @throws AccountServiceException if validation fails or DML operation fails
     */
    public static Database.SaveResult[] updateAccountRevenue(List<Id> accountIds, Decimal newRevenue) {
        if (accountIds == null || accountIds.isEmpty()) {
            throw new AccountServiceException('Account ID list cannot be null or empty');
        }
        
        if (newRevenue == null || newRevenue < 0) {
            throw new AccountServiceException('Revenue must be a non-negative number');
        }
        
        try {
            // Check CRUD permissions
            if (!Schema.sObjectType.Account.isUpdateable()) {
                throw new AccountServiceException('User does not have permission to update Account records');
            }
            
            // Bulk query with security enforced
            List<Account> accounts = [
                SELECT Id, AnnualRevenue 
                FROM Account 
                WHERE Id IN :accountIds 
                WITH SECURITY_ENFORCED
                LIMIT :MAX_QUERY_LIMIT
            ];
            
            if (accounts.isEmpty()) {
                throw new AccountServiceException('No accounts found with provided IDs');
            }
            
            // Update revenue
            for (Account acc : accounts) {
                acc.AnnualRevenue = newRevenue;
            }
            
            // Apply field-level security
            SObjectAccessDecision decision = Security.stripInaccessible(
                AccessType.UPDATABLE,
                accounts
            );
            
            List<Account> accessibleAccounts = decision.getRecords();
            
            System.debug(LoggingLevel.INFO, 'AccountService.updateAccountRevenue: Updating ' + accessibleAccounts.size() + ' accounts');
            
            // Use Database method for partial success handling
            Database.SaveResult[] results = Database.update(accessibleAccounts, false);
            
            // Log errors
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    String errorMsg = 'Failed to update account: ';
                    for (Database.Error error : results[i].getErrors()) {
                        errorMsg += error.getMessage() + ' ';
                    }
                    System.debug(LoggingLevel.ERROR, errorMsg);
                }
            }
            
            return results;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'AccountService.updateAccountRevenue error: ' + e.getMessage());
            throw new AccountServiceException('Error updating account revenue: ' + e.getMessage());
        }
    }
    
    /**
     * Deletes Account records older than specified days
     * @param daysOld Number of days old (defaults to 365)
     * @return Database.DeleteResult[] Results of the delete operation
     * @throws AccountServiceException if validation fails or DML operation fails
     */
    public static Database.DeleteResult[] deleteOldAccounts(Integer daysOld) {
        if (daysOld == null || daysOld < 0) {
            daysOld = 365; // Default to 1 year
        }
        
        try {
            // Check CRUD permissions
            if (!Schema.sObjectType.Account.isDeletable()) {
                throw new AccountServiceException('User does not have permission to delete Account records');
            }
            
            // Bulk query with security enforced and LIMIT
            List<Account> oldAccounts = [
                SELECT Id 
                FROM Account 
                WHERE CreatedDate < :Date.today().addDays(-daysOld)
                WITH SECURITY_ENFORCED
                LIMIT :MAX_QUERY_LIMIT
            ];
            
            if (oldAccounts.isEmpty()) {
                System.debug(LoggingLevel.INFO, 'AccountService.deleteOldAccounts: No old accounts found');
                return new Database.DeleteResult[0];
            }
            
            System.debug(LoggingLevel.INFO, 'AccountService.deleteOldAccounts: Deleting ' + oldAccounts.size() + ' accounts');
            
            // Use Database method for partial success handling
            Database.DeleteResult[] results = Database.delete(oldAccounts, false);
            
            // Log errors
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    String errorMsg = 'Failed to delete account: ';
                    for (Database.Error error : results[i].getErrors()) {
                        errorMsg += error.getMessage() + ' ';
                    }
                    System.debug(LoggingLevel.ERROR, errorMsg);
                }
            }
            
            return results;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'AccountService.deleteOldAccounts error: ' + e.getMessage());
            throw new AccountServiceException('Error deleting old accounts: ' + e.getMessage());
        }
    }
    
    /**
     * Sets default revenue for accounts that don't have revenue set
     * Used by trigger handler in before insert context
     * @param accounts List of Account records
     */
    public static void setDefaultRevenue(List<Account> accounts) {
        if (accounts == null || accounts.isEmpty()) {
            return;
        }
        
        for (Account acc : accounts) {
            if (acc.AnnualRevenue == null) {
                acc.AnnualRevenue = DEFAULT_REVENUE;
            }
        }
        
        System.debug(LoggingLevel.DEBUG, 'AccountService.setDefaultRevenue: Set default revenue for accounts');
    }
    
    /**
     * Creates follow-up tasks for newly created accounts
     * Used by trigger handler in after insert context
     * Uses @future or Queueable for async processing to avoid DML in trigger
     * @param accounts List of Account records
     */
    public static void createFollowUpTasks(List<Account> accounts) {
        if (accounts == null || accounts.isEmpty()) {
            return;
        }
        
        // Check CRUD permissions
        if (!Schema.sObjectType.Task.isCreateable()) {
            System.debug(LoggingLevel.WARN, 'AccountService.createFollowUpTasks: User does not have permission to create Task records');
            return;
        }
        
        List<Task> tasks = new List<Task>();
        
        for (Account acc : accounts) {
            Task t = new Task();
            t.Subject = 'Follow up on new account';
            t.WhatId = acc.Id;
            t.Status = 'Not Started';
            t.Priority = 'Normal';
            tasks.add(t);
        }
        
        if (!tasks.isEmpty()) {
            // Apply field-level security
            SObjectAccessDecision decision = Security.stripInaccessible(
                AccessType.CREATABLE,
                tasks
            );
            
            List<Task> accessibleTasks = decision.getRecords();
            
            System.debug(LoggingLevel.INFO, 'AccountService.createFollowUpTasks: Creating ' + accessibleTasks.size() + ' tasks');
            
            // Use Database method for partial success handling
            Database.SaveResult[] results = Database.insert(accessibleTasks, false);
            
            // Log errors
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    String errorMsg = 'Failed to create task: ';
                    for (Database.Error error : results[i].getErrors()) {
                        errorMsg += error.getMessage() + ' ';
                    }
                    System.debug(LoggingLevel.ERROR, errorMsg);
                }
            }
        }
    }
}
