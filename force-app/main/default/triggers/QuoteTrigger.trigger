trigger QuoteTrigger on Quote (after update) {
    if(Trigger.isUpdate && Trigger.isAfter){
        QuoteTriggerHandler.handle(
            Trigger.new,
            Trigger.oldMap
        );
    }
}