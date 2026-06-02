public with sharing class OverdueInvoiceScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        OverdueInvoiceBatch batch = new OverdueInvoiceBatch();
        Database.executeBatch(batch, 200);
    }
}