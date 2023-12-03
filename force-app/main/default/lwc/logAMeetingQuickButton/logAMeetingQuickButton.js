import { LightningElement, wire, api, track } from "lwc";
import findUsers from "@salesforce/apex/MeetingController.findUsersByName";
import getContacts from "@salesforce/apex/MeetingController.getRelatedContacts";
import createInternalAttendees from "@salesforce/apex/MeetingController.createInternalAttendees";
import createExternalAttendees from "@salesforce/apex/MeetingController.createExternalAttendees";
import sendMeetingEmail from "@salesforce/apex/MeetingController.sendMeetingEmail";

export default class LogAMeetingQuickButton extends LightningElement {
  @api recordId;
  userName = "";
  searchResults = [];
  @track attendeeList = [];
  contactList = [];
  showContactList;
  @track attendeeExternalList = [];
  spinner;
  form = true;
  error;
  output;
  meetingId;
  emailString = "";
  emailsection = true;
  emailsuccess;
  emailfailure;

  get showSearchResults() {
    return this.searchResults.length > 0;
  }

  get showAttendeeList() {
    return this.attendeeList.length > 0;
  }

  get showAttendeeExternalList() {
    return this.attendeeExternalList.length > 0;
  }

  @wire(getContacts, { accountId: "$recordId" })
  wiredContacts({ error, data }) {
    if (data) {
      data.forEach((contact) => {
        this.contactList.push({ label: contact.Name, value: contact.Id });
      });
      this.showContactList = true;
    } else if (error) {
      this.error = error;
    }
  }

  @wire(findUsers, { name: "$userName" })
  wiredUsers({ error, data }) {
    if (data) {
      this.searchResults = data;
    } else if (error) {
      this.error = error;
    }
  }

  handleKeyChange(event) {
    this.userName = event.target.value;
  }

  handleUserSelection(event) {
    var doUpdate = true;
    var selected = this.searchResults[event.target.dataset.index];

    this.attendeeList.forEach((user) => {
      if (user.Id === selected.Id) {
        doUpdate = false;
      }
    });

    if (doUpdate) {
      this.attendeeList.push(selected);
      this.validateUserInput();
    }

    this.searchResults = [];
  }

  handleRemoveUser(event) {
    this.attendeeList.splice(event.target.dataset.index, 1);
  }

  handleContactSelection(event) {
    var doUpdate = true;
    var contactId = event.detail.value;

    this.attendeeExternalList.forEach((contact) => {
      if (contact.Id === contactId) {
        doUpdate = false;
      }
    });

    if (doUpdate) {
      this.attendeeExternalList.push({
        Name: this.contactList.find((contact) => contact.value === contactId)
          .label,
        Id: contactId
      });
    }

    this.template.querySelector("lightning-combobox").value = null;
  }

  handleRemoveContact(event) {
    this.attendeeExternalList.splice(event.target.dataset.index, 1);
  }

  validateUserInput() {
    const searchBar = this.template.querySelector("lightning-input");

    if (!this.showAttendeeList) {
      searchBar.setCustomValidity("Please select at least one attendee");
    } else {
      searchBar.setCustomValidity("");
    }
    searchBar.reportValidity();
  }

  handleSubmit(event) {
    this.validateUserInput();

    if (!this.showAttendeeList) {
      event.preventDefault();
    }
  }

  handleSuccess(event) {
    this.spinner = true;
    this.meetingId = event.detail.id;

    if (this.showAttendeeList) {
      createInternalAttendees({
        meetingId: this.meetingId,
        userList: this.attendeeList
      })
        .then(() => {
          this.spinner = false;
          this.form = false;
          this.output = true;
        })
        .catch((error) => {
          this.spinner = false;
          this.error = error;
        });
    }

    if (this.showAttendeeExternalList) {
      createExternalAttendees({
        meetingId: this.meetingId,
        contactList: this.attendeeExternalList
      })
        .then(() => {
          this.spinner = false;
          this.form = false;
          this.output = true;
        })
        .catch((error) => {
          this.spinner = false;
          this.error = error;
        });
    }
  }

  handleEmailChange(event) {
    this.emailString = event.target.value;
  }

  sendEmail() {
    var emailList = [];
    var emailInput = this.template.querySelector("lightning-input");
    emailInput.reportValidity();

    if (this.emailString && emailInput.checkValidity()) {
      emailList = this.emailString.split(", ");
    }

    if (emailList.length > 0) {
      this.spinner = true;
      sendMeetingEmail({ meetingId: this.meetingId, emailList: emailList })
        .then(() => {
          this.spinner = false;
          this.emailsection = false;
          this.emailsuccess = true;
        })
        .catch((error) => {
          this.spinner = false;
          this.emailsection = false;
          this.emailfailure = true;
          this.error = error;
        });
    }
  }
}
