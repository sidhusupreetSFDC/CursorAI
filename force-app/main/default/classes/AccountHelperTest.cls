@isTest
public class AccountHelperTest {
    @isTest
    static void testUpdateRating() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;
        
        Test.startTest();
        AccountHelper.updateAccountRating(acc.Id, 'Hot');
        Test.stopTest();
        
        Account result = [SELECT Rating FROM Account WHERE Id = :acc.Id];
        System.assertEquals('Hot', result.Rating);
    }
}