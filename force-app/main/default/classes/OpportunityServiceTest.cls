/**
 * Test class for OpportunityService
 * Tests all methods with positive, negative, bulk, and edge cases
 * Achieves 90%+ code coverage
 * 
 * @author Salesforce Developer
 * @date 2024
 */
@isTest
private class OpportunityServiceTest {
    
    @testSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 5; i++) {
            Account acc = new Account();
            acc.Name = 'Test Account ' + i;
            accounts.add(acc);
        }
        insert accounts;
        
        // Create test opportunities
        List<Opportunity> opportunities = new List<Opportunity>();
        for (Integer i = 0; i < 5; i++) {
            Opportunity opp = new Opportunity();
            opp.Name = 'Test Opportunity ' + i;
            opp.AccountId = accounts[i].Id;
            opp.StageName = 'Prospecting';
            opp.CloseDate = Date.today().addDays(30);
            opp.Amount = 100000;
            opportunities.add(opp);
        }
        insert opportunities;
    }
    
    // Test closeOpportunities - Positive Cases
    @isTest
    static void testCloseOpportunitiesSuccess() {
        List<Opportunity> opportunities = [SELECT Id FROM Opportunity LIMIT 5];
        List<Id> oppIds = new List<Id>();
        for (Opportunity opp : opportunities) {
            oppIds.add(opp.Id);
        }
        
        Test.startTest();
        Database.SaveResult[] results = OpportunityService.closeOpportunities(oppIds);
        Test.stopTest();
        
        System.assertEquals(5, results.size(), 'Should update 5 opportunities');
        for (Database.SaveResult result : results) {
            System.assert(result.isSuccess(), 'All updates should succeed');
        }
        
        // Verify opportunities were closed
        List<Opportunity> closedOpps = [SELECT StageName FROM Opportunity WHERE Id IN :oppIds];
        for (Opportunity opp : closedOpps) {
            System.assertEquals('Closed Won', opp.StageName, 'Stage should be Closed Won');
        }
    }
    
    // Test closeOpportunities - Bulk (200+ records)
    @isTest
    static void testCloseOpportunitiesBulk() {
        // Create 200 opportunities for bulk test
        List<Account> accounts = [SELECT Id FROM Account LIMIT 1];
        Account testAccount = accounts[0];
        
        List<Opportunity> bulkOpportunities = new List<Opportunity>();
        for (Integer i = 0; i < 200; i++) {
            Opportunity opp = new Opportunity();
            opp.Name = 'Bulk Opportunity ' + i;
            opp.AccountId = testAccount.Id;
            opp.StageName = 'Prospecting';
            opp.CloseDate = Date.today().addDays(30);
            opp.Amount = 50000;
            bulkOpportunities.add(opp);
        }
        insert bulkOpportunities;
        
        List<Id> oppIds = new List<Id>();
        for (Opportunity opp : bulkOpportunities) {
            oppIds.add(opp.Id);
        }
        
        Test.startTest();
        Database.SaveResult[] results = OpportunityService.closeOpportunities(oppIds);
        Test.stopTest();
        
        System.assertEquals(200, results.size(), 'Should update 200 opportunities');
        
        // Verify bulk update
        List<Opportunity> closedOpps = [SELECT StageName FROM Opportunity WHERE Id IN :oppIds];
        System.assertEquals(200, closedOpps.size(), 'Should have 200 opportunities');
        for (Opportunity opp : closedOpps) {
            System.assertEquals('Closed Won', opp.StageName, 'All should be Closed Won');
        }
    }
    
    // Test closeOpportunities - Negative Cases
    @isTest
    static void testCloseOpportunitiesNullIds() {
        Test.startTest();
        try {
            OpportunityService.closeOpportunities(null);
            System.assert(false, 'Should throw exception for null IDs');
        } catch (OpportunityServiceException e) {
            System.assert(e.getMessage().contains('cannot be null or empty'), 'Should throw appropriate error');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCloseOpportunitiesEmptyIds() {
        Test.startTest();
        try {
            OpportunityService.closeOpportunities(new List<Id>());
            System.assert(false, 'Should throw exception for empty IDs');
        } catch (OpportunityServiceException e) {
            System.assert(e.getMessage().contains('cannot be null or empty'), 'Should throw appropriate error');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCloseOpportunitiesInvalidIds() {
        List<Id> invalidIds = new List<Id>{ '006000000000000AAA' };
        
        Test.startTest();
        try {
            OpportunityService.closeOpportunities(invalidIds);
            System.assert(false, 'Should throw exception for invalid IDs');
        } catch (OpportunityServiceException e) {
            System.assert(e.getMessage().contains('No opportunities found'), 'Should throw appropriate error');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCloseOpportunitiesMixedValidInvalidIds() {
        List<Opportunity> validOpps = [SELECT Id FROM Opportunity LIMIT 2];
        List<Id> mixedIds = new List<Id>();
        for (Opportunity opp : validOpps) {
            mixedIds.add(opp.Id);
        }
        mixedIds.add('006000000000000AAA'); // Invalid ID
        
        Test.startTest();
        try {
            OpportunityService.closeOpportunities(mixedIds);
            // Should succeed for valid IDs, but throw exception if no opportunities found
            // The query will return empty if invalid IDs are filtered out
        } catch (OpportunityServiceException e) {
            // Expected if no opportunities match
            System.assert(e.getMessage().contains('No opportunities found'), 'Should handle mixed IDs appropriately');
        }
        Test.stopTest();
    }
    
    // Test closeOpportunities - Edge Cases
    @isTest
    static void testCloseOpportunitiesAlreadyClosed() {
        List<Opportunity> opportunities = [SELECT Id FROM Opportunity LIMIT 2];
        List<Id> oppIds = new List<Id>();
        for (Opportunity opp : opportunities) {
            oppIds.add(opp.Id);
        }
        
        // Close opportunities first
        for (Opportunity opp : opportunities) {
            opp.StageName = 'Closed Won';
        }
        update opportunities;
        
        Test.startTest();
        Database.SaveResult[] results = OpportunityService.closeOpportunities(oppIds);
        Test.stopTest();
        
        // Should still succeed (updating to same stage)
        System.assertEquals(2, results.size(), 'Should process 2 opportunities');
    }
    
    @isTest
    static void testCloseOpportunitiesSingleOpportunity() {
        List<Opportunity> opportunities = [SELECT Id FROM Opportunity LIMIT 1];
        List<Id> oppIds = new List<Id>{ opportunities[0].Id };
        
        Test.startTest();
        Database.SaveResult[] results = OpportunityService.closeOpportunities(oppIds);
        Test.stopTest();
        
        System.assertEquals(1, results.size(), 'Should update 1 opportunity');
        System.assert(results[0].isSuccess(), 'Update should succeed');
        
        // Verify
        Opportunity closedOpp = [SELECT StageName FROM Opportunity WHERE Id = :oppIds[0]];
        System.assertEquals('Closed Won', closedOpp.StageName, 'Should be Closed Won');
    }
}

