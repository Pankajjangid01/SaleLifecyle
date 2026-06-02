@IsTest
private class AccountControllerTest {

    @IsTest
    static void testCreateAccount() {

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/accounts';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"Name":"Test Account"}');

        RestContext.request = req;
        RestContext.response = new RestResponse();

        Test.startTest();
        String response = AccountController.createAccount();
        Test.stopTest();

        Map<String,Object> result = (Map<String,Object>)JSON.deserializeUntyped(response);

        System.assertEquals(200, result.get('statusCode'));
        System.assertEquals('Account Created Successfully', result.get('message'));
        System.assertNotEquals(null, result.get('data'));
    }
    
    @IsTest
    static void testGetAccount() {
    
        Account acc = new Account(Name = 'Get Test');
        insert acc;
    
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/accounts/' + acc.Id;
        req.httpMethod = 'GET';
    
        RestContext.request = req;
        RestContext.response = new RestResponse();
    
        Test.startTest();
        String response = AccountController.getAccount();
        Test.stopTest();
    
        Map<String,Object> result = (Map<String,Object>)JSON.deserializeUntyped(response);
    
        System.assertEquals(200, result.get('statusCode'));
        System.assertEquals('Account Retrieved Successfully', result.get('message'));
    
        Map<String,Object> data = (Map<String,Object>)result.get('data');
    
        System.assertEquals(String.valueOf(acc.Id), String.valueOf(data.get('Id')));
    }
    
    @IsTest
    static void testUpdateAccount() {
    
        Account acc = new Account(Name = 'Old Name');
        insert acc;
    
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/accounts/' + acc.Id;
        req.httpMethod = 'PATCH';
        req.requestBody = Blob.valueOf('{"Name":"New Name"}');
    
        RestContext.request = req;
        RestContext.response = new RestResponse();
    
        Test.startTest();
        String response = AccountController.updateAccount();
        Test.stopTest();
    
        Map<String,Object> result = (Map<String,Object>)JSON.deserializeUntyped(response);
    
        System.assertEquals(200, result.get('statusCode'));
        System.assertEquals('Account Updated Successfully', result.get('message'));
    
        acc = [SELECT Name FROM Account WHERE Id = :acc.Id];
    
        System.assertEquals('New Name', acc.Name);
    }
    
    @IsTest
    static void testDeleteAccount() {
    
        Account acc = new Account(Name = 'Delete Test');
        insert acc;
    
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/accounts/' + acc.Id;
        req.httpMethod = 'DELETE';
    
        RestContext.request = req;
        RestContext.response = new RestResponse();
    
        Test.startTest();
        String response = AccountController.deleteAccount();
        Test.stopTest();
    
        Map<String,Object> result = (Map<String,Object>)JSON.deserializeUntyped(response);
    
        System.assertEquals(200, result.get('statusCode'));
        System.assertEquals('Account Deleted Successfully', result.get('message'));
    
        Account deletedAcc = [SELECT IsDeleted FROM Account WHERE Id = :acc.Id ALL ROWS];
    
        System.assertEquals(true, deletedAcc.IsDeleted);
    }
    
    @IsTest
    static void testInvalidRecordId() {
    
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/accounts/abc123';
        req.httpMethod = 'GET';
    
        RestContext.request = req;
        RestContext.response = new RestResponse();
    
        Test.startTest();
        String response = AccountController.getAccount();
        Test.stopTest();
    
        Map<String,Object> result = (Map<String,Object>)JSON.deserializeUntyped(response);
    
        System.assertEquals(400, result.get('statusCode'));
        System.assertEquals('Invalid Salesforce Record Id', result.get('message'));
    }
    
    @IsTest
    static void testRecordNotFound() {
    
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/accounts/001000000000000AAA';
        req.httpMethod = 'GET';
    
        RestContext.request = req;
        RestContext.response = new RestResponse();
    
        Test.startTest();
        String response = AccountController.getAccount();
        Test.stopTest();
    
        Map<String,Object> result = (Map<String,Object>)JSON.deserializeUntyped(response);
    
        System.assertEquals(404, result.get('statusCode'));
    }
    
    @IsTest
    static void testInvalidField() {
    
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/accounts';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"FakeField__c":"Test"}');
    
        RestContext.request = req;
        RestContext.response = new RestResponse();
    
        Test.startTest();
        String response = AccountController.createAccount();
        Test.stopTest();
    
        Map<String,Object> result = (Map<String,Object>)JSON.deserializeUntyped(response);
    
        System.assertEquals(400, result.get('statusCode'));
    }
    
    @IsTest
    static void testGetRecordEmptyFieldList() {
    
        Account acc = new Account(Name = 'Test');
        insert acc;
    
        try {
            ApiService.getRecord('Account', acc.Id, new List<String>());
            System.assert(false);
        } catch(ValidationException e) {
            System.assertEquals('Fields list cannot be empty', e.getMessage());
        }
    }
}