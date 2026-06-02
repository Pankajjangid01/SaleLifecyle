trigger LeadTrigger on Lead (after update) {
    if(Trigger.isUpdate && Trigger.isAfter){
        LeadTriggerHandler.convertQualifiedLeads(Trigger.new, Trigger.oldMap);
    }
}