import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/constants/app_constants.dart';
import 'package:speedygo_customer_app/core/navigation/app_locale.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/network/api_error_parser.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/core/utils/phone_input.dart';
import 'package:speedygo_customer_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';
import 'package:speedygo_customer_app/features/auth/application/session_state.dart';
import 'package:speedygo_customer_app/features/auth/data/auth_api.dart';
import 'package:speedygo_customer_app/features/auth/data/customer_api.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';

class SessionController extends Notifier<SessionState> {
  late SessionStore _store;
  late LaunchStore _launch;
  late AuthClient _authApi;
  late CustomerClient _customerApi;

  @override
  SessionState build() {
    _store = ref.read(sessionStoreProvider);
    _launch = ref.read(launchStoreProvider);
    _authApi = ref.read(authApiProvider);
    _customerApi = ref.read(customerApiProvider);
    return SessionState.initial;
  }

  Future<void> restore() async {
    final generation = state.generation;
    final onboardingSeen = await _launch.readOnboardingSeen();
    final languageSeen = await _launch.readLanguageSeen();
    final locale = AppLocale.sanitize(await _launch.readLocale());
    final stored = await _store.read();
    if (!_isCurrent(generation)) {
      return;
    }
    if (stored == null) {
      state = SessionState(
        phase: SessionPhase.signedOut,
        generation: generation,
        onboardingSeen: onboardingSeen,
        languageSeen: languageSeen,
        locale: locale,
      );
      return;
    }
    ref.read(tokenCacheProvider).current = stored;
    state = state.copyWith(
      tokens: stored,
      onboardingSeen: true,
      languageSeen: true,
      locale: locale,
      busy: true,
      clearError: true,
    );
    await _hydrateAfterAuth(
      generation: generation,
      tokens: stored,
      fromRestore: true,
    );
  }

  Future<void> retryRestore() => restore();

  Future<void> requestOtp(String rawPhone) async {
    if (!PhoneInput.isValid(rawPhone)) {
      state = state.copyWith(errorMessage: AppStrings.phoneInvalid);
      return;
    }
    if (!state.canRequestOtp) {
      state = state.copyWith(
        errorMessage: AppStrings.errorForCode('AUTH_RATE_LIMITED'),
      );
      return;
    }
    final identifier = PhoneInput.toIdentifier(rawPhone);
    final generation = state.generation;
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _authApi.requestOtp(identifier);
      if (!_isCurrent(generation)) {
        return;
      }
      state = state.copyWith(
        pendingPhone: identifier,
        busy: false,
        clearError: true,
        otpResendAvailableAt: DateTime.now().add(
          const Duration(seconds: AppConstants.otpResendCooldownSeconds),
        ),
      );
    } on AppException catch (error) {
      if (!_isCurrent(generation)) {
        return;
      }
      state = state.copyWith(
        busy: false,
        errorMessage: error.message,
        otpResendAvailableAt: error.code == 'AUTH_RATE_LIMITED'
            ? DateTime.now().add(
                const Duration(seconds: AppConstants.otpResendCooldownSeconds),
              )
            : state.otpResendAvailableAt,
      );
    }
  }

  Future<void> verifyOtp(String code) async {
    final identifier = state.pendingPhone;
    if (identifier == null) {
      state = state.copyWith(errorMessage: AppStrings.unexpected);
      return;
    }
    if (code.length != AppConstants.otpLength) {
      state = state.copyWith(errorMessage: AppStrings.otpIncomplete);
      return;
    }
    final generation = state.generation;
    state = state.copyWith(busy: true, clearError: true);
    try {
      final tokens = await _authApi.verifyOtp(
        OtpVerifyBody(
          identifier: identifier,
          code: code,
          platform: _platform(),
          appVersion: AppConstants.appVersion,
        ),
      );
      if (!_isCurrent(generation)) {
        return;
      }
      await _store.write(tokens);
      if (!_isCurrent(generation)) {
        return;
      }
      ref.read(tokenCacheProvider).current = tokens;
      state = state.copyWith(tokens: tokens);
      await _hydrateAfterAuth(
        generation: generation,
        tokens: tokens,
        fromRestore: false,
      );
    } on AppException catch (error) {
      if (!_isCurrent(generation)) {
        return;
      }
      state = state.copyWith(busy: false, errorMessage: error.message);
    }
  }

  Future<void> resendOtp() async {
    final identifier = state.pendingPhone;
    if (identifier == null) {
      return;
    }
    await requestOtp(identifier);
  }

  Future<void> markLanguageSeen({String locale = AppLocale.french}) async {
    final sanitized = AppLocale.sanitize(locale);
    await _launch.writeLocale(sanitized);
    await _launch.markLanguageSeen();
    state = state.copyWith(languageSeen: true, locale: sanitized);
  }

  Future<void> markWelcomeSeen() async {
    await _launch.markOnboardingSeen();
    state = state.copyWith(welcomeSeen: true, onboardingSeen: true);
  }

  Future<void> submitProfile(String fullName) async {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(errorMessage: AppStrings.fullNameRequired);
      return;
    }
    final generation = state.generation;
    state = state.copyWith(busy: true, clearError: true);
    try {
      await _customerApi.createProfile(fullName: trimmed);
      if (!_isCurrent(generation)) {
        return;
      }
      final me = await _customerApi.me();
      if (!_isCurrent(generation)) {
        return;
      }
      if (!me.profileComplete) {
        state = state.copyWith(
          busy: false,
          customer: me,
          errorMessage: AppStrings.unexpected,
        );
        return;
      }
      state = state.copyWith(
        phase: SessionPhase.ready,
        customer: me,
        busy: false,
        clearError: true,
      );
    } on ApiException catch (error) {
      if (!_isCurrent(generation)) {
        return;
      }
      if (error.code == 'CUSTOMER_PROFILE_ALREADY_EXISTS') {
        await _hydrateAfterAuth(
          generation: generation,
          tokens: state.tokens,
          fromRestore: false,
        );
        return;
      }
      state = state.copyWith(busy: false, errorMessage: error.message);
    } on AppException catch (error) {
      if (!_isCurrent(generation)) {
        return;
      }
      state = state.copyWith(busy: false, errorMessage: error.message);
    }
  }

  Future<void> logout() async {
    final previous = state.tokens;
    final generation = state.generation + 1;
    ref.read(sessionEpochProvider).value = generation;
    ref.read(tokenCacheProvider).current = null;
    await _store.clear();
    var serverConfirmed = false;
    if (previous != null) {
      try {
        await _authApi.logoutWithAccessToken(previous.accessToken);
        serverConfirmed = true;
      } catch (_) {
        serverConfirmed = false;
      }
    }
    if (state.generation >= generation) {
      return;
    }
    state = SessionState(
      phase: SessionPhase.signedOut,
      generation: generation,
      onboardingSeen: true,
      languageSeen: true,
      locale: state.locale,
      logoutServerConfirmed: previous != null ? serverConfirmed : true,
      errorMessage: previous != null && !serverConfirmed
          ? AppStrings.logoutLocalOnly
          : null,
    );
  }

  Future<void> switchAccount() async {
    final generation = state.generation + 1;
    ref.read(sessionEpochProvider).value = generation;
    ref.read(tokenCacheProvider).current = null;
    await _store.clear();
    state = SessionState(
      phase: SessionPhase.signedOut,
      generation: generation,
      onboardingSeen: true,
      languageSeen: true,
      locale: state.locale,
    );
  }

  Future<void> invalidateLocalSession() async {
    final generation = state.generation + 1;
    ref.read(sessionEpochProvider).value = generation;
    ref.read(tokenCacheProvider).current = null;
    await _store.clear();
    state = SessionState(
      phase: SessionPhase.signedOut,
      generation: generation,
      onboardingSeen: true,
      languageSeen: true,
      locale: state.locale,
      errorMessage: AppStrings.reauthRequired,
    );
  }

  Future<void> _hydrateAfterAuth({
    required int generation,
    required TokenPair? tokens,
    required bool fromRestore,
  }) async {
    try {
      final authMe = await _authApi.me();
      if (!_isCurrent(generation)) {
        return;
      }
      final customer = await _customerApi.me();
      if (!_isCurrent(generation)) {
        return;
      }
      ref.read(tokenCacheProvider).current = tokens;
      state = state.copyWith(
        tokens: tokens,
        customer: customer,
        signedInPhone: authMe.phone,
        busy: false,
        clearError: true,
        welcomeSeen: fromRestore,
        languageSeen: true,
        onboardingSeen: true,
        phase: customer.profileComplete
            ? SessionPhase.ready
            : SessionPhase.needsProfile,
      );
    } on RefreshAmbiguousException {
      if (!_isCurrent(generation)) {
        return;
      }
      await invalidateLocalSession();
    } on ApiException catch (error) {
      if (!_isCurrent(generation)) {
        return;
      }
      if (error.isAuthFailure || error.isAccountBlocked) {
        await invalidateLocalSession();
        return;
      }
      if (fromRestore && isRetryableNetwork(error)) {
        state = state.copyWith(
          phase: SessionPhase.restoreRetryable,
          tokens: tokens,
          busy: false,
          errorMessage: AppStrings.restoreOffline,
        );
        return;
      }
      if (fromRestore && error is! NetworkException) {
        // Confirmed business failure during restore — do not wipe on unknown 5xx.
        if ((error.statusCode ?? 0) >= 500) {
          state = state.copyWith(
            phase: SessionPhase.restoreRetryable,
            tokens: tokens,
            busy: false,
            errorMessage: AppStrings.offline,
          );
          return;
        }
      }
      state = state.copyWith(
        phase: fromRestore
            ? SessionPhase.restoreRetryable
            : SessionPhase.signedOut,
        tokens: fromRestore ? tokens : null,
        busy: false,
        errorMessage: error.message,
      );
    } on NetworkException catch (error) {
      if (!_isCurrent(generation)) {
        return;
      }
      if (fromRestore) {
        state = state.copyWith(
          phase: SessionPhase.restoreRetryable,
          tokens: tokens,
          busy: false,
          errorMessage: AppStrings.restoreOffline,
        );
        return;
      }
      state = state.copyWith(busy: false, errorMessage: error.message);
    }
  }

  bool _isCurrent(int generation) => state.generation == generation;

  String _platform() {
    if (kIsWeb) {
      return 'web';
    }
    if (Platform.isIOS) {
      return 'ios';
    }
    return 'android';
  }
}

final sessionControllerProvider =
    NotifierProvider<SessionController, SessionState>(SessionController.new);

final authApiProvider = Provider<AuthClient>((ref) {
  return ref.watch(authInfrastructureProvider).authApi;
});

final customerApiProvider = Provider<CustomerClient>((ref) {
  return ref.watch(authInfrastructureProvider).customerApi;
});
