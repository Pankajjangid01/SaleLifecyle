@isTest
public class QuoteTriggerTest {

    // ─── Helper: create full Opportunity + Quote setup ───
    static Map<String, Id> createTestData() {
        // Account
        Account acc = new Account(Name = 'NorthWind Test Account');
        insert acc;

        // Opportunity
        Opportunity opp = new Opportunity(
            Name            = 'NorthWind Test Opp',
            AccountId       = acc.Id,
            StageName       = 'Proposal/Price Quote',
            CloseDate       = Date.today().addDays(30),
            Amount          = 500000
        );
        insert opp;

        // Pricebook
        Id pricebookId = Test.getStandardPricebookId();

        // Product
        Product2 prod = new Product2(
            Name      = 'Office Chair',
            IsActive  = true
        );
        insert prod;

        // Pricebook Entry
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id   = prod.Id,
            UnitPrice    = 5000,
            IsActive     = true
        );
        insert pbe;

        // Quote
        Quote q = new Quote(
            Name           = 'Test Quote',
            OpportunityId  = opp.Id,
            Pricebook2Id   = pricebookId,
            Status         = 'Draft'
        );
        insert q;

        // Quote Line Item
        QuoteLineItem qli = new QuoteLineItem(
            QuoteId          = q.Id,
            Product2Id       = prod.Id,
            PricebookEntryId = pbe.Id,
            Quantity         = 10,
            UnitPrice        = 5000
        );
        insert qli;

        return new Map<String, Id>{
            'accountId'     => acc.Id,
            'opportunityId' => opp.Id,
            'quoteId'       => q.Id,
            'qliId'         => qli.Id
        };
    }

    // ─── Test 1: Quote approved → line items locked ───
    @isTest
    static void testQuoteLineItemsLockedOnApproval() {
        Map<String, Id> data = createTestData();

        Quote q = [SELECT Id, Status FROM Quote WHERE Id = :data.get('quoteId')];

        Test.startTest();
            q.Status = 'Approved';
            update q;
        Test.stopTest();

        QuoteLineItem qli = [
            SELECT Is_Locked__c 
            FROM QuoteLineItem 
            WHERE Id = :data.get('qliId')
        ];
        System.assertEquals(true, qli.Is_Locked__c, 
            'QuoteLineItem should be locked after Quote approval');
    }

    // ─── Test 2: Quote approved → Opportunity gets Has_Approved_Quote__c = true ───
    @isTest
    static void testOpportunityStampedOnQuoteApproval() {
        Map<String, Id> data = createTestData();

        Quote q = [SELECT Id, Status FROM Quote WHERE Id = :data.get('quoteId')];

        Test.startTest();
            q.Status = 'Approved';
            update q;
        Test.stopTest();

        Opportunity opp = [
            SELECT Has_Approved_Quote__c 
            FROM Opportunity 
            WHERE Id = :data.get('opportunityId')
        ];
        System.assertEquals(true, opp.Has_Approved_Quote__c, 
            'Opportunity should be stamped with Has_Approved_Quote__c = true');
    }

    // ─── Test 3: Quote NOT approved → no lock ───
    @isTest
    static void testQuoteLineItemsNotLockedOnDraft() {
        Map<String, Id> data = createTestData();

        // update to Needs Review — not Approved
        Quote q = [SELECT Id, Status FROM Quote WHERE Id = :data.get('quoteId')];
        q.Status = 'Needs Review';
        update q;

        QuoteLineItem qli = [
            SELECT Is_Locked__c 
            FROM QuoteLineItem 
            WHERE Id = :data.get('qliId')
        ];
        System.assertNotEquals(true, qli.Is_Locked__c, 
            'QuoteLineItem should NOT be locked for non-approved status');
    }

    // ─── Test 4: Bulk - 200 quotes approved together ───
    @isTest
    static void testBulkQuoteApproval() {
        // create pricebook setup once
        Id pricebookId = Test.getStandardPricebookId();

        Product2 prod = new Product2(Name = 'Bulk Product', IsActive = true);
        insert prod;

        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id   = prod.Id,
            UnitPrice    = 1000,
            IsActive     = true
        );
        insert pbe;

        Account acc = new Account(Name = 'Bulk Account');
        insert acc;

        // create 50 opportunities (keep within limits)
        List<Opportunity> opps = new List<Opportunity>();
        for (Integer i = 0; i < 50; i++) {
            opps.add(new Opportunity(
                Name      = 'Bulk Opp ' + i,
                AccountId = acc.Id,
                StageName = 'Proposal/Price Quote',
                CloseDate = Date.today().addDays(30),
                Amount    = 10000
            ));
        }
        insert opps;

        // create quotes
        List<Quote> quotes = new List<Quote>();
        for (Opportunity opp : opps) {
            quotes.add(new Quote(
                Name          = 'Bulk Quote ' + opp.Name,
                OpportunityId = opp.Id,
                Pricebook2Id  = pricebookId,
                Status        = 'Draft'
            ));
        }
        insert quotes;

        // create line items
        List<QuoteLineItem> lineItems = new List<QuoteLineItem>();
        for (Quote q : quotes) {
            lineItems.add(new QuoteLineItem(
                QuoteId          = q.Id,
                Product2Id       = prod.Id,
                PricebookEntryId = pbe.Id,
                Quantity         = 1,
                UnitPrice        = 1000
            ));
        }
        insert lineItems;

        // now approve all quotes
        for (Quote q : quotes) {
            q.Status = 'Approved';
        }

        Test.startTest();
            update quotes;
        Test.stopTest();

        // verify all line items locked
        List<QuoteLineItem> lockedItems = [
            SELECT Is_Locked__c 
            FROM QuoteLineItem 
            WHERE QuoteId IN :quotes
            AND Is_Locked__c = true
        ];
        System.assertEquals(50, lockedItems.size(), 
            'All 50 quote line items should be locked');

        // verify all opportunities stamped
        List<Opportunity> approvedOpps = [
            SELECT Has_Approved_Quote__c 
            FROM Opportunity 
            WHERE Id IN :opps
            AND Has_Approved_Quote__c = true
        ];
        System.assertEquals(50, approvedOpps.size(), 
            'All 50 opportunities should be stamped');
    }
}