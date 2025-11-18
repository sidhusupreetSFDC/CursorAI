/**
 * Test class for AccountService
 * Provides comprehensive test coverage including positive, negative, bulk, and edge cases
 * Target: 90%+ code coverage
 */
@isTest
private class AccountServiceTest {
    
    @testSetup
    static void setupTestData() {
        // Create test accounts for various test scenarios
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            Account acc = new Account();
            acc.Name = 'Test Account ' + i;
            acc.AnnualRevenue = 1000 * (i + 1);
            testAccounts.add(acc);
        }
        insert testAccounts;
    }
    
    // ========== createAccounts Tests ==========
    
    @isTest
    static void testCreateAccounts_Positive_SingleRecord() {
        // Arrange
        List<Account> accounts = TestDataFactory.createAccounts(1, 'Test', 5000);
        
        Test.startTest();
        // Act
        Database.SaveResult[] results = AccountService.createAccounts(accounts);
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assert(results[0].isSuccess(), 'Account creation should succeed');
        
        // Verify account was created
        List<Account> createdAccounts = [SELECT Id, Name, AnnualRevenue FROM Account WHERE Name = 'Test 0'];
        System.assertEquals(1, createdAccounts.size(), 'Account should be created');
        System.assertEquals(5000, createdAccounts[0].AnnualRevenue, 'Revenue should match');
    }
    
    @isTest
    static void testCreateAccounts_Positive_BulkRecords() {
        // Arrange - Create 200+ records for bulk testing
        List<Account> accounts = TestDataFactory.createAccounts(250, 'Bulk Account', 10000);
        
        Test.startTest();
        // Act
        Database.SaveResult[] results = AccountService.createAccounts(accounts);
        Test.stopTest();
        
        // Assert
        System.assertEquals(250, results.size(), 'Should return 250 results');
        
        Integer successCount = 0;
        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            }
        }
        System.assertEquals(250, successCount, 'All accounts should be created successfully');
        
        // Verify accounts were created
        List<Account> createdAccounts = [SELECT Id FROM Account WHERE Name LIKE 'Bulk Account%'];
        System.assertEquals(250, createdAccounts.size(), '250 accounts should be created');
    }
    
    @isTest
    static void testCreateAccounts_Negative_NullList() {
        // Arrange
        List<Account> accounts = null;
        
        Test.startTest();
        // Act & Assert
        try {
            AccountService.createAccounts(accounts);
            System.assert(false, 'Should have thrown AccountServiceException');
        } catch (AccountServiceException e) {
            System.assert(e.getMessage().contains('null or empty'), 'Error message should mention null or empty');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCreateAccounts_Negative_EmptyList() {
        // Arrange
        List<Account> accounts = new List<Account>();
        
        Test.startTest();
        // Act & Assert
        try {
            AccountService.createAccounts(accounts);
            System.assert(false, 'Should have thrown AccountServiceException');
        } catch (AccountServiceException e) {
            System.assert(e.getMessage().contains('null or empty'), 'Error message should mention null or empty');
        }
        Test.stopTest();
    }
    
    // ========== createAccount Tests ==========
    
    @isTest
    static void testCreateAccount_Positive_Success() {
        // Arrange
        String accountName = 'Single Test Account';
        Decimal revenue = 7500;
        
        Test.startTest();
        // Act
        Id accountId = AccountService.createAccount(accountName, revenue);
        Test.stopTest();
        
        // Assert
        System.assertNotEquals(null, accountId, 'Account ID should not be null');
        
        Account createdAccount = [SELECT Id, Name, AnnualRevenue FROM Account WHERE Id = :accountId];
        System.assertEquals(accountName, createdAccount.Name, 'Account name should match');
        System.assertEquals(revenue, createdAccount.AnnualRevenue, 'Revenue should match');
    }
    
    @isTest
    static void testCreateAccount_Negative_BlankName() {
        // Arrange
        String accountName = '';
        Decimal revenue = 5000;
        
        Test.startTest();
        // Act & Assert
        try {
            AccountService.createAccount(accountName, revenue);
            System.assert(false, 'Should have thrown AccountServiceException');
        } catch (AccountServiceException e) {
            System.assert(e.getMessage().contains('blank'), 'Error message should mention blank');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCreateAccount_Negative_NullName() {
        // Arrange
        String accountName = null;
        Decimal revenue = 5000;
        
        Test.startTest();
        // Act & Assert
        try {
            AccountService.createAccount(accountName, revenue);
            System.assert(false, 'Should have thrown AccountServiceException');
        } catch (AccountServiceException e) {
            System.assert(e.getMessage().contains('blank'), 'Error message should mention blank');
        }
        Test.stopTest();
    }
    
    // ========== updateAccountRevenue Tests ==========
    
    @isTest
    static void testUpdateAccountRevenue_Positive_SingleRecord() {
        // Arrange
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Decimal newRevenue = 50000;
        
        Test.startTest();
        // Act
        Boolean result = AccountService.updateAccountRevenue(testAccount.Id, newRevenue);
        Test.stopTest();
        
        // Assert
        System.assert(result, 'Update should succeed');
        
        Account updatedAccount = [SELECT AnnualRevenue FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(newRevenue, updatedAccount.AnnualRevenue, 'Revenue should be updated');
    }
    
    @isTest
    static void testUpdateAccountRevenue_Positive_BulkRecords() {
        // Arrange
        List<Account> testAccounts = [SELECT Id FROM Account LIMIT 10];
        List<Id> accountIds = new List<Id>();
        for (Account acc : testAccounts) {
            accountIds.add(acc.Id);
        }
        Decimal newRevenue = 99999;
        
        Test.startTest();
        // Act
        Database.SaveResult[] results = AccountService.updateAccountRevenue(accountIds, newRevenue);
        Test.stopTest();
        
        // Assert
        System.assertEquals(10, results.size(), 'Should return 10 results');
        
        Integer successCount = 0;
        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            }
        }
        System.assertEquals(10, successCount, 'All updates should succeed');
        
        // Verify updates
        List<Account> updatedAccounts = [SELECT AnnualRevenue FROM Account WHERE Id IN :accountIds];
        for (Account acc : updatedAccounts) {
            System.assertEquals(newRevenue, acc.AnnualRevenue, 'All revenues should be updated');
        }
    }
    
    @isTest
    static void testUpdateAccountRevenue_Negative_NullAccountId() {
        // Arrange
        Id accountId = null;
        Decimal newRevenue = 5000;
        
        Test.startTest();
        // Act & Assert
        try {
            AccountService.updateAccountRevenue(accountId, newRevenue);
            System.assert(false, 'Should have thrown AccountServiceException');
        } catch (AccountServiceException e) {
            System.assert(e.getMessage().contains('null'), 'Error message should mention null');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateAccountRevenue_Negative_NullRevenue() {
        // Arrange
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Decimal newRevenue = null;
        
        Test.startTest();
        // Act & Assert
        try {
            AccountService.updateAccountRevenue(new List<Id>{ testAccount.Id }, newRevenue);
            System.assert(false, 'Should have thrown AccountServiceException');
        } catch (AccountServiceException e) {
            System.assert(e.getMessage().contains('null'), 'Error message should mention null');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateAccountRevenue_Negative_EmptyList() {
        // Arrange
        List<Id> accountIds = new List<Id>();
        Decimal newRevenue = 5000;
        
        Test.startTest();
        // Act & Assert
        try {
            AccountService.updateAccountRevenue(accountIds, newRevenue);
            System.assert(false, 'Should have thrown AccountServiceException');
        } catch (AccountServiceException e) {
            System.assert(e.getMessage().contains('null or empty'), 'Error message should mention null or empty');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testUpdateAccountRevenue_Negative_InvalidAccountId() {
        // Arrange
        Id invalidId = Test.getStandardPricebookId(); // Using a different object's ID
        Decimal newRevenue = 5000;
        
        Test.startTest();
        // Act & Assert
        try {
            AccountService.updateAccountRevenue(new List<Id>{ invalidId }, newRevenue);
            System.assert(false, 'Should have thrown AccountServiceException');
        } catch (AccountServiceException e) {
            System.assert(e.getMessage().contains('No accounts found'), 'Error message should mention no accounts found');
        }
        Test.stopTest();
    }
    
    // ========== deleteOldAccounts Tests ==========
    
    @isTest
    static void testDeleteOldAccounts_Positive_WithOldAccounts() {
        // Arrange - Create old accounts using Test.setCreatedDate
        List<Account> oldAccounts = TestDataFactory.createOldAccounts(5, 400);
        
        Test.startTest();
        // Act
        Database.DeleteResult[] results = AccountService.deleteOldAccounts(365);
        Test.stopTest();
        
        // Assert
        System.assert(results.size() > 0, 'Should have deleted some accounts');
        
        Integer successCount = 0;
        for (Database.DeleteResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            }
        }
        System.assert(successCount > 0, 'At least some deletions should succeed');
        
        // Verify accounts were deleted
        List<Account> remainingAccounts = [SELECT Id FROM Account WHERE Id IN :oldAccounts];
        System.assertEquals(0, remainingAccounts.size(), 'Old accounts should be deleted');
    }
    
    @isTest
    static void testDeleteOldAccounts_Positive_NoOldAccounts() {
        // Arrange - All accounts are new (created in @testSetup)
        
        Test.startTest();
        // Act
        Database.DeleteResult[] results = AccountService.deleteOldAccounts(365);
        Test.stopTest();
        
        // Assert
        System.assertEquals(0, results.size(), 'Should return empty results when no old accounts');
    }
    
    @isTest
    static void testDeleteOldAccounts_Positive_DefaultDays() {
        // Arrange - Create old accounts
        List<Account> oldAccounts = TestDataFactory.createOldAccounts(3, 400);
        
        Test.startTest();
        // Act - Use default 365 days
        Database.DeleteResult[] results = AccountService.deleteOldAccounts();
        Test.stopTest();
        
        // Assert
        System.assert(results.size() > 0, 'Should have deleted old accounts');
    }
    
    @isTest
    static void testDeleteOldAccounts_EdgeCase_NullDays() {
        // Arrange - Create old accounts
        List<Account> oldAccounts = TestDataFactory.createOldAccounts(3, 400);
        
        Test.startTest();
        // Act - Pass null, should default to 365
        Database.DeleteResult[] results = AccountService.deleteOldAccounts(null);
        Test.stopTest();
        
        // Assert
        System.assert(results.size() > 0, 'Should use default 365 days');
    }
    
    @isTest
    static void testDeleteOldAccounts_EdgeCase_NegativeDays() {
        // Arrange - Create old accounts
        List<Account> oldAccounts = TestDataFactory.createOldAccounts(3, 400);
        
        Test.startTest();
        // Act - Pass negative days, should default to 365
        Database.DeleteResult[] results = AccountService.deleteOldAccounts(-10);
        Test.stopTest();
        
        // Assert
        System.assert(results.size() > 0, 'Should use default 365 days');
    }
    
    // ========== createFollowUpTasks Tests ==========
    
    @isTest
    static void testCreateFollowUpTasks_Positive_SingleAccount() {
        // Arrange
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        List<Account> accounts = new List<Account>{ testAccount };
        
        Test.startTest();
        // Act
        Database.SaveResult[] results = AccountService.createFollowUpTasks(accounts);
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assert(results[0].isSuccess(), 'Task creation should succeed');
        
        // Verify task was created
        List<Task> tasks = [SELECT Id, Subject, WhatId FROM Task WHERE WhatId = :testAccount.Id];
        System.assertEquals(1, tasks.size(), 'One task should be created');
        System.assertEquals('Follow up on new account', tasks[0].Subject, 'Task subject should match');
    }
    
    @isTest
    static void testCreateFollowUpTasks_Positive_BulkAccounts() {
        // Arrange - Create 200+ accounts
        List<Account> accounts = TestDataFactory.createAndInsertAccounts(250, 'Bulk Task Account', 5000);
        
        Test.startTest();
        // Act
        Database.SaveResult[] results = AccountService.createFollowUpTasks(accounts);
        Test.stopTest();
        
        // Assert
        System.assertEquals(250, results.size(), 'Should return 250 results');
        
        Integer successCount = 0;
        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            }
        }
        System.assertEquals(250, successCount, 'All tasks should be created successfully');
        
        // Verify tasks were created
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId IN :accountIds];
        System.assertEquals(250, tasks.size(), '250 tasks should be created');
    }
    
    @isTest
    static void testCreateFollowUpTasks_EdgeCase_NullList() {
        // Arrange
        List<Account> accounts = null;
        
        Test.startTest();
        // Act
        Database.SaveResult[] results = AccountService.createFollowUpTasks(accounts);
        Test.stopTest();
        
        // Assert
        System.assertEquals(0, results.size(), 'Should return empty results');
    }
    
    @isTest
    static void testCreateFollowUpTasks_EdgeCase_EmptyList() {
        // Arrange
        List<Account> accounts = new List<Account>();
        
        Test.startTest();
        // Act
        Database.SaveResult[] results = AccountService.createFollowUpTasks(accounts);
        Test.stopTest();
        
        // Assert
        System.assertEquals(0, results.size(), 'Should return empty results');
    }
    
    @isTest
    static void testCreateFollowUpTasks_EdgeCase_AccountWithoutId() {
        // Arrange - Account without Id (not inserted)
        Account accountWithoutId = new Account();
        accountWithoutId.Name = 'Test Account';
        List<Account> accounts = new List<Account>{ accountWithoutId };
        
        Test.startTest();
        // Act
        Database.SaveResult[] results = AccountService.createFollowUpTasks(accounts);
        Test.stopTest();
        
        // Assert
        System.assertEquals(0, results.size(), 'Should return empty results when account has no Id');
        
        // Verify no tasks were created
        List<Task> tasks = [SELECT Id FROM Task];
        System.assertEquals(0, tasks.size(), 'No tasks should be created');
    }
}

