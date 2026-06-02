public with sharing class StudentController {
    @AuraEnabled(cacheable=true)
    public static List<Student__c> getStudents(){
        try {
            return [SELECT Id, Name, Email__c, Course__c, Course__r.Id, Course__r.Name, CreatedById, LastModifiedById FROM Student__c];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled(cacheable=true)
    public static Student__c getStudentDetails(String id) {
        try {
            List<Student__c> students = [SELECT Id, Name, Email__c, CreatedById, LastModifiedById FROM Student__c WHERE Id=:id WITH SECURITY_ENFORCED LIMIT 1];
            return students[0];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Student__c addStudent(String name, String email, Id courseId){
        try {
            List<Student__c> students = [SELECT Id, Name, Email__c FROM Student__c WHERE Email__c=:email LIMIT 1];
            if(!students.isEmpty()){
                List<Object> args = new List<Object>{ email };
                throw new RecordNotFoundException(String.format('Student already exists with {0}', args));
            }
            Student__c student = new Student__c(Name=name, Email__c=email, Course__c=courseId);
            insert student;
            return student;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}