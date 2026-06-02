public class ApiExceptionHandler {

    public static String handle(Exception e){

        if(e instanceof ValidationException){
            return ApiResponse.error(400, e.getMessage());
        }

        if(e instanceof ApiRequestException){
            return ApiResponse.error(400, e.getMessage());
        }

        if(e instanceof NotFoundException){
            return ApiResponse.error(404, e.getMessage());
        }

        if(e instanceof ServiceException){
            return ApiResponse.error(500, e.getMessage());
        }
        return ApiResponse.error(500, 'Internal Server Error');
    }
}