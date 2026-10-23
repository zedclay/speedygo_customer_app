import 'package:flutter_test/flutter_test.dart';

void main() {
  // Live HTTP belongs in integration_test with IntegrationTestWidgetsFlutterBinding
  // initialized first. This directory loads test/flutter_test_config.dart, which
  // installs TestWidgetsFlutterBinding and a fake HttpClient (HTTP 400).
  test(
    'customer Dio client: login, /auth/me restore, refresh, logout',
    () {},
    skip:
        'Widget-test HttpClient is mocked; use integration_test/auth_audience_16e_3103_test.dart on iPhone 16e',
  );
}
