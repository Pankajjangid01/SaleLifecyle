@isTest
private class SalesLifecycleControllerTest {

    private static final String DUPLICATE_NAME = 'Lifecycle Duplicate';
    private static final String LEAD_COMPANY = 'Lifecycle Test Company';

    @testSetup
    static void setupData() {
        Account accountRecord = new Account(Name = 'Lifecycle Test Account');
        insert accountRecord;

        Opportunity duplicateOpportunity = new Opportunity(
            Name = DUPLICATE_NAME,
            AccountId = accountRecord.Id,
            StageName = 'Proposal/Price Quote',
            CloseDate = Date.today().addDays(30),
            Amount = 125000
        );

        Opportunity standaloneOpportunity = new Opportunity(
            Name = 'Standalone Lifecycle Opportunity',
            AccountId = accountRecord.Id,
            StageName = 'Proposal/Price Quote',
            CloseDate = Date.today().addDays(40),
            Amount = 88000
        );

        Opportunity orphanOpportunity = new Opportunity(
            Name = 'Opportunity Without Related Records',
            AccountId = accountRecord.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(15),
            Amount = 25000
        );

        insert new List<Opportunity>{ duplicateOpportunity, standaloneOpportunity, orphanOpportunity };

        Id standardPricebookId = Test.getStandardPricebookId();
        Product2 productRecord = new Product2(Name = 'Lifecycle Product', IsActive = true);
        insert productRecord;

        PricebookEntry pricebookEntry = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = productRecord.Id,
            UnitPrice = 1000,
            IsActive = true
        );
        insert pricebookEntry;

        insert new List<Quote>{
            new Quote(
                Name = 'Duplicate Opportunity Quote',
                OpportunityId = duplicateOpportunity.Id,
                Pricebook2Id = standardPricebookId,
                Status = 'Draft'
            ),
            new Quote(
                Name = 'Standalone Opportunity Quote',
                OpportunityId = standaloneOpportunity.Id,
                Pricebook2Id = standardPricebookId,
                Status = 'Draft'
            )
        };

        Journal__c duplicateJournal = new Journal__c(
            Status__c = 'Draft',
            Journal_Date__c = Date.today(),
            Opportunity__c = duplicateOpportunity.Id
        );
        Journal__c standaloneJournal = new Journal__c(
            Status__c = 'Draft',
            Journal_Date__c = Date.today(),
            Opportunity__c = standaloneOpportunity.Id
        );
        insert new List<Journal__c>{ duplicateJournal, standaloneJournal };

        insert new List<Invoice__c>{
            new Invoice__c(
                Account__c = accountRecord.Id,
                Journal__c = duplicateJournal.Id,
                Opportunity__c = duplicateOpportunity.Id,
                Invoice_Date__c = Date.today().addDays(-15),
                Due_Date__c = Date.today().addDays(15),
                Amount__c = 15000,
                Payment_Status__c = 'Unpaid',
                Status__c = 'Sent'
            ),
            new Invoice__c(
                Account__c = accountRecord.Id,
                Journal__c = standaloneJournal.Id,
                Opportunity__c = standaloneOpportunity.Id,
                Invoice_Date__c = Date.today().addDays(-10),
                Due_Date__c = Date.today().addDays(20),
                Amount__c = 9000,
                Payment_Status__c = 'Unpaid',
                Status__c = 'Sent'
            )
        };

        Lead convertibleLead = new Lead(
            FirstName = 'Lifecycle',
            LastName = DUPLICATE_NAME,
            Company = LEAD_COMPANY,
            Email = 'lifecyclelead@example.com',
            Phone = '9800000001',
            MobilePhone = '9800000001',
            Status = 'Open - Not Contacted',
            GST_Number__c = '27AAAAA0000A1Z5'
        );
        insert convertibleLead;

        Database.LeadConvert leadConversion = new Database.LeadConvert();
        leadConversion.setLeadId(convertibleLead.Id);
        leadConversion.setConvertedStatus(getConvertedLeadStatus());
        leadConversion.setDoNotCreateOpportunity(false);
        leadConversion.setOpportunityName(DUPLICATE_NAME);

        Database.LeadConvertResult conversionResult = Database.convertLead(leadConversion);
        System.assert(conversionResult.isSuccess(), 'Lead conversion should succeed for lifecycle tests.');

        Opportunity convertedOpportunity = [
            SELECT Id, AccountId
            FROM Opportunity
            WHERE Id = :conversionResult.getOpportunityId()
            LIMIT 1
        ];

        insert new Quote(
            Name = 'Converted Lead Quote',
            OpportunityId = convertedOpportunity.Id,
            Pricebook2Id = standardPricebookId,
            Status = 'Draft'
        );

        Journal__c convertedJournal = new Journal__c(
            Status__c = 'Draft',
            Journal_Date__c = Date.today(),
            Opportunity__c = convertedOpportunity.Id
        );
        insert convertedJournal;

        insert new Invoice__c(
            Account__c = convertedOpportunity.AccountId,
            Journal__c = convertedJournal.Id,
            Opportunity__c = convertedOpportunity.Id,
            Invoice_Date__c = Date.today().addDays(-7),
            Due_Date__c = Date.today().addDays(10),
            Amount__c = 11000,
            Payment_Status__c = 'Unpaid',
            Status__c = 'Sent'
        );
    }

    @isTest
    static void testSearchRecordsReturnsTypedResults() {
        Lead convertedLead = [
            SELECT Id
            FROM Lead
            WHERE LastName = :DUPLICATE_NAME
            LIMIT 1
        ];
        Opportunity duplicateOpportunity = [
            SELECT Id
            FROM Opportunity
            WHERE Name = :DUPLICATE_NAME
            ORDER BY CreatedDate ASC
            LIMIT 1
        ];
        Journal__c duplicateJournal = [
            SELECT Id, Name
            FROM Journal__c
            WHERE Opportunity__r.Name = :DUPLICATE_NAME
            LIMIT 1
        ];
        Invoice__c duplicateInvoice = [
            SELECT Id, Name
            FROM Invoice__c
            WHERE Opportunity__r.Name = :DUPLICATE_NAME
            LIMIT 1
        ];

        Test.setFixedSearchResults(new Id[]{
            convertedLead.Id,
            duplicateOpportunity.Id
        });

        Test.startTest();
        List<SalesLifecycleController.SearchResultWrapper> coreResults =
            SalesLifecycleController.searchRecords('Lifecycle');
        List<SalesLifecycleController.SearchResultWrapper> journalResults =
            SalesLifecycleController.searchRecords(duplicateJournal.Name);
        List<SalesLifecycleController.SearchResultWrapper> invoiceResults =
            SalesLifecycleController.searchRecords(duplicateInvoice.Name);
        Test.stopTest();

        System.assertEquals(2, coreResults.size(),
            'Core SOSL search should return the searchable Lead and Opportunity results.');

        Set<String> coreObjectTypes = new Set<String>();
        for (SalesLifecycleController.SearchResultWrapper resultItem : coreResults) {
            coreObjectTypes.add(resultItem.objectType);
            System.assertNotEquals(null, resultItem.recordId, 'Search result id should be populated.');
            System.assertNotEquals(null, resultItem.recordName, 'Search result name should be populated.');
        }

        System.assert(coreObjectTypes.contains('Lead'), 'Lead should be represented in search results.');
        System.assert(coreObjectTypes.contains('Opportunity'), 'Opportunity should be represented in search results.');
        System.assert(containsResultType(journalResults, 'Journal__c'),
            'Journal search should return a Journal result through the SOQL fallback path.');
        System.assert(containsResultType(invoiceResults, 'Invoice__c'),
            'Invoice search should return an Invoice result through the SOQL fallback path.');
    }

    @isTest
    static void testSearchRecordsHandlesShortAndSanitizedTerms() {
        Test.setFixedSearchResults(new Id[]{});

        System.assertEquals(0, SalesLifecycleController.searchRecords(null).size(),
            'Blank search terms should return no results.');
        System.assertEquals(0, SalesLifecycleController.searchRecords('a').size(),
            'Single-character search terms should return no results.');

        Test.startTest();
        List<SalesLifecycleController.SearchResultWrapper> sanitizedResults =
            SalesLifecycleController.searchRecords('Lifecycle + Duplicate');
        Test.stopTest();

        System.assertNotEquals(null, sanitizedResults,
            'Sanitized search terms should still execute safely and return a valid list response.');
    }

    @isTest
    static void testGetLifecycleDataFromLead() {
        Lead convertedLead = [
            SELECT Id, ConvertedOpportunityId
            FROM Lead
            WHERE LastName = :DUPLICATE_NAME
            LIMIT 1
        ];

        Test.startTest();
        SalesLifecycleController.LifecycleWrapper lifecycle =
            SalesLifecycleController.getLifecycleData(String.valueOf(convertedLead.Id));
        Test.stopTest();

        System.assertNotEquals(null, lifecycle.leadRecord, 'Lead should be returned for lead-driven lifecycle fetch.');
        System.assertNotEquals(null, lifecycle.opportunityRecord, 'Converted opportunity should be returned.');
        System.assertEquals(convertedLead.ConvertedOpportunityId, lifecycle.opportunityRecord.Id,
            'Lead should resolve to the converted opportunity.');
        System.assertNotEquals(null, lifecycle.quoteRecord, 'Related quote should be populated.');
        System.assertNotEquals(null, lifecycle.journalRecord, 'Related journal should be populated.');
        System.assertNotEquals(null, lifecycle.invoiceRecord, 'Related invoice should be populated.');
    }

    @isTest
    static void testGetLifecycleDataFromOpportunity() {
        Opportunity standaloneOpportunity = [
            SELECT Id
            FROM Opportunity
            WHERE Name = 'Standalone Lifecycle Opportunity'
            LIMIT 1
        ];

        Test.startTest();
        SalesLifecycleController.LifecycleWrapper lifecycle =
            SalesLifecycleController.getLifecycleData(String.valueOf(standaloneOpportunity.Id));
        Test.stopTest();

        System.assertEquals(standaloneOpportunity.Id, lifecycle.opportunityRecord.Id,
            'Selected opportunity should remain the anchor record.');
        System.assertEquals(null, lifecycle.leadRecord,
            'Standalone opportunity should not backfill a lead when no converted lead exists.');
        System.assertNotEquals(null, lifecycle.quoteRecord, 'Opportunity quote should be populated.');
        System.assertNotEquals(null, lifecycle.journalRecord, 'Opportunity journal should be populated.');
        System.assertNotEquals(null, lifecycle.invoiceRecord, 'Opportunity invoice should be populated.');
    }

    @isTest
    static void testGetLifecycleDataFromJournal() {
        Journal__c journalRecord = [
            SELECT Id, Opportunity__c
            FROM Journal__c
            WHERE Opportunity__r.Name = 'Standalone Lifecycle Opportunity'
            LIMIT 1
        ];

        Test.startTest();
        SalesLifecycleController.LifecycleWrapper lifecycle =
            SalesLifecycleController.getLifecycleData(String.valueOf(journalRecord.Id));
        Test.stopTest();

        System.assertEquals(journalRecord.Id, lifecycle.journalRecord.Id,
            'Selected journal should remain on the lifecycle response.');
        System.assertEquals(journalRecord.Opportunity__c, lifecycle.opportunityRecord.Id,
            'Journal should resolve its related opportunity.');
        System.assertNotEquals(null, lifecycle.quoteRecord, 'Related quote should be returned.');
        System.assertNotEquals(null, lifecycle.invoiceRecord, 'Related invoice should be returned.');
    }

    @isTest
    static void testGetLifecycleDataFromInvoice() {
        Invoice__c invoiceRecord = [
            SELECT Id, Opportunity__c
            FROM Invoice__c
            WHERE Opportunity__r.Name = 'Standalone Lifecycle Opportunity'
            LIMIT 1
        ];

        Test.startTest();
        SalesLifecycleController.LifecycleWrapper lifecycle =
            SalesLifecycleController.getLifecycleData(String.valueOf(invoiceRecord.Id));
        Test.stopTest();

        System.assertEquals(invoiceRecord.Id, lifecycle.invoiceRecord.Id,
            'Selected invoice should remain on the lifecycle response.');
        System.assertEquals(invoiceRecord.Opportunity__c, lifecycle.opportunityRecord.Id,
            'Invoice should resolve its related opportunity.');
        System.assertNotEquals(null, lifecycle.quoteRecord, 'Related quote should be returned.');
        System.assertNotEquals(null, lifecycle.journalRecord, 'Related journal should be returned.');
    }

    @isTest
    static void testGetLifecycleDataHandlesMissingRelatedRecords() {
        Opportunity orphanOpportunity = [
            SELECT Id
            FROM Opportunity
            WHERE Name = 'Opportunity Without Related Records'
            LIMIT 1
        ];

        Test.startTest();
        SalesLifecycleController.LifecycleWrapper lifecycle =
            SalesLifecycleController.getLifecycleData(String.valueOf(orphanOpportunity.Id));
        Test.stopTest();

        System.assertNotEquals(null, lifecycle.opportunityRecord, 'Opportunity should be returned.');
        System.assertEquals(null, lifecycle.leadRecord, 'Lead should be null when none is related.');
        System.assertEquals(null, lifecycle.quoteRecord, 'Quote should be null when none is related.');
        System.assertEquals(null, lifecycle.journalRecord, 'Journal should be null when none is related.');
        System.assertEquals(null, lifecycle.invoiceRecord, 'Invoice should be null when none is related.');
    }

    @isTest
    static void testGetLifecycleDataHandlesNullRelationshipsWhenPossible() {
        if (Journal__c.Opportunity__c.getDescribe().isNillable()) {
            Journal__c orphanJournal = new Journal__c(
                Status__c = 'Draft',
                Journal_Date__c = Date.today()
            );
            insert orphanJournal;

            SalesLifecycleController.LifecycleWrapper journalLifecycle =
                SalesLifecycleController.getLifecycleData(String.valueOf(orphanJournal.Id));

            System.assertNotEquals(null, journalLifecycle.journalRecord,
                'Journal should still be returned even when it has no opportunity relationship.');
            System.assertEquals(null, journalLifecycle.opportunityRecord,
                'Opportunity should remain null when the journal is orphaned.');
        }

        if (Invoice__c.Opportunity__c.getDescribe().isNillable() && Invoice__c.Journal__c.getDescribe().isNillable()) {
            Account accountRecord = [SELECT Id FROM Account WHERE Name = 'Lifecycle Test Account' LIMIT 1];
            Invoice__c orphanInvoice = new Invoice__c(
                Account__c = accountRecord.Id,
                Invoice_Date__c = Date.today(),
                Due_Date__c = Date.today().addDays(5),
                Amount__c = 1000,
                Payment_Status__c = 'Unpaid',
                Status__c = 'Sent'
            );
            insert orphanInvoice;

            SalesLifecycleController.LifecycleWrapper invoiceLifecycle =
                SalesLifecycleController.getLifecycleData(String.valueOf(orphanInvoice.Id));

            System.assertNotEquals(null, invoiceLifecycle.invoiceRecord,
                'Invoice should still be returned even when it has no opportunity relationship.');
            System.assertEquals(null, invoiceLifecycle.opportunityRecord,
                'Opportunity should remain null when the invoice is orphaned.');
        }
    }

    @isTest
    static void testGetLifecycleDataHandlesBlankAndInvalidIds() {
        SalesLifecycleController.LifecycleWrapper blankLifecycle = SalesLifecycleController.getLifecycleData(null);
        System.assertEquals(null, blankLifecycle.leadRecord, 'Blank record id should return an empty wrapper.');
        System.assertEquals(null, blankLifecycle.opportunityRecord, 'Blank record id should return an empty wrapper.');

        try {
            SalesLifecycleController.getLifecycleData('invalid-id');
            System.assert(false, 'Invalid ids should throw an AuraHandledException.');
        } catch (AuraHandledException handledException) {
            System.assertNotEquals(null, handledException.getMessage(),
                'Invalid ids should return a non-empty handled exception message.');
        }
    }

    private static Boolean containsResultType(
        List<SalesLifecycleController.SearchResultWrapper> searchResults,
        String objectType
    ) {
        for (SalesLifecycleController.SearchResultWrapper searchResult : searchResults) {
            if (searchResult != null && searchResult.objectType == objectType) {
                return true;
            }
        }

        return false;
    }

    private static String getConvertedLeadStatus() {
        return [
            SELECT MasterLabel
            FROM LeadStatus
            WHERE IsConverted = true
            LIMIT 1
        ].MasterLabel;
    }
}