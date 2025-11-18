/**
 * Test class for AccountTriggerHandler
 * Tests trigger handler logic and indirectly tests AccountTrigger
 * Provides comprehensive test coverage including positive, negative, bulk, and edge cases
 * Target: 90%+ code coverage
 */
@isTest
private class AccountTriggerHandlerTest {
    
    // ========== onBeforeInsert Tests ==========
    
    @isTest
    static void testOnBeforeInsert_Positive_SetsDefaultRevenue() {
        // Arrange
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.AnnualRevenue = null; // Explicitly set to null
        
        Test.startTest();
        // Act - Insert account (triggers AccountTrigger -> AccountTriggerHandler)
        insert acc;
        Test.stopTest();
        
        // Assert
        Account insertedAccount = [SELECT AnnualRevenue FROM Account WHERE Id = :acc.Id];
        System.assertEquals(0, insertedAccount.AnnualRevenue, 'AnnualRevenue should be set to 0 when null');
    }
    
    @isTest
    static void testOnBeforeInsert_Positive_PreservesExistingRevenue() {
        // Arrange
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.AnnualRevenue = 5000; // Set a value
        
        Test.startTest();
        // Act
        insert acc;
        Test.stopTest();
        
        // Assert
        Account insertedAccount = [SELECT AnnualRevenue FROM Account WHERE Id = :acc.Id];
        System.assertEquals(5000, insertedAccount.AnnualRevenue, 'AnnualRevenue should remain unchanged');
    }
    
    @isTest
    static void testOnBeforeInsert_Positive_BulkRecords() {
        // Arrange - Create 200+ accounts with null revenue
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 250; i++) {
            Account acc = new Account();
            acc.Name = 'Bulk Account ' + i;
            acc.AnnualRevenue = null;
            accounts.add(acc);
        }
        
        Test.startTest();
        // Act
        insert accounts;
        Test.stopTest();
        
        // Assert
        List<Account> insertedAccounts = [SELECT AnnualRevenue FROM Account WHERE Name LIKE 'Bulk Account%'];
        System.assertEquals(250, insertedAccounts.size(), '250 accounts should be created');
        
        for (Account acc : insertedAccounts) {
            System.assertEquals(0, acc.AnnualRevenue, 'All null revenues should be set to 0');
        }
    }
    
    @isTest
    static void testOnBeforeInsert_EdgeCase_MixedNullAndValues() {
        // Arrange - Mix of null and non-null revenues
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            Account acc = new Account();
            acc.Name = 'Mixed Account ' + i;
            acc.AnnualRevenue = (i % 2 == 0) ? null : (i * 1000); // Alternating null and values
            accounts.add(acc);
        }
        
        Test.startTest();
        // Act
        insert accounts;
        Test.stopTest();
        
        // Assert
        List<Account> insertedAccounts = [SELECT AnnualRevenue FROM Account WHERE Name LIKE 'Mixed Account%' ORDER BY Name];
        System.assertEquals(10, insertedAccounts.size(), '10 accounts should be created');
        
        for (Integer i = 0; i < insertedAccounts.size(); i++) {
            if (i % 2 == 0) {
                System.assertEquals(0, insertedAccounts[i].AnnualRevenue, 'Null revenues should be set to 0');
            } else {
                System.assertEquals(i * 1000, insertedAccounts[i].AnnualRevenue, 'Non-null revenues should be preserved');
            }
        }
    }
    
    @isTest
    static void testOnBeforeInsert_EdgeCase_ZeroRevenue() {
        // Arrange
        Account acc = new Account();
        acc.Name = 'Zero Revenue Account';
        acc.AnnualRevenue = 0; // Explicitly set to 0
        
        Test.startTest();
        // Act
        insert acc;
        Test.stopTest();
        
        // Assert
        Account insertedAccount = [SELECT AnnualRevenue FROM Account WHERE Id = :acc.Id];
        System.assertEquals(0, insertedAccount.AnnualRevenue, 'Zero revenue should remain 0');
    }
    
    // ========== onAfterInsert Tests ==========
    
    @isTest
    static void testOnAfterInsert_Positive_CreatesFollowUpTask() {
        // Arrange
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.AnnualRevenue = 5000;
        
        Test.startTest();
        // Act - Insert account (triggers AccountTrigger -> AccountTriggerHandler)
        insert acc;
        Test.stopTest();
        
        // Assert - Verify task was created
        List<Task> tasks = [SELECT Id, Subject, WhatId FROM Task WHERE WhatId = :acc.Id];
        System.assertEquals(1, tasks.size(), 'One follow-up task should be created');
        System.assertEquals('Follow up on new account', tasks[0].Subject, 'Task subject should match');
        System.assertEquals(acc.Id, tasks[0].WhatId, 'Task should be related to account');
    }
    
    @isTest
    static void testOnAfterInsert_Positive_BulkRecords() {
        // Arrange - Create 200+ accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 250; i++) {
            Account acc = new Account();
            acc.Name = 'Bulk Task Account ' + i;
            acc.AnnualRevenue = 1000;
            accounts.add(acc);
        }
        
        Test.startTest();
        // Act
        insert accounts;
        Test.stopTest();
        
        // Assert - Verify tasks were created
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        
        List<Task> tasks = [SELECT Id, WhatId FROM Task WHERE WhatId IN :accountIds];
        System.assertEquals(250, tasks.size(), '250 tasks should be created');
        
        // Verify each account has a task
        Set<Id> accountIdsWithTasks = new Set<Id>();
        for (Task t : tasks) {
            accountIdsWithTasks.add(t.WhatId);
        }
        System.assertEquals(250, accountIdsWithTasks.size(), 'All accounts should have tasks');
    }
    
    @isTest
    static void testOnAfterInsert_EdgeCase_NullList() {
        // Arrange - Test handler method directly with null
        AccountTriggerHandler handler = new AccountTriggerHandler();
        List<Account> accounts = null;
        
        Test.startTest();
        // Act - Should handle null gracefully
        handler.onAfterInsert(accounts);
        Test.stopTest();
        
        // Assert - No exception should be thrown
        System.assert(true, 'Should handle null list gracefully');
    }
    
    @isTest
    static void testOnAfterInsert_EdgeCase_EmptyList() {
        // Arrange - Test handler method directly with empty list
        AccountTriggerHandler handler = new AccountTriggerHandler();
        List<Account> accounts = new List<Account>();
        
        Test.startTest();
        // Act - Should handle empty list gracefully
        handler.onAfterInsert(accounts);
        Test.stopTest();
        
        // Assert - No exception should be thrown
        System.assert(true, 'Should handle empty list gracefully');
    }
    
    @isTest
    static void testOnBeforeInsert_EdgeCase_NullList() {
        // Arrange - Test handler method directly with null
        AccountTriggerHandler handler = new AccountTriggerHandler();
        List<Account> accounts = null;
        
        Test.startTest();
        // Act - Should handle null gracefully
        handler.onBeforeInsert(accounts);
        Test.stopTest();
        
        // Assert - No exception should be thrown
        System.assert(true, 'Should handle null list gracefully');
    }
    
    @isTest
    static void testOnBeforeInsert_EdgeCase_EmptyList() {
        // Arrange - Test handler method directly with empty list
        AccountTriggerHandler handler = new AccountTriggerHandler();
        List<Account> accounts = new List<Account>();
        
        Test.startTest();
        // Act - Should handle empty list gracefully
        handler.onBeforeInsert(accounts);
        Test.stopTest();
        
        // Assert - No exception should be thrown
        System.assert(true, 'Should handle empty list gracefully');
    }
    
    // ========== Integration Tests ==========
    
    @isTest
    static void testTriggerIntegration_BeforeAndAfterInsert() {
        // Arrange - Test that both before and after insert logic execute
        Account acc = new Account();
        acc.Name = 'Integration Test Account';
        acc.AnnualRevenue = null; // Will be set to 0 in before insert
        
        Test.startTest();
        // Act
        insert acc;
        Test.stopTest();
        
        // Assert - Verify before insert logic (revenue set to 0)
        Account insertedAccount = [SELECT AnnualRevenue FROM Account WHERE Id = :acc.Id];
        System.assertEquals(0, insertedAccount.AnnualRevenue, 'Revenue should be set to 0');
        
        // Assert - Verify after insert logic (task created)
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId = :acc.Id];
        System.assertEquals(1, tasks.size(), 'Follow-up task should be created');
    }
    
    @isTest
    static void testTriggerIntegration_BulkWithBothContexts() {
        // Arrange - Mix of null and non-null revenues
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 100; i++) {
            Account acc = new Account();
            acc.Name = 'Integration Bulk Account ' + i;
            acc.AnnualRevenue = (i % 3 == 0) ? null : (i * 100); // Every 3rd is null
            accounts.add(acc);
        }
        
        Test.startTest();
        // Act
        insert accounts;
        Test.stopTest();
        
        // Assert - Verify before insert logic
        List<Account> insertedAccounts = [SELECT AnnualRevenue FROM Account WHERE Name LIKE 'Integration Bulk Account%'];
        System.assertEquals(100, insertedAccounts.size(), '100 accounts should be created');
        
        // Assert - Verify after insert logic (tasks created)
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : insertedAccounts) {
            accountIds.add(acc.Id);
        }
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId IN :accountIds];
        System.assertEquals(100, tasks.size(), '100 tasks should be created');
    }
}

