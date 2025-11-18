/**
 * @description Test class for AccountHelper
 * @author Salesforce
 * @date 2025
 */
@IsTest
private class AccountHelperTest {
    private static final Integer BULK_TEST_SIZE = 201;
    private static final String INVALID_ACCOUNT_ID_PREFIX = '001000000000000AAA';

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
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(new Account(Name = 'Bulk Test Account ' + i));
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