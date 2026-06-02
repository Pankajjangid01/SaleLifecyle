@IsTest
private class AccountServiceTest {

    @IsTest
    static void testCreateAccount() {

        Map<String,Object> fields = new Map<String,Object>{
                'Name' => 'Test Account'
            };
        Test.startTest();
        Id accountId = AccountService.create(fields);
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

        Account acc = new Account(Name = 'Exists Test' );
        insert acc;
        Test.startTest();
        Boolean exists = AccountService.exists(acc.Id);
        Test.stopTest();
        System.assertEquals(true, exists);
    }

    @IsTest
    static void testUpdateAccount() {

        Account acc = new Account(Name = 'Old Name');
        insert acc;
        Map<String,Object> fields = new Map<String,Object>{
                'Name' => 'New Name'
            };
        Test.startTest();
        AccountService.updateAccount(acc.Id, fields);
        Test.stopTest();
        acc = [
            SELECT Name
            FROM Account
            WHERE Id = :acc.Id
        ];
        System.assertEquals('New Name', acc.Name);
    }

    @IsTest
    static void testGetAccount() {

        Account acc = new Account(Name = 'Get Test');
        insert acc;
        Test.startTest();
        Account result = AccountService.get(acc.Id);
        Test.stopTest();
        System.assertEquals(acc.Id, result.Id);
    }

    @IsTest
    static void testDeleteAccount() {

        Account acc = new Account( Name = 'Delete Test');
        insert acc;
        Test.startTest();
        AccountService.deleteAccount(acc.Id);
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