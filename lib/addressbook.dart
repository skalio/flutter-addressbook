import 'dart:async';

import 'package:flutter/services.dart';

/// Class on which addressbook operations can be called via static methods.
class Addressbook {
  static const MethodChannel _channel = const MethodChannel('addressbook');

  /// Returns a [Future] that completes with a [List] of all available [Contacts].
  /// The search space can be reduced by passing a [query] string to which the results must match.
  /// Setting [onlyWithEmail] will filter out contacts without a single [Contacts#emailAddresses] entry.
  /// Profile image data can be included with the [profileImage] flag.
  static Future<List<Contact>> getContacts({
    String? query,
    bool? onlyWithEmail,
    bool? profileImage,
  }) async {
    List<dynamic> contacts = await _channel.invokeMethod(
      'getContacts',
      {
        if (query != null) "query": query,
        "onlyWithEmail": onlyWithEmail ?? false,
        "profileImage": profileImage ?? false
      },
    );

    if (contacts == null) {
      return [];
    }

    List<Map<dynamic, dynamic>> castedContacts = contacts.cast();
    List<Contact> mappedContacts = [];

    for (var map in castedContacts) {
      String? givenName = map["givenName"];
      String? familyName = map["familyName"];
      String? organization = map["organization"];

      Map<dynamic, dynamic> emailAddressesMap = map["emailAddresses"];
      Map<String, String>? emailAddresses = Map<String, String>();
      if (emailAddressesMap != null) {
        emailAddressesMap.forEach(
          (label, email) {
            emailAddresses![label] = email;
          },
        );
      } else {
        emailAddresses = null;
      }

      Map<dynamic, dynamic> phoneNumbersMap = map["phoneNumbers"];
      Map<String, String>? phoneNumbers = Map<String, String>();
      if (phoneNumbersMap != null) {
        phoneNumbersMap.forEach(
          (label, number) {
            phoneNumbers![label] = number;
          },
        );
      } else {
        phoneNumbers = null;
      }

      String? profileImage = map["profileImage"];

      mappedContacts.add(
        Contact(givenName, familyName, organization, emailAddresses,
            phoneNumbers, profileImage),
      );
    }

    return mappedContacts;
  }
}

/// Entity representing one contact in an addressbook.
class Contact {
  /// Given name alias forename.
  final String? givenName;

  /// Family name alias surname.
  final String? familyName;

  /// The organization this contact belongs to.
  final String? organization;

  /// A collection of all the emailAddresses attached to this contact.
  /// The key represents the type of the emailAddress (work, home, etc.) and the value is the actually emailAddress.
  final Map<String, String>? emailAddresses;

  /// A collection of all the phoneNumbers attached to this contact.
  /// The key represents the type of the phoneNumber (home, mobile, etc.) and the value is the actually phoneNumber as a [String].
  final Map<String, String>? phoneNumbers;

  /// Base64-encoded profile picture
  final String? profileImage;

  Contact(this.givenName, this.familyName, this.organization,
      this.emailAddresses, this.phoneNumbers, this.profileImage);
}
