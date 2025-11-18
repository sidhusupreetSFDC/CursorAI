/**
 * Test Data Factory for creating reusable test data
 * Provides methods to create test records for Accounts, Opportunities, and related objects
 * Follows best practices for test data creation
 */
@isTest
public class TestDataFactory {
    
    /**
     * Creates a single Account with specified name and revenue
     * @param name Account name
     * @param revenue Annual revenue
     * @return Account record (not inserted)
     */
    public static Account createAccount(String name, Decimal revenue) {
        Account acc = new Account();
        acc.Name = name;
        acc.AnnualRevenue = revenue;
        return acc;
    }
    
    /**
     * Creates and inserts a single Account
     * @param name Account name
     * @param revenue Annual revenue
     * @return Inserted Account record
     */
    public static Account createAndInsertAccount(String name, Decimal revenue) {
        Account acc = createAccount(name, revenue);
        insert acc;
        return acc;
    }
    
    /**
     * Creates a list of Account records (not inserted)
     * @param count Number of accounts to create
     * @param namePrefix Prefix for account names
     * @param revenue Annual revenue value
     * @return List of Account records
     */
    public static List<Account> createAccounts(Integer count, String namePrefix, Decimal revenue) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(createAccount(namePrefix + ' ' + i, revenue));
        }
        return accounts;
    }
    
    /**
     * Creates and inserts a list of Account records
     * @param count Number of accounts to create
     * @param namePrefix Prefix for account names
     * @param revenue Annual revenue value
     * @return List of inserted Account records
     */
    public static List<Account> createAndInsertAccounts(Integer count, String namePrefix, Decimal revenue) {
        List<Account> accounts = createAccounts(count, namePrefix, revenue);
        insert accounts;
        return accounts;
    }
    
    /**
     * Creates a single Opportunity with specified account and stage
     * @param accountId Account ID
     * @param name Opportunity name
     * @param stageName Stage name
     * @param amount Amount value
     * @param closeDate Close date
     * @return Opportunity record (not inserted)
     */
    public static Opportunity createOpportunity(Id accountId, String name, String stageName, Decimal amount, Date closeDate) {
        Opportunity opp = new Opportunity();
        opp.AccountId = accountId;
        opp.Name = name;
        opp.StageName = stageName;
        opp.Amount = amount;
        opp.CloseDate = closeDate;
        return opp;
    }
    
    /**
     * Creates and inserts a single Opportunity
     * @param accountId Account ID
     * @param name Opportunity name
     * @param stageName Stage name
     * @param amount Amount value
     * @param closeDate Close date
     * @return Inserted Opportunity record
     */
    public static Opportunity createAndInsertOpportunity(Id accountId, String name, String stageName, Decimal amount, Date closeDate) {
        Opportunity opp = createOpportunity(accountId, name, stageName, amount, closeDate);
        insert opp;
        return opp;
    }
    
    /**
     * Creates a list of Opportunity records (not inserted)
     * @param accountId Account ID
     * @param count Number of opportunities to create
     * @param namePrefix Prefix for opportunity names
     * @param stageName Stage name
     * @param amount Amount value
     * @param closeDate Close date
     * @return List of Opportunity records
     */
    public static List<Opportunity> createOpportunities(Id accountId, Integer count, String namePrefix, String stageName, Decimal amount, Date closeDate) {
        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 0; i < count; i++) {
            opportunities.add(createOpportunity(accountId, namePrefix + ' ' + i, stageName, amount, closeDate));
        }
        return opportunities;
    }
    
    /**
     * Creates and inserts a list of Opportunity records
     * @param accountId Account ID
     * @param count Number of opportunities to create
     * @param namePrefix Prefix for opportunity names
     * @param stageName Stage name
     * @param amount Amount value
     * @param closeDate Close date
     * @return List of inserted Opportunity records
     */
    public static List<Opportunity> createAndInsertOpportunities(Id accountId, Integer count, String namePrefix, String stageName, Decimal amount, Date closeDate) {
        List<Opportunity> opportunities = createOpportunities(accountId, count, namePrefix, stageName, amount, closeDate);
        insert opportunities;
        return opportunities;
    }
    
    /**
     * Creates old Account records for testing delete functionality
     * Uses Test.setCreatedDate to set creation date in the past
     * @param count Number of accounts to create
     * @param daysOld Number of days ago to set creation date
     * @return List of inserted Account records
     */
    public static List<Account> createOldAccounts(Integer count, Integer daysOld) {
        List<Account> accounts = createAndInsertAccounts(count, 'Old Account', 1000);
        
        // Set created date to daysOld days ago
        Datetime oldDate = Datetime.now().addDays(-daysOld);
        for (Account acc : accounts) {
            Test.setCreatedDate(acc.Id, oldDate);
        }
        
        return accounts;
    }
}

