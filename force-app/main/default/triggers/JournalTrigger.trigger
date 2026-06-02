trigger JournalTrigger on Journal__c (before delete) {
    if(Trigger.isDelete && Trigger.isBefore){
        JournalTriggerHandler.handleBeforeDelete(Trigger.old);
    }
}