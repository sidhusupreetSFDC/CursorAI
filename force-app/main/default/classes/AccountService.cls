public class AccountService {
    public static void createAccount(String name, Decimal revenue) {
        Account acc = new Account();
        acc.Name = name;
        acc.AnnualRevenue = revenue;
        insert acc;
    }
    
    public static void updateAccountRevenue(Id accountId, Decimal newRevenue) {
        Account acc = [SELECT Id FROM Account WHERE Id = :accountId];
        acc.AnnualRevenue = newRevenue;
        update acc;
    }
    
    public static void deleteOldAccounts() {
        List<Account> oldAccounts = [SELECT Id FROM Account WHERE CreatedDate < LAST_N_DAYS:365];
        delete oldAccounts;
    }
}