public with sharing class QuoteLockService {
    public static void lockQuoteLineItems(List<Id> quoteIds) {
        List<QuoteLineItem> lineItems = [SELECT Id FROM QuoteLineItem WHERE QuoteId IN :quoteIds];
        
        List<QuoteLineItem> toUpdate = new List<QuoteLineItem>();
        for (QuoteLineItem qli : lineItems) {
            qli.Is_Locked__c = true;
            toUpdate.add(qli);
        }
        
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
    public static void stampApprovedOnOpportunity(List<Id> opportunityIds) {
        
        List<Opportunity> opps = new List<Opportunity>();
        for (Id oppId : opportunityIds) {
            opps.add(new Opportunity(
                Id = oppId,
                Has_Approved_Quote__c = true
            ));
        }
        
        if (!opps.isEmpty()) {
            update opps;
        }
    }
}