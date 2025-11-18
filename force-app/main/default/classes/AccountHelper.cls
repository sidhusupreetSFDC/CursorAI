/**
 * @description Helper class that centralizes Account maintenance logic.
 */
public class AccountHelper {
    public static final Decimal TARGET_ANNUAL_REVENUE = 1000000;
    private static final String DEFAULT_ACCOUNT_ID = 'unknown';
    private static final String ERROR_PREFIX = 'Unable to update accounts: ';

    public class AccountHelperException extends Exception {}

    /**
     * @description Sets AnnualRevenue for the provided Account Ids.
     * @param accountIds Collection of Account record Ids to update.
     */
    public static void updateAccounts(List<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }

        enforceAccountAccess();

        Set<Id> uniqueAccountIds = new Set<Id>(accountIds);
        List<Account> accountsToUpdate = fetchAccounts(uniqueAccountIds);

        if (accountsToUpdate.isEmpty()) {
            return;
        }

        applyTargetRevenue(accountsToUpdate);
        List<Account> sanitizedAccounts = sanitizeForUpdate(accountsToUpdate);
        handleSaveResults(Database.update(sanitizedAccounts, false));
    }

    private static void enforceAccountAccess() {
        if (!Schema.sObjectType.Account.isUpdateable()) {
            throw new AccountHelperException('Insufficient access to update Account records.');
        }

        if (!Schema.sObjectType.Account.fields.AnnualRevenue.isUpdateable()) {
            throw new AccountHelperException('Insufficient field-level access to modify AnnualRevenue.');
        }
    }

    private static List<Account> fetchAccounts(Set<Id> accountIds) {
        return [
            SELECT Id, AnnualRevenue
            FROM Account
            WHERE Id IN :accountIds
        ];
    }

    private static void applyTargetRevenue(List<Account> accountsToUpdate) {
        for (Account accountRecord : accountsToUpdate) {
            accountRecord.AnnualRevenue = TARGET_ANNUAL_REVENUE;
        }
    }

    private static List<Account> sanitizeForUpdate(List<Account> accountsToUpdate) {
        SObjectAccessDecision accessDecision = Security.stripInaccessible(
            AccessType.UPDATABLE,
            accountsToUpdate
        );

        if (!accessDecision.getRemovedFields().isEmpty()) {
            throw new AccountHelperException('AnnualRevenue field is not updateable in the current context.');
        }

        return (List<Account>)accessDecision.getRecords();
    }

    private static void handleSaveResults(Database.SaveResult[] saveResults) {
        List<String> errorMessages = new List<String>();

        for (Database.SaveResult saveResult : saveResults) {
            if (!saveResult.isSuccess()) {
                for (Database.Error error : saveResult.getErrors()) {
                    errorMessages.add(
                        String.format(
                            'Account Id {0}: {1}',
                            new List<String>{
                                saveResult.getId() != null ? saveResult.getId() : DEFAULT_ACCOUNT_ID,
                                error.getMessage()
                            }
                        )
                    );
                }
            }
        }

        if (!errorMessages.isEmpty()) {
            throw new AccountHelperException(ERROR_PREFIX + String.join(errorMessages, '; '));
        }
    }
}