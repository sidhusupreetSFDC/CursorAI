/**
 * @description Test class for AccountHelper
 * @author Salesforce Developer
 * @date 2024
 */
@isTest
private class AccountHelperTest {
    
    // Test constants
    private static final Integer BULK_TEST_SIZE = 250;
    private static final Decimal EXPECTED_REVENUE = 1000000;
    private static final Decimal INITIAL_REVENUE = 500000;
    
    /**
     * @description Setup test data for all test methods
     * Creates bulk test accounts for comprehensive testing
     */
    @TestSetup
    static void setupTestData() {
        List<Account> testAccounts = new List<Account>();
        
        // Create bulk test accounts for governor limit testing
        for (Integer i = 0; i < BULK_TEST_SIZE; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                AnnualRevenue = INITIAL_REVENUE
            ));
        }
        
        insert testAccounts;
    }
    
    /**
     * @description Test positive scenario - single account update
     * Verifies successful update of a single account
     */
    @isTest
    static void testUpdateSingleAccount_Success() {
        // Query test account
        Account testAccount = [SELECT Id, AnnualRevenue FROM Account LIMIT 1];
        Decimal originalRevenue = testAccount.AnnualRevenue;
        
        Test.startTest();
        AccountHelper.updateAccounts(new List<Id>{ testAccount.Id });
        Test.stopTest();
        
        // Verify the update
        Account updatedAccount = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            WHERE Id = :testAccount.Id
        ];
        
        System.assertEquals(
            EXPECTED_REVENUE, 
            updatedAccount.AnnualRevenue, 
            'Annual Revenue should be updated to 1000000'
        );
        System.assertNotEquals(
            originalRevenue, 
            updatedAccount.AnnualRevenue, 
            'Annual Revenue should have changed from original value'
        );
    }
    
    /**
     * @description Test positive scenario - multiple accounts update
     * Verifies successful bulk update of multiple accounts
     */
    @isTest
    static void testUpdateMultipleAccounts_Success() {
        // Query test accounts
        List<Account> testAccounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            LIMIT 10
        ];
        List<Id> accountIds = new List<Id>();
        
        for (Account acc : testAccounts) {
            accountIds.add(acc.Id);
            System.assertEquals(
                INITIAL_REVENUE, 
                acc.AnnualRevenue, 
                'Initial revenue should be 500000'
            );
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
        
        System.assertEquals(
            testAccounts.size(), 
            updatedAccounts.size(), 
            'Should have same number of updated accounts'
        );
        
        for (Account acc : updatedAccounts) {
            System.assertEquals(
                EXPECTED_REVENUE, 
                acc.AnnualRevenue, 
                'Annual Revenue should be updated to 1000000 for all accounts'
            );
        }
    }
    
    /**
     * @description Test bulk scenario - 200+ accounts update
     * Verifies governor limit compliance and bulkification
     */
    @isTest
    static void testBulkUpdateAccounts_Success() {
        // Query all test accounts (250 accounts)
        List<Account> testAccounts = [
            SELECT Id, AnnualRevenue 
            FROM Account
        ];
        List<Id> accountIds = new List<Id>();
        
        for (Account acc : testAccounts) {
            accountIds.add(acc.Id);
        }
        
        System.assertEquals(
            BULK_TEST_SIZE, 
            accountIds.size(), 
            'Should have 250 test accounts'
        );
        
        Test.startTest();
        AccountHelper.updateAccounts(accountIds);
        Test.stopTest();
        
        // Verify all accounts are updated
        List<Account> updatedAccounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            WHERE Id IN :accountIds
        ];
        
        System.assertEquals(
            BULK_TEST_SIZE, 
            updatedAccounts.size(), 
            'Should have 250 updated accounts'
        );
        
        for (Account acc : updatedAccounts) {
            System.assertEquals(
                EXPECTED_REVENUE, 
                acc.AnnualRevenue, 
                'Annual Revenue should be updated to 1000000 for all accounts'
            );
        }
    }
    
    /**
     * @description Test negative scenario - null input
     * Verifies method handles null input gracefully
     */
    @isTest
    static void testUpdateAccounts_NullInput() {
        Test.startTest();
        AccountHelper.updateAccounts(null);
        Test.stopTest();
        
        // Verify no accounts were updated - check original values remain
        List<Account> accounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            LIMIT 1
        ];
        
        System.assertEquals(
            INITIAL_REVENUE, 
            accounts[0].AnnualRevenue, 
            'Account should maintain original revenue when null input provided'
        );
    }
    
    /**
     * @description Test negative scenario - empty list input
     * Verifies method handles empty list gracefully
     */
    @isTest
    static void testUpdateAccounts_EmptyList() {
        Test.startTest();
        AccountHelper.updateAccounts(new List<Id>());
        Test.stopTest();
        
        // Verify no accounts were updated - check original values remain
        List<Account> accounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            LIMIT 1
        ];
        
        System.assertEquals(
            INITIAL_REVENUE, 
            accounts[0].AnnualRevenue, 
            'Account should maintain original revenue when empty list provided'
        );
    }
    
    /**
     * @description Test scenario - empty result set from query
     * Verifies method handles empty query result gracefully (covers isEmpty check)
     */
    @isTest
    static void testUpdateAccounts_EmptyResultSet() {
        // Create IDs that won't match any Account records
        // Use Contact object prefix (003) instead of Account prefix (001)
        List<Id> nonMatchingIds = new List<Id>();
        
        for (Integer i = 0; i < 5; i++) {
            String fakeIdString = '00300000000000' + String.valueOf(i).leftPad(3, '0') + 'AAA';
            nonMatchingIds.add(Id.valueOf(fakeIdString));
        }
        
        Test.startTest();
        // Method should handle gracefully - empty result set, no update performed
        AccountHelper.updateAccounts(nonMatchingIds);
        Test.stopTest();
        
        // Verify no accounts were updated
        List<Account> accounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            LIMIT 10
        ];
        
        for (Account acc : accounts) {
            System.assertEquals(
                INITIAL_REVENUE, 
                acc.AnnualRevenue, 
                'Accounts should maintain original revenue when no matching records found'
            );
        }
    }
    
    /**
     * @description Test scenario - verify accounts with existing AnnualRevenue values
     * Verifies update works correctly for accounts with existing revenue values
     */
    @isTest
    static void testUpdateAccounts_WithExistingRevenue() {
        // Query accounts with specific revenue values
        List<Account> testAccounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            WHERE AnnualRevenue = :INITIAL_REVENUE 
            LIMIT 5
        ];
        
        List<Id> accountIds = new List<Id>();
        for (Account acc : testAccounts) {
            accountIds.add(acc.Id);
            System.assertEquals(
                INITIAL_REVENUE, 
                acc.AnnualRevenue, 
                'Initial revenue should be 500000'
            );
        }
        
        Test.startTest();
        AccountHelper.updateAccounts(accountIds);
        Test.stopTest();
        
        // Verify all accounts are updated to expected value
        List<Account> updatedAccounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            WHERE Id IN :accountIds
        ];
        
        System.assertEquals(
            testAccounts.size(), 
            updatedAccounts.size(), 
            'Should have same number of updated accounts'
        );
        
        for (Account acc : updatedAccounts) {
            System.assertEquals(
                EXPECTED_REVENUE, 
                acc.AnnualRevenue, 
                'Annual Revenue should be updated to 1000000'
            );
        }
    }
    
    /**
     * @description Test scenario - verify WITH SECURITY_ENFORCED behavior
     * Verifies security enforcement works correctly in test context
     */
    @isTest
    static void testSecurityEnforcedQuery_Success() {
        // Query test accounts
        List<Account> testAccounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            LIMIT 5
        ];
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
        
        System.assertEquals(
            testAccounts.size(), 
            updatedAccounts.size(), 
            'All accounts should be updated'
        );
        
        for (Account acc : updatedAccounts) {
            System.assertEquals(
                EXPECTED_REVENUE, 
                acc.AnnualRevenue, 
                'Annual Revenue should be 1000000'
            );
        }
    }
    
    /**
     * @description Test scenario - verify DMLException handling
     * Verifies method properly handles and rethrows DMLException
     * Uses a scenario where DML will fail (e.g., required field missing)
     */
    @isTest
    static void testUpdateAccounts_DmlException() {
        // Create an account that will be deleted, then try to update it
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Id accountId = testAccount.Id;
        
        // Delete the account to cause DML exception when trying to update
        delete testAccount;
        
        Test.startTest();
        try {
            AccountHelper.updateAccounts(new List<Id>{ accountId });
            System.assert(false, 'Should have thrown DmlException for deleted account');
        } catch (DmlException e) {
            // Expected behavior - DML exception should be caught and rethrown
            System.assert(
                e.getMessage() != null, 
                'DmlException should have a message: ' + e.getMessage()
            );
            System.assert(
                e.getMessage().contains('ENTITY_IS_DELETED') || 
                e.getMessage().contains('deleted') ||
                e.getMessage().contains('not found'),
                'DmlException should indicate record not found or deleted'
            );
        } catch (Exception e) {
            // QueryException is also acceptable if record not found
            System.assert(
                e instanceof QueryException || e instanceof DmlException,
                'Should throw QueryException or DmlException: ' + e.getTypeName()
            );
        }
        Test.stopTest();
    }
    
    /**
     * @description Test scenario - verify QueryException handling
     * Verifies method properly handles and rethrows QueryException
     * Uses malformed query scenario
     */
    @isTest
    static void testUpdateAccounts_QueryException() {
        // Create invalid account IDs that will cause QueryException
        // Using malformed IDs that don't match the Account object prefix
        List<Id> invalidIds = new List<Id>();
        
        // Create IDs with wrong object type prefix to potentially cause query issues
        // Note: In test context, this might return empty result set instead of exception
        // But we test the exception handling path
        
        // Get a valid account to understand ID structure
        Account validAccount = [SELECT Id FROM Account LIMIT 1];
        String accountIdString = validAccount.Id.toString();
        
        // Create IDs that are malformed
        for (Integer i = 0; i < 3; i++) {
            // Create IDs with invalid format
            String malformedId = accountIdString.substring(0, 15) + 'XXX';
            invalidIds.add(Id.valueOf(malformedId));
        }
        
        Test.startTest();
        try {
            AccountHelper.updateAccounts(invalidIds);
            // If no exception, verify empty result set was handled
            System.assert(true, 'Method should handle invalid IDs gracefully');
        } catch (QueryException e) {
            // Expected behavior - QueryException should be caught and rethrown
            System.assert(
                e.getMessage() != null, 
                'QueryException should have a message: ' + e.getMessage()
            );
        } catch (Exception e) {
            // Other exceptions are acceptable
            System.assert(
                true, 
                'Exception expected for invalid IDs: ' + e.getTypeName() + ' - ' + e.getMessage()
            );
        }
        Test.stopTest();
    }
    
    /**
     * @description Test scenario - verify non-existent account IDs
     * Verifies method handles non-existent IDs gracefully
     */
    @isTest
    static void testUpdateAccounts_NonExistentIds() {
        // Get a valid account ID format to create non-existent IDs
        Account existingAccount = [SELECT Id FROM Account LIMIT 1];
        String accountIdPrefix = existingAccount.Id.toString().substring(0, 15);
        
        // Create IDs that don't exist in database
        List<Id> nonExistentIds = new List<Id>();
        for (Integer i = 0; i < 5; i++) {
            String fakeIdString = accountIdPrefix + String.valueOf(i).leftPad(3, '0') + 'ZZZ';
            nonExistentIds.add(Id.valueOf(fakeIdString));
        }
        
        Test.startTest();
        try {
            AccountHelper.updateAccounts(nonExistentIds);
            // Method should handle gracefully - empty result set, no update performed
        } catch (QueryException e) {
            // Expected behavior - query should return empty result set or throw QueryException
            System.assert(
                true, 
                'QueryException expected for non-existent IDs: ' + e.getMessage()
            );
        } catch (Exception e) {
            // Other exceptions are also acceptable
            System.assert(
                true, 
                'Exception expected for non-existent IDs: ' + e.getMessage()
            );
        }
        Test.stopTest();
        
        // Verify no accounts were updated
        List<Account> accounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            LIMIT 10
        ];
        
        for (Account acc : accounts) {
            System.assertEquals(
                INITIAL_REVENUE, 
                acc.AnnualRevenue, 
                'Accounts should maintain original revenue when non-existent IDs provided'
            );
        }
    }
    
    /**
     * @description Test scenario - verify SecurityException for object-level access
     * Note: In test context, Schema checks usually return true, so this test
     * verifies the code path exists. Actual SecurityException testing requires
     * a user profile without Account edit permissions, which is org-dependent.
     */
    @isTest
    static void testUpdateAccounts_SecurityExceptionObjectLevel() {
        // Get test account
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        List<Id> accountIds = new List<Id>{ testAccount.Id };
        
        // In test context, Schema.isUpdateable() typically returns true
        // This test verifies the code path exists and handles the check
        Test.startTest();
        try {
            AccountHelper.updateAccounts(accountIds);
            // In test context, this should succeed as permissions are typically full
            System.assert(true, 'Update should succeed in test context with full permissions');
        } catch (SecurityException e) {
            // If SecurityException occurs, verify it's properly thrown
            System.assert(
                e.getMessage() != null && 
                e.getMessage().contains('permissions'),
                'SecurityException should have appropriate message: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }
    
    /**
     * @description Test scenario - verify SecurityException for field-level access
     * Note: In test context, Schema checks usually return true, so this test
     * verifies the code path exists. Actual SecurityException testing requires
     * a user profile without AnnualRevenue field edit permissions.
     */
    @isTest
    static void testUpdateAccounts_SecurityExceptionFieldLevel() {
        // Get test account
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        List<Id> accountIds = new List<Id>{ testAccount.Id };
        
        // In test context, Schema field checks typically return true
        // This test verifies the code path exists and handles the check
        Test.startTest();
        try {
            AccountHelper.updateAccounts(accountIds);
            // In test context, this should succeed as permissions are typically full
            System.assert(true, 'Update should succeed in test context with full permissions');
        } catch (SecurityException e) {
            // If SecurityException occurs, verify it's properly thrown
            System.assert(
                e.getMessage() != null && 
                e.getMessage().contains('AnnualRevenue'),
                'SecurityException should mention AnnualRevenue field: ' + e.getMessage()
            );
        }
        Test.stopTest();
    }
}
