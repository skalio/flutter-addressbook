import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:addressbook/addressbook.dart';

void main() {
  const MethodChannel channel = MethodChannel('addressbook');

  TestWidgetsFlutterBinding.ensureInitialized();
  /*
  setUp(() {
    channel.setMockMethodCallHandler((MethodCall methodCall) async {
      return '42';
    });
  });

  tearDown(() {
    channel.setMockMethodCallHandler(null);
  });

  test('getPlatformVersion', () async {
    expect(await Addressbook.platformVersion, '42');
  });*/
}
