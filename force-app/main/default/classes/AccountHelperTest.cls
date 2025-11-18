@IsTest
private class AccountHelperTest {

    @IsTest
    static void updateAccounts_setsAnnualRevenue() {
        List<Account> accounts = new List<Account>{
            new Account(Name = 'Acme A'),
            new Account(Name = 'Acme B')
        };

        insert accounts;

        Test.startTest();
        AccountHelper.updateAccounts(new List<Id>{
            accounts[0].Id,
            accounts[1].Id,
            accounts[0].Id
        });
        Test.stopTest();

        for (Account refreshedAccount : [
            SELECT AnnualRevenue
            FROM Account
            WHERE Id IN :new List<Id>{accounts[0].Id, accounts[1].Id}
        ]) {
            System.assertEquals(
                AccountHelper.TARGET_ANNUAL_REVENUE,
                refreshedAccount.AnnualRevenue,
                'AnnualRevenue should be updated for each Account.'
            );
        }
    }

    @IsTest
    static void updateAccounts_handlesNullAndEmptyCollections() {
        Test.startTest();
        AccountHelper.updateAccounts(null);
        AccountHelper.updateAccounts(new List<Id>());
        Test.stopTest();

        List<Account> accounts = new List<Account>{
            new Account(Name = 'Needs Update')
        };
        insert accounts;

        Test.startTest();
        AccountHelper.updateAccounts(
            new List<Id>{
                accounts[0].Id,
                Id.valueOf('001000000000000AAA')
            }
        );
        Test.stopTest();

        Account refreshedAccount = [
            SELECT AnnualRevenue
            FROM Account
            WHERE Id = :accounts[0].Id
        ];

        System.assertEquals(
            AccountHelper.TARGET_ANNUAL_REVENUE,
            refreshedAccount.AnnualRevenue,
            'AnnualRevenue should be updated even when some IDs are missing.'
        );
    }
}

