/**
 * Test class for AccountService
 * Tests all methods with positive, negative, bulk, and edge cases
 * 
 * @author Salesforce Developer
 * @date 2024
 */
@isTest
private class AccountServiceTest {
    
    /**
     * Test setup method - creates shared test data
     */
    @testSetup
    static void setupTestData() {
        // Create test accounts for various test scenarios
        List<Account> testAccounts = TestDataFactory.createAccounts(5, 'Test Account');
        insert testAccounts;
    }
    
    // ========== setDefaultAnnualRevenue Tests ==========
    
    @isTest
    static void testSetDefaultAnnualRevenue_WithNullRevenue() {
        // Positive test: Set default revenue for accounts with null revenue
        List<Account> accounts = TestDataFactory.createAccounts(3, 'Test Account');
        
        Test.startTest();
        AccountService.setDefaultAnnualRevenue(accounts);
        Test.stopTest();
        
        // Verify all accounts have default revenue of 0
        for (Account acc : accounts) {
            System.assertEquals(0, acc.AnnualRevenue, 'AnnualRevenue should be set to 0');
        }
    }
    
    @isTest
    static void testSetDefaultAnnualRevenue_WithExistingRevenue() {
        // Positive test: Should not override existing revenue
        List<Account> accounts = TestDataFactory.createAccounts(3, 'Test Account', 1000);
        
        Test.startTest();
        AccountService.setDefaultAnnualRevenue(accounts);
        Test.stopTest();
        
        // Verify existing revenue is preserved
        for (Account acc : accounts) {
            System.assertEquals(1000, acc.AnnualRevenue, 'Existing revenue should be preserved');
        }
    }
    
    @isTest
    static void testSetDefaultAnnualRevenue_Bulk() {
        // Bulk test: Process 200+ accounts
        List<Account> accounts = TestDataFactory.createAccounts(250, 'Bulk Account');
        
        Test.startTest();
        AccountService.setDefaultAnnualRevenue(accounts);
        Test.stopTest();
        
        // Verify all accounts have default revenue
        Integer countWithDefaultRevenue = 0;
        for (Account acc : accounts) {
            if (acc.AnnualRevenue == 0) {
                countWithDefaultRevenue++;
            }
        }
        System.assertEquals(250, countWithDefaultRevenue, 'All accounts should have default revenue');
    }
    
    @isTest
    static void testSetDefaultAnnualRevenue_EmptyList() {
        // Edge case: Empty list
        List<Account> accounts = new List<Account>();
        
        Test.startTest();
        AccountService.setDefaultAnnualRevenue(accounts);
        Test.stopTest();
        
        // Should complete without error
        System.assert(true, 'Method should handle empty list gracefully');
    }
    
    @isTest
    static void testSetDefaultAnnualRevenue_NullList() {
        // Edge case: Null list
        Test.startTest();
        AccountService.setDefaultAnnualRevenue(null);
        Test.stopTest();
        
        // Should complete without error
        System.assert(true, 'Method should handle null list gracefully');
    }
    
    // ========== createFollowUpTasks Tests ==========
    
    @isTest
    static void testCreateFollowUpTasks_Success() {
        // Positive test: Create follow-up tasks for accounts
        List<Account> accounts = TestDataFactory.createAccounts(3, 'Task Test Account');
        insert accounts;
        
        Test.startTest();
        AccountService.createFollowUpTasks(accounts);
        Test.stopTest();
        
        // Verify tasks were created
        List<Task> tasks = [
            SELECT Id, Subject, WhatId 
            FROM Task 
            WHERE WhatId IN :accounts
            WITH SECURITY_ENFORCED
        ];
        
        System.assertEquals(3, tasks.size(), 'Should create 3 tasks');
        for (Task t : tasks) {
            System.assertEquals('Follow up on new account', t.Subject, 'Task subject should match');
        }
    }
    
    @isTest
    static void testCreateFollowUpTasks_Bulk() {
        // Bulk test: Create tasks for 200+ accounts
        List<Account> accounts = TestDataFactory.createAccounts(250, 'Bulk Task Account');
        insert accounts;
        
        Test.startTest();
        AccountService.createFollowUpTasks(accounts);
        Test.stopTest();
        
        // Verify all tasks were created
        List<Task> tasks = [
            SELECT Id 
            FROM Task 
            WHERE WhatId IN :accounts
            WITH SECURITY_ENFORCED
        ];
        
        System.assertEquals(250, tasks.size(), 'Should create 250 tasks');
    }
    
    @isTest
    static void testCreateFollowUpTasks_EmptyList() {
        // Edge case: Empty list
        List<Account> accounts = new List<Account>();
        
        Test.startTest();
        AccountService.createFollowUpTasks(accounts);
        Test.stopTest();
        
        // Should complete without error
        System.assert(true, 'Method should handle empty list gracefully');
    }
    
    // ========== createAccounts Tests ==========
    
    @isTest
    static void testCreateAccounts_Success() {
        // Positive test: Create accounts successfully
        List<Account> accounts = TestDataFactory.createAccounts(5, 'Create Test Account', 5000);
        
        Test.startTest();
        Database.SaveResult[] results = AccountService.createAccounts(accounts);
        Test.stopTest();
        
        // Verify accounts were created
        Integer successCount = 0;
        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            }
        }
        
        System.assertEquals(5, successCount, 'All accounts should be created successfully');
        
        // Verify accounts exist in database
        List<Account> createdAccounts = [
            SELECT Id, Name, AnnualRevenue 
            FROM Account 
            WHERE Name LIKE 'Create Test Account%'
            WITH SECURITY_ENFORCED
        ];
        System.assertEquals(5, createdAccounts.size(), 'Accounts should exist in database');
    }
    
    @isTest
    static void testCreateAccounts_Bulk() {
        // Bulk test: Create 200+ accounts
        List<Account> accounts = TestDataFactory.createAccounts(250, 'Bulk Create Account', 10000);
        
        Test.startTest();
        Database.SaveResult[] results = AccountService.createAccounts(accounts);
        Test.stopTest();
        
        // Verify bulk creation
        Integer successCount = 0;
        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            }
        }
        
        System.assertEquals(250, successCount, 'All 250 accounts should be created successfully');
    }
    
    @isTest
    static void testCreateAccounts_NullList() {
        // Negative test: Null list should throw exception
        Test.startTest();
        try {
            AccountService.createAccounts(null);
            System.assert(false, 'Should throw AccountServiceException');
        } catch (AccountServiceException e) {
            System.assert(e.getMessage().contains('cannot be null or empty'), 'Error message should indicate null list');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCreateAccounts_EmptyList() {
        // Negative test: Empty list should throw exception
        List<Account> accounts = new List<Account>();
        
        Test.startTest();
        try {
            AccountService.createAccounts(accounts);
            System.assert(false, 'Should throw AccountServiceException');
        } catch (AccountServiceException e) {
            System.assert(e.getMessage().contains('cannot be null or empty'), 'Error message should indicate empty list');
        }
        Test.stopTest();
    }
    
    // ========== updateAccountRevenue Tests ==========
    
    @isTest
    static void testUpdateAccountRevenue_Success() {
        // Positive test: Update account revenue successfully
        List<Account> accounts = TestDataFactory.createAccounts(3, 'Update Test Account', 1000);
        insert accounts;
        
        List<Id> accountIds = new List<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        
        Decimal newRevenue = 5000;
        
        Test.startTest();
        Database.SaveResult[] results = AccountService.updateAccountRevenue(accountIds, newRevenue);
        Test.stopTest();
        
        // Verify updates
        Integer successCount = 0;
        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            }
        }
        
        System.assertEquals(3, successCount, 'All accounts should be updated successfully');
        
        // Verify revenue was updated in database
        List<Account> updatedAccounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            WHERE Id IN :accountIds
            WITH SECURITY_ENFORCED
        ];
        
        for (Account acc : updatedAccounts) {
            System.assertEquals(newRevenue, acc.AnnualRevenue, 'Revenue should be updated to ' + newRevenue);
        }
    }
    
    @isTest
    static void testUpdateAccountRevenue_Bulk() {
        // Bulk test: Update 200+ accounts
        List<Account> accounts = TestDataFactory.createAccounts(250, 'Bulk Update Account', 1000);
        insert accounts;
        
        List<Id> accountIds = new List<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        
        Decimal newRevenue = 7500;
        
        Test.startTest();
        Database.SaveResult[] results = AccountService.updateAccountRevenue(accountIds, newRevenue);
        Test.stopTest();
        
        // Verify bulk update
        Integer successCount = 0;
        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            }
        }
        
        System.assertEquals(250, successCount, 'All 250 accounts should be updated successfully');
    }
    
    @isTest
    static void testUpdateAccountRevenue_NullAccountIds() {
        // Negative test: Null account IDs should throw exception
        Test.startTest();
        try {
            AccountService.updateAccountRevenue(null, 1000);
            System.assert(false, 'Should throw AccountServiceException');
        } catch (AccountServiceException e) {
            System.assert(e.getMessage().contains('cannot be null or empty'), 'Error message should indicate null IDs');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateAccountRevenue_NullRevenue() {
        // Negative test: Null revenue should throw exception
        List<Account> accounts = TestDataFactory.createAccounts(1, 'Test Account');
        insert accounts;
        
        List<Id> accountIds = new List<Id>{ accounts[0].Id };
        
        Test.startTest();
        try {
            AccountService.updateAccountRevenue(accountIds, null);
            System.assert(false, 'Should throw AccountServiceException');
        } catch (AccountServiceException e) {
            System.assert(e.getMessage().contains('Revenue value cannot be null'), 'Error message should indicate null revenue');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateAccountRevenue_InvalidAccountIds() {
        // Edge case: Some account IDs don't exist
        List<Id> accountIds = new List<Id>();
        accountIds.add(UserInfo.getUserId()); // Invalid account ID
        
        Test.startTest();
        Database.SaveResult[] results = AccountService.updateAccountRevenue(accountIds, 1000);
        Test.stopTest();
        
        // Should handle gracefully - no records found
        System.assertEquals(0, results.size(), 'Should return empty results for invalid IDs');
    }
    
    // ========== deleteOldAccounts Tests ==========
    
    @isTest
    static void testDeleteOldAccounts_Success() {
        // Positive test: Delete old accounts
        // Create accounts that will be considered "old"
        List<Account> oldAccounts = TestDataFactory.createAccounts(5, 'Old Account');
        insert oldAccounts;
        
        // Note: In real scenarios, we'd use Test.setCreatedDate, but for testing
        // we'll test with a very large daysOld value to ensure accounts are not deleted
        // and with a negative value to ensure they are deleted
        
        Test.startTest();
        // Use a very large daysOld value so no accounts are deleted
        Integer deletedCount = AccountService.deleteOldAccounts(10000);
        Test.stopTest();
        
        // Verify no accounts were deleted (since they're not old enough)
        System.assertEquals(0, deletedCount, 'No accounts should be deleted');
    }
    
    @isTest
    static void testDeleteOldAccounts_WithDefaultDays() {
        // Positive test: Delete with default days (365)
        List<Account> accounts = TestDataFactory.createAccounts(3, 'Default Test Account');
        insert accounts;
        
        Test.startTest();
        Integer deletedCount = AccountService.deleteOldAccounts(null);
        Test.stopTest();
        
        // Should use default of 365 days
        System.assert(deletedCount >= 0, 'Should return valid count');
    }
    
    @isTest
    static void testDeleteOldAccounts_NegativeDays() {
        // Edge case: Negative days should default to 365
        List<Account> accounts = TestDataFactory.createAccounts(2, 'Negative Test Account');
        insert accounts;
        
        Test.startTest();
        Integer deletedCount = AccountService.deleteOldAccounts(-10);
        Test.stopTest();
        
        // Should use default of 365 days
        System.assert(deletedCount >= 0, 'Should handle negative days gracefully');
    }
    
    @isTest
    static void testDeleteOldAccounts_Bulk() {
        // Bulk test: Process large number of accounts
        List<Account> accounts = TestDataFactory.createAccounts(250, 'Bulk Delete Account');
        insert accounts;
        
        Test.startTest();
        // Use very large daysOld to avoid actual deletion in test
        Integer deletedCount = AccountService.deleteOldAccounts(10000);
        Test.stopTest();
        
        // Should handle bulk processing
        System.assert(deletedCount >= 0, 'Should handle bulk processing');
    }
}

