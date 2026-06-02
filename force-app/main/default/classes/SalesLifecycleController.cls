public with sharing class SalesLifecycleController {

    private static final Integer SEARCH_LIMIT_PER_OBJECT = 7;
    private static final Integer LIFECYCLE_RECORD_LIMIT = 1;
    private static final Integer MIN_SEARCH_LENGTH = 2;
    private static final String LEAD_OBJECT = 'Lead';
    private static final String OPPORTUNITY_OBJECT = 'Opportunity';
    private static final String QUOTE_OBJECT = 'Quote';
    private static final String JOURNAL_OBJECT = 'Journal__c';
    private static final String INVOICE_OBJECT = 'Invoice__c';
    private static final Map<String, Schema.SObjectType> GLOBAL_DESCRIBE = Schema.getGlobalDescribe();

    @AuraEnabled(cacheable=true)
    public static List<SearchResultWrapper> searchRecords(String searchKey) {
        try {
            List<SearchResultWrapper> searchResults = new List<SearchResultWrapper>();
            String sanitizedSearchKey = sanitizeSearchKey(searchKey);

            if (String.isBlank(sanitizedSearchKey) || sanitizedSearchKey.length() < MIN_SEARCH_LENGTH) {
                return searchResults;
            }

            assertSearchReadAccess();

            String soslSearchTerm = buildSoslSearchTerm(sanitizedSearchKey);
            if (String.isBlank(soslSearchTerm)) {
                return searchResults;
            }

            String soslQuery =
                'FIND \'' + String.escapeSingleQuotes(soslSearchTerm) + '\' IN NAME FIELDS RETURNING ' +
                'Lead(Id, Name LIMIT ' + SEARCH_LIMIT_PER_OBJECT + '), ' +
                'Opportunity(Id, Name LIMIT ' + SEARCH_LIMIT_PER_OBJECT + ')';

            List<List<SObject>> searchGroups = Search.query(soslQuery);

            addSearchResults(searchResults, searchGroups, 0, LEAD_OBJECT);
            addSearchResults(searchResults, searchGroups, 1, OPPORTUNITY_OBJECT);
            addLeadFallbackResults(searchResults, sanitizedSearchKey);
            addJournalResults(searchResults, sanitizedSearchKey);
            addInvoiceResults(searchResults, sanitizedSearchKey);

            return searchResults;
        } catch (AuraHandledException handledException) {
            throw handledException;
        } catch (Exception unexpectedException) {
            throw new AuraHandledException(
                'Unable to search lifecycle records right now. ' + unexpectedException.getMessage()
            );
        }
    }

    @AuraEnabled(cacheable=true)
    public static LifecycleWrapper getLifecycleData(String recordId) {
        try {
            assertLifecycleReadAccess();

            LifecycleWrapper result = new LifecycleWrapper();
            if (String.isBlank(recordId)) {
                return result;
            }

            Id sourceRecordId = parseRecordId(recordId);
            String sourceObjectName = sourceRecordId.getSObjectType().getDescribe().getName();
            Id opportunityId;

            if (sourceObjectName == LEAD_OBJECT) {
                Lead leadRecord = getLeadById(sourceRecordId);
                if (leadRecord == null) {
                    throw new AuraHandledException('The selected Lead could not be found or is no longer accessible.');
                }

                result.leadRecord = leadRecord;
                opportunityId = leadRecord.ConvertedOpportunityId;
            } else if (sourceObjectName == OPPORTUNITY_OBJECT) {
                Opportunity opportunityRecord = getOpportunityById(sourceRecordId);
                if (opportunityRecord == null) {
                    throw new AuraHandledException('The selected Opportunity could not be found or is no longer accessible.');
                }

                result.opportunityRecord = opportunityRecord;
                opportunityId = opportunityRecord.Id;
            } else if (sourceObjectName == JOURNAL_OBJECT) {
                Journal__c journalRecord = getJournalById(sourceRecordId);
                if (journalRecord == null) {
                    throw new AuraHandledException('The selected Journal could not be found or is no longer accessible.');
                }

                result.journalRecord = journalRecord;
                opportunityId = journalRecord.Opportunity__c;
            } else if (sourceObjectName == INVOICE_OBJECT) {
                Invoice__c invoiceRecord = getInvoiceById(sourceRecordId);
                if (invoiceRecord == null) {
                    throw new AuraHandledException('The selected Invoice could not be found or is no longer accessible.');
                }

                result.invoiceRecord = invoiceRecord;
                opportunityId = invoiceRecord.Opportunity__c;
            } else {
                throw new AuraHandledException('The selected record type is not supported by the lifecycle tracker.');
            }

            if (opportunityId == null) {
                return result;
            }

            populateLifecycleFromOpportunity(result, opportunityId);
            return result;
        } catch (AuraHandledException handledException) {
            throw handledException;
        } catch (Exception unexpectedException) {
            throw new AuraHandledException('Unable to load lifecycle details right now. Please try again later.');
        }
    }

    private static void populateLifecycleFromOpportunity(LifecycleWrapper result, Id opportunityId) {
        if (result == null || opportunityId == null) {
            return;
        }

        if (result.opportunityRecord == null) {
            result.opportunityRecord = getOpportunityById(opportunityId);
        }

        if (result.leadRecord == null) {
            result.leadRecord = getLeadByOpportunityId(opportunityId);
        }

        if (result.quoteRecord == null) {
            result.quoteRecord = getQuoteByOpportunityId(opportunityId);
        }

        if (result.journalRecord == null) {
            result.journalRecord = getJournalByOpportunityId(opportunityId);
        }

        if (result.invoiceRecord == null) {
            result.invoiceRecord = getInvoiceByOpportunityId(opportunityId);
        }
    }

    private static Lead getLeadById(Id leadId) {
        if (leadId == null) {
            return null;
        }

        List<Lead> leads = [
            SELECT Id, Name, ConvertedOpportunityId
            FROM Lead
            WHERE Id = :leadId
            LIMIT :LIFECYCLE_RECORD_LIMIT
        ];
        return leads.isEmpty() ? null : leads[0];
    }

    private static Lead getLeadByOpportunityId(Id opportunityId) {
        if (opportunityId == null) {
            return null;
        }

        List<Lead> leads = [
            SELECT Id, Name, ConvertedOpportunityId
            FROM Lead
            WHERE ConvertedOpportunityId = :opportunityId
            ORDER BY LastModifiedDate DESC
            LIMIT :LIFECYCLE_RECORD_LIMIT
        ];
        return leads.isEmpty() ? null : leads[0];
    }

    private static Opportunity getOpportunityById(Id opportunityId) {
        if (opportunityId == null) {
            return null;
        }

        List<Opportunity> opportunities = [
            SELECT Id, Name, StageName, Amount
            FROM Opportunity
            WHERE Id = :opportunityId
            LIMIT :LIFECYCLE_RECORD_LIMIT
        ];
        return opportunities.isEmpty() ? null : opportunities[0];
    }

    private static Quote getQuoteByOpportunityId(Id opportunityId) {
        if (opportunityId == null) {
            return null;
        }

        List<Quote> quotes = [
            SELECT Id, Name, Status
            FROM Quote
            WHERE OpportunityId = :opportunityId
            ORDER BY LastModifiedDate DESC
            LIMIT :LIFECYCLE_RECORD_LIMIT
        ];
        return quotes.isEmpty() ? null : quotes[0];
    }

    private static Journal__c getJournalById(Id journalId) {
        if (journalId == null) {
            return null;
        }

        List<Journal__c> journals = [
            SELECT Id, Name, Opportunity__c
            FROM Journal__c
            WHERE Id = :journalId
            LIMIT :LIFECYCLE_RECORD_LIMIT
        ];
        return journals.isEmpty() ? null : journals[0];
    }

    private static Journal__c getJournalByOpportunityId(Id opportunityId) {
        if (opportunityId == null) {
            return null;
        }

        List<Journal__c> journals = [
            SELECT Id, Name, Opportunity__c
            FROM Journal__c
            WHERE Opportunity__c = :opportunityId
            ORDER BY LastModifiedDate DESC
            LIMIT :LIFECYCLE_RECORD_LIMIT
        ];
        return journals.isEmpty() ? null : journals[0];
    }

    private static Invoice__c getInvoiceById(Id invoiceId) {
        if (invoiceId == null) {
            return null;
        }

        List<Invoice__c> invoices = [
            SELECT Id, Name, Status__c, Opportunity__c
            FROM Invoice__c
            WHERE Id = :invoiceId
            LIMIT :LIFECYCLE_RECORD_LIMIT
        ];
        return invoices.isEmpty() ? null : invoices[0];
    }

    private static Invoice__c getInvoiceByOpportunityId(Id opportunityId) {
        if (opportunityId == null) {
            return null;
        }

        List<Invoice__c> invoices = [
            SELECT Id, Name, Status__c, Opportunity__c
            FROM Invoice__c
            WHERE Opportunity__c = :opportunityId
            ORDER BY LastModifiedDate DESC
            LIMIT :LIFECYCLE_RECORD_LIMIT
        ];
        return invoices.isEmpty() ? null : invoices[0];
    }

    private static void assertSearchReadAccess() {
        assertReadableFields(LEAD_OBJECT, new Set<String>{ 'Id', 'Name', 'FirstName', 'LastName', 'Company' });
        assertReadableFields(OPPORTUNITY_OBJECT, new Set<String>{ 'Id', 'Name' });
        assertReadableFields(JOURNAL_OBJECT, new Set<String>{ 'Id', 'Name' });
        assertReadableFields(INVOICE_OBJECT, new Set<String>{ 'Id', 'Name' });
    }

    private static void assertLifecycleReadAccess() {
        assertReadableFields(LEAD_OBJECT, new Set<String>{ 'Id', 'Name', 'ConvertedOpportunityId' });
        assertReadableFields(OPPORTUNITY_OBJECT, new Set<String>{ 'Id', 'Name', 'StageName', 'Amount' });
        assertReadableFields(QUOTE_OBJECT, new Set<String>{ 'Id', 'Name', 'Status', 'OpportunityId' });
        assertReadableFields(JOURNAL_OBJECT, new Set<String>{ 'Id', 'Name', 'Opportunity__c' });
        assertReadableFields(INVOICE_OBJECT, new Set<String>{ 'Id', 'Name', 'Status__c', 'Opportunity__c' });
    }

    private static void assertReadableFields(String objectApiName, Set<String> fieldApiNames) {
        Schema.SObjectType sObjectType = GLOBAL_DESCRIBE.get(objectApiName);
        if (sObjectType == null) {
            throw new AuraHandledException('Configuration error: ' + objectApiName + ' is not available in this org.');
        }

        Schema.DescribeSObjectResult objectDescribe = sObjectType.getDescribe();
        if (!objectDescribe.isAccessible()) {
            throw new AuraHandledException('You do not have permission to access ' + objectDescribe.getLabel() + ' records.');
        }

        Map<String, Schema.SObjectField> fieldMap = objectDescribe.fields.getMap();
        for (String fieldApiName : fieldApiNames) {
            Schema.SObjectField fieldToken = fieldMap.get(fieldApiName);
            if (fieldToken == null || !fieldToken.getDescribe().isAccessible()) {
                throw new AuraHandledException(
                    'You do not have permission to view the ' + objectDescribe.getLabel() + '.' + fieldApiName + ' field.'
                );
            }
        }
    }

    private static void addSearchResults(
        List<SearchResultWrapper> searchResults,
        List<List<SObject>> searchGroups,
        Integer groupIndex,
        String objectType
    ) {
        if (searchResults == null || searchGroups == null || groupIndex == null || searchGroups.size() <= groupIndex) {
            return;
        }

        for (SObject recordItem : searchGroups[groupIndex]) {
            if (recordItem == null) {
                continue;
            }

            searchResults.add(
                new SearchResultWrapper(
                    (Id) recordItem.get('Id'),
                    (String) recordItem.get('Name'),
                    objectType
                )
            );
        }
    }

    private static void addLeadFallbackResults(List<SearchResultWrapper> searchResults, String sanitizedSearchKey) {
        if (searchResults == null || String.isBlank(sanitizedSearchKey)) {
            return;
        }

        Integer currentLeadCount = countResultsByObjectType(searchResults, LEAD_OBJECT);
        if (currentLeadCount >= SEARCH_LIMIT_PER_OBJECT) {
            return;
        }

        String likePattern = '%' + sanitizedSearchKey + '%';
        Integer remainingLeadSlots = SEARCH_LIMIT_PER_OBJECT - currentLeadCount;
        Set<Id> existingLeadIds = collectResultIdsByObjectType(searchResults, LEAD_OBJECT);

        List<Lead> leadResults = [
            SELECT Id, Name, FirstName, LastName, Company
            FROM Lead
            WHERE FirstName LIKE :likePattern
                OR LastName LIKE :likePattern
                OR Company LIKE :likePattern
            ORDER BY LastModifiedDate DESC
            LIMIT :remainingLeadSlots
        ];

        for (Lead leadRecord : leadResults) {
            if (leadRecord == null || existingLeadIds.contains(leadRecord.Id)) {
                continue;
            }

            searchResults.add(new SearchResultWrapper(leadRecord.Id, leadRecord.Name, LEAD_OBJECT));
            existingLeadIds.add(leadRecord.Id);
        }
    }

    private static void addJournalResults(List<SearchResultWrapper> searchResults, String sanitizedSearchKey) {
        if (searchResults == null || String.isBlank(sanitizedSearchKey)) {
            return;
        }

        String likePattern = '%' + sanitizedSearchKey + '%';
        Set<Id> existingJournalIds = collectResultIdsByObjectType(searchResults, JOURNAL_OBJECT);

        List<Journal__c> journalResults = [
            SELECT Id, Name
            FROM Journal__c
            WHERE Name LIKE :likePattern
            ORDER BY LastModifiedDate DESC
            LIMIT :SEARCH_LIMIT_PER_OBJECT
        ];

        for (Journal__c journalRecord : journalResults) {
            if (journalRecord == null || existingJournalIds.contains(journalRecord.Id)) {
                continue;
            }

            searchResults.add(new SearchResultWrapper(journalRecord.Id, journalRecord.Name, JOURNAL_OBJECT));
            existingJournalIds.add(journalRecord.Id);
        }
    }

    private static void addInvoiceResults(List<SearchResultWrapper> searchResults, String sanitizedSearchKey) {
        if (searchResults == null || String.isBlank(sanitizedSearchKey)) {
            return;
        }

        String likePattern = '%' + sanitizedSearchKey + '%';
        Set<Id> existingInvoiceIds = collectResultIdsByObjectType(searchResults, INVOICE_OBJECT);

        List<Invoice__c> invoiceResults = [
            SELECT Id, Name
            FROM Invoice__c
            WHERE Name LIKE :likePattern
            ORDER BY LastModifiedDate DESC
            LIMIT :SEARCH_LIMIT_PER_OBJECT
        ];

        for (Invoice__c invoiceRecord : invoiceResults) {
            if (invoiceRecord == null || existingInvoiceIds.contains(invoiceRecord.Id)) {
                continue;
            }

            searchResults.add(new SearchResultWrapper(invoiceRecord.Id, invoiceRecord.Name, INVOICE_OBJECT));
            existingInvoiceIds.add(invoiceRecord.Id);
        }
    }

    private static Integer countResultsByObjectType(List<SearchResultWrapper> searchResults, String objectType) {
        Integer resultCount = 0;
        for (SearchResultWrapper searchResult : searchResults) {
            if (searchResult != null && searchResult.objectType == objectType) {
                resultCount++;
            }
        }
        return resultCount;
    }

    private static Set<Id> collectResultIdsByObjectType(List<SearchResultWrapper> searchResults, String objectType) {
        Set<Id> resultIds = new Set<Id>();
        for (SearchResultWrapper searchResult : searchResults) {
            if (searchResult != null && searchResult.objectType == objectType && searchResult.recordId != null) {
                resultIds.add(searchResult.recordId);
            }
        }
        return resultIds;
    }

    private static Id parseRecordId(String recordId) {
        try {
            return (Id) recordId.trim();
        } catch (Exception invalidIdException) {
            throw new AuraHandledException('The selected record id is invalid.');
        }
    }

    private static String sanitizeSearchKey(String searchKey) {
        if (String.isBlank(searchKey)) {
            return null;
        }

        String normalizedSearchKey = searchKey.trim();
        String sanitizedValue = '';

        for (Integer index = 0; index < normalizedSearchKey.length(); index++) {
            String currentCharacter = normalizedSearchKey.substring(index, index + 1);
            sanitizedValue += isBlockedSearchCharacter(currentCharacter) ? ' ' : currentCharacter;
        }

        sanitizedValue = sanitizedValue.replaceAll('\\s+', ' ').trim();
        return sanitizedValue;
    }

    private static Boolean isBlockedSearchCharacter(String characterValue) {
        return characterValue == '?'
            || characterValue == '&'
            || characterValue == '|'
            || characterValue == '!'
            || characterValue == '{'
            || characterValue == '}'
            || characterValue == '['
            || characterValue == ']'
            || characterValue == '('
            || characterValue == ')'
            || characterValue == '^'
            || characterValue == '~'
            || characterValue == ':'
            || characterValue == '"'
            || characterValue == '\''
            || characterValue == '\\'
            || characterValue == '+';
    }

    private static String buildSoslSearchTerm(String searchKey) {
        String normalizedSearchKey = searchKey == null ? null : searchKey.trim();
        if (String.isBlank(normalizedSearchKey)) {
            return null;
        }

        return normalizedSearchKey + '*';
    }

    public class SearchResultWrapper {
        @AuraEnabled public Id recordId;
        @AuraEnabled public String recordName;
        @AuraEnabled public String objectType;

        public SearchResultWrapper(Id recordId, String recordName, String objectType) {
            this.recordId = recordId;
            this.recordName = recordName;
            this.objectType = objectType;
        }
    }

    public class LifecycleWrapper {
        @AuraEnabled public Lead leadRecord;
        @AuraEnabled public Opportunity opportunityRecord;
        @AuraEnabled public Quote quoteRecord;
        @AuraEnabled public Journal__c journalRecord;
        @AuraEnabled public Invoice__c invoiceRecord;
    }
}