@isTest
public class LifecycleTrackerControllerTest {
    private static Journal__c createTestJournal(Id opportunityId) {
        Journal__c j = new Journal__c(
            Opportunity__c  = opportunityId,
            Journal_Date__c = Date.today(),
            Status__c       = 'Draft'
        );
        insert j;
        return j;
    }
    
    private static Invoice__c buildInvoice(Id opportunityId, Id accountId, Id journalId) {
        return new Invoice__c(
            Opportunity__c  = opportunityId,
            Account__c      = accountId,
            Amount__c       = 10000,
            Journal__c      = journalId,
            Invoice_Date__c = Date.today(),
            Due_Date__c     = Date.today().addDays(30)
        );
    }

    @isTest
    static void testGetChainFromLead() {

        Account acc = new Account(
            Name           = 'Codetrade Technologies',
            GST_Number__c  = '27ABCDE1234F1Z5'
        );
        insert acc;

        Lead leadRec = new Lead(
            FirstName     = 'Pankaj',
            LastName      = 'Sharma',
            Company       = 'Codetrade',
            Status        = 'Open - Not Contacted',
            Email         = 'pankaj_' + DateTime.now().getTime() + '@test.com',
            MobilePhone   = '9876543210',
            GST_Number__c = '27ABCDE1234F1Z5'
        );
        insert leadRec;

        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadRec.Id);
        lc.setAccountId(acc.Id);
        lc.setDoNotCreateOpportunity(false);

        LeadStatus convertStatus = [
            SELECT MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1
        ];
        lc.setConvertedStatus(convertStatus.MasterLabel);

        Database.LeadConvertResult lcr = Database.convertLead(lc);
        Id oppId = lcr.getOpportunityId();

        Opportunity opp = [SELECT Id, Name FROM Opportunity WHERE Id = :oppId LIMIT 1];

        Quote q = new Quote(
            Name          = 'Quote Test',
            OpportunityId = opp.Id,
            Status        = 'Draft'
        );
        insert q;

        Journal__c j = createTestJournal(opp.Id);

        Invoice__c inv = buildInvoice(opp.Id, acc.Id, j.Id);
        insert inv;

        Test.startTest();
        List<LifecycleTrackerController.SearchResult> results =
            LifecycleTrackerController.getChain('Codetrade');
        Test.stopTest();

        System.assert(results.size() > 0, 'Expected at least one result for Codetrade');
        System.assertNotEquals(null, results[0].lead, 'Lead should not be null');
    }

    @isTest
    static void testGetChainFromOpportunity() {

        Account acc = new Account(
            Name          = 'Infosys',
            GST_Number__c = '27ABCDE1234F1Z5'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name      = 'Infosys ERP Deal',
            StageName = 'Qualification',
            CloseDate = Date.today().addDays(5),
            AccountId = acc.Id
        );
        insert opp;

        Test.startTest();
        List<LifecycleTrackerController.SearchResult> results =
            LifecycleTrackerController.getChain('Infosys');
        Test.stopTest();

        System.assert(results.size() > 0, 'Expected at least one result for Infosys');
        System.assertNotEquals(null, results[0].opportunity, 'Opportunity should not be null');
    }

    @isTest
    static void testGetChainFromInvoice() {

        Account acc = new Account(
            Name          = 'TCS',
            GST_Number__c = '27ABCDE1234F1Z5'
        );
        insert acc;

        Opportunity opp = new Opportunity(
            Name      = 'TCS Project',
            StageName = 'Proposal',
            CloseDate = Date.today().addDays(7),
            AccountId = acc.Id
        );
        insert opp;

        Journal__c j = createTestJournal(opp.Id);

        Invoice__c inv = buildInvoice(opp.Id, acc.Id, j.Id);
        insert inv;

        Invoice__c insertedInv = [SELECT Id, Name FROM Invoice__c WHERE Id = :inv.Id LIMIT 1];
        String invoiceName = insertedInv.Name;

        Test.startTest();
        List<LifecycleTrackerController.SearchResult> results =
            LifecycleTrackerController.getChain(invoiceName);
        Test.stopTest();

        System.assert(results.size() > 0, 'Expected at least one result for Invoice: ' + invoiceName);

        Boolean invoiceFound = false;
        for (LifecycleTrackerController.SearchResult r : results) {
            if (r.invoiceRecord != null && r.invoiceRecord.Id == inv.Id) {
                invoiceFound = true;
                break;
            }
        }
        System.assert(invoiceFound, 'Invoice should be present in results');
    }

    @isTest
    static void testBlankSearch() {
        Test.startTest();
        try {
            LifecycleTrackerController.getChain('');
            System.assert(false, 'Should have thrown AuraHandledException for blank input');
        } catch (AuraHandledException ex) {
            System.assert(true, 'AuraHandledException correctly thrown for blank input');
        }
        Test.stopTest();
    }

    @isTest
    static void testShortSearch() {
        Test.startTest();
        try {
            LifecycleTrackerController.getChain('ab');
            System.assert(false, 'Should have thrown AuraHandledException for short input');
        } catch (AuraHandledException ex) {
            System.assert(true, 'AuraHandledException correctly thrown for short input');
        }
        Test.stopTest();
    }

    @isTest
    static void testNoRecordsFound() {
        Test.startTest();
        try {
            LifecycleTrackerController.getChain('ZZZZZZ');
            System.assert(false, 'Should have thrown AuraHandledException for no results');
        } catch (AuraHandledException ex) {
            System.assert(true, 'AuraHandledException correctly thrown for no matching records');
        }
        Test.stopTest();
    }
}