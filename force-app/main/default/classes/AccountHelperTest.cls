/**
 * @description Test class for AccountHelper
 * @author Salesforce Dev Team
 * @date 2025
 */
@isTest
public class AccountHelperTest {
    
    /**
     * @description Setup test data for all test methods
     */
    @TestSetup
    static void setupTestData() {
        // Create test accounts for various scenarios
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 50; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                Rating = 'Cold'
            ));
        }
        insert testAccounts;
    }
    
    /**
     * @description Test single account rating update - positive scenario
     */
    @isTest
    static void testUpdateSingleAccountRating_Success() {
        // Given: A test account
        Account acc = new Account(Name = 'Single Test Account');
        insert acc;
        
        // When: Update rating using single account method
        Test.startTest();
        Boolean result = AccountHelper.updateAccountRating(acc.Id, 'Hot');
        Test.stopTest();
        
        // Then: Verify the rating was updated successfully
        System.assertEquals(true, result, 'Update should succeed');
        
        Account updatedAcc = [SELECT Rating FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Hot', updatedAcc.Rating, 'Rating should be updated to Hot');
    }
    
    /**
     * @description Test single account rating update with null account ID
     */
    @isTest
    static void testUpdateSingleAccountRating_NullAccountId() {
        // When: Try to update with null account ID
        Test.startTest();
        Boolean result = AccountHelper.updateAccountRating(null, 'Hot');
        Test.stopTest();
        
        // Then: Should return false
        System.assertEquals(false, result, 'Should return false for null account ID');
    }
    
    /**
     * @description Test single account rating update with blank rating
     */
    @isTest
    static void testUpdateSingleAccountRating_BlankRating() {
        // Given: A test account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // When: Try to update with blank rating
        Test.startTest();
        Boolean result = AccountHelper.updateAccountRating(acc.Id, '');
        Test.stopTest();
        
        // Then: Should return false
        System.assertEquals(false, result, 'Should return false for blank rating');
    }
    
    /**
     * @description Test single account rating update with invalid rating
     */
    @isTest
    static void testUpdateSingleAccountRating_InvalidRating() {
        // Given: A test account
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        // When: Try to update with invalid rating
        Test.startTest();
        Boolean result = AccountHelper.updateAccountRating(acc.Id, 'InvalidRating');
        Test.stopTest();
        
        // Then: Should return false
        System.assertEquals(false, result, 'Should return false for invalid rating');
    }
    
    /**
     * @description Test bulk account rating update with 50 records
     */
    @isTest
    static void testUpdateAccountRatings_Bulk50Records() {
        // Given: 50 test accounts from setup
        List<Account> accounts = [SELECT Id FROM Account LIMIT 50];
        System.assertEquals(50, accounts.size(), 'Should have 50 test accounts');
        
        // Prepare bulk update map
        Map<Id, String> accountRatingMap = new Map<Id, String>();
        for (Account acc : accounts) {
            accountRatingMap.put(acc.Id, 'Hot');
        }
        
        // When: Update all accounts at once
        Test.startTest();
        Map<Id, String> results = AccountHelper.updateAccountRatings(accountRatingMap);
        Test.stopTest();
        
        // Then: Verify all updates succeeded
        System.assertEquals(50, results.size(), 'Should have results for all 50 accounts');
        
        for (Id accId : results.keySet()) {
            System.assertEquals('Success', results.get(accId), 
                'All updates should succeed. Failed for: ' + accId);
        }
        
        // Verify database state
        List<Account> updatedAccounts = [SELECT Id, Rating FROM Account WHERE Id IN :accountRatingMap.keySet()];
        for (Account acc : updatedAccounts) {
            System.assertEquals('Hot', acc.Rating, 'All accounts should have Hot rating');
        }
    }
    
    /**
     * @description Test bulk account rating update with 200 records (max limit)
     */
    @isTest
    static void testUpdateAccountRatings_Bulk200Records() {
        // Given: 200 test accounts
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            testAccounts.add(new Account(
                Name = 'Bulk Test Account ' + i,
                Rating = 'Cold'
            ));
        }
        insert testAccounts;
        
        // Prepare bulk update map
        Map<Id, String> accountRatingMap = new Map<Id, String>();
        for (Account acc : testAccounts) {
            accountRatingMap.put(acc.Id, 'Warm');
        }
        
        // When: Update all 200 accounts at once
        Test.startTest();
        Map<Id, String> results = AccountHelper.updateAccountRatings(accountRatingMap);
        Test.stopTest();
        
        // Then: Verify all updates succeeded
        System.assertEquals(200, results.size(), 'Should have results for all 200 accounts');
        
        Integer successCount = 0;
        for (String result : results.values()) {
            if (result == 'Success') {
                successCount++;
            }
        }
        System.assertEquals(200, successCount, 'All 200 updates should succeed');
        
        // Verify database state
        Integer warmCount = [SELECT COUNT() FROM Account WHERE Rating = 'Warm' AND Id IN :accountRatingMap.keySet()];
        System.assertEquals(200, warmCount, 'All 200 accounts should have Warm rating');
    }
    
    /**
     * @description Test bulk update exceeding 200 records limit
     */
    @isTest
    static void testUpdateAccountRatings_ExceedLimit() {
        // Given: Map with 201 entries
        Map<Id, String> accountRatingMap = new Map<Id, String>();
        for (Integer i = 0; i < 201; i++) {
            // Create fake IDs (won't be inserted, just for size validation)
            String fakeId = '001' + String.valueOf(i).leftPad(15, '0');
            accountRatingMap.put((Id)fakeId, 'Hot');
        }
        
        // When/Then: Should throw exception for exceeding limit
        Test.startTest();
        try {
            AccountHelper.updateAccountRatings(accountRatingMap);
            System.assert(false, 'Should have thrown AccountHelperException');
        } catch (AccountHelper.AccountHelperException e) {
            System.assert(e.getMessage().contains('Cannot process more than 200'), 
                'Exception message should mention the limit');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test bulk update with null map
     */
    @isTest
    static void testUpdateAccountRatings_NullMap() {
        // When: Call with null map
        Test.startTest();
        Map<Id, String> results = AccountHelper.updateAccountRatings(null);
        Test.stopTest();
        
        // Then: Should return empty map
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(0, results.size(), 'Results should be empty');
    }
    
    /**
     * @description Test bulk update with empty map
     */
    @isTest
    static void testUpdateAccountRatings_EmptyMap() {
        // When: Call with empty map
        Test.startTest();
        Map<Id, String> results = AccountHelper.updateAccountRatings(new Map<Id, String>());
        Test.stopTest();
        
        // Then: Should return empty map
        System.assertEquals(0, results.size(), 'Results should be empty');
    }
    
    /**
     * @description Test bulk update with non-existent account ID
     */
    @isTest
    static void testUpdateAccountRatings_NonExistentAccount() {
        // Given: A fake account ID that doesn't exist
        Id fakeId = '001000000000000AAA';
        Map<Id, String> accountRatingMap = new Map<Id, String>();
        accountRatingMap.put(fakeId, 'Hot');
        
        // When: Try to update non-existent account
        Test.startTest();
        Map<Id, String> results = AccountHelper.updateAccountRatings(accountRatingMap);
        Test.stopTest();
        
        // Then: Should have error message for that account
        System.assertEquals(1, results.size(), 'Should have one result');
        System.assert(results.get(fakeId).contains('not found'), 
            'Error message should indicate account not found');
    }
    
    /**
     * @description Test bulk update with mixed valid and invalid ratings
     */
    @isTest
    static void testUpdateAccountRatings_MixedValidInvalidRatings() {
        // Given: Two test accounts
        List<Account> accounts = [SELECT Id FROM Account LIMIT 2];
        
        Map<Id, String> accountRatingMap = new Map<Id, String>();
        accountRatingMap.put(accounts[0].Id, 'Hot');        // Valid
        accountRatingMap.put(accounts[1].Id, 'Invalid');    // Invalid
        
        // When: Update with mixed ratings
        Test.startTest();
        Map<Id, String> results = AccountHelper.updateAccountRatings(accountRatingMap);
        Test.stopTest();
        
        // Then: First should succeed, second should fail
        System.assertEquals('Success', results.get(accounts[0].Id), 
            'Valid rating should succeed');
        System.assert(results.get(accounts[1].Id).contains('Invalid rating'), 
            'Invalid rating should have error message');
    }
    
    /**
     * @description Test bulk update with blank rating values
     */
    @isTest
    static void testUpdateAccountRatings_BlankRatings() {
        // Given: Test account
        Account acc = [SELECT Id FROM Account LIMIT 1];
        
        Map<Id, String> accountRatingMap = new Map<Id, String>();
        accountRatingMap.put(acc.Id, '');
        
        // When: Try to update with blank rating
        Test.startTest();
        Map<Id, String> results = AccountHelper.updateAccountRatings(accountRatingMap);
        Test.stopTest();
        
        // Then: Should have error for blank rating
        System.assert(results.get(acc.Id).contains('cannot be blank'), 
            'Should have error message for blank rating');
    }
    
    /**
     * @description Test updateAccountRatingsForList with list of accounts
     */
    @isTest
    static void testUpdateAccountRatingsForList_Success() {
        // Given: List of 10 accounts
        List<Account> accounts = [SELECT Id, Rating FROM Account LIMIT 10];
        
        // When: Update all accounts with same rating
        Test.startTest();
        Map<Id, String> results = AccountHelper.updateAccountRatingsForList(accounts, 'Warm');
        Test.stopTest();
        
        // Then: All should succeed
        System.assertEquals(10, results.size(), 'Should have 10 results');
        
        for (String result : results.values()) {
            System.assertEquals('Success', result, 'All updates should succeed');
        }
        
        // Verify database
        List<Account> updatedAccounts = [SELECT Rating FROM Account WHERE Id IN :accounts];
        for (Account acc : updatedAccounts) {
            System.assertEquals('Warm', acc.Rating, 'Rating should be Warm');
        }
    }
    
    /**
     * @description Test updateAccountRatingsForList with null list
     */
    @isTest
    static void testUpdateAccountRatingsForList_NullList() {
        // When: Call with null list
        Test.startTest();
        Map<Id, String> results = AccountHelper.updateAccountRatingsForList(null, 'Hot');
        Test.stopTest();
        
        // Then: Should return empty map
        System.assertEquals(0, results.size(), 'Should return empty map');
    }
    
    /**
     * @description Test updateAccountRatingsForList with blank rating
     */
    @isTest
    static void testUpdateAccountRatingsForList_BlankRating() {
        // Given: List of accounts
        List<Account> accounts = [SELECT Id FROM Account LIMIT 5];
        
        // When: Call with blank rating
        Test.startTest();
        Map<Id, String> results = AccountHelper.updateAccountRatingsForList(accounts, '');
        Test.stopTest();
        
        // Then: Should return empty map
        System.assertEquals(0, results.size(), 'Should return empty map for blank rating');
    }
    
    /**
     * @description Test isValidRating private method using different values
     */
    @isTest
    static void testIsValidRating() {
        // Test valid ratings
        Account acc = new Account(Name = 'Test');
        insert acc;
        
        Test.startTest();
        // Valid ratings should succeed
        Boolean hotResult = AccountHelper.updateAccountRating(acc.Id, 'Hot');
        System.assertEquals(true, hotResult, 'Hot should be valid');
        
        Boolean warmResult = AccountHelper.updateAccountRating(acc.Id, 'Warm');
        System.assertEquals(true, warmResult, 'Warm should be valid');
        
        Boolean coldResult = AccountHelper.updateAccountRating(acc.Id, 'Cold');
        System.assertEquals(true, coldResult, 'Cold should be valid');
        
        // Invalid rating should fail
        Boolean invalidResult = AccountHelper.updateAccountRating(acc.Id, 'SuperHot');
        System.assertEquals(false, invalidResult, 'SuperHot should be invalid');
        Test.stopTest();
    }
}