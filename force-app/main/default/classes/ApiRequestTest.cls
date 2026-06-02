@IsTest
private class ApiRequestTest {

    @IsTest
    static void testApiRequestMethods() {

        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/accounts/001000000000001AAA';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"Name":"Test Account"}');

        req.addParameter('status', 'Active');

        req.headers.put('Content-Type', 'application/json');
        req.headers.put('Authorization', 'Bearer TestToken');

        RestContext.request = req;

        ApiRequest apiReq = new ApiRequest();

        System.assertEquals('POST', apiReq.getMethod());
        System.assertEquals('/services/apexrest/accounts/001000000000001AAA', apiReq.getRequestUri());
        System.assertEquals('Test Account', apiReq.getField('Name'));
        System.assertEquals('Active', apiReq.getParam('status'));
        System.assertEquals('application/json', apiReq.getContentType());
        System.assertEquals('Bearer TestToken', apiReq.getAuthorization());

        System.assertEquals(true, apiReq.hasField('Name'));
        System.assertEquals(true, apiReq.hasParam('status'));
        System.assertEquals(true, apiReq.hasHeader('Authorization'));
        System.assertEquals(false, apiReq.isBodyEmpty());
    }
    
    @IsTest
    static void testHeadersParamsAndRawBody() {
    
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/accounts';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"Name":"Test Account"}');
    
        req.addParameter('status', 'Active');
    
        req.headers.put('Content-Type', 'application/json');
        req.headers.put('Authorization', 'Bearer Token');
    
        RestContext.request = req;
    
        ApiRequest apiReq = new ApiRequest();
    
        System.assertEquals('{"Name":"Test Account"}', apiReq.getRawBody());
    
        System.assertEquals('Active', apiReq.getParams().get('status'));
    
        System.assertEquals('application/json', apiReq.getHeaders().get('Content-Type'));
        System.assertEquals('Bearer Token', apiReq.getHeader('Authorization'));
    }
    
    @IsTest
    static void testGetBodyAndRecordId() {
    
        RestRequest req = new RestRequest();
        req.requestUri = '/services/apexrest/accounts/001000000000001AAA';
        req.httpMethod = 'POST';
        req.requestBody = Blob.valueOf('{"Name":"Test Account"}');
    
        RestContext.request = req;
    
        ApiRequest apiReq = new ApiRequest();
    
        System.assertEquals('Test Account', apiReq.getBody().get('Name'));
    
        System.assertNotEquals(null, apiReq.getRecordId());
    }
}