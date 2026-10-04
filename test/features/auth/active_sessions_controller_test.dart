import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/storage/session_store.dart';
import 'package:speedygo_customer_app/features/auth/application/active_sessions_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';
import 'package:speedygo_customer_app/features/auth/application/session_state.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/auth/presentation/active_sessions_screen.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';

import '../../helpers/fakes.dart';

AuthSession sessionRow({
  required String id,
  bool current = false,
  bool revoked = false,
  String? deviceName = 'Device',
  String platform = 'ios',
}) {
  return AuthSession(
    id: id,
    deviceId: 'dev-$id',
    platform: platform,
    deviceName: deviceName,
    createdAt: '2026-09-10T00:00:00.000Z',
    expiresAt: '2026-10-10T00:00:00.000Z',
    revoked: revoked,
    currentSession: current,
  );
}

ProviderContainer sessionsContainer(FakeAuthClient auth) {
  return ProviderContainer(
    overrides: [
      catalogScopeProvider.overrideWithValue('scope-a'),
      sessionStoreProvider.overrideWithValue(MemorySessionStore()),
      launchStoreProvider.overrideWithValue(
        MemoryLaunchStore(onboardingSeen: true),
      ),
      authApiProvider.overrideWithValue(auth),
      customerApiProvider.overrideWithValue(FakeCustomerClient()),
    ],
  );
}

void main() {
  test('lists active sessions and marks current', () async {
    final auth = FakeAuthClient()
      ..sessions = [
        sessionRow(id: 'cur', current: true, deviceName: 'iPhone SE'),
        sessionRow(id: 'other', deviceName: 'Android'),
        sessionRow(id: 'old', revoked: true, deviceName: 'Old'),
      ];
    final container = sessionsContainer(auth);
    addTearDown(container.dispose);
    container.listen(activeSessionsControllerProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    final state = container.read(activeSessionsControllerProvider);
    expect(state.activeItems.length, 2);
    expect(state.activeItems.first.currentSession, isTrue);
    expect(auth.listSessionsCount, greaterThanOrEqualTo(1));
  });

  test('revoking another session keeps local session ready', () async {
    final auth = FakeAuthClient()
      ..sessions = [
        sessionRow(id: 'cur', current: true),
        sessionRow(id: 'other'),
      ]
      ..meResult = const AuthMe(
        accountId: 'acc-1',
        phone: '+213550000072',
        status: 'ACTIVE',
        hasCustomerProfile: true,
      );
    final store = MemorySessionStore();
    await store.write(auth.pair);
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('scope-a'),
        sessionStoreProvider.overrideWithValue(store),
        launchStoreProvider.overrideWithValue(
          MemoryLaunchStore(onboardingSeen: true),
        ),
        authApiProvider.overrideWithValue(auth),
        customerApiProvider.overrideWithValue(
          FakeCustomerClient()
            ..meResult = const CustomerMe(
              customerProfileExists: true,
              profileComplete: true,
              addressReady: true,
              profile: CustomerProfile(id: 'p1', fullName: 'Revue'),
            ),
        ),
      ],
    );
    addTearDown(container.dispose);
    await container.read(sessionControllerProvider.notifier).restore();
    expect(
      container.read(sessionControllerProvider).phase,
      SessionPhase.ready,
    );
    container.listen(activeSessionsControllerProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    final signedOut = await container
        .read(activeSessionsControllerProvider.notifier)
        .revokeSession('other');
    expect(signedOut, isFalse);
    expect(auth.revokeSessionCount, 1);
    expect(
      container.read(sessionControllerProvider).phase,
      SessionPhase.ready,
    );
    expect(
      container
          .read(activeSessionsControllerProvider)
          .activeItems
          .any((s) => s.id == 'other'),
      isFalse,
    );
  });

  test('uncertain revoke reconciles via list refresh', () async {
    final auth = FakeAuthClient()
      ..sessions = [
        sessionRow(id: 'cur', current: true),
        sessionRow(id: 'other'),
      ]
      ..revokeSessionError = const ApiException(
        'uncertain',
        code: 'SESSION_REVOKE_UNCERTAIN',
        statusCode: 503,
      );
    final container = sessionsContainer(auth);
    addTearDown(container.dispose);
    container.listen(activeSessionsControllerProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    final before = auth.listSessionsCount;
    await container
        .read(activeSessionsControllerProvider.notifier)
        .revokeSession('other');
    expect(auth.listSessionsCount, greaterThan(before));
    expect(
      container.read(activeSessionsControllerProvider).errorMessage,
      AppStrings.securityRevokeUncertain,
    );
  });

  test('account scope isolates session list', () async {
    final authA = FakeAuthClient()
      ..sessions = [sessionRow(id: 'a', current: true)];
    final a = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('scope-a'),
        sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        launchStoreProvider.overrideWithValue(
          MemoryLaunchStore(onboardingSeen: true),
        ),
        authApiProvider.overrideWithValue(authA),
        customerApiProvider.overrideWithValue(FakeCustomerClient()),
      ],
    );
    addTearDown(a.dispose);
    a.listen(activeSessionsControllerProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(a.read(activeSessionsControllerProvider).activeItems, isNotEmpty);

    final b = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('scope-b'),
        sessionStoreProvider.overrideWithValue(MemorySessionStore()),
        launchStoreProvider.overrideWithValue(
          MemoryLaunchStore(onboardingSeen: true),
        ),
        authApiProvider.overrideWithValue(FakeAuthClient()),
        customerApiProvider.overrideWithValue(FakeCustomerClient()),
      ],
    );
    addTearDown(b.dispose);
    b.listen(activeSessionsControllerProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(b.read(activeSessionsControllerProvider).activeItems, isEmpty);
  });

  test('INTERNAL_ERROR maps to otp server unavailable copy', () {
    expect(
      AppStrings.errorForCode('INTERNAL_ERROR'),
      AppStrings.otpServerUnavailable,
    );
  });

  testWidgets('revoke dialog cancel does not call API', (tester) async {
    final auth = FakeAuthClient()
      ..sessions = [
        sessionRow(id: 'cur', current: true),
        sessionRow(id: 'other', deviceName: 'Other'),
      ];
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogScopeProvider.overrideWithValue('ui'),
          sessionStoreProvider.overrideWithValue(MemorySessionStore()),
          launchStoreProvider.overrideWithValue(
            MemoryLaunchStore(onboardingSeen: true),
          ),
          authApiProvider.overrideWithValue(auth),
          customerApiProvider.overrideWithValue(FakeCustomerClient()),
        ],
        child: const MaterialApp(home: ActiveSessionsScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.ensureVisible(find.byKey(const Key('session-revoke-other')));
    await tester.tap(find.byKey(const Key('session-revoke-other')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('sessions-revoke-cancel')));
    await tester.pump();
    expect(auth.revokeSessionCount, 0);
  });
}
