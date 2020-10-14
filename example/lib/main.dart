import 'package:flutter/material.dart';
import 'dart:async';

import 'package:addressbook/addressbook.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Future _contactsFuture;

  @override
  void initState() {
    super.initState();
    _contactsFuture = loadContacts();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> loadContacts() async {
    List<Contact> contacts = await Addressbook.getContacts(onlyWithEmail: true);
    if (contacts != null) {
      for (var value in contacts) {
        print((value.givenName != null ? value.givenName : "") +
            " " +
            (value.familyName != null ? value.familyName : "") +
            " " +
            (value.organization != null ? value.organization : ""));
        if (value.emailAddresses != null) {
          value.emailAddresses.forEach(
            (key, email) {
              print(key + ": " + email);
            },
          );
        }
        if (value.phoneNumbers != null) {
          value.phoneNumbers.forEach(
            (key, phone) {
              print(key + ": " + phone);
            },
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text("Addressbook plugin example"),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Demonstrating addressbook library, check log."),
              IconButton(
                icon: FutureBuilder(
                  future: _contactsFuture,
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.none:
                      case ConnectionState.waiting:
                      case ConnectionState.active:
                        return CircularProgressIndicator();
                      case ConnectionState.done:
                        return Icon(Icons.cached);
                    }
                  },
                ),
                onPressed: () => setState(
                  () {
                    _contactsFuture = loadContacts();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
