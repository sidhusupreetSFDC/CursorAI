/**
 * @description Service class for Account operations.
 *              Provides bulkified methods for updating Account records with proper
 *              security enforcement and error handling.
 *              Follows SOLID principles and Salesforce best practices.
 * @author Salesforce
 * @date 2025
 */
public with sharing class AccountHelper {
    /** @description Target Annual Revenue value to set on Account records */
    public static final Decimal TARGET_ANNUAL_REVENUE = 1000000;
    
    private static final String DEFAULT_ACCOUNT_ID = 'unknown';
    private static final String ERROR_PREFIX = 'Unable to update accounts: ';
    private static final String ERROR_INSUFFICIENT_OBJECT_ACCESS = 'Insufficient access to update Account records.';
    private static final String ERROR_INSUFFICIENT_FIELD_ACCESS = 'Insufficient field-level access to modify AnnualRevenue.';
    private static final String ERROR_FIELD_REMOVED_BY_SECURITY = 'AnnualRevenue field is not updateable in the current context.';
    private static final String ERROR_ACCOUNT_ID_FORMAT = 'Account Id {0}: {1}';

    /**
     * @description Custom exception for AccountHelper operations
     */
    public class AccountHelperException extends Exception {}

    /**
     * @description Sets AnnualRevenue for the provided Account Ids.
     *              Handles bulk operations, enforces security, and provides detailed error reporting.
     * @param accountIds Collection of Account record Ids to update. Duplicates are automatically handled.
     * @throws AccountHelperException if security checks fail or DML operations encounter errors
     */
    public static void updateAccounts(List<Id> accountIds) {
        try {
            validateInputs(accountIds);
            
            enforceAccountAccess();

            Set<Id> uniqueAccountIds = deduplicateAccountIds(accountIds);
            List<Account> accountsToUpdate = fetchAccounts(uniqueAccountIds);

            if (accountsToUpdate.isEmpty()) {
                return;
            }

            applyTargetRevenue(accountsToUpdate);
            List<Account> sanitizedAccounts = sanitizeForUpdate(accountsToUpdate);
            performBulkUpdate(sanitizedAccounts);
        } catch (AccountHelperException ex) {
            throw ex;
        } catch (Exception ex) {
            throw new AccountHelperException(
                'Unexpected error occurred while updating accounts: ' + ex.getMessage(),
                ex
            );
        }
    }

    /**
     * @description Validates input parameters
     * @param accountIds List of Account Ids to validate
     */
    private static void validateInputs(List<Id> accountIds) {
        if (accountIds == null || accountIds.isEmpty()) {
            return;
        }
    }

    /**
     * @description Removes duplicate Account Ids from the input list
     * @param accountIds List of Account Ids that may contain duplicates
     * @return Set of unique Account Ids
     */
    private static Set<Id> deduplicateAccountIds(List<Id> accountIds) {
        return new Set<Id>(accountIds);
    }

    /**
     * @description Performs bulk update operation with error handling
     * @param accountsToUpdate List of Account records to update
     * @throws AccountHelperException if update operation fails
     */
    private static void performBulkUpdate(List<Account> accountsToUpdate) {
        if (accountsToUpdate == null || accountsToUpdate.isEmpty()) {
            return;
        }

        Database.SaveResult[] saveResults = Database.update(accountsToUpdate, false);
        handleSaveResults(saveResults);
    }

    /**
     * @description Enforces CRUD and FLS permissions for Account updates
     * @throws AccountHelperException if insufficient permissions are detected
     */
    private static void enforceAccountAccess() {
        if (!Schema.sObjectType.Account.isUpdateable()) {
            throw new AccountHelperException(ERROR_INSUFFICIENT_OBJECT_ACCESS);
        }

        if (!Schema.sObjectType.Account.fields.AnnualRevenue.isUpdateable()) {
            throw new AccountHelperException(ERROR_INSUFFICIENT_FIELD_ACCESS);
        }
    }

    /**
     * @description Fetches Account records for the provided Ids
     * @param accountIds Set of unique Account Ids to query
     * @return List of Account records with Id and AnnualRevenue fields
     */
    private static List<Account> fetchAccounts(Set<Id> accountIds) {
        return [
            SELECT Id, AnnualRevenue
            FROM Account
            WHERE Id IN :accountIds
            WITH SECURITY_ENFORCED
        ];
    }

    /**
     * @description Applies the target Annual Revenue to all accounts in the list
     * @param accountsToUpdate List of Account records to update
     */
    private static void applyTargetRevenue(List<Account> accountsToUpdate) {
        if (accountsToUpdate == null || accountsToUpdate.isEmpty()) {
            return;
        }

        for (Account accountRecord : accountsToUpdate) {
            if (accountRecord != null) {
                accountRecord.AnnualRevenue = TARGET_ANNUAL_REVENUE;
            }
        }
    }

    /**
     * @description Sanitizes Account records using Security.stripInaccessible
     *              to ensure only accessible fields are updated
     * @param accountsToUpdate List of Account records to sanitize
     * @return List of sanitized Account records
     * @throws AccountHelperException if AnnualRevenue field is removed by security enforcement
     */
    private static List<Account> sanitizeForUpdate(List<Account> accountsToUpdate) {
        SObjectAccessDecision accessDecision = Security.stripInaccessible(
            AccessType.UPDATABLE,
            accountsToUpdate
        );

        Map<String, Set<String>> removedFields = accessDecision.getRemovedFields();
        if (!removedFields.isEmpty() && removedFields.containsKey('AnnualRevenue')) {
            throw new AccountHelperException(ERROR_FIELD_REMOVED_BY_SECURITY);
        }

        return (List<Account>)accessDecision.getRecords();
    }

    /**
     * @description Processes Database.SaveResult array and throws exception if any failures occur
     * @param saveResults Array of SaveResult objects from DML operation
     * @throws AccountHelperException if any save operations failed, with detailed error messages
     */
    private static void handleSaveResults(Database.SaveResult[] saveResults) {
        if (saveResults == null || saveResults.isEmpty()) {
            return;
        }

        List<String> errorMessages = new List<String>();

        for (Database.SaveResult saveResult : saveResults) {
            if (saveResult != null && !saveResult.isSuccess()) {
                String accountId = saveResult.getId() != null 
                    ? String.valueOf(saveResult.getId()) 
                    : DEFAULT_ACCOUNT_ID;
                
                for (Database.Error error : saveResult.getErrors()) {
                    if (error != null) {
                        errorMessages.add(
                            String.format(
                                ERROR_ACCOUNT_ID_FORMAT,
                                new List<String>{
                                    accountId,
                                    error.getMessage()
                                }
                            )
                        );
                    }
                }
            }
        }

        if (!errorMessages.isEmpty()) {
            throw new AccountHelperException(
                ERROR_PREFIX + String.join(errorMessages, '; ')
            );
        }
    }
}