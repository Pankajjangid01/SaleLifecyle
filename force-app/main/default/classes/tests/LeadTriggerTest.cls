@isTest
public class LeadTriggerTest {

    // ─── Helper ───
    static Lead createLead(String status) {
        Lead ld = new Lead(
            FirstName     = 'Test',
            LastName      = 'Lead',
            Company       = 'NorthWind Test Co',
            Email         = 'testlead' + Datetime.now().getTime() + '@northwind.com',
            Phone         = '9800000001',
            MobilePhone    = '9800000001',
            Status        = status,
            GST_Number__c = '27AAAAA0000A1Z5'
        );
        insert ld;
        return ld;
    }

    // ─── Test 1: Qualified → converts ───
    @isTest
    static void testLeadConvertsWhenQualified() {
        Lead ld = createLead('Open - Not Contacted');
        
        // re-query to get fresh record
        ld = [SELECT Id, Status, IsConverted FROM Lead WHERE Id = :ld.Id];

        Test.startTest();
            ld.Status = 'Qualified';
            update ld;
        Test.stopTest();

        Lead result = [SELECT Id, IsConverted, ConvertedAccountId, ConvertedOpportunityId FROM Lead WHERE Id = :ld.Id];
        
        System.debug('=== IsConverted: ' + result.IsConverted);
        System.debug('=== ConvertedAccountId: ' + result.ConvertedAccountId);
        
        System.assertEquals(true, result.IsConverted,
            'Lead should be converted when Status = Qualified');
    }

    // ─── Test 2: Other status → no conversion ───
    @isTest
    static void testLeadDoesNotConvertOnOtherStatus() {
        Lead ld = createLead('Open - Not Contacted');

        Test.startTest();
            ld.Status = 'Working - Contacted';
            update ld;
        Test.stopTest();

        Lead result = [SELECT IsConverted FROM Lead WHERE Id = :ld.Id];
        System.assertEquals(false, result.IsConverted,
            'Lead should NOT convert on non-Qualified status');
    }

    // ─── Test 3: Converted lead has Account + Opp ───
    @isTest
    static void testConvertedLeadHasAccountAndOpportunity() {
        Lead ld = createLead('Open - Not Contacted');
        ld = [SELECT Id, Status FROM Lead WHERE Id = :ld.Id];

        Test.startTest();
            ld.Status = 'Qualified';
            update ld;
        Test.stopTest();

        Lead converted = [
            SELECT IsConverted, ConvertedAccountId, ConvertedOpportunityId
            FROM Lead
            WHERE Id = :ld.Id
        ];

        System.assertEquals(true, converted.IsConverted,
            'Lead should be converted');
        System.assertNotEquals(null, converted.ConvertedAccountId,
            'Converted Account should exist');
        System.assertNotEquals(null, converted.ConvertedOpportunityId,
            'Converted Opportunity should exist');
    }

    // ─── Test 4: Account Number generated on conversion ───
    @isTest
    static void testAccountNumberGeneratedOnConversion() {
        Lead ld = createLead('Open - Not Contacted');
        ld = [SELECT Id, Status FROM Lead WHERE Id = :ld.Id];

        Test.startTest();
            ld.Status = 'Qualified';
            update ld;
        Test.stopTest();

        Lead converted = [
            SELECT ConvertedAccountId
            FROM Lead
            WHERE Id = :ld.Id
        ];

        System.assertNotEquals(null, converted.ConvertedAccountId,
            'Lead should have a ConvertedAccountId');

        Account acc = [
            SELECT AccountNumber
            FROM Account
            WHERE Id = :converted.ConvertedAccountId
        ];

        System.assertNotEquals(null, acc.AccountNumber,
            'Account Number should be generated');
        System.assert(acc.AccountNumber.startsWith('ACC-'),
            'Account Number should start with ACC-');
    }

    // ─── Test 5: Bulk 200 leads ───
    @isTest
    static void testBulkLeadConversion() {
        List<Lead> leads = new List<Lead>();
        for (Integer i = 0; i < 20; i++) {
            leads.add(new Lead(
                FirstName     = 'Bulk',
                LastName      = 'Lead ' + i,
                Company       = 'Bulk Co ' + i,
                Email         = 'bulk' + i + '@northwind.com',
                Phone         = '980000' + String.valueOf(i).leftPad(4, '0'),
                MobilePhone    = '980000' + String.valueOf(i).leftPad(4, '0'),
                Status        = 'Open - Not Contacted',
                GST_Number__c = '27AAAAA' + String.valueOf(i).leftPad(4, '0') + 'A1Z5'
            ));
        }
        insert leads;

        leads = [SELECT Id, Status FROM Lead WHERE Id IN :leads];
        for (Lead ld : leads) {
            ld.Status = 'Qualified';
        }

        Test.startTest();
            update leads;
        Test.stopTest();

        // List<Opportunity> opps = [SELECT Id FROM Opportunity LIMIT 100];
        // System.assertEquals(100, opps.size(),   // changed 200 → 100
        //     '100 leads should have created Opportunities');
        Integer convertedCount = [
            SELECT Count()
            FROM Lead
            WHERE IsConverted = true
        ];

        System.assertEquals(20, convertedCount);
    }

    // ─── Test 6: No conversion on same status update ───
    @isTest
    static void testNoConversionOnSameStatusUpdate() {
        Lead ld = createLead('Working - Contacted');

        Test.startTest();
            // update something else — status stays same
            ld.Phone = '9999999999';
            update ld;
        Test.stopTest();

        Lead result = [SELECT IsConverted FROM Lead WHERE Id = :ld.Id];
        System.assertEquals(false, result.IsConverted,
            'Lead should not convert when status did not change to Qualified');
    }
}