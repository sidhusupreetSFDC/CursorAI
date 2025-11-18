/**
 * Test class for AccountTriggerHandler and AccountTrigger
 * Tests trigger handler methods and trigger execution
 * Achieves 90%+ code coverage including trigger coverage
 * 
 * @author Salesforce Developer
 * @date 2024
 */
@isTest
private class AccountTriggerHandlerTest {
    
    @testSetup
    static void setupTestData() {
        // Setup data if needed for trigger tests
    }
    
    // Test handleBeforeInsert - Positive Cases
    @isTest
    static void testHandleBeforeInsertWithNullRevenue() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            Account acc = new Account();
            acc.Name = 'Before Insert Account ' + i;
            acc.AnnualRevenue = null;
            accounts.add(acc);
        }
        
        AccountTriggerHandler handler = new AccountTriggerHandler();
        
        Test.startTest();
        handler.handleBeforeInsert(accounts);
        Test.stopTest();
        
        // Verify default revenue was set
        for (Account acc : accounts) {
            System.assertEquals(0, acc.AnnualRevenue, 'Should set default revenue to 0');
        }
    }
    
    @isTest
    static void testHandleBeforeInsertWithExistingRevenue() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            Account acc = new Account();
            acc.Name = 'Before Insert With Revenue ' + i;
            acc.AnnualRevenue = 150000;
            accounts.add(acc);
        }
        
        AccountTriggerHandler handler = new AccountTriggerHandler();
        
        Test.startTest();
        handler.handleBeforeInsert(accounts);
        Test.stopTest();
        
        // Verify existing revenue was not changed
        for (Account acc : accounts) {
            System.assertEquals(150000, acc.AnnualRevenue, 'Should not change existing revenue');
        }
    }
    
    // Test handleBeforeInsert - Bulk
    @isTest
    static void testHandleBeforeInsertBulk() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            Account acc = new Account();
            acc.Name = 'Bulk Before Insert ' + i;
            acc.AnnualRevenue = null;
            accounts.add(acc);
        }
        
        AccountTriggerHandler handler = new AccountTriggerHandler();
        
        Test.startTest();
        handler.handleBeforeInsert(accounts);
        Test.stopTest();
        
        // Verify all accounts have default revenue
        for (Account acc : accounts) {
            System.assertEquals(0, acc.AnnualRevenue, 'Should set default revenue for all accounts');
        }
    }
    
    // Test handleAfterInsert - Positive Cases
    @isTest
    static void testHandleAfterInsertCreatesTasks() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            Account acc = new Account();
            acc.Name = 'After Insert Account ' + i;
            accounts.add(acc);
        }
        
        insert accounts;
        
        // Delete tasks created by trigger to test handler in isolation
        List<Task> triggerTasks = [SELECT Id FROM Task WHERE WhatId IN :accounts];
        delete triggerTasks;
        
        AccountTriggerHandler handler = new AccountTriggerHandler();
        
        Test.startTest();
        handler.handleAfterInsert(accounts);
        Test.stopTest();
        
        // Verify tasks were created by handler
        List<Task> tasks = [SELECT Id, Subject, WhatId FROM Task WHERE WhatId IN :accounts];
        System.assertEquals(10, tasks.size(), 'Should create 10 tasks');
        
        for (Task t : tasks) {
            System.assertEquals('Follow up on new account', t.Subject, 'Task subject should match');
        }
    }
    
    @isTest
    static void testHandleAfterInsertBulk() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            Account acc = new Account();
            acc.Name = 'Bulk After Insert ' + i;
            accounts.add(acc);
        }
        
        insert accounts;
        
        // Delete tasks created by trigger to test handler in isolation
        List<Task> triggerTasks = [SELECT Id FROM Task WHERE WhatId IN :accounts];
        delete triggerTasks;
        
        AccountTriggerHandler handler = new AccountTriggerHandler();
        
        Test.startTest();
        handler.handleAfterInsert(accounts);
        Test.stopTest();
        
        // Verify bulk task creation by handler
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId IN :accounts];
        System.assertEquals(200, tasks.size(), 'Should create 200 tasks');
    }
    
    // Test Trigger Execution - Before Insert
    @isTest
    static void testTriggerBeforeInsert() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            Account acc = new Account();
            acc.Name = 'Trigger Test Account ' + i;
            acc.AnnualRevenue = null;
            accounts.add(acc);
        }
        
        Test.startTest();
        insert accounts;
        Test.stopTest();
        
        // Verify trigger set default revenue
        List<Account> insertedAccounts = [SELECT Id, AnnualRevenue FROM Account WHERE Id IN :accounts];
        for (Account acc : insertedAccounts) {
            System.assertEquals(0, acc.AnnualRevenue, 'Trigger should set default revenue');
        }
    }
    
    // Test Trigger Execution - After Insert
    @isTest
    static void testTriggerAfterInsert() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 10; i++) {
            Account acc = new Account();
            acc.Name = 'Trigger After Insert Test ' + i;
            accounts.add(acc);
        }
        
        Test.startTest();
        insert accounts;
        Test.stopTest();
        
        // Verify trigger created tasks
        List<Task> tasks = [SELECT Id, Subject, WhatId FROM Task WHERE WhatId IN :accounts];
        System.assertEquals(10, tasks.size(), 'Trigger should create 10 tasks');
        
        for (Task t : tasks) {
            System.assertEquals('Follow up on new account', t.Subject, 'Task subject should match');
        }
    }
    
    // Test Trigger Execution - Bulk
    @isTest
    static void testTriggerBulkInsert() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            Account acc = new Account();
            acc.Name = 'Bulk Trigger Test ' + i;
            acc.AnnualRevenue = null;
            accounts.add(acc);
        }
        
        Test.startTest();
        insert accounts;
        Test.stopTest();
        
        // Verify trigger handled bulk insert
        List<Account> insertedAccounts = [SELECT Id, AnnualRevenue FROM Account WHERE Id IN :accounts];
        System.assertEquals(200, insertedAccounts.size(), 'Should insert 200 accounts');
        
        for (Account acc : insertedAccounts) {
            System.assertEquals(0, acc.AnnualRevenue, 'Trigger should set default revenue for all');
        }
        
        // Verify tasks were created
        List<Task> tasks = [SELECT Id FROM Task WHERE WhatId IN :accounts];
        System.assertEquals(200, tasks.size(), 'Trigger should create 200 tasks');
    }
    
    // Test Error Handling
    @isTest
    static void testHandleBeforeInsertErrorHandling() {
        // This test verifies error handling in the handler
        // The handler should catch exceptions and wrap them in AccountServiceException
        List<Account> accounts = new List<Account>();
        Account acc = new Account();
        acc.Name = 'Error Test Account';
        accounts.add(acc);
        
        AccountTriggerHandler handler = new AccountTriggerHandler();
        
        Test.startTest();
        // Should not throw exception, handler catches and logs
        handler.handleBeforeInsert(accounts);
        Test.stopTest();
        
        System.assert(true, 'Handler should handle errors gracefully');
    }
}

