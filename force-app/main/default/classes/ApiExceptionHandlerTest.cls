@IsTest
private class ApiExceptionHandlerTest {

    @IsTest
    static void testValidationException() {

        String response = ApiExceptionHandler.handle(
            new ValidationException('Validation Error')
        );

        Map<String,Object> result =
            (Map<String,Object>)JSON.deserializeUntyped(response);

        System.assertEquals(400, result.get('statusCode'));
    }

    @IsTest
    static void testApiRequestException() {

        String response = ApiExceptionHandler.handle(
            new ApiRequestException('Request Error')
        );

        Map<String,Object> result =
            (Map<String,Object>)JSON.deserializeUntyped(response);

        System.assertEquals(400, result.get('statusCode'));
    }

    @IsTest
    static void testNotFoundException() {

        String response = ApiExceptionHandler.handle(
            new NotFoundException('Not Found')
        );

        Map<String,Object> result =
            (Map<String,Object>)JSON.deserializeUntyped(response);

        System.assertEquals(404, result.get('statusCode'));
    }

    @IsTest
    static void testServiceException() {

        String response = ApiExceptionHandler.handle(
            new ServiceException('Service Error')
        );

        Map<String,Object> result =
            (Map<String,Object>)JSON.deserializeUntyped(response);

        System.assertEquals(500, result.get('statusCode'));
    }

    @IsTest
    static void testGenericException() {

        try {
            String s;
            s.length();
        }
        catch(Exception e) {
            String response = ApiExceptionHandler.handle(e);
            Map<String,Object> result =(Map<String,Object>)JSON.deserializeUntyped(response);
            System.assertEquals(500, result.get('statusCode'));
            System.assertEquals('Internal Server Error', result.get('message'));
        }
    }
}