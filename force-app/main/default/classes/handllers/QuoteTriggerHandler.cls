public with sharing class QuoteTriggerHandler {
    public static void handle(List<Quote> newQuotes, Map<Id, Quote> oldQuotes) {
        List<Id> lockedQuoteIds = new List<Id>();
        List<Id> approvedOpportunityIds = new List<Id>();
        for (Quote q : newQuotes) {
            Quote oldQ = oldQuotes.get(q.Id);
            Boolean isApproved = q.Status == 'Approved';
            Boolean wasNotApproved = oldQ.Status != 'Approved';
            if (isApproved && wasNotApproved) {
                lockedQuoteIds.add(q.Id);
                approvedOpportunityIds.add(q.OpportunityId);
            }
        }
        if (!lockedQuoteIds.isEmpty()) {
            QuoteLockService.lockQuoteLineItems(lockedQuoteIds);
        }
        if (!approvedOpportunityIds.isEmpty()) {
            QuoteLockService.stampApprovedOnOpportunity(approvedOpportunityIds);
        }
    }
}