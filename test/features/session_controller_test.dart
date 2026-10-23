import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_locale.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';
import 'package:speedygo_customer_app/features/auth/application/session_state.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';

import '../helpers/fakes.dart';

ProviderContainer containerOf({
  required FakeAuthClient auth,
  required FakeCustomerClient customer,
  MemorySessionStore? store,
}) {
  final memory = store ?? MemorySessionStore();
  return ProviderContainer(
    overrides: [
      sessionStoreProvider.overrideWithValue(memory),
      launchStoreProvider.overrideWithValue(
        MemoryLaunchStore(onboardingSeen: true),
      ),
      authApiProvider.overrideWithValue(auth),
      customerApiProvider.overrideWithValue(customer),
    ],
  );
}

void main() {
  test('first launch without credentials keeps onboarding unseen', () async {
    final container = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        launchStoreProvider.overrideWithValue(
          MemoryLaunchStore(onboardingSeen: false),
        ),
        authApiProvider.overrideWithValue(FakeAuthClient()),
        customerApiProvider.overrideWithValue(FakeCustomerClient()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.notifier).restore();
    final state = container.read(sessionControllerProvider);
    expect(state.phase, SessionPhase.signedOut);
    expect(state.onboardingSeen, isFalse);
    expect(state.languageSeen, isFalse);
    expect(state.locale, AppLocale.french);
  });

  test('markLanguageSeen persists Arabic', () async {
    final launch = MemoryLaunchStore(onboardingSeen: false, locale: 'fr');
    final container = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        launchStoreProvider.overrideWithValue(launch),
        authApiProvider.overrideWithValue(FakeAuthClient()),
        customerApiProvider.overrideWithValue(FakeCustomerClient()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.notifier).restore();
    await container
        .read(sessionControllerProvider.notifier)
        .markLanguageSeen(locale: AppLocale.arabic);
    expect(container.read(sessionControllerProvider).locale, AppLocale.arabic);
    expect(launch.locale, AppLocale.arabic);
  });

  test('stored Arabic locale is restored after restart', () async {
    final launch = MemoryLaunchStore(onboardingSeen: true, locale: 'ar');
    final container = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        launchStoreProvider.overrideWithValue(launch),
        authApiProvider.overrideWithValue(FakeAuthClient()),
        customerApiProvider.overrideWithValue(FakeCustomerClient()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.notifier).restore();
    expect(container.read(sessionControllerProvider).locale, AppLocale.arabic);
    expect(launch.locale, AppLocale.arabic);
  });

  test('stored unsupported locale falls back to French', () async {
    final launch = MemoryLaunchStore(onboardingSeen: true, locale: 'en');
    final container = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        launchStoreProvider.overrideWithValue(launch),
        authApiProvider.overrideWithValue(FakeAuthClient()),
        customerApiProvider.overrideWithValue(FakeCustomerClient()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.notifier).restore();
    expect(container.read(sessionControllerProvider).locale, AppLocale.french);
    expect(launch.locale, AppLocale.french);
  });

  test('startup with no credentials signs the user out', () async {
    final container = containerOf(
      auth: FakeAuthClient(),
      customer: FakeCustomerClient(),
    );
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.notifier).restore();
    expect(
      container.read(sessionControllerProvider).phase,
      SessionPhase.signedOut,
    );
  });

  test(
    'restore + incomplete profile routes to onboarding, address ignored',
    () async {
      final store = MemorySessionStore()
        ..value = const TokenPair(
          accessToken: 'access-1',
          refreshToken: 'refresh-1-token-value',
          expiresIn: 900,
          tokenType: 'Bearer',
        );
      final customer = FakeCustomerClient()
        ..meResult = const CustomerMe(
          customerProfileExists: true,
          profileComplete: false,
          addressReady: false,
        );
      final container = containerOf(
        auth: FakeAuthClient(),
        customer: customer,
        store: store,
      );
      addTearDown(container.dispose);
      await container.read(sessionControllerProvider.notifier).restore();
      final state = container.read(sessionControllerProvider);
      expect(state.phase, SessionPhase.needsProfile);
      expect(state.welcomeSeen, isTrue);
      expect(state.customer?.addressReady, isFalse);
    },
  );

  test('stored tokens enter restoring before hydrate completes', () async {
    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'access-1',
        refreshToken: 'refresh-1-token-value',
        expiresIn: 900,
        tokenType: 'Bearer',
      );
    final auth = FakeAuthClient()..meDelay = const Duration(milliseconds: 80);
    final customer = FakeCustomerClient()
      ..meResult = const CustomerMe(
        customerProfileExists: true,
        profileComplete: true,
        addressReady: true,
      );
    final container = containerOf(auth: auth, customer: customer, store: store);
    addTearDown(container.dispose);
    final controller = container.read(sessionControllerProvider.notifier);
    final future = controller.restore();
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(sessionControllerProvider).phase,
      SessionPhase.restoring,
    );
    expect(store.value, isNotNull);
    await future;
    expect(container.read(sessionControllerProvider).phase, SessionPhase.ready);
  });

  test('offline restore keeps credentials', () async {
    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'access-1',
        refreshToken: 'refresh-1-token-value',
        expiresIn: 900,
        tokenType: 'Bearer',
      );
    final auth = FakeAuthClient()
      ..meError = const NetworkException('offline', code: 'NETWORK');
    final container = containerOf(
      auth: auth,
      customer: FakeCustomerClient(),
      store: store,
    );
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.notifier).restore();
    final state = container.read(sessionControllerProvider);
    expect(state.phase, SessionPhase.restoreRetryable);
    expect(store.value, isNotNull);
  });

  test('confirmed revocation clears the session', () async {
    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'access-1',
        refreshToken: 'refresh-1-token-value',
        expiresIn: 900,
        tokenType: 'Bearer',
      );
    final auth = FakeAuthClient()
      ..meError = const ApiException(
        'revoked',
        code: 'AUTH_SESSION_REVOKED',
        statusCode: 401,
      );
    final container = containerOf(
      auth: auth,
      customer: FakeCustomerClient(),
      store: store,
    );
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.notifier).restore();
    expect(
      container.read(sessionControllerProvider).phase,
      SessionPhase.signedOut,
    );
    expect(store.value, isNull);
  });

  test('OTP resend cooldown blocks a second request', () async {
    final auth = FakeAuthClient();
    final container = containerOf(auth: auth, customer: FakeCustomerClient());
    addTearDown(container.dispose);
    final controller = container.read(sessionControllerProvider.notifier);
    await controller.requestOtp('555123456');
    expect(auth.requestCount, 1);
    expect(container.read(sessionControllerProvider).canRequestOtp, isFalse);
    await controller.requestOtp('555123456');
    expect(auth.requestCount, 1);
    expect(
      container.read(sessionControllerProvider).errorMessage,
      AppStrings.errorForCode('AUTH_RATE_LIMITED'),
    );
  });

  test('OTP validation rejects a short code', () async {
    final container = containerOf(
      auth: FakeAuthClient(),
      customer: FakeCustomerClient(),
    );
    addTearDown(container.dispose);
    final controller = container.read(sessionControllerProvider.notifier);
    await controller.requestOtp('555123456');
    await controller.verifyOtp('12');
    expect(
      container.read(sessionControllerProvider).errorMessage,
      AppStrings.otpIncomplete,
    );
    expect(container.read(sessionControllerProvider).tokens, isNull);
  });

  test(
    'OTP verify then profile submit reaches ready without address',
    () async {
      final customer = FakeCustomerClient();
      final container = containerOf(auth: FakeAuthClient(), customer: customer);
      addTearDown(container.dispose);
      final controller = container.read(sessionControllerProvider.notifier);
      await controller.requestOtp('555 12 34 56');
      await controller.verifyOtp('123456');
      expect(
        container.read(sessionControllerProvider).phase,
        SessionPhase.needsProfile,
      );
      await controller.submitProfile('Amel Benali');
      final state = container.read(sessionControllerProvider);
      expect(state.phase, SessionPhase.ready);
      expect(state.customer?.addressReady, isFalse);
      expect(customer.lastFullName, 'Amel Benali');
    },
  );

  test('logout clears storage and ignores a later hydrate', () async {
    final store = MemorySessionStore();
    final auth = FakeAuthClient();
    final customer = FakeCustomerClient()
      ..meResult = const CustomerMe(
        customerProfileExists: true,
        profileComplete: true,
        addressReady: false,
        profile: CustomerProfile(id: 'p', fullName: 'Amel'),
      );
    final container = containerOf(auth: auth, customer: customer, store: store);
    addTearDown(container.dispose);
    final controller = container.read(sessionControllerProvider.notifier);
    await controller.requestOtp('555123456');
    await controller.verifyOtp('123456');
    expect(store.value, isNotNull);
    await controller.logout();
    expect(store.value, isNull);
    expect(
      container.read(sessionControllerProvider).phase,
      SessionPhase.signedOut,
    );
    expect(auth.logoutCount, 1);
  });

  test('failed server logout still clears local session', () async {
    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'access-1',
        refreshToken: 'refresh-1-token-value',
        expiresIn: 900,
        tokenType: 'Bearer',
      );
    final auth = FakeAuthClient()
      ..logoutError = const NetworkException('offline', code: 'NETWORK');
    final customer = FakeCustomerClient()
      ..meResult = const CustomerMe(
        customerProfileExists: true,
        profileComplete: true,
        addressReady: true,
      );
    final container = containerOf(auth: auth, customer: customer, store: store);
    addTearDown(container.dispose);
    final controller = container.read(sessionControllerProvider.notifier);
    await controller.restore();
    await controller.logout();
    expect(store.value, isNull);
    expect(
      container.read(sessionControllerProvider).logoutServerConfirmed,
      isFalse,
    );
  });

  test('interceptor auth failure signs out a ready session', () async {
    final store = MemorySessionStore()
      ..value = const TokenPair(
        accessToken: 'access-1',
        refreshToken: 'refresh-1-token-value',
        expiresIn: 900,
        tokenType: 'Bearer',
      );
    final customer = FakeCustomerClient()
      ..meResult = const CustomerMe(
        customerProfileExists: true,
        profileComplete: true,
        addressReady: true,
      );
    final container = containerOf(
      auth: FakeAuthClient(),
      customer: customer,
      store: store,
    );
    addTearDown(container.dispose);
    final controller = container.read(sessionControllerProvider.notifier);
    await controller.restore();
    expect(container.read(sessionControllerProvider).phase, SessionPhase.ready);

    await container.read(tokenCacheProvider).onAuthFailure?.call();
    final state = container.read(sessionControllerProvider);
    expect(state.phase, SessionPhase.signedOut);
    expect(state.customer, isNull);
    expect(store.value, isNull);
    expect(state.errorMessage, AppStrings.reauthRequired);
  });
}
