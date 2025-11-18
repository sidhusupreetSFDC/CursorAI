/**
 * Helper class for Account-related operations.
 * Provides utility methods for common Account data manipulation tasks.
 */
public class AccountHelper {
    
    /**
     * Updates the Rating field for a single Account record.
     * 
     * @param accountId The Id of the Account record to update
     * @param rating The new rating value to assign to the Account
     * @throws NullPointerException if accountId is null
     * @throws Exception if rating is null or empty
     * @throws QueryException if the Account record is not found
     * @throws DmlException if the update operation fails
     */
    public static void updateAccountRating(Id accountId, String rating) {
        // Validate input parameters
        if (accountId == null) {
            throw new NullPointerException('Account Id cannot be null');
        }
        if (String.isBlank(rating)) {
            throw new Exception('Rating cannot be null or empty');
        }
        
        try {
            // Query the Account record
            Account account = [
                SELECT Id, Rating 
                FROM Account 
                WHERE Id = :accountId 
                LIMIT 1
            ];
            
            // Update the rating
            account.Rating = rating;
            update account;
        } catch (QueryException e) {
            throw new QueryException('Account not found with Id: ' + accountId, e);
        } catch (DmlException e) {
            throw new DmlException('Failed to update Account rating: ' + e.getMessage(), e);
        }
    }
}