public with sharing class AccountTriggerHandler {
    public static void generateAccountNumber(List<Account> accounts) {
        List<Account> lastAccount = [
            SELECT AccountNumber 
            FROM Account 
            WHERE AccountNumber LIKE 'ACC-%'
            ORDER BY AccountNumber DESC
            LIMIT 1
        ];
        
        Integer startNumber = 1;
        
        if (!lastAccount.isEmpty()) {
            String lastNum = lastAccount[0].AccountNumber.replace('ACC-', '');
            startNumber = Integer.valueOf(lastNum) + 1;
        }
        
        for (Account acc : accounts) {
            if (String.isBlank(acc.AccountNumber)) {
                acc.AccountNumber = 'ACC-' + String.valueOf(startNumber).leftPad(4, '0');
                startNumber++;
            }
        }
    
    }
}