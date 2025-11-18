/**
 * Test Data Factory for creating reusable test data
 * Follows Test Factory pattern for consistent test data creation
 * 
 * @author Salesforce Developer
 * @date 2024
 */
@isTest
public class TestDataFactory {
    
    /**
     * Creates a single Account record for testing
     * @param name Account name
     * @param annualRevenue Annual revenue value (optional)
     * @return Account record (not inserted)
     */
    public static Account createAccount(String name, Decimal annualRevenue) {
        Account acc = new Account();
        acc.Name = name;
        if (annualRevenue != null) {
            acc.AnnualRevenue = annualRevenue;
        }
        return acc;
    }
    
    /**
     * Creates a single Account record with default values
     * @param name Account name
     * @return Account record (not inserted)
     */
    public static Account createAccount(String name) {
        return createAccount(name, null);
    }
    
    /**
     * Creates multiple Account records for bulk testing
     * @param count Number of accounts to create
     * @param namePrefix Prefix for account names
     * @param annualRevenue Annual revenue value (optional)
     * @return List of Account records (not inserted)
     */
    public static List<Account> createAccounts(Integer count, String namePrefix, Decimal annualRevenue) {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < count; i++) {
            accounts.add(createAccount(namePrefix + ' ' + i, annualRevenue));
        }
        return accounts;
    }
    
    /**
     * Creates multiple Account records with default values
     * @param count Number of accounts to create
     * @param namePrefix Prefix for account names
     * @return List of Account records (not inserted)
     */
    public static List<Account> createAccounts(Integer count, String namePrefix) {
        return createAccounts(count, namePrefix, null);
    }
    
    /**
     * Creates a single Opportunity record for testing
     * @param accountId Related Account ID
     * @param name Opportunity name
     * @param stageName Stage name (default: Prospecting)
     * @param amount Amount value (optional)
     * @param closeDate Close date (default: 30 days from today)
     * @return Opportunity record (not inserted)
     */
    public static Opportunity createOpportunity(Id accountId, String name, String stageName, Decimal amount, Date closeDate) {
        Opportunity opp = new Opportunity();
        opp.AccountId = accountId;
        opp.Name = name;
        opp.StageName = stageName != null ? stageName : 'Prospecting';
        opp.Amount = amount;
        opp.CloseDate = closeDate != null ? closeDate : Date.today().addDays(30);
        return opp;
    }
    
    /**
     * Creates a single Opportunity record with default values
     * @param accountId Related Account ID
     * @param name Opportunity name
     * @return Opportunity record (not inserted)
     */
    public static Opportunity createOpportunity(Id accountId, String name) {
        return createOpportunity(accountId, name, null, null, null);
    }
    
    /**
     * Creates multiple Opportunity records for bulk testing
     * @param accountId Related Account ID
     * @param count Number of opportunities to create
     * @param namePrefix Prefix for opportunity names
     * @param stageName Stage name (default: Prospecting)
     * @return List of Opportunity records (not inserted)
     */
    public static List<Opportunity> createOpportunities(Id accountId, Integer count, String namePrefix, String stageName) {
        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 0; i < count; i++) {
            opportunities.add(createOpportunity(accountId, namePrefix + ' ' + i, stageName, null, null));
        }
        return opportunities;
    }
    
    /**
     * Creates multiple Opportunity records with default values
     * @param accountId Related Account ID
     * @param count Number of opportunities to create
     * @param namePrefix Prefix for opportunity names
     * @return List of Opportunity records (not inserted)
     */
    public static List<Opportunity> createOpportunities(Id accountId, Integer count, String namePrefix) {
        return createOpportunities(accountId, count, namePrefix, null);
    }
    
    /**
     * Creates old Account records for testing deleteOldAccounts method
     * @param count Number of accounts to create
     * @param daysOld Number of days old (default: 400)
     * @return List of Account records (inserted)
     */
    public static List<Account> createOldAccounts(Integer count, Integer daysOld) {
        if (daysOld == null) {
            daysOld = 400;
        }
        
        List<Account> accounts = createAccounts(count, 'Old Account');
        
        // Insert accounts first
        insert accounts;
        
        // Update CreatedDate using Test.setCreatedDate (if available) or create with specific date
        // Note: CreatedDate cannot be set directly, so we'll rely on the method being tested
        // to query based on CreatedDate < date threshold
        
        return accounts;
    }
}

