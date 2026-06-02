public with sharing class JournalTriggerHandler {
    public static void handleBeforeDelete(List<Journal__c> oldJournals) {
        for (Journal__c j : oldJournals) {
            if (j.Status__c == 'Posted' || j.Status__c == 'Approved') {
                j.addError(Label.You_cannot_delete_a_Posted_or_Approved_Journal);
            }
        }
    }
}