@isTest
private class AccountTestClass {
    @isTest
    static void testAccountCreation() {
        // Arrange
        Account acc = new Account(
            Name = 'Test Account'
        );
        // Act
        insert acc;
        // Assert
        Account result = [
            SELECT Id, Name
            FROM Account
            WHERE Id = :acc.Id
        ];
        System.assertEquals(
            'Test Account',
            result.Name
        );
    }
}