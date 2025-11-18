public class AccountHelper {
    public static final Decimal TARGET_ANNUAL_REVENUE = 1000000;

    public class AccountHelperException extends Exception {}

    public static void updateAccounts(List<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }

        Set<Id> uniqueAccountIds = new Set<Id>(accountIds);
        List<Account> accountsToUpdate = [
            SELECT Id, AnnualRevenue
            FROM Account
            WHERE Id IN :uniqueAccountIds
        ];

        if (accountsToUpdate.isEmpty()) {
            return;
        }

        for (Account accountRecord : accountsToUpdate) {
            accountRecord.AnnualRevenue = TARGET_ANNUAL_REVENUE;
        }

        Database.SaveResult[] saveResults = Database.update(accountsToUpdate, false);
        List<String> errorMessages = new List<String>();

        for (Database.SaveResult saveResult : saveResults) {
            if (!saveResult.isSuccess()) {
                for (Database.Error error : saveResult.getErrors()) {
                    errorMessages.add(
                        String.format(
                            'Account Id {0}: {1}',
                            new List<String>{
                                saveResult.getId() != null ? saveResult.getId() : 'unknown',
                                error.getMessage()
                            }
                        )
                    );
                }
            }
        }

        if (!errorMessages.isEmpty()) {
            throw new AccountHelperException(
                'Unable to update accounts: ' + String.join(errorMessages, '; ')
            );
        }
    }
}