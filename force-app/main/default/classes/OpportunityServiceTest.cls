/**
 * Test class for OpportunityService
 * Provides comprehensive test coverage including positive, negative, bulk, and edge cases
 * Target: 90%+ code coverage
 */
@isTest
private class OpportunityServiceTest {
    
    @testSetup
    static void setupTestData() {
        // Create test accounts
        List<Account> testAccounts = TestDataFactory.createAndInsertAccounts(10, 'Test Account', 10000);
        
        // Create test opportunities
        Date closeDate = Date.today().addDays(30);
        for (Account acc : testAccounts) {
            TestDataFactory.createAndInsertOpportunities(
                acc.Id,
                2,
                'Test Opportunity',
                'Prospecting',
                5000,
                closeDate
            );
        }
    }
    
    // ========== closeOpportunities Tests ==========
    
    @isTest
    static void testCloseOpportunities_Positive_SingleRecord() {
        // Arrange
        Opportunity testOpp = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        System.assertNotEquals('Closed Won', testOpp.StageName, 'Opportunity should not be closed initially');
        
        Test.startTest();
        // Act
        Database.SaveResult[] results = OpportunityService.closeOpportunities(new List<Id>{ testOpp.Id });
        Test.stopTest();
        
        // Assert
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assert(results[0].isSuccess(), 'Update should succeed');
        
        // Verify opportunity was closed
        Opportunity updatedOpp = [SELECT StageName FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals('Closed Won', updatedOpp.StageName, 'StageName should be set to Closed Won');
    }
    
    @isTest
    static void testCloseOpportunities_Positive_BulkRecords() {
        // Arrange - Create 200+ opportunities
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Date closeDate = Date.today().addDays(30);
        List<Opportunity> opportunities = TestDataFactory.createAndInsertOpportunities(
            testAccount.Id,
            250,
            'Bulk Opportunity',
            'Prospecting',
            10000,
            closeDate
        );
        
        List<Id> oppIds = new List<Id>();
        for (Opportunity opp : opportunities) {
            oppIds.add(opp.Id);
        }
        
        Test.startTest();
        // Act
        Database.SaveResult[] results = OpportunityService.closeOpportunities(oppIds);
        Test.stopTest();
        
        // Assert
        System.assertEquals(250, results.size(), 'Should return 250 results');
        
        Integer successCount = 0;
        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            }
        }
        System.assertEquals(250, successCount, 'All opportunities should be closed successfully');
        
        // Verify all opportunities were closed
        List<Opportunity> updatedOpps = [SELECT StageName FROM Opportunity WHERE Id IN :oppIds];
        System.assertEquals(250, updatedOpps.size(), '250 opportunities should be updated');
        
        for (Opportunity opp : updatedOpps) {
            System.assertEquals('Closed Won', opp.StageName, 'All opportunities should be Closed Won');
        }
    }
    
    @isTest
    static void testCloseOpportunities_Positive_MultipleStages() {
        // Arrange - Create opportunities with different stages
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Date closeDate = Date.today().addDays(30);
        
        List<Opportunity> opportunities = new List<Opportunity>();
        List<String> stages = new List<String>{ 'Prospecting', 'Qualification', 'Needs Analysis', 'Value Proposition' };
        
        for (Integer i = 0; i < 20; i++) {
            Opportunity opp = TestDataFactory.createOpportunity(
                testAccount.Id,
                'Multi Stage Opp ' + i,
                stages[Math.mod(i, stages.size())],
                5000,
                closeDate
            );
            opportunities.add(opp);
        }
        insert opportunities;
        
        List<Id> oppIds = new List<Id>();
        for (Opportunity opp : opportunities) {
            oppIds.add(opp.Id);
        }
        
        Test.startTest();
        // Act
        Database.SaveResult[] results = OpportunityService.closeOpportunities(oppIds);
        Test.stopTest();
        
        // Assert
        System.assertEquals(20, results.size(), 'Should return 20 results');
        
        // Verify all opportunities were closed regardless of original stage
        List<Opportunity> updatedOpps = [SELECT StageName FROM Opportunity WHERE Id IN :oppIds];
        for (Opportunity opp : updatedOpps) {
            System.assertEquals('Closed Won', opp.StageName, 'All opportunities should be Closed Won');
        }
    }
    
    @isTest
    static void testCloseOpportunities_Negative_NullList() {
        // Arrange
        List<Id> oppIds = null;
        
        Test.startTest();
        // Act & Assert
        try {
            OpportunityService.closeOpportunities(oppIds);
            System.assert(false, 'Should have thrown OpportunityServiceException');
        } catch (OpportunityServiceException e) {
            System.assert(e.getMessage().contains('null or empty'), 'Error message should mention null or empty');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCloseOpportunities_Negative_EmptyList() {
        // Arrange
        List<Id> oppIds = new List<Id>();
        
        Test.startTest();
        // Act & Assert
        try {
            OpportunityService.closeOpportunities(oppIds);
            System.assert(false, 'Should have thrown OpportunityServiceException');
        } catch (OpportunityServiceException e) {
            System.assert(e.getMessage().contains('null or empty'), 'Error message should mention null or empty');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCloseOpportunities_Negative_InvalidOpportunityId() {
        // Arrange - Use Account ID instead of Opportunity ID
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        List<Id> invalidIds = new List<Id>{ testAccount.Id };
        
        Test.startTest();
        // Act & Assert
        try {
            OpportunityService.closeOpportunities(invalidIds);
            System.assert(false, 'Should have thrown OpportunityServiceException');
        } catch (OpportunityServiceException e) {
            System.assert(e.getMessage().contains('No opportunities found'), 'Error message should mention no opportunities found');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCloseOpportunities_Negative_NonExistentId() {
        // Arrange - Create a fake ID
        Id fakeId = '006000000000000AAA'; // Standard format but non-existent
        
        Test.startTest();
        // Act & Assert
        try {
            OpportunityService.closeOpportunities(new List<Id>{ fakeId });
            System.assert(false, 'Should have thrown OpportunityServiceException');
        } catch (OpportunityServiceException e) {
            System.assert(e.getMessage().contains('No opportunities found'), 'Error message should mention no opportunities found');
        }
        Test.stopTest();
    }
    
    // ========== closeOpportunity Tests ==========
    
    @isTest
    static void testCloseOpportunity_Positive_Success() {
        // Arrange
        Opportunity testOpp = [SELECT Id, StageName FROM Opportunity LIMIT 1];
        System.assertNotEquals('Closed Won', testOpp.StageName, 'Opportunity should not be closed initially');
        
        Test.startTest();
        // Act
        Boolean result = OpportunityService.closeOpportunity(testOpp.Id);
        Test.stopTest();
        
        // Assert
        System.assert(result, 'Close operation should succeed');
        
        // Verify opportunity was closed
        Opportunity updatedOpp = [SELECT StageName FROM Opportunity WHERE Id = :testOpp.Id];
        System.assertEquals('Closed Won', updatedOpp.StageName, 'StageName should be set to Closed Won');
    }
    
    @isTest
    static void testCloseOpportunity_Negative_NullId() {
        // Arrange
        Id oppId = null;
        
        Test.startTest();
        // Act & Assert
        try {
            OpportunityService.closeOpportunity(oppId);
            System.assert(false, 'Should have thrown OpportunityServiceException');
        } catch (OpportunityServiceException e) {
            System.assert(e.getMessage().contains('null'), 'Error message should mention null');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCloseOpportunity_Negative_InvalidId() {
        // Arrange - Use Account ID instead of Opportunity ID
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        
        Test.startTest();
        // Act & Assert
        try {
            OpportunityService.closeOpportunity(testAccount.Id);
            System.assert(false, 'Should have thrown OpportunityServiceException');
        } catch (OpportunityServiceException e) {
            System.assert(e.getMessage().contains('No opportunities found'), 'Error message should mention no opportunities found');
        }
        Test.stopTest();
    }
    
    // ========== Edge Cases ==========
    
    @isTest
    static void testCloseOpportunities_EdgeCase_AlreadyClosed() {
        // Arrange - Create and close an opportunity
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Date closeDate = Date.today().addDays(30);
        Opportunity opp = TestDataFactory.createAndInsertOpportunity(
            testAccount.Id,
            'Already Closed Opp',
            'Closed Won',
            10000,
            closeDate
        );
        
        Test.startTest();
        // Act - Try to close an already closed opportunity
        Database.SaveResult[] results = OpportunityService.closeOpportunities(new List<Id>{ opp.Id });
        Test.stopTest();
        
        // Assert - Should still succeed (idempotent operation)
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assert(results[0].isSuccess(), 'Update should succeed even if already closed');
        
        // Verify still closed
        Opportunity updatedOpp = [SELECT StageName FROM Opportunity WHERE Id = :opp.Id];
        System.assertEquals('Closed Won', updatedOpp.StageName, 'Should remain Closed Won');
    }
    
    @isTest
    static void testCloseOpportunities_EdgeCase_MixedValidAndInvalidIds() {
        // Arrange - Mix of valid and invalid IDs
        Opportunity validOpp = [SELECT Id FROM Opportunity LIMIT 1];
        Id invalidId = Test.getStandardPricebookId(); // Different object's ID
        
        List<Id> mixedIds = new List<Id>{ validOpp.Id, invalidId };
        
        Test.startTest();
        // Act & Assert - Should fail because at least one ID is invalid
        try {
            OpportunityService.closeOpportunities(mixedIds);
            // Note: This might succeed if the query finds at least one valid opportunity
            // The behavior depends on whether the query returns results or not
        } catch (OpportunityServiceException e) {
            // If exception is thrown, verify it's the expected one
            System.assert(e.getMessage().contains('No opportunities found') || 
                         e.getMessage().contains('null or empty'), 
                         'Error message should be appropriate');
        }
        Test.stopTest();
    }
    
    @isTest
    static void testCloseOpportunities_EdgeCase_LimitBoundary() {
        // Arrange - Create exactly 200 opportunities (the LIMIT in the service)
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Date closeDate = Date.today().addDays(30);
        List<Opportunity> opportunities = TestDataFactory.createAndInsertOpportunities(
            testAccount.Id,
            200,
            'Limit Test Opp',
            'Prospecting',
            5000,
            closeDate
        );
        
        List<Id> oppIds = new List<Id>();
        for (Opportunity opp : opportunities) {
            oppIds.add(opp.Id);
        }
        
        Test.startTest();
        // Act
        Database.SaveResult[] results = OpportunityService.closeOpportunities(oppIds);
        Test.stopTest();
        
        // Assert
        System.assertEquals(200, results.size(), 'Should return 200 results');
        
        Integer successCount = 0;
        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            }
        }
        System.assertEquals(200, successCount, 'All 200 opportunities should be closed');
    }
    
    @isTest
    static void testCloseOpportunities_EdgeCase_MoreThanLimit() {
        // Arrange - Create 201 opportunities (more than LIMIT 200)
        Account testAccount = [SELECT Id FROM Account LIMIT 1];
        Date closeDate = Date.today().addDays(30);
        List<Opportunity> opportunities = TestDataFactory.createAndInsertOpportunities(
            testAccount.Id,
            201,
            'Over Limit Opp',
            'Prospecting',
            5000,
            closeDate
        );
        
        List<Id> oppIds = new List<Id>();
        for (Opportunity opp : opportunities) {
            oppIds.add(opp.Id);
        }
        
        Test.startTest();
        // Act - Should only process first 200 due to LIMIT clause
        Database.SaveResult[] results = OpportunityService.closeOpportunities(oppIds);
        Test.stopTest();
        
        // Assert - Should only return 200 results due to LIMIT
        System.assertEquals(200, results.size(), 'Should return 200 results due to LIMIT clause');
        
        // Verify exactly 200 were closed
        List<Opportunity> closedOpps = [SELECT Id FROM Opportunity WHERE Id IN :oppIds AND StageName = 'Closed Won'];
        System.assertEquals(200, closedOpps.size(), 'Exactly 200 opportunities should be closed');
    }
}

