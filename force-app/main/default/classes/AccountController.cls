@RestResource(urlMapping='/Accounts/*')
global with sharing class AccountController {

    @HttpGet
    global static String getAccount() {

        try {
            ApiRequest req = new ApiRequest();
            Account accountRecord = AccountService.get(req.getRecordId());
            
            return ApiResponse.success(
                'Account Retrieved Successfully', accountRecord);
        }
        catch(Exception e){
            return ApiExceptionHandler.handle(e);
        }
    }

    @HttpPost
    global static String createAccount() {

        try {
            ApiRequest req = new ApiRequest();
            Id accountId = AccountService.create(req.getBody());

            return ApiResponse.success(
                'Account Created Successfully', new Map<String,Object>{
                    'id' => accountId
                }
            );
        }
        catch(Exception e){
            return ApiExceptionHandler.handle(e);
        }
    }

    @HttpPatch
    global static String updateAccount() {

        try {
            ApiRequest req = new ApiRequest();
            Id accountId = AccountService.updateAccount(
                req.getRecordId(), req.getBody());

            return ApiResponse.success(
                'Account Updated Successfully', new Map<String,Object>{
                    'id' => accountId
                }
            );
        }
        catch(Exception e){
            return ApiExceptionHandler.handle(e);
        }
    }

    @HttpDelete
    global static String deleteAccount() {

        try {
            ApiRequest req = new ApiRequest();
            AccountService.deleteAccount(req.getRecordId());

            return ApiResponse.success('Account Deleted Successfully', null);
        }
        catch(Exception e){
            return ApiExceptionHandler.handle(e);
        }
    }
}