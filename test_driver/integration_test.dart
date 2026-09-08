import 'dart:io';

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver_extended.dart';

Future<void> main() async {
  final driver = await FlutterDriver.connect();
  const directory = '/tmp/speedygo-customer-auth-visual-review';
  await Directory(directory).create(recursive: true);
  await integrationDriver(
    driver: driver,
    onScreenshot: (name, image, [args]) async {
      await File('$directory/$name.png').writeAsBytes(image);
      return true;
    },
  );
}
