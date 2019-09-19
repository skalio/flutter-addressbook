import 'dart:async';

import 'package:flutter/services.dart';

class Addressbook {
  static const MethodChannel _channel = const MethodChannel('addressbook');

  static Future<List<Contact>> getContacts({String query, bool onlyWithEmail, bool profileImage}) async {
    List<dynamic> contacts = await _channel.invokeMethod('getContacts', {"query": query, "onlyWithEmail": onlyWithEmail, "profileImage": profileImage});
    List<Map<dynamic, dynamic>> castedContacts = contacts.cast();
    List<Contact> mappedContacts = [];

    for (var map in castedContacts) {
      String givenName = map["givenName"];
      String familyName = map["familyName"];
      String organization = map["organization"];

      Map<dynamic, dynamic> emailAddressesMap = map["emailAddresses"];
      Map<String, String> emailAddresses = Map<String, String>();
      if (emailAddressesMap != null) {
        emailAddressesMap.forEach((label, email) {
          emailAddresses[label] = email;
        });
      } else {
        emailAddresses = null;
      }

      Map<dynamic, dynamic> phoneNumbersMap = map["phoneNumbers"];
      Map<String, String> phoneNumbers = Map<String, String>();
      if (phoneNumbersMap != null) {
        phoneNumbersMap.forEach((label, number) {
          phoneNumbers[label] = number;
        });
      } else {
        phoneNumbers = null;
      }

      String profileImage = map["profileImage"];

      mappedContacts.add(Contact(givenName, familyName, organization, emailAddresses, phoneNumbers, profileImage));
    }

    return mappedContacts;
  }
}

class Contact {
  final String givenName;
  final String familyName;
  final String organization;
  final Map<String, String> emailAddresses;
  final Map<String, String> phoneNumbers;
  final String profileImage;

  Contact(this.givenName, this.familyName, this.organization, this.emailAddresses, this.phoneNumbers, this.profileImage);
}