@IsTest
private class ApiServiceTest {

    @IsTest
    static void testCreateRecord() {

        Map<String,Object> fields = new Map<String,Object>{
                'Name' => 'Test Account'
            };
        Test.startTest();
        Id accountId = ApiService.createRecord('Account', fields);
        Test.stopTest();
        Account acc = [
            SELECT Id, Name
            FROM Account
            WHERE Id = :accountId
        ];
        System.assertNotEquals(null, accountId);
        System.assertEquals('Test Account', acc.Name);
    }
    
    @IsTest
    static void testExists() {
    
        Account acc = new Account(Name = 'Exists Test');    
        insert acc;    
        Test.startTest();   
        Boolean exists = ApiService.exists('Account', acc.Id);   
        Test.stopTest();    
        System.assertEquals(true, exists);
    }
    
    @IsTest
    static void testUpdateRecord() {
    
        Account acc = new Account(Name = 'Old Name');    
        insert acc;   
        Map<String,Object> fields = new Map<String,Object>{
                'Name' => 'New Name'
            };    
        Test.startTest();   
        ApiService.updateRecord('Account', acc.Id, fields);
        Test.stopTest();
        acc = [
            SELECT Name
            FROM Account
            WHERE Id = :acc.Id
        ];
        System.assertEquals('New Name', acc.Name);
    }
    
    @IsTest
    static void testGetRecord() {
    
        Account acc = new Account(Name = 'Get Test');   
        insert acc;    
        Test.startTest();
        Account result =(Account)ApiService.getRecord
            ('Account', acc.Id, new List<String>{
                    'Id', 'Name'
                }
            );    
        Test.stopTest();    
        System.assertEquals(acc.Id, result.Id);
    }
    
    @IsTest
    static void testDeleteRecord() {
        
        Account acc = new Account(Name = 'Delete Test');    
        insert acc;    
        Test.startTest();
        ApiService.deleteRecord('Account', acc.Id);
        Test.stopTest();
        Account deletedAcc = [
            SELECT Id, IsDeleted
            FROM Account
            WHERE Id = :acc.Id
            ALL ROWS
        ];
        System.assertEquals(true, deletedAcc.IsDeleted);
    }
}