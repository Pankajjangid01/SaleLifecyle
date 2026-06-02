public with sharing class ApiRequest {

    private RestRequest request;
    private Map<String, Object> bodyData;

    public ApiRequest() {

        request = RestContext.request;
        bodyData = new Map<String,Object>();
    
        try {
            if (request.requestBody != null && !String.isBlank
                (request.requestBody.toString())
            ) {
                bodyData =(Map<String,Object>)
                    JSON.deserializeUntyped
                    (request.requestBody.toString());
            }
        }
        catch(Exception e) {
            throw new ApiRequestException(
                'Invalid JSON Request Body: ' + e.getMessage());
        }
    }

    public Map<String, Object> getBody() {
        return bodyData;
    }

    // Single field from body
    public Object getField(String fieldName) {
        return bodyData.get(fieldName);
    }

    // HTTP Method
    public String getMethod() {
        return request.httpMethod;
    }

    // Complete URL
    public String getRequestUri() {
        return request.requestURI;
    }

    /* Last URL segment
     * Example:
     * /cases/500XYZ
     * returns 500XYZ
    */
    public Id getRecordId() {

        String uri = request.requestURI;
        String recordId =
            uri.substring(
                uri.lastIndexOf('/') + 1
            );
    
        try {
            return Id.valueOf(recordId);
        }
        catch(Exception e) {
            throw new ApiRequestException(
                'Invalid Salesforce Record Id'
            );
        }
    }
    
    /* Query Parameter
     * Example:
     * ?status=New
    */
    public String getParam(String paramName) {
        return request.params.get(paramName);
    }

    // All Query Parameters
    public Map<String, String> getParams() {
        return request.params;
    }

    // Header
    public String getHeader(String headerName) {
        return request.headers.get(headerName);
    }

    // All Headers
    public Map<String, String> getHeaders() {
        return request.headers;
    }

    // Content Type
    public String getContentType() {
        return request.headers.get('Content-Type');
    }

    // Authorization Header
    public String getAuthorization() {
        return request.headers.get('Authorization');
    }

    // Raw Request Body
    public String getRawBody() {
        return request.requestBody == null
            ? null
            : request.requestBody.toString();
    }

    // Check field exists
    public Boolean hasField(String fieldName) {
        return bodyData.containsKey(fieldName);
    }

    // Check parameter exists
    public Boolean hasParam(String paramName) {
        return request.params.containsKey(paramName);
    }

    // Check header exists
    public Boolean hasHeader(String headerName) {
        return request.headers.containsKey(headerName);
    }

    // Body empty?
    public Boolean isBodyEmpty() {
        return bodyData.isEmpty();
    }
}