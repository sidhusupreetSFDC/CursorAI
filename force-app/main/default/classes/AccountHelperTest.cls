/**
 * @description Test class for AccountHelper
 * Provides comprehensive test coverage for all AccountHelper methods including
 * single account updates, bulk operations, validation, and error handling
 * @author Salesforce Dev Team
 * @date 2025
 */
@isTest
private class AccountHelperTest {
    
    private static final String VALID_RATING_HOT = 'Hot';
    private static final String VALID_RATING_WARM = 'Warm';
    private static final String VALID_RATING_COLD = 'Cold';
    private static final String INVALID_RATING = 'InvalidRating';
    private static final Integer SETUP_ACCOUNT_COUNT = 50;
    private static final Integer BULK_TEST_COUNT = 200;
    
    /**
     * @description Setup test data for all test methods
     * Creates 50 test accounts with Cold rating for use across test methods
     */
    @TestSetup
    static void setupTestData() {
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < SETUP_ACCOUNT_COUNT; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                Rating = VALID_RATING_COLD
            ));
        }
        insert testAccounts;
    }
    
    /**
     * @description Test single account rating update - positive scenario
     * Verifies successful update of account rating with valid input
     */
    @isTest
    static void testUpdateSingleAccountRating_Success() {
        // Arrange: Create a test account
        Account testAccount = new Account(Name = 'Single Test Account');
        insert testAccount;
        
        // Act: Update rating using single account method
        Test.startTest();
        Boolean result = AccountHelper.updateAccountRating(testAccount.Id, VALID_RATING_HOT);
        Test.stopTest();
        
        // Assert: Verify the rating was updated successfully
        System.assertEquals(true, result, 'Update should succeed');
        
        Account updatedAccount = [SELECT Rating FROM Account WHERE Id = :testAccount.Id LIMIT 1];
        System.assertEquals(VALID_RATING_HOT, updatedAccount.Rating, 
            'Rating should be updated to Hot');
    }
    
    /**
     * @description Test single account rating update with null account ID
     * Verifies method handles null account ID gracefully
     */
    @isTest
    static void testUpdateSingleAccountRating_NullAccountId() {
        // Act: Try to update with null account ID
        Test.startTest();
        Boolean result = AccountHelper.updateAccountRating(null, VALID_RATING_HOT);
        Test.stopTest();
        
        // Assert: Should return false
        System.assertEquals(false, result, 'Should return false for null account ID');
    }
    
    /**
     * @description Test single account rating update with blank rating
     * Verifies method rejects blank rating values
     */
    @isTest
    static void testUpdateSingleAccountRating_BlankRating() {
        // Arrange: Create a test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Act: Try to update with blank rating
        Test.startTest();
        Boolean result = AccountHelper.updateAccountRating(testAccount.Id, '');
        Test.stopTest();
        
        // Assert: Should return false
        System.assertEquals(false, result, 'Should return false for blank rating');
    }
    
    /**
     * @description Test single account rating update with invalid rating
     * Verifies method rejects invalid rating values
     */
    @isTest
    static void testUpdateSingleAccountRating_InvalidRating() {
        // Arrange: Create a test account
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;
        
        // Act: Try to update with invalid rating
        Test.startTest();
        Boolean result = AccountHelper.updateAccountRating(testAccount.Id, INVALID_RATING);
        Test.stopTest();
        
        // Assert: Should return false
        System.assertEquals(false, result, 'Should return false for invalid rating');
    }
    
    /**
     * @description Test bulk account rating update with 50 records
     * Verifies bulk update functionality with moderate record count
     */
    @isTest
    static void testUpdateAccountRatings_Bulk50Records() {
        // Arrange: Get 50 test accounts from setup
        List<Account> accounts = [SELECT Id FROM Account LIMIT :SETUP_ACCOUNT_COUNT];
        System.assertEquals(SETUP_ACCOUNT_COUNT, accounts.size(), 
            'Should have ' + SETUP_ACCOUNT_COUNT + ' test accounts');
        
        Map<Id, String> accountRatingMap = new Map<Id, String>();
        for (Account acc : accounts) {
            accountRatingMap.put(acc.Id, VALID_RATING_HOT);
        }
        
        // Act: Update all accounts at once
        Test.startTest();
        Map<Id, String> results = AccountHelper.updateAccountRatings(accountRatingMap);
        Test.stopTest();
        
        // Assert: Verify all updates succeeded
        System.assertEquals(SETUP_ACCOUNT_COUNT, results.size(), 
            'Should have results for all ' + SETUP_ACCOUNT_COUNT + ' accounts');
        
        for (Id accId : results.keySet()) {
            System.assertEquals('Success', results.get(accId), 
                'All updates should succeed. Failed for: ' + accId);
        }
        
        // Verify database state
        List<Account> updatedAccounts = [
            SELECT Id, Rating 
            FROM Account 
            WHERE Id IN :accountRatingMap.keySet()
        ];
        for (Account acc : updatedAccounts) {
            System.assertEquals(VALID_RATING_HOT, acc.Rating, 
                'All accounts should have Hot rating');
        }
    }
    
    /**
     * @description Test bulk account rating update with 200 records (max limit)
     * Verifies bulk update functionality at maximum supported record count
     */
    @isTest
    static void testUpdateAccountRatings_Bulk200Records() {
        // Arrange: Create 200 test accounts
        List<Account> testAccounts = new List<Account>();
        for (Integer i = 0; i < BULK_TEST_COUNT; i++) {
            testAccounts.add(new Account(
                Name = 'Bulk Test Account ' + i,
                Rating = VALID_RATING_COLD
            ));
        }
        insert testAccounts;
        
        Map<Id, String> accountRatingMap = new Map<Id, String>();
        for (Account acc : testAccounts) {
            accountRatingMap.put(acc.Id, VALID_RATING_WARM);
        }
        
        // Act: Update all accounts at once
        Test.startTest();
        Map<Id, String> results = AccountHelper.updateAccountRatings(accountRatingMap);
        Test.stopTest();
        
        // Assert: Verify all updates succeeded
        System.assertEquals(BULK_TEST_COUNT, results.size(), 
            'Should have results for all ' + BULK_TEST_COUNT + ' accounts');
        
        Integer successCount = 0;
        for (String result : results.values()) {
            if (result == 'Success') {
                successCount++;
            }
        }
        System.assertEquals(BULK_TEST_COUNT, successCount, 
            'All ' + BULK_TEST_COUNT + ' updates should succeed');
        
        // Verify database state
        Integer warmCount = [
            SELECT COUNT() 
            FROM Account 
            WHERE Rating = :VALID_RATING_WARM 
            AND Id IN :accountRatingMap.keySet()
        ];
        System.assertEquals(BULK_TEST_COUNT, warmCount, 
            'All ' + BULK_TEST_COUNT + ' accounts should have Warm rating');
    }
    
    /**
     * @description Test bulk update exceeding 200 records limit
     * Verifies exception is thrown when attempting to process more than maximum allowed records
     */
    @isTest
    static void testUpdateAccountRatings_ExceedLimit() {
        // Arrange: Create map with 201 entries (exceeds limit)
        Map<Id, String> accountRatingMap = new Map<Id, String>();
        Integer exceedLimitCount = BULK_TEST_COUNT + 1;
        for (Integer i = 0; i < exceedLimitCount; i++) {
            // Create fake IDs (won't be inserted, just for size validation)
            String fakeId = '001' + String.valueOf(i).leftPad(15, '0');
            accountRatingMap.put((Id)fakeId, VALID_RATING_HOT);
        }
        
        // Act & Assert: Should throw exception for exceeding limit
        Test.startTest();
        try {
            AccountHelper.updateAccountRatings(accountRatingMap);
            System.assert(false, 'Should have thrown AccountHelperException');
        } catch (AccountHelper.AccountHelperException e) {
            System.assert(e.getMessage().contains('Cannot process more than ' + BULK_TEST_COUNT), 
                'Exception message should mention the limit');
        }
        Test.stopTest();
    }
    
    /**
     * @description Test bulk update with null map
     * Verifies method handles null input gracefully
     */
    @isTest
    static void testUpdateAccountRatings_NullMap() {
        // Act: Call with null map
        Test.startTest();
        Map<Id, String> results = AccountHelper.updateAccountRatings(null);
        Test.stopTest();
        
        // Assert: Should return empty map
        System.assertNotEquals(null, results, 'Results should not be null');
        System.assertEquals(0, results.size(), 'Results should be empty');
    }
    
    /**
     * @description Test bulk update with empty map
     * Verifies method handles empty input gracefully
     */
    @isTest
    static void testUpdateAccountRatings_EmptyMap() {
        // Act: Call with empty map
        Test.startTest();
        Map<Id, String> results = AccountHelper.updateAccountRatings(new Map<Id, String>());
        Test.stopTest();
        
        // Assert: Should return empty map
        System.assertEquals(0, results.size(), 'Results should be empty');
    }
    
    /**
     * @description Test bulk update with non-existent account ID
     * Verifies method handles non-existent account IDs gracefully
     */
    @isTest
    static void testUpdateAccountRatings_NonExistentAccount() {
        // Arrange: Create a fake account ID that doesn't exist
        Id fakeId = '001000000000000AAA';
        Map<Id, String> accountRatingMap = new Map<Id, String>();
        accountRatingMap.put(fakeId, VALID_RATING_HOT);
        
        // Act: Try to update non-existent account
        Test.startTest();
        Map<Id, String> results = AccountHelper.updateAccountRatings(accountRatingMap);
        Test.stopTest();
        
        // Assert: Should have error message for that account
        System.assertEquals(1, results.size(), 'Should have one result');
        System.assert(results.get(fakeId).contains('not found'), 
            'Error message should indicate account not found');
    }
    
    /**
     * @description Test bulk update with mixed valid and invalid ratings
     * Verifies partial success handling when some ratings are valid and others invalid
     */
    @isTest
    static void testUpdateAccountRatings_MixedValidInvalidRatings() {
        // Arrange: Get two test accounts
        List<Account> accounts = [SELECT Id FROM Account LIMIT 2];
        System.assert(accounts.size() >= 2, 'Should have at least 2 test accounts');
        
        Map<Id, String> accountRatingMap = new Map<Id, String>();
        accountRatingMap.put(accounts[0].Id, VALID_RATING_HOT);        // Valid
        accountRatingMap.put(accounts[1].Id, INVALID_RATING);        // Invalid
        
        // Act: Update with mixed ratings
        Test.startTest();
        Map<Id, String> results = AccountHelper.updateAccountRatings(accountRatingMap);
        Test.stopTest();
        
        // Assert: First should succeed, second should fail
        System.assertEquals('Success', results.get(accounts[0].Id), 
            'Valid rating should succeed');
        System.assert(results.get(accounts[1].Id).contains('Invalid rating'), 
            'Invalid rating should have error message');
    }
    
    /**
     * @description Test bulk update with blank rating values
     * Verifies method rejects blank rating values in bulk operations
     */
    @isTest
    static void testUpdateAccountRatings_BlankRatings() {
        // Arrange: Get a test account
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Map<Id, String> accountRatingMap = new Map<Id, String>();
        accountRatingMap.put(testAccount.Id, '');
        
        // Act: Try to update with blank rating
        Test.startTest();
        Map<Id, String> results = AccountHelper.updateAccountRatings(accountRatingMap);
        Test.stopTest();
        
        // Assert: Should have error for blank rating
        System.assert(results.get(testAccount.Id).contains('cannot be blank'), 
            'Should have error message for blank rating');
    }
    
    /**
     * @description Test updateAccountRatingsForList with list of accounts
     * Verifies list-based bulk update functionality
     */
    @isTest
    static void testUpdateAccountRatingsForList_Success() {
        // Arrange: Get list of 10 accounts
        Integer accountCount = 10;
        List<Account> accounts = [SELECT Id, Rating FROM Account LIMIT :accountCount];
        
        // Act: Update all accounts with same rating
        Test.startTest();
        Map<Id, String> results = AccountHelper.updateAccountRatingsForList(accounts, VALID_RATING_WARM);
        Test.stopTest();
        
        // Assert: All should succeed
        System.assertEquals(accountCount, results.size(), 'Should have ' + accountCount + ' results');
        
        for (String result : results.values()) {
            System.assertEquals('Success', result, 'All updates should succeed');
        }
        
        // Verify database state
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : accounts) {
            accountIds.add(acc.Id);
        }
        List<Account> updatedAccounts = [
            SELECT Rating 
            FROM Account 
            WHERE Id IN :accountIds
        ];
        for (Account acc : updatedAccounts) {
            System.assertEquals(VALID_RATING_WARM, acc.Rating, 'Rating should be Warm');
        }
    }
    
    /**
     * @description Test updateAccountRatingsForList with null list
     * Verifies method handles null list input gracefully
     */
    @isTest
    static void testUpdateAccountRatingsForList_NullList() {
        // Act: Call with null list
        Test.startTest();
        Map<Id, String> results = AccountHelper.updateAccountRatingsForList(null, VALID_RATING_HOT);
        Test.stopTest();
        
        // Assert: Should return empty map
        System.assertEquals(0, results.size(), 'Should return empty map');
    }
    
    /**
     * @description Test updateAccountRatingsForList with blank rating
     * Verifies method rejects blank rating values
     */
    @isTest
    static void testUpdateAccountRatingsForList_BlankRating() {
        // Arrange: Get list of accounts
        List<Account> accounts = [SELECT Id FROM Account LIMIT 5];
        
        // Act: Call with blank rating
        Test.startTest();
        Map<Id, String> results = AccountHelper.updateAccountRatingsForList(accounts, '');
        Test.stopTest();
        
        // Assert: Should return empty map
        System.assertEquals(0, results.size(), 'Should return empty map for blank rating');
    }
    
    /**
     * @description Test rating validation using different values
     * Verifies all valid ratings are accepted and invalid ratings are rejected
     */
    @isTest
    static void testRatingValidation() {
        // Arrange: Create a test account
        Account testAccount = new Account(Name = 'Rating Validation Test');
        insert testAccount;
        
        Test.startTest();
        // Act & Assert: Valid ratings should succeed
        Boolean hotResult = AccountHelper.updateAccountRating(testAccount.Id, VALID_RATING_HOT);
        System.assertEquals(true, hotResult, 'Hot should be valid');
        
        Boolean warmResult = AccountHelper.updateAccountRating(testAccount.Id, VALID_RATING_WARM);
        System.assertEquals(true, warmResult, 'Warm should be valid');
        
        Boolean coldResult = AccountHelper.updateAccountRating(testAccount.Id, VALID_RATING_COLD);
        System.assertEquals(true, coldResult, 'Cold should be valid');
        
        // Invalid rating should fail
        Boolean invalidResult = AccountHelper.updateAccountRating(testAccount.Id, 'SuperHot');
        System.assertEquals(false, invalidResult, 'SuperHot should be invalid');
        Test.stopTest();
    }
}