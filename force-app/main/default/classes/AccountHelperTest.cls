/**
 * @description Test class for AccountHelper
 * @author Salesforce Developer
 * @date 2024
 */
@IsTest
private class AccountHelperTest {
    private static final String ACCOUNT_KEY_PREFIX = '001';
    private static final Integer BULK_TEST_SIZE = 250;

    /**
     * @description Setup test data for all test methods
     */
    @TestSetup
    static void setupTestData() {
        List<Account> testAccounts = new List<Account>();

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
    @IsTest
    static void testUpdateAccountsSingleAccountSuccess() {
        Account testAccount = [SELECT Id, AnnualRevenue FROM Account LIMIT 1];
        Decimal originalRevenue = testAccount.AnnualRevenue;

        Test.startTest();
        AccountHelper.updateAccounts(new List<Id>{ testAccount.Id });
        Test.stopTest();

        Account updatedAccount = [SELECT Id, AnnualRevenue FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(1000000, updatedAccount.AnnualRevenue,
            'AnnualRevenue should be set to 1000000');
        System.assertNotEquals(originalRevenue, updatedAccount.AnnualRevenue,
            'AnnualRevenue should have changed');
    }

    /**
     * @description Positive test: Update multiple accounts successfully
     */
    @IsTest
    static void testUpdateAccountsMultipleAccountsSuccess() {
        List<Account> testAccounts = [SELECT Id, AnnualRevenue FROM Account LIMIT 5];
        List<Id> accountIds = new List<Id>();

        for (Account acc : testAccounts) {
            accountIds.add(acc.Id);
        }

        Test.startTest();
        AccountHelper.updateAccounts(accountIds);
        Test.stopTest();

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
    @IsTest
    static void testUpdateAccountsBulkScenarioSuccess() {
        List<Account> bulkAccounts = new List<Account>();
        for (Integer i = 0; i < BULK_TEST_SIZE; i++) {
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

        List<Account> updatedAccounts = [
            SELECT Id, AnnualRevenue
            FROM Account
            WHERE Id IN :accountIds
        ];

        System.assertEquals(BULK_TEST_SIZE, updatedAccounts.size(),
            'All accounts should be retrieved');

        for (Account acc : updatedAccounts) {
            System.assertEquals(1000000, acc.AnnualRevenue,
                'Each account AnnualRevenue should be set to 1000000');
        }
    }

    /**
     * @description Negative test: Null input should not throw exception
     */
    @IsTest
    static void testUpdateAccountsNullInputNoException() {
        Test.startTest();
        try {
            AccountHelper.updateAccounts(null);
            System.assert(true, 'Method should handle null input gracefully');
        } catch (Exception e) {
            System.assert(false, 'Null input should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }

    /**
     * @description Negative test: Empty list input should not throw exception
     */
    @IsTest
    static void testUpdateAccountsEmptyListNoException() {
        Test.startTest();
        try {
            AccountHelper.updateAccounts(new List<Id>());
            System.assert(true, 'Method should handle empty list input gracefully');
        } catch (Exception e) {
            System.assert(false, 'Empty list input should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }

    /**
     * @description Negative test: Invalid account IDs should not throw exception
     */
    @IsTest
    static void testUpdateAccountsInvalidIdsNoException() {
        String fakeId = ACCOUNT_KEY_PREFIX + '000000000000';
        List<Id> invalidIds = new List<Id>{ (Id)fakeId };

        Test.startTest();
        try {
            AccountHelper.updateAccounts(invalidIds);
            System.assert(true, 'Method should handle invalid IDs gracefully');
        } catch (Exception e) {
            System.assert(false, 'Invalid IDs should not throw exception: ' + e.getMessage());
        }
        Test.stopTest();
    }

    /**
     * @description Negative test: Mix of valid and invalid account IDs
     */
    @IsTest
    static void testUpdateAccountsMixedValidInvalidIdsSuccess() {
        Account validAccount = [SELECT Id FROM Account LIMIT 1];
        String fakeId = ACCOUNT_KEY_PREFIX + '000000000000';
        List<Id> mixedIds = new List<Id>{ validAccount.Id, (Id)fakeId };

        Test.startTest();
        AccountHelper.updateAccounts(mixedIds);
        Test.stopTest();

        Account updatedAccount = [SELECT Id, AnnualRevenue FROM Account WHERE Id = :validAccount.Id];
        System.assertEquals(1000000, updatedAccount.AnnualRevenue,
            'Valid account should be updated even when mixed with invalid IDs');
    }

    /**
     * @description Test: Verify that only queried accounts are updated
     */
    @IsTest
    static void testUpdateAccountsSelectiveUpdateSuccess() {
        List<Account> allAccounts = [SELECT Id, AnnualRevenue FROM Account];
        List<Id> accountIdsToUpdate = new List<Id>();
        for (Integer i = 0; i < 3 && i < allAccounts.size(); i++) {
            accountIdsToUpdate.add(allAccounts[i].Id);
        }

        Test.startTest();
        AccountHelper.updateAccounts(accountIdsToUpdate);
        Test.stopTest();

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

        for (Account acc : updatedAccounts) {
            System.assertEquals(1000000, acc.AnnualRevenue,
                'Selected accounts should be updated');
        }

        for (Account acc : nonUpdatedAccounts) {
            System.assertNotEquals(1000000, acc.AnnualRevenue,
                'Non-selected accounts should not be updated');
        }
    }

    /**
     * @description Test: Verify AnnualRevenue field is updated correctly with different initial values
     */
    @IsTest
    static void testUpdateAccountsDifferentInitialValuesSuccess() {
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
    @IsTest
    static void testUpdateAccountsAlreadyAtTargetValueSuccess() {
        Account testAccount = new Account(
            Name = 'Account At Target',
            AnnualRevenue = 1000000
        );
        insert testAccount;

        Test.startTest();
        AccountHelper.updateAccounts(new List<Id>{ testAccount.Id });
        Test.stopTest();

        Account updatedAccount = [SELECT Id, AnnualRevenue FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(1000000, updatedAccount.AnnualRevenue,
            'Account should maintain AnnualRevenue value of 1000000');
    }

    /**
     * @description Test: Verify System.runAs() works correctly
     */
    @IsTest
    static void testUpdateAccountsWithRunAs() {
        User testUser = createTestUser();
        Account testAccount = [SELECT Id FROM Account LIMIT 1];

        Test.startTest();
        System.runAs(testUser) {
            AccountHelper.updateAccounts(new List<Id>{ testAccount.Id });
        }
        Test.stopTest();

        Account updatedAccount = [SELECT Id, AnnualRevenue FROM Account WHERE Id = :testAccount.Id];
        System.assertEquals(1000000, updatedAccount.AnnualRevenue,
            'Account should be updated when run as test user');
    }

    /**
     * @description Creates a test user for System.runAs() testing
     * @return User test user
     */
    private static User createTestUser() {
        Profile standardProfile = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        User testUser = new User(
            FirstName = 'Test',
            LastName = 'User',
            Email = 'testuser@example.com',
            Username = 'testuser' + System.now().getTime() + '@example.com',
            Alias = 'tuser',
            ProfileId = standardProfile.Id,
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US'
        );
        insert testUser;
        return testUser;
    }
}
