import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/network/api_config.dart';
import 'package:speedygo_customer_app/core/network/api_error_parser.dart';
import 'package:speedygo_customer_app/core/utils/phone_input.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';

void main() {
  group('PhoneInput', () {
    test('formats and builds a national identifier', () {
      expect(PhoneInput.formatLocal('0550123456'), '550 12 34 56');
      expect(PhoneInput.isValid('555 12 34 56'), isTrue);
      expect(PhoneInput.toIdentifier('555 12 34 56'), '0555123456');
      expect(PhoneInput.maskInternational('0555123456'), '+213 555 ** ** 56');
    });

    test('rejects short numbers', () {
      expect(PhoneInput.isValid('555'), isFalse);
    });
  });

  group('contracts', () {
    test('parses token pair and customer me flags', () {
      final tokens = TokenPair.fromJson({
        'accessToken': 'a',
        'refreshToken': 'r-token-value-long',
        'expiresIn': 900,
        'tokenType': 'Bearer',
      });
      expect(tokens.accessToken, 'a');
      expect(tokens.tokenType, 'Bearer');

      final me = CustomerMe.fromJson({
        'customerProfileExists': false,
        'profileComplete': false,
        'addressReady': false,
        'profile': null,
        'addresses': <Object>[],
        'defaultAddressId': null,
      });
      expect(me.profileComplete, isFalse);
      expect(me.addressReady, isFalse);
    });

    test('otp bodies use backend field names', () {
      expect(const OtpRequestBody(identifier: '0550123456').toJson(), {
        'channel': 'PHONE',
        'identifier': '0550123456',
        'purpose': 'AUTHENTICATE',
      });
      expect(
        const OtpVerifyBody(
          identifier: '0550123456',
          code: '123456',
          platform: 'ios',
          appVersion: '1.0.0',
        ).toJson(),
        {
          'channel': 'PHONE',
          'identifier': '0550123456',
          'purpose': 'AUTHENTICATE',
          'code': '123456',
          'platform': 'ios',
          'appVersion': '1.0.0',
        },
      );
    });

    test('maps error envelope codes', () {
      final error = parseApiException(401, {
        'error': {'code': 'AUTH_INVALID_OTP', 'message': 'Verification failed'},
      });
      expect(error.code, 'AUTH_INVALID_OTP');
      expect(error.message, contains('incorrect'));
    });

    test('health origin strips /api/v1 once', () {
      const config = ApiConfig(apiBaseUrl: 'http://127.0.0.1:3000/api/v1');
      expect(config.healthUri.toString(), 'http://127.0.0.1:3000/health');
    });
  });
}
