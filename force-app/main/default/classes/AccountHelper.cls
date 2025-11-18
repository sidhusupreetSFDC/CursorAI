/**
 * @description Helper class for Account operations
 * @author Salesforce Developer
 * @date 2024
 */
public with sharing class AccountHelper {
    private static final Decimal TARGET_ANNUAL_REVENUE = 1000000;

    /**
     * @description Updates AnnualRevenue for the provided Account records
     * @param accountIds List of Account Ids to update
     * @throws AccountHelperException if operation fails
     */
    public static void updateAccounts(List<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }

        List<Account> accountsToUpdate = fetchAccounts(accountIds);
        if (accountsToUpdate.isEmpty()) {
            return;
        }

        validateFieldAccess();
        applyTargetRevenue(accountsToUpdate);
        performUpdate(accountsToUpdate);
    }

    /**
     * @description Fetches Account records for the provided Ids
     * @param accountIds List of Account Ids to query
     * @return List of Account records
     */
    private static List<Account> fetchAccounts(List<Id> accountIds) {
        return [
            SELECT Id, Name, AnnualRevenue
            FROM Account
            WHERE Id IN :accountIds
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * @description Validates field-level security for AnnualRevenue
     * @throws SecurityException if field is not updateable
     */
    private static void validateFieldAccess() {
        if (!Schema.sObjectType.Account.fields.AnnualRevenue.isUpdateable()) {
            throw new SecurityException('Insufficient permissions to update AnnualRevenue field');
        }
    }

    /**
     * @description Applies target revenue to all accounts
     * @param accounts List of Account records to update
     */
    private static void applyTargetRevenue(List<Account> accounts) {
        for (Account acc : accounts) {
            acc.AnnualRevenue = TARGET_ANNUAL_REVENUE;
        }
    }

    /**
     * @description Performs bulk update operation
     * @param accounts List of Account records to update
     * @throws AccountHelperException if update fails
     */
    private static void performUpdate(List<Account> accounts) {
        try {
            update accounts;
        } catch (DmlException e) {
            throw new AccountHelperException('Error updating Accounts: ' + e.getMessage(), e);
        } catch (Exception e) {
            throw new AccountHelperException('Unexpected error updating Accounts: ' + e.getMessage(), e);
        }
    }

    /**
     * @description Custom exception class for AccountHelper operations
     */
    public class AccountHelperException extends Exception {}
}
