/**
 * Helper class for Account-related operations
 * Provides utility methods for managing Account records
 */
public class AccountHelper {
    /**
     * Updates the Rating field for a specific Account record
     * @param accountId The Id of the Account to update
     * @param rating The new rating value to set
     * @throws IllegalArgumentException if accountId is null or rating is null/empty
     * @throws QueryException if the Account record is not found
     * @throws DmlException if the update operation fails
     */
    public static void updateAccountRating(Id accountId, String rating) {
        // Input validation
        if (accountId == null) {
            throw new IllegalArgumentException('Account Id cannot be null');
        }
        if (String.isBlank(rating)) {
            throw new IllegalArgumentException('Rating cannot be null or empty');
        }

        try {
            // Query the Account record
            List<Account> accounts = [
                SELECT Id, Rating
                FROM Account
                WHERE Id = :accountId
                LIMIT 1
            ];

            if (accounts.isEmpty()) {
                throw new QueryException('Account not found with Id: ' + accountId);
            }

            Account accountToUpdate = accounts[0];
            accountToUpdate.Rating = rating;

            // Update the Account record
            update accountToUpdate;
        } catch (DmlException e) {
            System.debug(
                LoggingLevel.ERROR,
                'Error updating Account Rating: ' + e.getMessage()
            );
            throw new DmlException(
                'Failed to update Account Rating: ' + e.getMessage()
            );
        } catch (QueryException e) {
            System.debug(
                LoggingLevel.ERROR,
                'Error querying Account: ' + e.getMessage()
            );
            throw e;
        } catch (Exception e) {
            System.debug(
                LoggingLevel.ERROR,
                'Unexpected error in updateAccountRating: ' + e.getMessage()
            );
            throw e;
        }
    }
}