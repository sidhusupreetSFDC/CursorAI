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
    @testSetup
    static void setupTestData() {
        List<Account> testAccounts = new List<Account>();
        
        // Create test accounts with various AnnualRevenue values
        for (Integer i = 0; i < 10; i++) {
            testAccounts.add(new Account(
                Name = 'Test Account ' + i,
                AnnualRevenue = 50000 + (i * 10000)
            ));
        }
        
        insert testAccounts;
    }
    
    /**
     * @description Positive test: Update single account successfully
     */
    @isTest
    static void testUpdateAccounts_SingleAccount_Success() {
        // Get test account
        Account testAccount = [SELECT Id, AnnualRevenue FROM Account LIMIT 1];
        Decimal originalRevenue = testAccount.AnnualRevenue;
        
        Test.startTest();
        AccountHelper.updateAccounts(new List<Id>{ testAccount.Id });
        Test.stopTest();
        
        // Verify the account was updated
        Account updatedAccount = [SELECT Id, AnnualRevenue FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(1000000, updatedAccount.AnnualRevenue, 
            'AnnualRevenue should be set to 1000000');
        System.assertNotEquals(originalRevenue, updatedAccount.AnnualRevenue, 
            'AnnualRevenue should have changed');
    }
    
    /**
     * @description Positive test: Update multiple accounts successfully
     */
    @isTest
    static void testUpdateAccounts_MultipleAccounts_Success() {
        // Get test accounts
        List<Account> testAccounts = [SELECT Id, AnnualRevenue FROM Account LIMIT 5];
        List<Id> accountIds = new List<Id>();
        
        for (Account acc : testAccounts) {
            accountIds.add(acc.Id);
        }
        
        Test.startTest();
        AccountHelper.updateAccounts(accountIds);
        Test.stopTest();
        
        // Verify all accounts were updated
        List<Account> updatedAccounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            WHERE Id IN :accountIds
        ];
        
        System.assertEquals(testAccounts.size(), updatedAccounts.size(), 
            'All accounts should be retrieved');
        
        for (Account acc : updatedAccounts) {
            System.assertEquals(1000000, acc.AnnualRevenue, 
                'Each account AnnualRevenue should be set to 1000000');
        }
    }
    
    /**
     * @description Bulk test: Update 200+ accounts to test bulkification
     */
    @isTest
    static void testUpdateAccounts_BulkScenario_Success() {
        // Create 250 accounts for bulk testing
        List<Account> bulkAccounts = new List<Account>();
        for (Integer i = 0; i < 250; i++) {
            bulkAccounts.add(new Account(
                Name = 'Bulk Test Account ' + i,
                AnnualRevenue = 10000
            ));
        }
        insert bulkAccounts;
        
        List<Id> accountIds = new List<Id>();
        for (Account acc : bulkAccounts) {
            accountIds.add(acc.Id);
        }
        
        Test.startTest();
        AccountHelper.updateAccounts(accountIds);
        Test.stopTest();
        
        // Verify all accounts were updated
        List<Account> updatedAccounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            WHERE Id IN :accountIds
        ];
        
        System.assertEquals(250, updatedAccounts.size(), 
            'All 250 accounts should be retrieved');
        
        for (Account acc : updatedAccounts) {
            System.assertEquals(1000000, acc.AnnualRevenue, 
                'Each account AnnualRevenue should be set to 1000000');
        }
    }
    
    /**
     * @description Negative test: Null input should not throw exception
     */
    @isTest
    static void testUpdateAccounts_NullInput_NoException() {
        Test.startTest();
        try {
            AccountHelper.updateAccounts(null);
            // Should complete without exception
            System.assert(true, 'Method should handle null input gracefully');
        } catch (Exception e) {
            System.assert(false, 'Null input should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    /**
     * @description Negative test: Empty list input should not throw exception
     */
    @isTest
    static void testUpdateAccounts_EmptyList_NoException() {
        Test.startTest();
        try {
            AccountHelper.updateAccounts(new List<Id>());
            // Should complete without exception
            System.assert(true, 'Method should handle empty list input gracefully');
        } catch (Exception e) {
            System.assert(false, 'Empty list input should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    /**
     * @description Negative test: Invalid account IDs (non-existent) should not throw exception
     */
    @isTest
    static void testUpdateAccounts_InvalidIds_NoException() {
        // Create a valid format ID that doesn't exist
        // Account key prefix is '001', followed by 12 alphanumeric characters (15 total)
        String fakeIdPrefix = Account.sObjectType.getDescribe().getKeyPrefix();
        String fakeId = fakeIdPrefix + '000000000000'; // 12 zeros after prefix (15 chars total)
        List<Id> invalidIds = new List<Id>{ (Id)fakeId };
        
        Test.startTest();
        try {
            AccountHelper.updateAccounts(invalidIds);
            // Should complete without exception (empty query result)
            System.assert(true, 'Method should handle invalid IDs gracefully');
        } catch (Exception e) {
            System.assert(false, 'Invalid IDs should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    /**
     * @description Negative test: Mix of valid and invalid account IDs
     */
    @isTest
    static void testUpdateAccounts_MixedValidInvalidIds_Success() {
        // Get one valid account
        Account validAccount = [SELECT Id FROM Account LIMIT 1];
        
        // Create invalid IDs
        List<Id> mixedIds = new List<Id>{ validAccount.Id };
        String fakeIdPrefix = Account.sObjectType.getDescribe().getKeyPrefix();
        String fakeId = fakeIdPrefix + '000000000000'; // 12 zeros after prefix (15 chars total)
        mixedIds.add((Id)fakeId);
        
        Decimal originalRevenue = [SELECT AnnualRevenue FROM Account WHERE Id = :validAccount.Id].AnnualRevenue;
        
        Test.startTest();
        AccountHelper.updateAccounts(mixedIds);
        Test.stopTest();
        
        // Verify valid account was updated
        Account updatedAccount = [SELECT Id, AnnualRevenue FROM Account WHERE Id = :validAccount.Id];
        System.assertEquals(1000000, updatedAccount.AnnualRevenue, 
            'Valid account should be updated even when mixed with invalid IDs');
    }
    
    /**
     * @description Test: Verify that only queried accounts are updated
     */
    @isTest
    static void testUpdateAccounts_SelectiveUpdate_Success() {
        // Get all accounts
        List<Account> allAccounts = [SELECT Id, AnnualRevenue FROM Account];
        
        // Select only first 3 accounts to update
        List<Id> accountIdsToUpdate = new List<Id>();
        for (Integer i = 0; i < 3 && i < allAccounts.size(); i++) {
            accountIdsToUpdate.add(allAccounts[i].Id);
        }
        
        Test.startTest();
        AccountHelper.updateAccounts(accountIdsToUpdate);
        Test.stopTest();
        
        // Verify only selected accounts were updated
        List<Account> updatedAccounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            WHERE Id IN :accountIdsToUpdate
        ];
        
        List<Account> nonUpdatedAccounts = [
            SELECT Id, AnnualRevenue 
            FROM Account 
            WHERE Id NOT IN :accountIdsToUpdate
        ];
        
        // Verify updated accounts
        for (Account acc : updatedAccounts) {
            System.assertEquals(1000000, acc.AnnualRevenue, 
                'Selected accounts should be updated');
        }
        
        // Verify non-updated accounts remain unchanged
        for (Account acc : nonUpdatedAccounts) {
            System.assertNotEquals(1000000, acc.AnnualRevenue, 
                'Non-selected accounts should not be updated');
        }
    }
    
    /**
     * @description Test: Verify AnnualRevenue field is updated correctly with different initial values
     */
    @isTest
    static void testUpdateAccounts_DifferentInitialValues_Success() {
        // Create accounts with different AnnualRevenue values
        List<Account> testAccounts = new List<Account>{
            new Account(Name = 'Account Zero', AnnualRevenue = 0),
            new Account(Name = 'Account Null', AnnualRevenue = null),
            new Account(Name = 'Account High', AnnualRevenue = 5000000),
            new Account(Name = 'Account Negative', AnnualRevenue = -1000)
        };
        insert testAccounts;
        
        List<Id> accountIds = new List<Id>();
        for (Account acc : testAccounts) {
            accountIds.add(acc.Id);
        }
        
        Test.startTest();
        AccountHelper.updateAccounts(accountIds);
        Test.stopTest();
        
        // Verify all accounts have same AnnualRevenue value
        List<Account> updatedAccounts = [
            SELECT Id, Name, AnnualRevenue 
            FROM Account 
            WHERE Id IN :accountIds
        ];
        
        for (Account acc : updatedAccounts) {
            System.assertEquals(1000000, acc.AnnualRevenue, 
                'Account ' + acc.Name + ' should have AnnualRevenue set to 1000000');
        }
    }
    
    /**
     * @description Test: Verify method handles accounts that are already at target value
     */
    @isTest
    static void testUpdateAccounts_AlreadyAtTargetValue_Success() {
        // Create account with AnnualRevenue already at 1000000
        Account testAccount = new Account(
            Name = 'Account At Target',
            AnnualRevenue = 1000000
        );
        insert testAccount;
        
        Test.startTest();
        AccountHelper.updateAccounts(new List<Id>{ testAccount.Id });
        Test.stopTest();
        
        // Verify account still has correct value
        Account updatedAccount = [SELECT Id, AnnualRevenue FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(1000000, updatedAccount.AnnualRevenue, 
            'Account should maintain AnnualRevenue value of 1000000');
    }
}

