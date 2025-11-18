/**
 * Service class for Opportunity business logic
 * Implements Service Layer pattern with bulkification and error handling
 * 
 * @author Salesforce Developer
 * @date 2024
 */
public class OpportunityService {
    
    private static final String STAGE_CLOSED_WON = 'Closed Won';
    private static final Integer MAX_RECORDS_PER_BATCH = 10000;
    
    /**
     * Closes opportunities by setting stage to Closed Won
     * Bulkified to handle 200+ records efficiently
     * @param oppIds List of Opportunity IDs to close
     * @return Database.SaveResult[] Results of the update operation
     */
    public static Database.SaveResult[] closeOpportunities(List<Id> oppIds) {
        if (oppIds == null || oppIds.isEmpty()) {
            throw new OpportunityServiceException('Opportunity ID list cannot be null or empty');
        }
        
        System.debug(LoggingLevel.DEBUG, 'OpportunityService.closeOpportunities - Processing ' + oppIds.size() + ' opportunities');
        
        // Check CRUD permissions
        if (!Schema.sObjectType.Opportunity.isUpdateable()) {
            throw new OpportunityServiceException('Insufficient permissions to update Opportunity records');
        }
        
        // Query all opportunities upfront (bulk query - no SOQL in loop)
        List<Opportunity> opportunities = [
            SELECT Id, StageName 
            FROM Opportunity 
            WHERE Id IN :oppIds 
            WITH SECURITY_ENFORCED
            LIMIT :MAX_RECORDS_PER_BATCH
        ];
        
        if (opportunities.isEmpty()) {
            System.debug(LoggingLevel.WARN, 'OpportunityService.closeOpportunities - No opportunities found or accessible');
            return new Database.SaveResult[0];
        }
        
        if (opportunities.size() != oppIds.size()) {
            System.debug(LoggingLevel.WARN, 'OpportunityService.closeOpportunities - Some opportunities were not found or not accessible. Expected: ' + 
                oppIds.size() + ', Found: ' + opportunities.size());
        }
        
        // Update all opportunities in bulk (no DML in loop)
        for (Opportunity opp : opportunities) {
            opp.StageName = STAGE_CLOSED_WON;
        }
        
        // Apply field-level security
        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.UPDATABLE,
            opportunities
        );
        
        List<Opportunity> accessibleOpportunities = new List<Opportunity>();
        for (SObject opp : decision.getRecords()) {
            accessibleOpportunities.add((Opportunity) opp);
        }
        
        // Bulk update with partial success handling
        Database.SaveResult[] results = Database.update(accessibleOpportunities, false);
        handleDmlResults(results, 'OpportunityService.closeOpportunities');
        
        System.debug(LoggingLevel.DEBUG, 'OpportunityService.closeOpportunities - Successfully processed ' + accessibleOpportunities.size() + ' opportunities');
        
        return results;
    }
    
    /**
     * Handles DML operation results and logs errors
     * @param results Database operation results
     * @param context Context string for logging
     * @return Integer Number of successful operations
     */
    private static Integer handleDmlResults(Database.SaveResult[] results, String context) {
        Integer successCount = 0;
        Integer failureCount = 0;
        
        for (Database.SaveResult result : results) {
            if (result.isSuccess()) {
                successCount++;
            } else {
                failureCount++;
                String errorMsg = context + ' - DML Error: ';
                for (Database.Error error : result.getErrors()) {
                    errorMsg += error.getMessage() + ' (' + error.getStatusCode() + '); ';
                }
                System.debug(LoggingLevel.ERROR, errorMsg);
            }
        }
        
        if (failureCount > 0) {
            System.debug(LoggingLevel.WARN, context + ' - ' + successCount + ' succeeded, ' + failureCount + ' failed');
        }
        
        return successCount;
    }
}
