/**
 * Service layer for Opportunity business logic
 * Provides bulkified, secure, and error-handled methods for Opportunity operations
 */
public class OpportunityService {
    
    private static final String STAGE_CLOSED_WON = 'Closed Won';
    
    /**
     * Closes one or more Opportunities by setting StageName to 'Closed Won'
     * Bulkified to handle 200+ records - removes SOQL/DML from loops
     * @param oppIds List of Opportunity IDs to close
     * @return Database.SaveResult[] Results of the update operation
     * @throws OpportunityServiceException if oppIds list is null or empty
     */
    public static Database.SaveResult[] closeOpportunities(List<Id> oppIds) {
        if (oppIds == null || oppIds.isEmpty()) {
            throw new OpportunityServiceException('Opportunity ID list cannot be null or empty');
        }
        
        // Check CRUD permissions
        if (!Schema.sObjectType.Opportunity.isUpdateable()) {
            throw new OpportunityServiceException('Insufficient permissions to update Opportunity records');
        }
        
        // Bulk query with security enforcement - removes SOQL from loop
        List<Opportunity> opportunities = [
            SELECT Id, StageName
            FROM Opportunity
            WHERE Id IN :oppIds
            WITH SECURITY_ENFORCED
            LIMIT 200
        ];
        
        if (opportunities.isEmpty()) {
            throw new OpportunityServiceException('No opportunities found for the provided IDs');
        }
        
        // Update StageName for all opportunities
        for (Opportunity opp : opportunities) {
            opp.StageName = STAGE_CLOSED_WON;
        }
        
        // Strip inaccessible fields
        SObjectAccessDecision decision = Security.stripInaccessible(
            AccessType.UPDATABLE,
            opportunities
        );
        List<Opportunity> accessibleOpportunities = decision.getRecords();
        
        // Perform bulk update with partial success allowed - removes DML from loop
        Database.SaveResult[] results = Database.update(accessibleOpportunities, false);
        
        // Log errors
        logSaveResults('closeOpportunities', results, accessibleOpportunities);
        
        return results;
    }
    
    /**
     * Convenience method to close a single Opportunity
     * @param oppId Opportunity ID to close
     * @return true if update succeeded, false otherwise
     */
    public static Boolean closeOpportunity(Id oppId) {
        if (oppId == null) {
            throw new OpportunityServiceException('Opportunity ID cannot be null');
        }
        
        Database.SaveResult[] results = closeOpportunities(new List<Id>{ oppId });
        
        return results != null && !results.isEmpty() && results[0].isSuccess();
    }
    
    /**
     * Logs SaveResult errors for debugging
     * @param methodName Name of the calling method
     * @param results Database.SaveResult array
     * @param records List of SObjects that were processed
     */
    private static void logSaveResults(String methodName, Database.SaveResult[] results, List<SObject> records) {
        if (results == null || records == null) {
            return;
        }
        
        for (Integer i = 0; i < results.size(); i++) {
            Database.SaveResult result = results[i];
            if (!result.isSuccess()) {
                String errorMsg = methodName + ' failed for record at index ' + i + ': ';
                for (Database.Error error : result.getErrors()) {
                    errorMsg += error.getMessage() + ' (' + error.getStatusCode() + ')';
                }
                System.debug(LoggingLevel.ERROR, errorMsg);
            }
        }
    }
}