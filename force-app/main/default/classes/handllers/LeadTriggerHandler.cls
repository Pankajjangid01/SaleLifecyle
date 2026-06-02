public with sharing class LeadTriggerHandler {
    public static void convertQualifiedLeads(List<Lead> newLeads,Map<Id, Lead> oldMap) {
        List<Id> leadIds = new List<Id>();
        for (Lead ld : newLeads) {
            Lead oldLead = oldMap.get(ld.Id);
            if (ld.Status == 'Qualified' && oldLead.Status != 'Qualified' && !ld.IsConverted) {
                leadIds.add(ld.Id);
            }
        }

        if (!leadIds.isEmpty()) {
            Database.executeBatch(
                new LeadConversionBatch(leadIds),
                20
            );
        }
    }
}