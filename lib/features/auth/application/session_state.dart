import 'package:speedygo_customer_app/features/auth/data/models.dart';

enum SessionPhase {
  bootstrapping,
  signedOut,
  restoring,
  restoreRetryable,
  needsProfile,
  ready,
}

class SessionState {
  const SessionState({
    required this.phase,
    this.tokens,
    this.customer,
    this.pendingPhone,
    this.signedInPhone,
    this.welcomeSeen = false,
    this.onboardingSeen = false,
    this.languageSeen = false,
    this.locale = 'fr',
    this.errorMessage,
    this.logoutServerConfirmed,
    this.busy = false,
    this.generation = 0,
    this.otpResendAvailableAt,
  });

  final SessionPhase phase;
  final TokenPair? tokens;
  final CustomerMe? customer;
  final String? pendingPhone;
  final String? signedInPhone;
  final bool welcomeSeen;
  final bool onboardingSeen;
  final bool languageSeen;
  final String locale;
  final String? errorMessage;
  final bool? logoutServerConfirmed;
  final bool busy;
  final int generation;
  final DateTime? otpResendAvailableAt;

  bool get isAuthenticated =>
      phase == SessionPhase.needsProfile || phase == SessionPhase.ready;

  int get otpResendSecondsRemaining {
    final until = otpResendAvailableAt;
    if (until == null) {
      return 0;
    }
    final left = until.difference(DateTime.now()).inSeconds;
    return left < 0 ? 0 : left;
  }

  bool get canRequestOtp => otpResendSecondsRemaining == 0;

  SessionState copyWith({
    SessionPhase? phase,
    TokenPair? tokens,
    CustomerMe? customer,
    String? pendingPhone,
    String? signedInPhone,
    bool? welcomeSeen,
    bool? onboardingSeen,
    bool? languageSeen,
    String? locale,
    String? errorMessage,
    bool? logoutServerConfirmed,
    bool? busy,
    int? generation,
    DateTime? otpResendAvailableAt,
    bool clearTokens = false,
    bool clearCustomer = false,
    bool clearPendingPhone = false,
    bool clearSignedInPhone = false,
    bool clearError = false,
    bool clearLogoutFlag = false,
    bool clearOtpCooldown = false,
  }) {
    return SessionState(
      phase: phase ?? this.phase,
      tokens: clearTokens ? null : (tokens ?? this.tokens),
      customer: clearCustomer ? null : (customer ?? this.customer),
      pendingPhone: clearPendingPhone
          ? null
          : (pendingPhone ?? this.pendingPhone),
      signedInPhone: clearSignedInPhone
          ? null
          : (signedInPhone ?? this.signedInPhone),
      welcomeSeen: welcomeSeen ?? this.welcomeSeen,
      onboardingSeen: onboardingSeen ?? this.onboardingSeen,
      languageSeen: languageSeen ?? this.languageSeen,
      locale: locale ?? this.locale,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      logoutServerConfirmed: clearLogoutFlag
          ? null
          : (logoutServerConfirmed ?? this.logoutServerConfirmed),
      busy: busy ?? this.busy,
      generation: generation ?? this.generation,
      otpResendAvailableAt: clearOtpCooldown
          ? null
          : (otpResendAvailableAt ?? this.otpResendAvailableAt),
    );
  }

  static const initial = SessionState(phase: SessionPhase.bootstrapping);
}
