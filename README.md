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
List<Contact> Addressbook.getContacts("example") // querying contacts with given querystring which can be the fullname, organizationname or email address
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