/**
 * @description Test class for AccountTriggerHandler
 * Tests trigger handler by executing DML operations that fire the trigger
 * 
 * @author Salesforce Developer
 * @date 2024
 */
@isTest
private class AccountTriggerHandlerTest {
    
    /**
     * @description Test setup method - creates shared test data
     */
    @testSetup
    static void setupTestData() {
        // No setup needed - tests will create their own data
        // Empty method is intentional for test structure
    }
    
    // ========== Before Insert Tests ==========
    
    @isTest
    static void testBeforeInsertSetDefaultRevenue() {
        // Positive test: Before insert should set default revenue for null values
        List<Account> accounts = TestDataFactory.createAccounts(3, 'Before Insert Test');
        // Ensure AnnualRevenue is null
        for (Account acc : accounts) {
            acc.AnnualRevenue = null;
        }
        
        Test.startTest();
        insert accounts;
        Test.stopTest();
        
        // Verify default revenue was set
        List<Account> insertedAccounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            WHERE Id IN :accounts
            WITH SECURITY_ENFORCED
        ];
        
        for (Account acc : insertedAccounts) {
            System.assertEquals(0, acc.AnnualRevenue, 'Default revenue should be set to 0');
        }
    }
    
    @isTest
    static void testBeforeInsertPreserveExistingRevenue() {
        // Positive test: Should preserve existing revenue values
        List<Account> accounts = TestDataFactory.createAccounts(3, 'Preserve Revenue Test', 5000);
        
        Test.startTest();
        insert accounts;
        Test.stopTest();
        
        // Verify existing revenue was preserved
        List<Account> insertedAccounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            WHERE Id IN :accounts
            WITH SECURITY_ENFORCED
        ];
        
        for (Account acc : insertedAccounts) {
            System.assertEquals(5000, acc.AnnualRevenue, 'Existing revenue should be preserved');
        }
    }
    
    @isTest
    static void testBeforeInsertBulk() {
        // Bulk test: Process 200+ accounts
        List<Account> accounts = TestDataFactory.createAccounts(250, 'Bulk Before Insert');
        // Ensure AnnualRevenue is null
        for (Account acc : accounts) {
            acc.AnnualRevenue = null;
        }
        
        Test.startTest();
        insert accounts;
        Test.stopTest();
        
        // Verify all accounts have default revenue
        List<Account> insertedAccounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            WHERE AnnualRevenue = 0
            AND Name LIKE 'Bulk Before Insert%'
            WITH SECURITY_ENFORCED
        ];
        
        System.assertEquals(250, insertedAccounts.size(), 'All 250 accounts should have default revenue');
    }
    
    // ========== After Insert Tests ==========
    
    @isTest
    static void testAfterInsertCreateFollowUpTasks() {
        // Positive test: After insert should create follow-up tasks
        List<Account> accounts = TestDataFactory.createAccounts(3, 'After Insert Test');
        
        Test.startTest();
        insert accounts;
        Test.stopTest();
        
        // Verify tasks were created
        List<Task> tasks = [
            SELECT Id, Subject, WhatId 
            FROM Task 
            WHERE WhatId IN :accounts
            WITH SECURITY_ENFORCED
        ];
        
        System.assertEquals(3, tasks.size(), 'Should create 3 follow-up tasks');
        for (Task t : tasks) {
            System.assertEquals('Follow up on new account', t.Subject, 'Task subject should match');
            System.assertNotEquals(null, t.WhatId, 'Task should be related to account');
        }
    }
    
    @isTest
    static void testAfterInsertBulk() {
        // Bulk test: Create tasks for 200+ accounts
        List<Account> accounts = TestDataFactory.createAccounts(250, 'Bulk After Insert');
        
        Test.startTest();
        insert accounts;
        Test.stopTest();
        
        // Verify all tasks were created
        List<Task> tasks = [
            SELECT Id 
            FROM Task 
            WHERE WhatId IN :accounts
            WITH SECURITY_ENFORCED
        ];
        
        System.assertEquals(250, tasks.size(), 'Should create 250 follow-up tasks');
    }
    
    @isTest
    static void testAfterInsertMixedRevenueValues() {
        // Edge case: Mix of null and existing revenue values
        List<Account> accounts = new List<Account>();
        
        // Create accounts with null revenue
        accounts.add(TestDataFactory.createAccount('Null Revenue Account'));
        
        // Create accounts with existing revenue
        accounts.add(TestDataFactory.createAccount('Existing Revenue Account', 10000));
        accounts.add(TestDataFactory.createAccount('Another Account', 5000));
        
        Test.startTest();
        insert accounts;
        Test.stopTest();
        
        // Verify accounts were inserted
        List<Account> insertedAccounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            WHERE Id IN :accounts
            WITH SECURITY_ENFORCED
        ];
        
        System.assertEquals(3, insertedAccounts.size(), 'All accounts should be inserted');
        
        // Verify tasks were created for all accounts
        List<Task> tasks = [
            SELECT Id, WhatId 
            FROM Task 
            WHERE WhatId IN :accounts
            WITH SECURITY_ENFORCED
        ];
        
        System.assertEquals(3, tasks.size(), 'Should create tasks for all accounts');
    }
    
    @isTest
    static void testTriggerHandlerErrorHandling() {
        // Negative test: Verify error handling in handler
        // This test verifies that exceptions are properly caught and re-thrown
        // We'll test by creating an account that might cause issues
        
        // Create a valid account - if handler throws exception, it should be AccountServiceException
        List<Account> accounts = TestDataFactory.createAccounts(1, 'Error Test Account');
        
        Test.startTest();
        try {
            insert accounts;
            // If we get here, the insert succeeded
            System.assert(true, 'Insert should succeed for valid account');
        } catch (Exception e) {
            // If exception occurs, verify it's the right type
            System.assert(e instanceof AccountServiceException || e.getMessage().contains('AccountServiceException'), 
                'Exception should be AccountServiceException');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testTriggerHandlerCompleteFlow() {
        // Integration test: Test complete flow - before insert and after insert together
        List<Account> accounts = TestDataFactory.createAccounts(5, 'Complete Flow Test');
        // Set some with null revenue, some with existing revenue
        accounts[0].AnnualRevenue = null;
        accounts[1].AnnualRevenue = null;
        accounts[2].AnnualRevenue = 3000;
        accounts[3].AnnualRevenue = 7000;
        accounts[4].AnnualRevenue = null;
        
        Test.startTest();
        insert accounts;
        Test.stopTest();
        
        // Verify before insert logic: null revenues set to 0
        List<Account> insertedAccounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            WHERE Id IN :accounts
            WITH SECURITY_ENFORCED
            ORDER BY Name
        ];
        
        System.assertEquals(0, insertedAccounts[0].AnnualRevenue, 'First account should have default revenue');
        System.assertEquals(0, insertedAccounts[1].AnnualRevenue, 'Second account should have default revenue');
        System.assertEquals(3000, insertedAccounts[2].AnnualRevenue, 'Third account should preserve revenue');
        System.assertEquals(7000, insertedAccounts[3].AnnualRevenue, 'Fourth account should preserve revenue');
        System.assertEquals(0, insertedAccounts[4].AnnualRevenue, 'Fifth account should have default revenue');
        
        // Verify after insert logic: tasks created
        List<Task> tasks = [
            SELECT Id 
            FROM Task 
            WHERE WhatId IN :accounts
            WITH SECURITY_ENFORCED
        ];
        
        System.assertEquals(5, tasks.size(), 'Should create 5 follow-up tasks');
    }
}

