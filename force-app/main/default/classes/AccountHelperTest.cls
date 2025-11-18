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

