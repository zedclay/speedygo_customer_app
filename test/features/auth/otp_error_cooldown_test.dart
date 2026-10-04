import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../helpers/fakes.dart';

void main() {
  test('INTERNAL_ERROR does not invent OTP cooldown', () async {
    final auth = FakeAuthClient()
      ..requestError = ApiException(
        AppStrings.errorForCode('INTERNAL_ERROR'),
        code: 'INTERNAL_ERROR',
        statusCode: 500,
      );
    final container = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        launchStoreProvider.overrideWithValue(
          MemoryLaunchStore(onboardingSeen: true),
        ),
        authApiProvider.overrideWithValue(auth),
        customerApiProvider.overrideWithValue(FakeCustomerClient()),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(sessionControllerProvider.notifier);
    await controller.requestOtp('550000072');
    final state = container.read(sessionControllerProvider);
    expect(state.errorMessage, AppStrings.otpServerUnavailable);
    expect(state.canRequestOtp, isTrue);
    expect(state.otpResendSecondsRemaining, 0);
  });

  test('AUTH_RATE_LIMITED sets cooldown and dedicated copy', () async {
    final auth = FakeAuthClient()
      ..requestError = ApiException(
        AppStrings.errorForCode('AUTH_RATE_LIMITED'),
        code: 'AUTH_RATE_LIMITED',
        statusCode: 429,
      );
    final container = ProviderContainer(
      overrides: [
        sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        launchStoreProvider.overrideWithValue(
          MemoryLaunchStore(onboardingSeen: true),
        ),
        authApiProvider.overrideWithValue(auth),
        customerApiProvider.overrideWithValue(FakeCustomerClient()),
      ],
    );
    addTearDown(container.dispose);
    final controller = container.read(sessionControllerProvider.notifier);
    await controller.requestOtp('550000072');
    final state = container.read(sessionControllerProvider);
    expect(state.errorMessage, AppStrings.errorForCode('AUTH_RATE_LIMITED'));
    expect(state.canRequestOtp, isFalse);
  });
}
