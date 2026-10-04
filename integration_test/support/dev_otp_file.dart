import 'dart:io';

/// Host-side development OTP capture. Unavailable in production backends.
File speedyGoDevOtpFile() {
  const defined = String.fromEnvironment('SPEEDYGO_DEV_OTP_FILE');
  if (defined.isNotEmpty) {
    return File(defined);
  }
  final fromEnv = Platform.environment['SPEEDYGO_DEV_OTP_FILE'];
  if (fromEnv != null && fromEnv.isNotEmpty) {
    return File(fromEnv);
  }
  final home = Platform.environment['HOME'];
  if (home != null && home.isNotEmpty) {
    return File('$home/.speedygo/dev/otp-last');
  }
  throw StateError(
    'Set SPEEDYGO_DEV_OTP_FILE (dart-define or env) for live OTP capture.',
  );
}
