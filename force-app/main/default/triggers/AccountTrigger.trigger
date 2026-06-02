trigger AccountTrigger on Account (before insert) {
    If(Trigger.isInsert && Trigger.isBefore){
        AccountTriggerHandler.generateAccountNumber(Trigger.new);
    }
}