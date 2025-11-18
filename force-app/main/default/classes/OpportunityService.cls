/**
 * Service class for Opportunity business logic
 * Implements Service Layer pattern with bulkified methods
 * Handles all Opportunity-related business operations
 * 
 * @author Salesforce Developer
 * @date 2024
 */
public with sharing class OpportunityService {
    
    private static final Integer MAX_QUERY_LIMIT = 10000;
    private static final String CLOSED_WON_STAGE = 'Closed Won';
    
    /**
     * Closes multiple Opportunity records in bulk
     * Bulkified to avoid SOQL/DML in loops
     * @param oppIds List of Opportunity IDs to close
     * @return Database.SaveResult[] Results of the update operation
     * @throws OpportunityServiceException if validation fails or DML operation fails
     */
    public static Database.SaveResult[] closeOpportunities(List<Id> oppIds) {
        if (oppIds == null || oppIds.isEmpty()) {
            throw new OpportunityServiceException('Opportunity ID list cannot be null or empty');
        }
        
        try {
            // Check CRUD permissions
            if (!Schema.sObjectType.Opportunity.isUpdateable()) {
                throw new OpportunityServiceException('User does not have permission to update Opportunity records');
            }
            
            // Bulk query with security enforced - NO LOOP
            List<Opportunity> opportunities = [
                SELECT Id, StageName 
                FROM Opportunity 
                WHERE Id IN :oppIds 
                WITH SECURITY_ENFORCED
                LIMIT :MAX_QUERY_LIMIT
            ];
            
            if (opportunities.isEmpty()) {
                throw new OpportunityServiceException('No opportunities found with provided IDs');
            }
            
            // Update stage in bulk - NO LOOP
            for (Opportunity opp : opportunities) {
                opp.StageName = CLOSED_WON_STAGE;
            }
            
            // Apply field-level security
            SObjectAccessDecision decision = Security.stripInaccessible(
                AccessType.UPDATABLE,
                opportunities
            );
            
            List<Opportunity> accessibleOpportunities = decision.getRecords();
            
            System.debug(LoggingLevel.INFO, 'OpportunityService.closeOpportunities: Closing ' + accessibleOpportunities.size() + ' opportunities');
            
            // Bulk update - NO LOOP
            Database.SaveResult[] results = Database.update(accessibleOpportunities, false);
            
            // Log errors
            for (Integer i = 0; i < results.size(); i++) {
                if (!results[i].isSuccess()) {
                    String errorMsg = 'Failed to close opportunity: ';
                    for (Database.Error error : results[i].getErrors()) {
                        errorMsg += error.getMessage() + ' ';
                    }
                    System.debug(LoggingLevel.ERROR, errorMsg);
                }
            }
            
            return results;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'OpportunityService.closeOpportunities error: ' + e.getMessage());
            throw new OpportunityServiceException('Error closing opportunities: ' + e.getMessage());
        }
    }
}
