@isTest
private class AccountHelperTest {
    @testSetup
    static void setupData() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 3; i++) {
            accounts.add(new Account(
                Name = 'Test Account ' + i,
                Rating = 'Cold'
            ));
        }
        insert accounts;
    }

    @isTest
    static void updateAccountRating_updatesSingleRecord() {
        Account testAccount = [SELECT Id, Rating FROM Account LIMIT 1];

        Test.startTest();
        AccountHelper.updateAccountRating(testAccount.Id, 'Hot');
        Test.stopTest();

        testAccount = [SELECT Rating FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals('Hot', testAccount.Rating, 'Rating should update via single-record helper.');
    }

    @isTest
    static void updateAccountRating_throwsForMissingId() {
        try {
            AccountHelper.updateAccountRating(null, 'Warm');
            System.assert(false, 'Method should throw when Account Id is null.');
        } catch (IllegalArgumentException ex) {
            System.assertEquals('Account Id is required.', ex.getMessage());
        }
    }

    @isTest
    static void updateAccountRating_throwsForBlankRating() {
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        try {
            AccountHelper.updateAccountRating(testAccount.Id, '');
            System.assert(false, 'Method should throw when rating is blank.');
        } catch (IllegalArgumentException ex) {
            System.assertEquals('Rating is required.', ex.getMessage());
        }
    }

    @isTest
    static void updateAccountRatings_bulkUpdatesValidRecords() {
        List<Account> accounts = [
            SELECT Id, Rating
            FROM Account
            ORDER BY CreatedDate
            LIMIT 3
        ];

        Map<Id, String> ratingUpdates = new Map<Id, String>{
            accounts[0].Id => 'Warm',
            accounts[1].Id => 'Hot',
            accounts[2].Id => null
        };
        ratingUpdates.put(null, 'Cold');

        Test.startTest();
        AccountHelper.updateAccountRatings(ratingUpdates);
        Test.stopTest();

        accounts = [
            SELECT Id, Rating
            FROM Account
            WHERE Id IN :new List<Id>{accounts[0].Id, accounts[1].Id, accounts[2].Id}
            ORDER BY CreatedDate
        ];

        System.assertEquals('Warm', accounts[0].Rating, 'First account should update to Warm.');
        System.assertEquals('Hot', accounts[1].Rating, 'Second account should update to Hot.');
        System.assertEquals('Cold', accounts[2].Rating, 'Third account should remain unchanged because blank rating was ignored.');
    }

    @isTest
    static void updateAccountRatings_handlesEmptyInput() {
        Test.startTest();
        AccountHelper.updateAccountRatings(new Map<Id, String>());
        AccountHelper.updateAccountRatings(null);
        Test.stopTest();

        System.assertEquals(3, [SELECT COUNT() FROM Account], 'No accounts should be added or removed when inputs are empty.');
    }
}
/**
 * Test class for AccountHelper.
 * Provides comprehensive test coverage for AccountHelper methods.
 */
@isTest
private class AccountHelperTest {
    
    /**
     * Test successful update of Account rating with valid inputs.
     */
    @isTest
    static void testUpdateAccountRating_Success() {
        // Arrange: Create a test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            Rating = 'Hot'
        );
        insert testAccount;
        
        String newRating = 'Warm';
        
        // Act: Update the Account rating
        Test.startTest();
        AccountHelper.updateAccountRating(testAccount.Id, newRating);
        Test.stopTest();
        
        // Assert: Verify the rating was updated
        Account updatedAccount = [
            SELECT Id, Rating 
            FROM Account 
            WHERE Id = :testAccount.Id 
            LIMIT 1
        ];
        System.assertEquals(newRating, updatedAccount.Rating, 'Account rating should be updated to the new value');
    }
    
    /**
     * Test that NullPointerException is thrown when accountId is null.
     */
    @isTest
    static void testUpdateAccountRating_NullAccountId() {
        // Arrange
        String testRating = 'Hot';
        
        // Act & Assert: Verify NullPointerException is thrown
        Test.startTest();
        try {
            AccountHelper.updateAccountRating(null, testRating);
            System.assert(false, 'Expected NullPointerException was not thrown');
        } catch (NullPointerException e) {
            System.assert(e.getMessage().contains('Account Id cannot be null'), 
                'Exception message should indicate Account Id cannot be null');
        }
        Test.stopTest();
    }
    
    /**
     * Test that Exception is thrown when rating is null.
     */
    @isTest
    static void testUpdateAccountRating_NullRating() {
        // Arrange: Create a test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            Rating = 'Hot'
        );
        insert testAccount;
        
        // Act & Assert: Verify Exception is thrown
        Test.startTest();
        try {
            AccountHelper.updateAccountRating(testAccount.Id, null);
            System.assert(false, 'Expected Exception was not thrown');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Rating cannot be null or empty'), 
                'Exception message should indicate Rating cannot be null or empty');
        }
        Test.stopTest();
    }
    
    /**
     * Test that Exception is thrown when rating is empty string.
     */
    @isTest
    static void testUpdateAccountRating_EmptyRating() {
        // Arrange: Create a test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            Rating = 'Hot'
        );
        insert testAccount;
        
        // Act & Assert: Verify Exception is thrown
        Test.startTest();
        try {
            AccountHelper.updateAccountRating(testAccount.Id, '');
            System.assert(false, 'Expected Exception was not thrown');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Rating cannot be null or empty'), 
                'Exception message should indicate Rating cannot be null or empty');
        }
        Test.stopTest();
    }
    
    /**
     * Test that Exception is thrown when rating is blank (whitespace only).
     */
    @isTest
    static void testUpdateAccountRating_BlankRating() {
        // Arrange: Create a test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            Rating = 'Hot'
        );
        insert testAccount;
        
        // Act & Assert: Verify Exception is thrown
        Test.startTest();
        try {
            AccountHelper.updateAccountRating(testAccount.Id, '   ');
            System.assert(false, 'Expected Exception was not thrown');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Rating cannot be null or empty'), 
                'Exception message should indicate Rating cannot be null or empty');
        }
        Test.stopTest();
    }
    
    /**
     * Test that QueryException is thrown when Account record is not found.
     */
    @isTest
    static void testUpdateAccountRating_AccountNotFound() {
        // Arrange: Create an Account, then delete it to get a non-existent Id
        Account tempAccount = new Account(Name = 'Temp Account');
        insert tempAccount;
        Id deletedAccountId = tempAccount.Id;
        delete tempAccount;
        
        // Act & Assert: Verify QueryException is thrown
        Test.startTest();
        try {
            AccountHelper.updateAccountRating(deletedAccountId, 'Hot');
            System.assert(false, 'Expected QueryException was not thrown');
        } catch (QueryException e) {
            System.assert(e.getMessage().contains('Account not found'), 
                'Exception message should indicate Account not found');
        }
        Test.stopTest();
    }
    
    /**
     * Test update with different rating values to ensure method handles various inputs.
     */
    @isTest
    static void testUpdateAccountRating_WithDifferentRatings() {
        // Arrange: Create a test Account
        Account testAccount = new Account(
            Name = 'Test Account',
            Rating = 'Cold'
        );
        insert testAccount;
        
        List<String> testRatings = new List<String>{ 'Hot', 'Warm', 'Cold', 'Custom Rating' };
        
        // Act & Assert: Test each rating value
        Test.startTest();
        for (String rating : testRatings) {
            AccountHelper.updateAccountRating(testAccount.Id, rating);
            
            Account updatedAccount = [
                SELECT Id, Rating 
                FROM Account 
                WHERE Id = :testAccount.Id 
                LIMIT 1
            ];
            System.assertEquals(rating, updatedAccount.Rating, 
                'Account rating should be updated to: ' + rating);
        }
        Test.stopTest();
    }
}

