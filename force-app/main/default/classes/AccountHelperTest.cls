@IsTest
private class AccountHelperTest {

    @testSetup
    static void createTestData() {
        insert new List<Account>{
            new Account(Name = 'Acme A'),
            new Account(Name = 'Acme B'),
            new Account(Name = 'Acme C')
        };
    }

    @IsTest
    static void updateAccounts_setsAnnualRevenue() {
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
    static void updateAccounts_ignoresNullAndEmptyInputs() {
        Test.startTest();
        Integer queriesBefore = Limits.getQueries();
        Integer dmlBefore = Limits.getDMLStatements();

        AccountHelper.updateAccounts(null);
        AccountHelper.updateAccounts(new List<Id>());

        Integer queriesAfter = Limits.getQueries();
        Integer dmlAfter = Limits.getDMLStatements();
        Test.stopTest();

        System.assertEquals(
            queriesBefore,
            queriesAfter,
            'Method should not perform queries when no Ids are supplied.'
        );
        System.assertEquals(
            dmlBefore,
            dmlAfter,
            'Method should not perform DML when no Ids are supplied.'
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
    static void updateAccounts_handlesSingleAccount() {
        List<Account> targetAccount = fetchAccounts(1);

        Test.startTest();
        AccountHelper.updateAccounts(new List<Id>{targetAccount[0].Id});
        Test.stopTest();

        assertAnnualRevenueEqualsTarget(new List<Id>{targetAccount[0].Id});
    }

    private static List<Account> fetchAccounts(Integer recordLimit) {
        return [
            SELECT Id, AnnualRevenue
            FROM Account
            ORDER BY CreatedDate ASC
            LIMIT :recordLimit
        ];
    }

    private static void assertAnnualRevenueEqualsTarget(List<Id> accountIds) {
        for (Account refreshedAccount : [
            SELECT Id, AnnualRevenue
            FROM Account
            WHERE Id IN :accountIds
        ]) {
            System.assertEquals(
                AccountHelper.TARGET_ANNUAL_REVENUE,
                refreshedAccount.AnnualRevenue,
                'AnnualRevenue should be updated for Account ' + refreshedAccount.Id
            );
        }
    }

    private static Id buildInvalidAccountId() {
        return Id.valueOf('001000000000000AAA');
    }
}