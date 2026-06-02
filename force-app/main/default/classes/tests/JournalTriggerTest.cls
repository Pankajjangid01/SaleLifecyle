@isTest
public class JournalTriggerTest {

    // ─── Helper: create Account + Opportunity + Journal ───
    static Journal__c createJournal(String status) {
        
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Opportunity opp = new Opportunity(
            Name      = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Proposal/Price Quote',
            CloseDate = Date.today().addDays(30),
            Amount    = 100000
        );
        insert opp;

        Journal__c j = new Journal__c(
            Status__c       = status,
            Journal_Date__c = Date.today(),
            Opportunity__c  = opp.Id
        );
        insert j;
        return j;
    }

    // ─── Test 1: Posted journal cannot be deleted ───
    @isTest
    static void testDeletePostedJournalBlocked() {
        Journal__c j = createJournal('Posted');

        Test.startTest();
            try {
                delete j;
                System.assert(false, 'Delete should have been blocked for Posted journal');
            } catch (DmlException e) {
                System.assert(e.getMessage() != null,
                    'Error message should not be null');
            }
        Test.stopTest();

        // verify journal still exists
        List<Journal__c> remaining = [SELECT Id FROM Journal__c WHERE Id = :j.Id];
        System.assertEquals(1, remaining.size(),
            'Posted journal should still exist after blocked delete');
    }

    // ─── Test 2: Draft journal CAN be deleted ───
    @isTest
    static void testDeleteDraftJournalAllowed() {
        Journal__c j = createJournal('Draft');

        Test.startTest();
            delete j;
        Test.stopTest();

        List<Journal__c> result = [SELECT Id FROM Journal__c WHERE Id = :j.Id];
        System.assertEquals(0, result.size(),
            'Draft journal should be deletable');
    }

    // ─── Test 3: Bulk 200 posted journals all blocked ───
    @isTest
    static void testBulkDeletePostedJournalsBlocked() {
        Account acc = new Account(Name = 'Bulk Test Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name      = 'Bulk Test Opp',
            AccountId = acc.Id,
            StageName = 'Proposal/Price Quote',
            CloseDate = Date.today().addDays(30),
            Amount    = 100000
        );
        insert opp;

        // insert as Draft first to avoid Flow firing on insert
        List<Journal__c> journals = new List<Journal__c>();
        for (Integer i = 0; i < 200; i++) {
            journals.add(new Journal__c(
                Status__c       = 'Draft',
                Journal_Date__c = Date.today(),
                Opportunity__c  = opp.Id
            ));
        }
        insert journals;

        // now update to Posted — Flow fires here
        for (Journal__c j : journals) {
            j.Status__c = 'Posted';
        }
        update journals;

        Test.startTest();
            try {
                delete journals;
                System.assert(false, 'Bulk delete should have been blocked');
            } catch (DmlException e) {
                System.assert(e.getMessage() != null,
                    'Should throw error for bulk delete of posted journals');
            }
        Test.stopTest();

        List<Journal__c> remaining = [
            SELECT Id FROM Journal__c WHERE Id IN :journals
        ];
        System.assertEquals(200, remaining.size(),
            'All 200 posted journals should still exist');
    }

    // ─── Test 4: Multiple draft journals can all be deleted ───
    @isTest
    static void testBulkDeleteDraftJournalsAllowed() {
        Account acc = new Account(Name = 'Bulk Draft Account');
        insert acc;

        Opportunity opp = new Opportunity(
            Name      = 'Bulk Draft Opp',
            AccountId = acc.Id,
            StageName = 'Proposal/Price Quote',
            CloseDate = Date.today().addDays(30),
            Amount    = 100000
        );
        insert opp;

        List<Journal__c> journals = new List<Journal__c>();
        for (Integer i = 0; i < 50; i++) {
            journals.add(new Journal__c(
                Status__c       = 'Draft',
                Journal_Date__c = Date.today(),
                Opportunity__c  = opp.Id
            ));
        }
        insert journals;

        Test.startTest();
            delete journals;
        Test.stopTest();

        List<Journal__c> remaining = [
            SELECT Id FROM Journal__c WHERE Id IN :journals
        ];
        System.assertEquals(0, remaining.size(),
            'All draft journals should be deletable');
    }
}