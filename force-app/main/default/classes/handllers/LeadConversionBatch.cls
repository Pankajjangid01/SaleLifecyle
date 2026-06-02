public with sharing class LeadConversionBatch implements Database.Batchable<SObject> {
    private List<Id> leadIds;
    public LeadConversionBatch(List<Id> leadIds) {
        this.leadIds = leadIds;
    }
    public Database.QueryLocator start(
        Database.BatchableContext bc
    ) {
        return Database.getQueryLocator([
            SELECT Id
            FROM Lead
            WHERE Id IN :leadIds
            AND IsConverted = false
        ]);
    }

    public void execute(
        Database.BatchableContext bc,
        List<Lead> scope
    ) {
        LeadStatus convertedStatus = [
            SELECT MasterLabel
            FROM LeadStatus
            WHERE IsConverted = true
            LIMIT 1
        ];
        List<Database.LeadConvert> conversions = new List<Database.LeadConvert>();
        for (Lead ld : scope) {
            Database.LeadConvert lc = new Database.LeadConvert();
            lc.setLeadId(ld.Id);
            lc.setConvertedStatus(convertedStatus.MasterLabel);
            lc.setDoNotCreateOpportunity(false);
            conversions.add(lc);
        }
        Database.convertLead(conversions, false);
    }

    public void finish(
        Database.BatchableContext bc
    ) {

    }
}