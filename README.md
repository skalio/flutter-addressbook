# flutter-addressbook-mobile
A Flutter plugin to access the mobile device's address book.

## Features
* Automatically ask user for permission
* Get all contacts or querying for certain contacts
* [WIP] Android

## Requirements
* iOS 9.0+
* MacOS 10.11+

## Installation
Add following lines to your `pubspec.yaml
```
dependencies:
  flutter-addressbook-mobile:
```

## API
```dart
import 'package:addressbook/addressbook.dart';

List<Contact> Addressbook.getContacts() // get all contacts
List<Contact> Addressbook.getContacts(query: "example", onlywithEmail: true, profileImage: true) // querying contacts with given querystring which can be the fullname, organizationname or email address. If you want to return only contacts with a email address, set onlyWithEmail to true. If you want to return the contacts profil image, set to true. All arguments are optional
 

String contact.givenName
String contact.familyName
String contact.organization
Map<String, String> emailAddresses // key of the map is an associated label of the address such as "private" or "job"
Map<String, String> phoneNumbers // key of the map is an associated label of the number such as "private" or "home"
String profileImage // base64 encoded image
```

## Permissions
#### iOS
On iOS you'll need to add the NSContactsUsageDescription to your Info.plist file in order to access the device's address book. Simply open your Info.plist file and add the following:
```
<key>NSContactsUsageDescription</key>
<string>This app needs access to address book</string>
```

#### Android
Coming soon..