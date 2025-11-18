public with sharing class AccountHelper {
    /**
     * Updates the rating for a single Account record. This method delegates to the bulk-safe method to
     * ensure consistent validation and behavior.
     *
     * @param accountId The Id of the Account to update (required).
     * @param rating The new rating value to apply (required).
     */
    public static void updateAccountRating(Id accountId, String rating) {
        if (accountId == null) {
            throw new IllegalArgumentException('Account Id is required.');
        }
        if (String.isBlank(rating)) {
            throw new IllegalArgumentException('Rating is required.');
        }

        updateAccountRatings(new Map<Id, String>{accountId => rating});
    }

    /**
     * Bulk-safe method to update Account ratings.
     *
     * @param accountRatings Map of Account Ids to the desired rating value. Null or blank rating values
     *                       are ignored to avoid overwriting existing data unintentionally.
     */
    public static void updateAccountRatings(Map<Id, String> accountRatings) {
        if (accountRatings == null || accountRatings.isEmpty()) {
            return;
        }

        Set<Id> validAccountIds = new Set<Id>();
        for (Id accountId : accountRatings.keySet()) {
            if (accountId != null) {
                validAccountIds.add(accountId);
            }
        }

        if (validAccountIds.isEmpty()) {
            return;
        }

        List<Account> accountsToUpdate = [
            SELECT Id, Rating
            FROM Account
            WHERE Id IN :validAccountIds
            FOR UPDATE
        ];

        for (Account acc : accountsToUpdate) {
            String newRating = accountRatings.get(acc.Id);
            if (String.isNotBlank(newRating)) {
                acc.Rating = newRating;
            }
        }

        if (!accountsToUpdate.isEmpty()) {
            Database.update(accountsToUpdate, false);
        }
    }
}