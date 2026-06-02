public with sharing class AccountService {

    public static Id create(
        Map<String,Object> fields
    ){
        return ApiService.createRecord(
            'Account',fields);
    }

    public static Boolean exists(
        Id accountId
    ){
        return ApiService.exists(
            'Account', accountId);
    }

    public static Id updateAccount(
        Id accountId,
        Map<String,Object> fields
    ){
        return ApiService.updateRecord(
            'Account', accountId, fields);
    }
    
    public static Account get(
        Id accountId
    ){
        return (Account)ApiService.getRecord(
            'Account',
            accountId,
            new List<String>{
                'Id',
                'Name',
                'Phone',
                'Website',
                'Type',
                'Industry',
                'Rating',
                'Description'
            }
        );
    }
    
    public static void deleteAccount(
        Id accountId
    ){
        ApiService.deleteRecord(
            'Account', accountId);
    }
}