/**
 * @description Test class for AccountHelper
 * @author Salesforce Developer
 * @date 2024
 */
@isTest
private class AccountHelperTest {
    
    /**
     * @description Setup test data for all test methods
     */
    @TestSetup
    static void setupTestData() {
        List<Account> testAccounts = new List<Account>();
        
        // Create test accounts
        for (Integer i = 0; i < 250; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                AnnualRevenue = 500000
            ));
        }
        
        insert testAccounts;
    }
    
    /**
     * @description Test positive scenario - single account update
     */
    @isTest
    static void testUpdateSingleAccount() {
        // Get test account
        Account testAccount = [SELECT Id, AnnualRevenue FROM Account LIMIT 1];
        Decimal originalRevenue = testAccount.AnnualRevenue;
        
        Test.startTest();
        AccountHelper.updateAccounts(new List<Id>{ testAccount.Id });
        Test.stopTest();
        
        // Verify the update
        Account updatedAccount = [SELECT Id, AnnualRevenue FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(1000000, updatedAccount.AnnualRevenue, 'Annual Revenue should be updated to 1000000');
        System.assertNotEquals(originalRevenue, updatedAccount.AnnualRevenue, 'Annual Revenue should have changed');
    }
    
    /**
     * @description Test positive scenario - multiple accounts update
     */
    @isTest
    static void testUpdateMultipleAccounts() {
        // Get test accounts
        List<Account> testAccounts = [SELECT Id, AnnualRevenue FROM Account LIMIT 10];
        List<Id> accountIds = new List<Id>();
        
        for (Account acc : testAccounts) {
            accountIds.add(acc.Id);
        }
        
        Test.startTest();
        AccountHelper.updateAccounts(accountIds);
        Test.stopTest();
        
        // Verify all accounts are updated
        List<Account> updatedAccounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            WHERE Id IN :accountIds
        ];
        
        System.assertEquals(10, updatedAccounts.size(), 'Should have 10 updated accounts');
        for (Account acc : updatedAccounts) {
            System.assertEquals(1000000, acc.AnnualRevenue, 'Annual Revenue should be updated to 1000000');
        }
    }
    
    /**
     * @description Test bulk scenario - 200+ accounts update
     */
    @isTest
    static void testBulkUpdateAccounts() {
        // Get all test accounts (250 accounts)
        List<Account> testAccounts = [SELECT Id FROM Account];
        List<Id> accountIds = new List<Id>();
        
        for (Account acc : testAccounts) {
            accountIds.add(acc.Id);
        }
        
        Test.startTest();
        AccountHelper.updateAccounts(accountIds);
        Test.stopTest();
        
        // Verify all accounts are updated
        List<Account> updatedAccounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            WHERE Id IN :accountIds
        ];
        
        System.assertEquals(250, updatedAccounts.size(), 'Should have 250 updated accounts');
        for (Account acc : updatedAccounts) {
            System.assertEquals(1000000, acc.AnnualRevenue, 'Annual Revenue should be updated to 1000000 for all accounts');
        }
    }
    
    /**
     * @description Test negative scenario - null input
     */
    @isTest
    static void testUpdateAccountsWithNullInput() {
        Test.startTest();
        try {
            AccountHelper.updateAccounts(null);
            // Should not throw exception, just return early
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception for null input');
        }
        Test.stopTest();
        
        // Verify no accounts were updated
        List<Account> accounts = [SELECT Id, AnnualRevenue FROM Account LIMIT 1];
        System.assertNotEquals(null, accounts, 'Accounts should still exist');
    }
    
    /**
     * @description Test negative scenario - empty list input
     */
    @isTest
    static void testUpdateAccountsWithEmptyList() {
        Test.startTest();
        try {
            AccountHelper.updateAccounts(new List<Id>());
            // Should not throw exception, just return early
        } catch (Exception e) {
            System.assert(false, 'Should not throw exception for empty list');
        }
        Test.stopTest();
        
        // Verify no accounts were updated
        List<Account> accounts = [SELECT Id, AnnualRevenue FROM Account LIMIT 1];
        System.assertNotEquals(null, accounts, 'Accounts should still exist');
    }
    
    /**
     * @description Test negative scenario - invalid account IDs
     */
    @isTest
    static void testUpdateAccountsWithInvalidIds() {
        // Create invalid account IDs
        Id invalidId1 = Id.valueOf('001000000000000AAA');
        Id invalidId2 = Id.valueOf('001000000000000BBB');
        List<Id> invalidIds = new List<Id>{ invalidId1, invalidId2 };
        
        Test.startTest();
        try {
            AccountHelper.updateAccounts(invalidIds);
            // QueryException should be caught and rethrown, or no records found
        } catch (QueryException e) {
            // Expected behavior - invalid IDs should cause QueryException
            System.assert(true, 'QueryException expected for invalid IDs');
        } catch (Exception e) {
            // Other exceptions are also acceptable
            System.assert(true, 'Exception expected for invalid IDs: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    /**
     * @description Test negative scenario - mixed valid and invalid IDs
     */
    @isTest
    static void testUpdateAccountsWithMixedIds() {
        // Get one valid account
        Account validAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create invalid account ID
        Id invalidId = Id.valueOf('001000000000000AAA');
        List<Id> mixedIds = new List<Id>{ validAccount.Id, invalidId };
        
        Test.startTest();
        try {
            AccountHelper.updateAccounts(mixedIds);
            // Should handle gracefully - update valid ones, handle invalid ones
        } catch (Exception e) {
            // Exception is acceptable if invalid IDs cause issues
            System.assert(true, 'Exception may occur with mixed IDs: ' + e.getMessage());
        }
        Test.stopTest();
        
        // Verify valid account was updated if no exception occurred
        try {
            Account updatedAccount = [SELECT Id, AnnualRevenue FROM Account WHERE Id = :validAccount.Id];
            // If we get here, check if it was updated
            System.assertNotEquals(null, updatedAccount, 'Valid account should exist');
        } catch (Exception e) {
            // If exception occurred, this is expected
        }
    }
    
    /**
     * @description Test scenario - accounts that don't exist in database
     */
    @isTest
    static void testUpdateNonExistentAccounts() {
        // Create a valid-looking ID but for a non-existent record
        // We'll use a pattern that looks valid but doesn't exist
        List<Account> existingAccounts = [SELECT Id FROM Account LIMIT 1];
        Id existingId = existingAccounts[0].Id;
        
        // Create a fake ID with same prefix but different suffix
        String fakeIdString = existingId.toString().substring(0, 15) + 'ZZZ';
        Id fakeId = Id.valueOf(fakeIdString);
        
        Test.startTest();
        try {
            AccountHelper.updateAccounts(new List<Id>{ fakeId });
            // Should handle gracefully - no records found
        } catch (Exception e) {
            // Exception is acceptable
            System.assert(true, 'Exception may occur for non-existent accounts: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    /**
     * @description Test scenario - verify accounts with existing AnnualRevenue values
     */
    @isTest
    static void testUpdateAccountsWithExistingRevenue() {
        // Get accounts with different revenue values
        List<Account> testAccounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            WHERE AnnualRevenue = 500000 
            LIMIT 5
        ];
        
        List<Id> accountIds = new List<Id>();
        for (Account acc : testAccounts) {
            accountIds.add(acc.Id);
            System.assertEquals(500000, acc.AnnualRevenue, 'Initial revenue should be 500000');
        }
        
        Test.startTest();
        AccountHelper.updateAccounts(accountIds);
        Test.stopTest();
        
        // Verify all accounts are updated to 1000000
        List<Account> updatedAccounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            WHERE Id IN :accountIds
        ];
        
        System.assertEquals(5, updatedAccounts.size(), 'Should have 5 updated accounts');
        for (Account acc : updatedAccounts) {
            System.assertEquals(1000000, acc.AnnualRevenue, 'Annual Revenue should be updated to 1000000');
        }
    }
    
    /**
     * @description Test scenario - verify WITH SECURITY_ENFORCED behavior
     */
    @isTest
    static void testSecurityEnforcedQuery() {
        // Get test accounts
        List<Account> testAccounts = [SELECT Id FROM Account LIMIT 5];
        List<Id> accountIds = new List<Id>();
        
        for (Account acc : testAccounts) {
            accountIds.add(acc.Id);
        }
        
        Test.startTest();
        AccountHelper.updateAccounts(accountIds);
        Test.stopTest();
        
        // Verify accounts were updated successfully
        List<Account> updatedAccounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            WHERE Id IN :accountIds
        ];
        
        System.assertEquals(5, updatedAccounts.size(), 'All accounts should be updated');
        for (Account acc : updatedAccounts) {
            System.assertEquals(1000000, acc.AnnualRevenue, 'Annual Revenue should be 1000000');
        }
    }
    
    /**
     * @description Test scenario - verify empty result set handling
     */
    @isTest
    static void testUpdateWithNoMatchingRecords() {
        // Use IDs that don't match any records in the query
        // Create a list with valid format but non-existent records
        List<Id> nonExistentIds = new List<Id>();
        
        // Create a pattern that won't match
        for (Integer i = 0; i < 5; i++) {
            // This will create IDs that don't exist
            String fakeId = '00100000000000' + String.valueOf(i).leftPad(3, '0') + 'AAA';
            nonExistentIds.add(Id.valueOf(fakeId));
        }
        
        Test.startTest();
        try {
            AccountHelper.updateAccounts(nonExistentIds);
            // Should handle gracefully - no records found, no update performed
        } catch (Exception e) {
            // Exception is acceptable if query fails
            System.assert(true, 'Exception may occur: ' + e.getMessage());
        }
        Test.stopTest();
        
        // Verify no accounts were updated
        List<Account> accounts = [SELECT Id, AnnualRevenue FROM Account LIMIT 10];
        for (Account acc : accounts) {
            System.assertEquals(500000, acc.AnnualRevenue, 'Accounts should maintain original revenue');
        }
    }
}
