@isTest
public class AccountTriggerTest {

    // ─── Test 1: Single account gets ACC-0001 ───
    @isTest
    static void testSingleAccountNumberGenerated() {
        Account acc = new Account(Name = 'NorthWind Test Co');

        Test.startTest();
            insert acc;
        Test.stopTest();

        Account result = [SELECT AccountNumber FROM Account WHERE Id = :acc.Id];
        System.assertNotEquals(null, result.AccountNumber, 
            'Account Number should be generated');
        System.assert(result.AccountNumber.startsWith('ACC-'), 
            'Account Number should start with ACC-');
    }

    // ─── Test 2: Bulk - 200 accounts get unique numbers ───
    @isTest
    static void testBulkAccountNumberGenerated() {
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            accounts.add(new Account(Name = 'Bulk Test Co ' + i));
        }

        Test.startTest();
            insert accounts;
        Test.stopTest();

        List<Account> results = [
            SELECT AccountNumber 
            FROM Account 
            WHERE Id IN :accounts
        ];

        // collect all numbers into a set to check uniqueness
        Set<String> accountNumbers = new Set<String>();
        for (Account acc : results) {
            System.assertNotEquals(null, acc.AccountNumber, 
                'Every account should have a number');
            System.assert(acc.AccountNumber.startsWith('ACC-'), 
                'Every number should start with ACC-');
            accountNumbers.add(acc.AccountNumber);
        }

        System.assertEquals(200, accountNumbers.size(), 
            'All 200 account numbers should be unique');
    }

    // ─── Test 3: Sequential numbering continues correctly ───
    @isTest
    static void testSequentialNumbering() {
        // insert first account
        Account acc1 = new Account(Name = 'First Co');
        insert acc1;

        // insert second account
        Account acc2 = new Account(Name = 'Second Co');
        insert acc2;

        Account result1 = [SELECT AccountNumber FROM Account WHERE Id = :acc1.Id];
        Account result2 = [SELECT AccountNumber FROM Account WHERE Id = :acc2.Id];

        // extract numbers and verify sequential
        Integer num1 = Integer.valueOf(result1.AccountNumber.replace('ACC-', ''));
        Integer num2 = Integer.valueOf(result2.AccountNumber.replace('ACC-', ''));

        System.assertEquals(1, num2 - num1, 
            'Account numbers should be sequential');
    }

    // ─── Test 4: Account with existing number is not overwritten ───
    @isTest
    static void testExistingAccountNumberNotOverwritten() {
        Account acc = new Account(
            Name = 'Pre-numbered Co',
            AccountNumber = 'ACC-9999'
        );

        Test.startTest();
            insert acc;
        Test.stopTest();

        Account result = [SELECT AccountNumber FROM Account WHERE Id = :acc.Id];
        System.assertEquals('ACC-9999', result.AccountNumber, 
            'Pre-existing account number should not be overwritten');
    }
}