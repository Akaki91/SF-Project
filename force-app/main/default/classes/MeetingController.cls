public with sharing class MeetingController {
  @AuraEnabled(cacheable=true)
  public static List<User> findUsersByName(String name) {
    List<User> userList = new List<User>();

    if (name != '') {
      String query = '%' + name + '%';
      userList = [
        SELECT Id, Name
        FROM User
        WHERE Name LIKE :query AND UserType = 'Standard'
      ];
    }

    return userList;
  }

  @AuraEnabled(cacheable=true)
  public static List<Contact> getRelatedContacts(String accountId) {
    return [SELECT Id, Name FROM Contact WHERE AccountId = :accountId];
  }

  @AuraEnabled
  public static void createInternalAttendees(
    String meetingId,
    List<User> userList
  ) {
    try {
      List<Internal_Attendee__c> attendeeList = new List<Internal_Attendee__c>();

      for (User user : userList) {
        Internal_Attendee__c attendee = new Internal_Attendee__c(
          Name = user.Name,
          User__c = user.Id,
          Meeting__c = meetingId
        );

        attendeeList.add(attendee);
      }

      insert attendeeList;
    } catch (DmlException e) {
      throw new AuraHandledException(
        'Exception occured during Attendee creation: ' + e.getMessage()
      );
    }
  }

  @AuraEnabled
  public static void createExternalAttendees(
    String meetingId,
    List<Contact> contactList
  ) {
    try {
      List<External_Attendee__c> attendeeList = new List<External_Attendee__c>();

      for (Contact contact : contactList) {
        External_Attendee__c attendee = new External_Attendee__c(
          Name = contact.Name,
          Contact__c = contact.Id,
          Meeting__c = meetingId
        );
        attendeeList.add(attendee);
      }

      insert attendeeList;
    } catch (DmlException e) {
      throw new AuraHandledException(
        'Exception occured during External Attendee creation: ' + e.getMessage()
      );
    }
  }

  @AuraEnabled
  public static void sendMeetingEmail(
    String meetingId,
    List<String> emailList
  ) {
    try {
      Meeting__c meeting = new Meeting__c();
      meeting = [
        SELECT Name, Summary__c, Meeting_Date__c, Detailed_Note__c
        FROM Meeting__c
        WHERE Id = :meetingId
        LIMIT 1
      ];

      List<Internal_Attendee__c> internalList = [
        SELECT Name, Email__c
        FROM Internal_Attendee__c
        WHERE Meeting__c = :meetingId
      ];

      List<External_Attendee__c> externalList = [
        SELECT Name, Email__c
        FROM External_Attendee__c
        WHERE Meeting__c = :meetingId
      ];

      OrgWideEmailAddress orgwideEm = new OrgWideEmailAddress();
      orgwideEm = [
        SELECT Id, DisplayName
        FROM OrgWideEmailAddress
        WHERE DisplayName = 'No-Reply'
        LIMIT 1
      ];

      List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
      if (meeting != null && !emailList.isEmpty() && orgwideEm != null) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        email.setToAddresses(emailList);
        email.setOrgWideEmailAddressId(orgwideEm.id);
        email.setSubject('Meeting: ' + meeting.Name);

        String body = 'Here Are meeting details: </br>';
        body += meeting.Summary__c + '</br>';
        body += 'Meeting Date: ' + meeting.Meeting_Date__c + ' </br>';
        body += 'Meeting Details: ' + meeting.Detailed_Note__c + ' </br>';
        if (!internalList.isEmpty()) {
          body += 'Internal Attendees:' + ' </br>';
          for (Internal_Attendee__c att : internalList) {
            body += att.Name + ' ' + att.Email__c + ' </br>';
          }
        }
        if (!externalList.isEmpty()) {
          body += 'Internal Attendees:' + ' </br>';
          for (External_Attendee__c att : externalList) {
            body += att.Name + ' ' + att.Email__c + ' </br>';
          }
        }
        body += 'Best Regards';
        email.setHtmlBody(body);

        emailsToSend.add(email);
      }

      if (!emailList.isEmpty()) {
        Messaging.sendEmail(emailsToSend);
      }
    } catch (Exception e) {
      throw new AuraHandledException(
        'Exception occured while sending email ' + e.getMessage()
      );
    }
  }
}
