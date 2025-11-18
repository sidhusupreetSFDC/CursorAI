/**
 * @description Comprehensive test class for AccountHelper.
 *              Tests all scenarios including positive, negative, bulk, and edge cases.
 * @author Salesforce
 * @date 2025
 */
@IsTest
private class AccountHelperTest {
    private static final Integer BULK_TEST_SIZE = 201;
    private static final String INVALID_ACCOUNT_ID_PREFIX = '001000000000000AAA';
    private static final String TEST_ACCOUNT_NAME_PREFIX = 'Test Account';

    @testSetup
    static void createTestData() {
        insert new List<Account>{
            new Account(Name = 'Acme A'),
            new Account(Name = 'Acme B'),
            new Account(Name = 'Acme C')
        };
    }

    // Positive Test Cases

    @IsTest
    static void updateAccounts_setsAnnualRevenueForMultipleAccounts() {
        List<Account> targetAccounts = fetchAccounts(2);

        Test.startTest();
        AccountHelper.updateAccounts(
            new List<Id>{
                targetAccounts[0].Id,
                targetAccounts[1].Id,
                targetAccounts[0].Id
            }
        );
        Test.stopTest();

        assertAnnualRevenueEqualsTarget(new List<Id>{
            targetAccounts[0].Id,
            targetAccounts[1].Id
        });
    }

    @IsTest
    static void updateAccounts_updatesSingleAccount() {
        List<Account> targetAccount = fetchAccounts(1);

        Test.startTest();
        AccountHelper.updateAccounts(new List<Id>{targetAccount[0].Id});
        Test.stopTest();

        assertAnnualRevenueEqualsTarget(new List<Id>{targetAccount[0].Id});
    }

    @IsTest
    static void updateAccounts_updatesAllAccountsFromSetup() {
        List<Account> allAccounts = fetchAccounts(3);

        Test.startTest();
        AccountHelper.updateAccounts(
            new List<Id>{
                allAccounts[0].Id,
                allAccounts[1].Id,
                allAccounts[2].Id
            }
        );
        Test.stopTest();

        assertAnnualRevenueEqualsTarget(
            new List<Id>{
                allAccounts[0].Id,
                allAccounts[1].Id,
                allAccounts[2].Id
            }
        );
    }

    @IsTest
    static void updateAccounts_handlesBulkOperations() {
        List<Account> bulkAccounts = createBulkTestAccounts(BULK_TEST_SIZE);

        Test.startTest();
        List<Id> accountIds = new List<Id>();
        for (Account acc : bulkAccounts) {
            accountIds.add(acc.Id);
        }
        AccountHelper.updateAccounts(accountIds);
        Test.stopTest();

        assertAnnualRevenueEqualsTarget(accountIds);
        System.assertEquals(
            BULK_TEST_SIZE,
            [SELECT COUNT() FROM Account WHERE AnnualRevenue = :AccountHelper.TARGET_ANNUAL_REVENUE],
            'All bulk accounts should be updated.'
        );
    }

    // Edge Case Test Cases

    @IsTest
    static void updateAccounts_ignoresNullInput() {
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        Integer dmlBefore = Limits.getDMLStatements();

        AccountHelper.updateAccounts(null);

        Integer queriesAfter = Limits.getQueries();
        Integer dmlAfter = Limits.getDMLStatements();
        Test.stopTest();

        System.assertEquals(
            queriesBefore,
            queriesAfter,
            'Method should not perform queries when null is supplied.'
        );
        System.assertEquals(
            dmlBefore,
            dmlAfter,
            'Method should not perform DML when null is supplied.'
        );
    }

    @IsTest
    static void updateAccounts_ignoresEmptyList() {
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        Integer dmlBefore = Limits.getDMLStatements();

        AccountHelper.updateAccounts(new List<Id>());

        Integer queriesAfter = Limits.getQueries();
        Integer dmlAfter = Limits.getDMLStatements();
        Test.stopTest();

        System.assertEquals(
            queriesBefore,
            queriesAfter,
            'Method should not perform queries when empty list is supplied.'
        );
        System.assertEquals(
            dmlBefore,
            dmlAfter,
            'Method should not perform DML when empty list is supplied.'
        );
    }

    @IsTest
    static void updateAccounts_handlesEmptyAccountList() {
        Test.startTest();
        AccountHelper.updateAccounts(
            new List<Id>{
                buildInvalidAccountId(),
                buildInvalidAccountId()
            }
        );
        Test.stopTest();

        System.assertEquals(
            0,
            [SELECT COUNT() FROM Account WHERE AnnualRevenue = :AccountHelper.TARGET_ANNUAL_REVENUE],
            'No accounts should be updated when all IDs are invalid.'
        );
    }

    @IsTest
    static void updateAccounts_updatesExistingIdsOnly() {
        List<Account> targetAccounts = fetchAccounts(1);

        Test.startTest();
        AccountHelper.updateAccounts(
            new List<Id>{
                targetAccounts[0].Id,
                buildInvalidAccountId()
            }
        );
        Test.stopTest();

        assertAnnualRevenueEqualsTarget(new List<Id>{targetAccounts[0].Id});
    }

    @IsTest
    static void updateAccounts_handlesDuplicateIds() {
        List<Account> targetAccounts = fetchAccounts(1);
        Id duplicateId = targetAccounts[0].Id;

        Test.startTest();
        AccountHelper.updateAccounts(
            new List<Id>{
                duplicateId,
                duplicateId,
                duplicateId
            }
        );
        Test.stopTest();

        assertAnnualRevenueEqualsTarget(new List<Id>{duplicateId});
        
        Account updatedAccount = [
            SELECT AnnualRevenue
            FROM Account
            WHERE Id = :duplicateId
        ];
        System.assertEquals(
            AccountHelper.TARGET_ANNUAL_REVENUE,
            updatedAccount.AnnualRevenue,
            'Account should be updated only once despite duplicate IDs.'
        );
    }

    // Negative Test Cases

    @IsTest
    static void updateAccounts_throwsExceptionOnDmlFailure() {
        List<Account> accounts = createBulkTestAccounts(1);
        Account accountToDelete = accounts[0];
        delete accountToDelete;

        Test.startTest();
        try {
            AccountHelper.updateAccounts(new List<Id>{accountToDelete.Id});
            System.assert(false, 'Expected AccountHelperException to be thrown.');
        } catch (AccountHelper.AccountHelperException ex) {
            System.assert(
                ex.getMessage().contains('Unable to update accounts'),
                'Exception message should indicate account update failure.'
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void updateAccounts_handlesVeryLargeBulkOperation() {
        List<Account> bulkAccounts = createBulkTestAccounts(500);

        Test.startTest();
        List<Id> accountIds = new List<Id>();
        for (Account acc : bulkAccounts) {
            accountIds.add(acc.Id);
        }
        AccountHelper.updateAccounts(accountIds);
        Test.stopTest();

        Integer updatedCount = [
            SELECT COUNT()
            FROM Account
            WHERE Id IN :accountIds
            AND AnnualRevenue = :AccountHelper.TARGET_ANNUAL_REVENUE
        ];
        System.assertEquals(
            500,
            updatedCount,
            'All 500 accounts should be updated successfully.'
        );
    }

    @IsTest
    static void updateAccounts_handlesMixedValidAndInvalidIds() {
        List<Account> validAccounts = createBulkTestAccounts(5);
        List<Id> mixedIds = new List<Id>();
        
        for (Account acc : validAccounts) {
            mixedIds.add(acc.Id);
        }
        mixedIds.add(buildInvalidAccountId());
        mixedIds.add(buildInvalidAccountId());

        Test.startTest();
        AccountHelper.updateAccounts(mixedIds);
        Test.stopTest();

        assertAnnualRevenueEqualsTarget(
            new List<Id>{
                validAccounts[0].Id,
                validAccounts[1].Id,
                validAccounts[2].Id,
                validAccounts[3].Id,
                validAccounts[4].Id
            }
        );
    }

    @IsTest
    static void updateAccounts_validatesGovernorLimits() {
        List<Account> bulkAccounts = createBulkTestAccounts(BULK_TEST_SIZE);
        List<Id> accountIds = new List<Id>();
        for (Account acc : bulkAccounts) {
            accountIds.add(acc.Id);
        }

        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        Integer dmlBefore = Limits.getDMLStatements();
        
        AccountHelper.updateAccounts(accountIds);
        
        Integer queriesAfter = Limits.getQueries();
        Integer dmlAfter = Limits.getDMLStatements();
        Test.stopTest();

        System.assert(
            queriesAfter - queriesBefore <= 2,
            'Should use minimal SOQL queries (1 for fetch, 1 for assertion).'
        );
        System.assert(
            dmlAfter - dmlBefore == 1,
            'Should use single DML statement for bulk update.'
        );
    }

    // Helper Methods

    /**
     * @description Fetches Account records from test setup data
     * @param recordLimit Number of records to fetch
     * @return List of Account records
     */
    private static List<Account> fetchAccounts(Integer recordLimit) {
        return [
            SELECT Id, AnnualRevenue
            FROM Account
            ORDER BY CreatedDate ASC
            LIMIT :recordLimit
        ];
    }

    /**
     * @description Creates bulk test accounts for bulkification testing
     * @param count Number of accounts to create
     * @return List of created Account records
     */
    private static List<Account> createBulkTestAccounts(Integer count) {
        if (count <= 0) {
            return new List<Account>();
        }

        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(new Account(Name = TEST_ACCOUNT_NAME_PREFIX + ' ' + i));
        }
        insert accounts;
        return accounts;
    }

    /**
     * @description Asserts that AnnualRevenue equals the target value for all provided Account Ids
     * @param accountIds List of Account Ids to verify
     */
    private static void assertAnnualRevenueEqualsTarget(List<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }

        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, AnnualRevenue
            FROM Account
            WHERE Id IN :accountIds
        ]);

        for (Id accountId : accountIds) {
            Account refreshedAccount = accountMap.get(accountId);
            System.assertNotEquals(
                null,
                refreshedAccount,
                'Account with Id ' + accountId + ' should exist.'
            );
            System.assertEquals(
                AccountHelper.TARGET_ANNUAL_REVENUE,
                refreshedAccount.AnnualRevenue,
                'AnnualRevenue should be updated for Account ' + accountId
            );
        }
    }

    /**
     * @description Builds an invalid Account Id for testing
     * @return Invalid Account Id
     */
    private static Id buildInvalidAccountId() {
        return Id.valueOf(INVALID_ACCOUNT_ID_PREFIX);
    }
}