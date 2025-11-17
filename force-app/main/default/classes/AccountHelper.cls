public class AccountHelper {
    public static void updateAccountRating(Id accountId, String rating) {
        Account acc = [SELECT Id, Rating FROM Account WHERE Id = :accountId];
        acc.Rating = rating;
        update acc;
    }
}