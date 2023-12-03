@isTest
private class MeetingControllerTest {
  @testSetup
  static void setup() {
    Account acc = new Account(Name = 'TestAcct Company');
    insert acc;

    Contact cont = new Contact(
      FirstName = 'Bob',
      LastName = 'Doe',
      AccountId = acc.Id
    );
    insert cont;

    Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
    User user = new User(
      FirstName = 'Jonq00',
      LastName = 'Testman',
      Alias = 'standt',
      Email = 'standarduser@testorg.com',
      EmailEncodingKey = 'UTF-8',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = 'jontestman@testorg.com'
    );
    insert user;

    Meeting__c meeting = new Meeting__c(
      Account__c = acc.Id,
      Summary__c = 'Test Meeting',
      Detailed_Note__c = '<p>Test details</p>',
      Meeting_Date__c = System.Today()
    );
    insert meeting;
  }

  @isTest
  static void findUsersByNameTest() {
    Test.startTest();
    List<User> users = MeetingController.findUsersByName('jonq');
    Test.stopTest();

    System.assertEquals(1, users.size());
  }

  @isTest
  static void getRelatedContactsTest() {
    List<Account> accList = [
      SELECT Id
      FROM Account
      WHERE Name = 'TestAcct Company'
      LIMIT 1
    ];
    Test.startTest();
    List<Contact> contacts = MeetingController.getRelatedContacts(
      accList[0].Id
    );
    Test.stopTest();

    System.assertEquals(1, contacts.size());
  }

  @isTest
  static void createInternalAttendeesTest() {
    List<Meeting__c> meetings = [
      SELECT Id
      FROM Meeting__c
    ];

    List<User> users = [
      SELECT Id, Name
      FROM User
      WHERE FirstName = 'Jonq00'
    ];

    Test.startTest();
    MeetingController.createInternalAttendees(meetings[0].Id, users);
    Test.stopTest();

    List<Internal_Attendee__c> intenalList = [
      SELECT Id
      FROM Internal_Attendee__c
    ];

    System.assertEquals(1, intenalList.size());
  }

  @isTest
  static void createExternalAttendeesTest() {
    List<Meeting__c> meetings = [
      SELECT Id
      FROM Meeting__c
    ];

    List<Contact> contacts = [
      SELECT Id, Name
      FROM Contact
      WHERE FirstName = 'Bob'
    ];

    Test.startTest();
    MeetingController.createExternalAttendees(meetings[0].Id, contacts);
    Test.stopTest();

    List<External_Attendee__c> externalList = [
      SELECT Id
      FROM External_Attendee__c
    ];

    System.assertEquals(1, externalList.size());
  }

  @isTest
  static void sendMeetingEmailTest() {
    List<Meeting__c> meetings = [
      SELECT Id
      FROM Meeting__c
    ];

    List<User> users = [
      SELECT Id, Name
      FROM User
      WHERE FirstName = 'Jonq00'
    ];

    List<Contact> contacts = [
      SELECT Id, Name
      FROM Contact
      WHERE FirstName = 'Bob'
    ];

    Test.startTest();
    MeetingController.createInternalAttendees(meetings[0].Id, users);
    MeetingController.createExternalAttendees(meetings[0].Id, contacts);
    MeetingController.sendMeetingEmail(
      meetings[0].Id,
      new List<String>{ 'test@test.com' }
    );
    Integer invocations = Limits.getEmailInvocations();
    Test.stopTest();

    System.assertEquals(1, invocations, 'An email should be sent');
  }
}
