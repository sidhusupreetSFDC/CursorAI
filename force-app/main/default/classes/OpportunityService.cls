public class OpportunityService {
    public static void closeOpportunities(List<Id> oppIds) {
        for(Id oppId : oppIds) {
            Opportunity opp = [SELECT Id FROM Opportunity WHERE Id = :oppId];
            opp.StageName = 'Closed Won';
            update opp;
        }
    }
}