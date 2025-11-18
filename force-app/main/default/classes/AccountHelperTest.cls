/**
 * Test class for AccountHelper
 * Provides comprehensive test coverage for AccountHelper methods
 */
@isTest
private class AccountHelperTest {
    /**
     * Test data setup method
     * Creates test Account records for use in test methods
     */
    @testSetup
    static void setupTestData() {
        List<Account> testAccounts = new List<Account>();
        testAccounts.add(
            new Account(Name = 'Test Account 1', Rating = 'Hot')
        );
        testAccounts.add(
            new Account(Name = 'Test Account 2', Rating = 'Cold')
        );
        insert testAccounts;
    }

    /**
     * Test successful update of Account Rating
     * Verifies that the rating is updated correctly
     */
    @isTest
    static void testUpdateAccountRating_Success() {
        // Get test account
        Account testAccount = [
            SELECT Id, Rating
            FROM Account
            WHERE Name = 'Test Account 1'
            LIMIT 1
        ];

        String newRating = 'Warm';
        Test.startTest();
        AccountHelper.updateAccountRating(testAccount.Id, newRating);
        Test.stopTest();

        // Verify the rating was updated
        Account updatedAccount = [
            SELECT Id, Rating
            FROM Account
            WHERE Id = :testAccount.Id
            LIMIT 1
        ];

        System.assertEquals(
            newRating,
            updatedAccount.Rating,
            'Account Rating should be updated to ' + newRating
        );
    }

    /**
     * Test update with null accountId
     * Verifies that IllegalArgumentException is thrown
     */
    @isTest
    static void testUpdateAccountRating_NullAccountId() {
        String rating = 'Hot';
        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            AccountHelper.updateAccountRating(null, rating);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
            System.assert(
                e.getMessage().contains('Account Id cannot be null'),
                'Exception message should indicate null Account Id'
            );
        }
        Test.stopTest();

        System.assert(
            exceptionThrown,
            'IllegalArgumentException should be thrown for null accountId'
        );
    }

    /**
     * Test update with null rating
     * Verifies that IllegalArgumentException is thrown
     */
    @isTest
    static void testUpdateAccountRating_NullRating() {
        Account testAccount = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account 1'
            LIMIT 1
        ];

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            AccountHelper.updateAccountRating(testAccount.Id, null);
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
            System.assert(
                e.getMessage().contains('Rating cannot be null or empty'),
                'Exception message should indicate null or empty rating'
            );
        }
        Test.stopTest();

        System.assert(
            exceptionThrown,
            'IllegalArgumentException should be thrown for null rating'
        );
    }

    /**
     * Test update with empty rating
     * Verifies that IllegalArgumentException is thrown
     */
    @isTest
    static void testUpdateAccountRating_EmptyRating() {
        Account testAccount = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account 1'
            LIMIT 1
        ];

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            AccountHelper.updateAccountRating(testAccount.Id, '');
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
            System.assert(
                e.getMessage().contains('Rating cannot be null or empty'),
                'Exception message should indicate null or empty rating'
            );
        }
        Test.stopTest();

        System.assert(
            exceptionThrown,
            'IllegalArgumentException should be thrown for empty rating'
        );
    }

    /**
     * Test update with blank rating (whitespace only)
     * Verifies that IllegalArgumentException is thrown
     */
    @isTest
    static void testUpdateAccountRating_BlankRating() {
        Account testAccount = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account 1'
            LIMIT 1
        ];

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            AccountHelper.updateAccountRating(testAccount.Id, '   ');
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
            System.assert(
                e.getMessage().contains('Rating cannot be null or empty'),
                'Exception message should indicate null or empty rating'
            );
        }
        Test.stopTest();

        System.assert(
            exceptionThrown,
            'IllegalArgumentException should be thrown for blank rating'
        );
    }

    /**
     * Test update with non-existent Account Id
     * Verifies that QueryException is thrown
     */
    @isTest
    static void testUpdateAccountRating_AccountNotFound() {
        // Create a fake Id that doesn't exist (Account prefix is 001)
        // Using a valid ID format but with a non-existent ID
        Id fakeAccountId = Id.valueOf('001000000000000AAA');

        Boolean exceptionThrown = false;

        Test.startTest();
        try {
            AccountHelper.updateAccountRating(fakeAccountId, 'Hot');
        } catch (QueryException e) {
            exceptionThrown = true;
            System.assert(
                e.getMessage().contains('Account not found'),
                'Exception message should indicate Account not found'
            );
        }
        Test.stopTest();

        System.assert(
            exceptionThrown,
            'QueryException should be thrown for non-existent Account'
        );
    }

    /**
     * Test bulk update scenario
     * Verifies that multiple accounts can be updated
     */
    @isTest
    static void testUpdateAccountRating_BulkUpdate() {
        List<Account> testAccounts = [
            SELECT Id, Rating
            FROM Account
            LIMIT 2
        ];

        String newRating = 'Hot';
        Test.startTest();
        for (Account acc : testAccounts) {
            AccountHelper.updateAccountRating(acc.Id, newRating);
        }
        Test.stopTest();

        // Verify all accounts were updated
        List<Account> updatedAccounts = [
            SELECT Id, Rating
            FROM Account
            WHERE Id IN :testAccounts
        ];

        for (Account acc : updatedAccounts) {
            System.assertEquals(
                newRating,
                acc.Rating,
                'All Account Ratings should be updated to ' + newRating
            );
        }
    }

    /**
     * Test update with different rating values
     * Verifies that various valid rating values can be set
     */
    @isTest
    static void testUpdateAccountRating_DifferentRatings() {
        Account testAccount = [
            SELECT Id
            FROM Account
            WHERE Name = 'Test Account 1'
            LIMIT 1
        ];

        List<String> ratings = new List<String>{ 'Hot', 'Warm', 'Cold' };

        Test.startTest();
        for (String rating : ratings) {
            AccountHelper.updateAccountRating(testAccount.Id, rating);

            Account updatedAccount = [
                SELECT Id, Rating
                FROM Account
                WHERE Id = :testAccount.Id
                LIMIT 1
            ];

            System.assertEquals(
                rating,
                updatedAccount.Rating,
                'Rating should be updated to ' + rating
            );
        }
        Test.stopTest();
    }
}
