public with sharing class OverdueInvoiceBatch implements Database.Batchable<SObject> {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator([
            SELECT Id, 
                   Status__c, 
                   Payment_Status__c, 
                   Due_Date__c
            FROM Invoice__c
            WHERE Due_Date__c < TODAY
            AND   Payment_Status__c != 'Paid'
            AND   Status__c != 'Overdue'
            AND   Status__c != 'Cancelled'
        ]);
    }
    
    public void execute(Database.BatchableContext bc, List<Invoice__c> invoices) {
        List<Invoice__c> toUpdate = new List<Invoice__c>();
        for (Invoice__c inv : invoices) {
            inv.Status__c = 'Overdue';
            toUpdate.add(inv);
        }
        
        if (!toUpdate.isEmpty()) {
            try {
                update toUpdate;
            } catch (DmlException e) {
                System.debug(LoggingLevel.ERROR,'OverdueInvoiceBatch failed: ' + e.getMessage());
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug(LoggingLevel.INFO, 'OverdueInvoiceBatch completed at: ' + System.now());
    }
}