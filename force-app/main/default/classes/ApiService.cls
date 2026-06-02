public with sharing class ApiService {

    // Validate and return object type
    private static Schema.SObjectType getObjectType(
        String objectName
    ){
        Schema.SObjectType objType =
            Schema.getGlobalDescribe().get(objectName);
        if(objType == null){
            throw new ValidationException(
                'Invalid Object Name');
        }
        return objType;
    }

    // Validate fields
    private static void validateFields(
        Schema.SObjectType objType,
        Set<String> fieldNames
    ){
        Map<String, Schema.SObjectField> fieldMap =
            objType.getDescribe().fields.getMap();
        for(String fieldName : fieldNames){
            if(!fieldMap.containsKey(fieldName)){
                throw new ValidationException(
                    'Invalid Field: ' + fieldName);
            }
        }
    }

    // Create Record
    public static Id createRecord(
        String objectName,
        Map<String,Object> fields
    ){
        Schema.SObjectType objType = getObjectType(objectName);
        validateFields(objType, fields.keySet());
        SObject record = objType.newSObject();
        for(String fieldName : fields.keySet()){
            record.put(fieldName, fields.get(fieldName));
        }
        try{
            insert record;
        }catch(DmlException e){
            throw new ServiceException(e.getDmlMessage(0));
        }
        return (Id)record.get('Id');
    }

    // Update Record
    public static Id updateRecord(
        String objectName,
        Id recordId,
        Map<String,Object> fields
    ){
        Schema.SObjectType objType =
            getObjectType(objectName);
        validateFields(
            objType,fields.keySet());
        SObject record =
            objType.newSObject(recordId);
        for(String fieldName : fields.keySet()){
            record.put(
                fieldName,fields.get(fieldName));
        }
        try{
            update record;
        }catch(DmlException e){
            throw new ServiceException(e.getDmlMessage(0));
        }
        return recordId;
    }

    // Delete Record
    public static void deleteRecord(
        String objectName,
        Id recordId
    ){
        Schema.SObjectType objType =
            getObjectType(objectName);
        SObject record =
            objType.newSObject(recordId);
        try{
            delete record;
        }catch(DmlException e){
            throw new ServiceException(e.getDmlMessage(0));
        }
    }

    // Get Record
    public static SObject getRecord(
        String objectName,
        Id recordId,
        List<String> fields
    ){
        Schema.SObjectType objType =
            getObjectType(objectName);
        if(fields == null || fields.isEmpty()){
            throw new ValidationException(
                'Fields list cannot be empty');
        }
        validateFields(
            objType, new Set<String>(fields)
        );

        String query =
            'SELECT ' + String.join(fields, ',') +
            ' FROM ' + objectName +
            ' WHERE Id = \'' + String.escapeSingleQuotes(
                String.valueOf(recordId)) +
            '\' LIMIT 1';

        List<SObject> records;

        try{
            records = Database.query(query);
        }catch(QueryException e){
            throw new ServiceException(e.getMessage());
        }
        if(records.isEmpty()){
            throw new NotFoundException(
                objectName + ' record not found');
        }
        return records[0];
    }

    // Check Record Exists
    public static Boolean exists(
        String objectName,
        Id recordId
    ){
        getObjectType(objectName);
        String query =
            'SELECT Id FROM ' + objectName +
            ' WHERE Id = \'' + String.escapeSingleQuotes(
                String.valueOf(recordId)) +
            '\' LIMIT 1';

        return !Database.query(query).isEmpty();
    }
}