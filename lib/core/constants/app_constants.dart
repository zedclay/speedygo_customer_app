class AppConstants {
  AppConstants._();

  static const String appName = 'SpeedyGo';
  static const String appVersion = '1.0.0';

  /// Full API prefix including `/api/v1` exactly once.
  ///
  /// Examples (dart-define):
  /// - Android emulator: `http://10.0.2.2:3000/api/v1`
  /// - iOS simulator: `http://127.0.0.1:3000/api/v1`
  /// - Physical-device LAN HTTP is not supported by the current
  ///   localhost-only ATS / cleartext allowlist. See README.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000/api/v1',
  );

  static const int otpLength = 6;
  static const int otpResendCooldownSeconds = 60;
  static const int refreshMaxAttempts = 1;
}

/// Resolves the server origin used by unprefixed `GET /health`.
class ApiEndpoints {
  ApiEndpoints._();

  static const String healthPath = '/health';
  static const String otpRequestPath = '/auth/otp/request';
  static const String otpVerifyPath = '/auth/otp/verify';
  static const String refreshPath = '/auth/refresh';
  static const String logoutPath = '/auth/logout';
  static const String authMePath = '/auth/me';
  static const String customerMePath = '/customer/me';
  static const String customerProfilePath = '/customer/profile';
}
