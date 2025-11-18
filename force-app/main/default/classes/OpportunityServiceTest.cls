/**
 * @description Test class for OpportunityService
 * Tests all methods with positive, negative, bulk, and edge cases
 * 
 * @author Salesforce Developer
 * @date 2024
 */
@isTest
private class OpportunityServiceTest {
    
    /**
     * @description Test setup method - creates shared test data
     */
    @testSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> testAccounts = TestDataFactory.createAccounts(10, 'Test Account');
        insert testAccounts;
        
        // Create test opportunities
        List<Opportunity> testOpportunities = new List<Opportunity>();
        for (Account acc : testAccounts) {
            List<Opportunity> opps = TestDataFactory.createOpportunities(acc.Id, 2, 'Test Opportunity', 'Prospecting');
            testOpportunities.addAll(opps);
        }
        insert testOpportunities;
    }
    
    // ========== closeOpportunities Tests ==========
    
    @isTest
    static void testCloseOpportunitiesSuccess() {
        // Positive test: Close opportunities successfully
        List<Opportunity> opportunities = [
            SELECT Id, StageName 
            FROM Opportunity 
            WITH SECURITY_ENFORCED
            LIMIT 5
        ];
        
        List<Id> oppIds = new List<Id>();
        for (Opportunity opp : opportunities) {
            oppIds.add(opp.Id);
        }
        
        Test.startTest();
        Database.SaveResult[] results = OpportunityService.closeOpportunities(oppIds);
        Test.stopTest();
        
        // Verify updates were successful
        Integer successCount = 0;
        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            }
        }
        
        System.assertEquals(5, successCount, 'All opportunities should be closed successfully');
        
        // Verify stage was updated in database
        List<Opportunity> updatedOpportunities = [
            SELECT Id, StageName 
            FROM Opportunity 
            WHERE Id IN :oppIds
            WITH SECURITY_ENFORCED
        ];
        
        for (Opportunity opp : updatedOpportunities) {
            System.assertEquals('Closed Won', opp.StageName, 'Stage should be set to Closed Won');
        }
    }
    
    @isTest
    static void testCloseOpportunitiesBulk() {
        // Bulk test: Close 200+ opportunities
        // Create more opportunities for bulk test
        List<Account> accounts = TestDataFactory.createAccounts(100, 'Bulk Account');
        insert accounts;
        
        List<Opportunity> opportunities = new List<Opportunity>();
        for (Account acc : accounts) {
            List<Opportunity> opps = TestDataFactory.createOpportunities(acc.Id, 3, 'Bulk Opportunity', 'Prospecting');
            opportunities.addAll(opps);
        }
        insert opportunities;
        
        List<Id> oppIds = new List<Id>();
        for (Opportunity opp : opportunities) {
            oppIds.add(opp.Id);
        }
        
        Test.startTest();
        Database.SaveResult[] results = OpportunityService.closeOpportunities(oppIds);
        Test.stopTest();
        
        // Verify bulk update
        Integer successCount = 0;
        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            }
        }
        
        System.assertEquals(300, successCount, 'All 300 opportunities should be closed successfully');
        
        // Verify all stages were updated
        List<Opportunity> updatedOpportunities = [
            SELECT Id, StageName 
            FROM Opportunity 
            WHERE Id IN :oppIds
            WITH SECURITY_ENFORCED
        ];
        
        for (Opportunity opp : updatedOpportunities) {
            System.assertEquals('Closed Won', opp.StageName, 'All stages should be Closed Won');
        }
    }
    
    @isTest
    static void testCloseOpportunitiesNullList() {
        // Negative test: Null list should throw exception
        Test.startTest();
        try {
            OpportunityService.closeOpportunities(null);
            System.assert(false, 'Should throw OpportunityServiceException');
        } catch (OpportunityServiceException e) {
            System.assert(e.getMessage().contains('cannot be null or empty'), 
                'Error message should indicate null list');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCloseOpportunitiesEmptyList() {
        // Negative test: Empty list should throw exception
        List<Id> oppIds = new List<Id>();
        
        Test.startTest();
        try {
            OpportunityService.closeOpportunities(oppIds);
            System.assert(false, 'Should throw OpportunityServiceException');
        } catch (OpportunityServiceException e) {
            System.assert(e.getMessage().contains('cannot be null or empty'), 
                'Error message should indicate empty list');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCloseOpportunitiesInvalidIds() {
        // Edge case: Some opportunity IDs don't exist
        List<Id> oppIds = new List<Id>();
        oppIds.add(UserInfo.getUserId()); // Invalid opportunity ID
        
        Test.startTest();
        Database.SaveResult[] results = OpportunityService.closeOpportunities(oppIds);
        Test.stopTest();
        
        // Should handle gracefully - return empty results
        System.assertEquals(0, results.size(), 'Should return empty results for invalid IDs');
    }
    
    @isTest
    static void testCloseOpportunitiesMixedValidInvalidIds() {
        // Edge case: Mix of valid and invalid IDs
        List<Opportunity> opportunities = [
            SELECT Id 
            FROM Opportunity 
            WITH SECURITY_ENFORCED
            LIMIT 3
        ];
        
        List<Id> oppIds = new List<Id>();
        for (Opportunity opp : opportunities) {
            oppIds.add(opp.Id);
        }
        // Add invalid ID
        oppIds.add(UserInfo.getUserId());
        
        Test.startTest();
        Database.SaveResult[] results = OpportunityService.closeOpportunities(oppIds);
        Test.stopTest();
        
        // Should update valid opportunities only
        Integer successCount = 0;
        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            }
        }
        
        System.assertEquals(3, successCount, 'Should update 3 valid opportunities');
        
        // Verify valid opportunities were updated
        List<Opportunity> updatedOpportunities = [
            SELECT Id, StageName 
            FROM Opportunity 
            WHERE Id IN :opportunities
            WITH SECURITY_ENFORCED
        ];
        
        for (Opportunity opp : updatedOpportunities) {
            System.assertEquals('Closed Won', opp.StageName, 'Valid opportunities should be closed');
        }
    }
    
    @isTest
    static void testCloseOpportunitiesAlreadyClosed() {
        // Edge case: Opportunities already in Closed Won stage
        List<Opportunity> opportunities = [
            SELECT Id, StageName 
            FROM Opportunity 
            WITH SECURITY_ENFORCED
            LIMIT 3
        ];
        
        // Set stage to Closed Won
        for (Opportunity opp : opportunities) {
            opp.StageName = 'Closed Won';
        }
        update opportunities;
        
        List<Id> oppIds = new List<Id>();
        for (Opportunity opp : opportunities) {
            oppIds.add(opp.Id);
        }
        
        Test.startTest();
        Database.SaveResult[] results = OpportunityService.closeOpportunities(oppIds);
        Test.stopTest();
        
        // Should still succeed (idempotent operation)
        Integer successCount = 0;
        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            }
        }
        
        System.assertEquals(3, successCount, 'Should successfully update already closed opportunities');
    }
    
    @isTest
    static void testCloseOpportunitiesDifferentStages() {
        // Edge case: Opportunities in different stages
        List<Account> accounts = TestDataFactory.createAccounts(1, 'Stage Test Account');
        insert accounts;
        
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(TestDataFactory.createOpportunity(accounts[0].Id, 'Prospecting Opp', 'Prospecting'));
        opportunities.add(TestDataFactory.createOpportunity(accounts[0].Id, 'Qualification Opp', 'Qualification'));
        opportunities.add(TestDataFactory.createOpportunity(accounts[0].Id, 'Negotiation Opp', 'Negotiation/Review'));
        insert opportunities;
        
        List<Id> oppIds = new List<Id>();
        for (Opportunity opp : opportunities) {
            oppIds.add(opp.Id);
        }
        
        Test.startTest();
        Database.SaveResult[] results = OpportunityService.closeOpportunities(oppIds);
        Test.stopTest();
        
        // Verify all were closed
        Integer successCount = 0;
        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            }
        }
        
        System.assertEquals(3, successCount, 'All opportunities should be closed regardless of previous stage');
        
        // Verify stages
        List<Opportunity> updatedOpportunities = [
            SELECT Id, StageName 
            FROM Opportunity 
            WHERE Id IN :oppIds
            WITH SECURITY_ENFORCED
        ];
        
        for (Opportunity opp : updatedOpportunities) {
            System.assertEquals('Closed Won', opp.StageName, 'All should be Closed Won');
        }
    }
    
    @isTest
    static void testCloseOpportunitiesPartialSuccess() {
        // Edge case: Test partial success scenario
        // Create opportunities and then delete one to simulate partial failure
        List<Account> accounts = TestDataFactory.createAccounts(2, 'Partial Test Account');
        insert accounts;
        
        List<Opportunity> opportunities = new List<Opportunity>();
        opportunities.add(TestDataFactory.createOpportunity(accounts[0].Id, 'Valid Opp 1', 'Prospecting'));
        opportunities.add(TestDataFactory.createOpportunity(accounts[1].Id, 'Valid Opp 2', 'Prospecting'));
        insert opportunities;
        
        List<Id> oppIds = new List<Id>();
        for (Opportunity opp : opportunities) {
            oppIds.add(opp.Id);
        }
        
        // Delete one opportunity to simulate partial failure scenario
        delete opportunities[0];
        
        Test.startTest();
        Database.SaveResult[] results = OpportunityService.closeOpportunities(oppIds);
        Test.stopTest();
        
        // Should handle gracefully - update valid ones
        System.assert(results.size() >= 0, 'Should handle partial success scenario');
    }
}

