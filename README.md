# flutter-addressbook
A Flutter plugin to access the device's address book.

## Features
* Automatically ask user for permission
* Get all contacts or querying for certain contacts

## Requirements
* iOS 9.0+
* MacOS 10.11+
* Android 4.0+

## Installation
Add following lines to your `pubspec.yaml
```
dependencies:
  flutter-addressbook:
```

## API
```dart
import 'package:addressbook/addressbook.dart';

List<Contact> Addressbook.getContacts() // get all contacts
List<Contact> Addressbook.getContacts(query: "example", onlywithEmail: true, profileImage: true) // querying contacts with given querystring which can be the fullname, organizationname or email address. If you want to return only contacts with a email address, set onlyWithEmail to true (default is false). If you want to return the contacts profil image, set to true (default is true). All arguments are optional
 

String contact.givenName
String contact.familyName
String contact.organization
Map<String, String> contact.emailAddresses // key of the map is an associated label of the address such as "private" or "job"
Map<String, String> contact.phoneNumbers // key of the map is an associated label of the number such as "private" or "home"
String contact.profileImage // base64 encoded image
```

## Permissions
#### iOS/MacOS
On iOS or MacOS you'll need to add the NSContactsUsageDescription to your Info.plist file in order to access the device's address book. Simply open your Info.plist file and add the following:
```
<key>NSContactsUsageDescription</key>
<string>This app needs access to address book</string>
```
