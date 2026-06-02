public class ApiResponse {

    public Integer statusCode;
    public String message;
    public Object data;

    public ApiResponse(
        Integer statusCode,
        String message,
        Object data
    ){
        this.statusCode = statusCode;
        this.message = message;
        this.data = data;
    }

    public static String success(
        String message,
        Object data
    ){
        if(data == null){
            data = new Map<String,Object>();
        }
        return JSON.serialize(
            new ApiResponse(
                200,
                message,
                data)
        );
    }

    public static String error(
        Integer statusCode,
        String message
    ){
        return JSON.serialize(
            new ApiResponse(statusCode, message, null)
        );
    }
}