public with sharing class ContactService {

    public static Id create(
        Map<String,Object> fields
    ){
        return ApiService.createRecord(
            'Contact',fields);
    }

    public static Boolean exists(
        Id contactId
    ){
        return ApiService.exists(
            'Contact', contactId);
    }

    public static Id updateContact(
        Id contactId,
        Map<String,Object> fields
    ){
        return ApiService.updateRecord(
            'Contact', contactId, fields);
    }

    public static Contact get(
        Id contactId
    ){
        return (Contact)ApiService.getRecord(
            'Contact',
            contactId,
            new List<String>{
                'Id',
                'FirstName',
                'LastName',
                'Email',
                'Phone'
            }
        );
    }

    public static void deleteContact(
        Id contactId
    ){
        ApiService.deleteRecord(
            'Contact', contactId);
    }
}