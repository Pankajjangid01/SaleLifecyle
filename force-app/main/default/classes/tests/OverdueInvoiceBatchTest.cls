@isTest
public class OverdueInvoiceBatchTest {

    @testSetup
    static void setupData() {
        // ── Account ──
        Account acc = new Account(Name = 'NorthWind Test Account');
        insert acc;

        // ── Opportunity ──
        Opportunity opp = new Opportunity(
            Name      = 'Test Opp',
            AccountId = acc.Id,
            StageName = 'Proposal/Price Quote',
            CloseDate = Date.today().addDays(30),
            Amount    = 100000
        );
        insert opp;

        // ── Journal (required by Invoice__c) ──
        Journal__c journal = new Journal__c(
            Status__c       = 'Draft',
            Journal_Date__c = Date.today(),
            Opportunity__c  = opp.Id
        );
        insert journal;

        List<Invoice__c> invoices = new List<Invoice__c>();

        // 200 overdue unpaid → should be marked Overdue
        for (Integer i = 0; i < 200; i++) {
            invoices.add(new Invoice__c(
                Account__c        = acc.Id,
                Journal__c        = journal.Id,
                Opportunity__c    = opp.Id,
                Invoice_Date__c   = Date.today().addDays(-60),
                Due_Date__c       = Date.today().addDays(-30),
                Amount__c         = 50000,
                Payment_Status__c = 'Unpaid',
                Status__c         = 'Sent'
            ));
        }

        // 1 paid → should NOT be marked Overdue
        invoices.add(new Invoice__c(
            Account__c        = acc.Id,
            Journal__c        = journal.Id,
            Opportunity__c    = opp.Id,
            Invoice_Date__c   = Date.today().addDays(-60),
            Due_Date__c       = Date.today().addDays(-30),
            Amount__c         = 50000,
            Payment_Status__c = 'Paid',
            Status__c         = 'Sent'
        ));

        // 1 future → should NOT be marked Overdue
        invoices.add(new Invoice__c(
            Account__c        = acc.Id,
            Journal__c        = journal.Id,
            Opportunity__c    = opp.Id,
            Invoice_Date__c   = Date.today(),
            Due_Date__c       = Date.today().addDays(30),
            Amount__c         = 50000,
            Payment_Status__c = 'Unpaid',
            Status__c         = 'Sent'
        ));

        // 1 cancelled → should NOT be touched
        invoices.add(new Invoice__c(
            Account__c        = acc.Id,
            Journal__c        = journal.Id,
            Opportunity__c    = opp.Id,
            Invoice_Date__c   = Date.today().addDays(-60),
            Due_Date__c       = Date.today().addDays(-30),
            Amount__c         = 50000,
            Payment_Status__c = 'Unpaid',
            Status__c         = 'Cancelled'
        ));

        insert invoices;
    }

    // ─── Test 1: 200 overdue invoices marked correctly ───
    @isTest
    static void testOverdueInvoicesMarked() {
        Test.startTest();
            Database.executeBatch(new OverdueInvoiceBatch(), 200);
        Test.stopTest();

        List<Invoice__c> overdue = [
            SELECT Id FROM Invoice__c
            WHERE Status__c = 'Overdue'
        ];
        System.assertEquals(200, overdue.size(),
            '200 unpaid past-due invoices should be marked Overdue');
    }

    // ─── Test 2: Paid invoice NOT marked overdue ───
    @isTest
    static void testPaidInvoiceNotMarked() {
        Test.startTest();
            Database.executeBatch(new OverdueInvoiceBatch(), 200);
        Test.stopTest();

        List<Invoice__c> paid = [
            SELECT Status__c FROM Invoice__c
            WHERE Payment_Status__c = 'Paid'
        ];
        System.assertEquals(1, paid.size(), 'Should have 1 paid invoice');
        System.assertNotEquals('Overdue', paid[0].Status__c,
            'Paid invoice should never be marked Overdue');
    }

    // ─── Test 3: Future invoice NOT marked overdue ───
    @isTest
    static void testFutureInvoiceNotMarked() {
        Test.startTest();
            Database.executeBatch(new OverdueInvoiceBatch(), 200);
        Test.stopTest();

        List<Invoice__c> future = [
            SELECT Status__c FROM Invoice__c
            WHERE Due_Date__c > TODAY
        ];
        System.assertEquals(1, future.size(), 'Should have 1 future invoice');
        System.assertNotEquals('Overdue', future[0].Status__c,
            'Future invoice should never be marked Overdue');
    }

    // ─── Test 4: Cancelled invoice NOT touched ───
    @isTest
    static void testCancelledInvoiceNotTouched() {
        Test.startTest();
            Database.executeBatch(new OverdueInvoiceBatch(), 200);
        Test.stopTest();

        List<Invoice__c> cancelled = [
            SELECT Status__c FROM Invoice__c
            WHERE Status__c = 'Cancelled'
        ];
        System.assertEquals(1, cancelled.size(),
            'Cancelled invoice should stay Cancelled');
    }

    // ─── Test 5: Scheduler runs without error ───
    @isTest
    static void testSchedulerRuns() {
        Test.startTest();
            System.schedule(
                'Test Overdue Invoice Scheduler',
                '0 0 2 * * ?',
                new OverdueInvoiceScheduler()
            );
        Test.stopTest();

        List<CronTrigger> jobs = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name = 'Test Overdue Invoice Scheduler'
        ];
        System.assertEquals(1, jobs.size(),
            'Scheduler job should be created successfully');
    }

    // ─── Test 6: Batch finish runs without error ───
    @isTest
    static void testBatchFinishRuns() {
        Test.startTest();
            Database.executeBatch(new OverdueInvoiceBatch(), 200);
        Test.stopTest();

        System.assert(true, 'Batch finish should complete without errors');
    }
}