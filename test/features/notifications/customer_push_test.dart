import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_state.dart';
import 'package:speedygo_customer_app/features/notifications/application/customer_push_controller.dart';
import 'package:speedygo_customer_app/features/notifications/application/notification_inbox_controller.dart';
import 'package:speedygo_customer_app/features/notifications/application/notification_navigation.dart';
import 'package:speedygo_customer_app/features/notifications/data/push_messaging_gateway.dart';
import 'package:speedygo_customer_app/features/notifications/data/push_registration.dart';
import '../../helpers/notification_support_fakes.dart';

const _accountA = 'aaaaaaaa-aaaa-7aaa-8aaa-aaaaaaaaaaaa';
const _accountB = 'bbbbbbbb-bbbb-7bbb-8bbb-bbbbbbbbbbbb';
const _order = '01a0d97f-9cbd-7b41-8dbf-ef8238661920';

class _FakeGateway implements PushMessagingGateway {
  PushAuthorization auth = PushAuthorization.authorized;
  PushAuthorization authAfterRequest = PushAuthorization.authorized;
  int requestCount = 0;
  int deleteCount = 0;
  int _serial = 2;
  String token = 'tok-1';
  PushOrderHint? initial;
  final refresh = StreamController<String>.broadcast();
  final foreground = StreamController<PushOrderHint>.broadcast();
  final opened = StreamController<PushOrderHint>.broadcast();

  @override
  bool get isAvailable => true;
  @override
  String get platform => 'android';
  @override
  Future<PushAuthorization> authorizationStatus() async => auth;
  @override
  Future<PushAuthorization> requestAuthorization() async {
    requestCount++;
    auth = authAfterRequest;
    return auth;
  }

  @override
  Future<String?> getToken() async => token;
  @override
  Future<void> deleteToken() async {
    deleteCount++;
    token = 'tok-${_serial++}';
  }

  @override
  Stream<String> get onTokenRefresh => refresh.stream;
  @override
  Stream<PushOrderHint> get onForegroundHint => foreground.stream;
  @override
  Stream<PushOrderHint> get onOpenedHint => opened.stream;
  @override
  Future<PushOrderHint?> takeInitialHint() async {
    final h = initial;
    initial = null;
    return h;
  }
}

class _MemoryStore extends CustomerPushRegistration {
  StoredPushToken? value;
  @override
  Future<void> storeRegisteredToken({
    required String token,
    required String platform,
    required String? accountId,
  }) async {
    value = (token: token, platform: platform, accountId: accountId);
  }

  @override
  Future<StoredPushToken?> loadStoredToken() async => value;
  @override
  Future<void> clearStoredToken() async => value = null;
}

class _FakeSession extends SessionController {
  @override
  SessionState build() => const SessionState(phase: SessionPhase.signedOut);

  void signIn(String accountId, {int generation = 1}) {
    state = SessionState(
      phase: SessionPhase.ready,
      accountId: accountId,
      generation: generation,
    );
  }

  void signOut() {
    state = SessionState(
      phase: SessionPhase.signedOut,
      generation: state.generation + 1,
    );
  }

  Future<void> signOutLikeLogout() async {
    await ref
        .read(customerPushControllerProvider.notifier)
        .deactivateForSignOut(callServer: true);
    signOut();
  }
}

class _Harness {
  _Harness() {
    container = ProviderContainer(
      overrides: [
        pushMessagingGatewayProvider.overrideWithValue(gateway),
        pushRegistrationStoreProvider.overrideWithValue(store),
        notificationsApiProvider.overrideWithValue(api),
        sessionControllerProvider.overrideWith(_FakeSession.new),
      ],
    );
    container.listen(customerPushControllerProvider, (_, _) {});
    container.listen(
      sessionControllerProvider,
      (prev, next) => container
          .read(customerPushControllerProvider.notifier)
          .onSessionChanged(prev, next),
    );
  }

  final gateway = _FakeGateway();
  final store = _MemoryStore();
  final api = FakeNotificationsClient();
  late final ProviderContainer container;

  _FakeSession get session =>
      container.read(sessionControllerProvider.notifier) as _FakeSession;
  CustomerPushController get push =>
      container.read(customerPushControllerProvider.notifier);
  CustomerPushState get state => container.read(customerPushControllerProvider);

  Future<void> settle() async {
    for (var i = 0; i < 10; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }
}

void main() {
  group('PushOrderHint.fromData', () {
    test('accepts customer order payloads and normalizes ids', () {
      final hint = PushOrderHint.fromData({
        'type': 'ORDER_READY',
        'orderId': _order.toUpperCase(),
        'notificationId': 'not-a-uuid',
      });
      expect(hint?.type, 'ORDER_READY');
      expect(hint?.orderId, _order);
      expect(hint?.notificationId, isNull);
      expect(
        resolveNotificationDestinationFromParts(
          type: hint!.type,
          sourceId: hint.orderId,
        ).canOpen,
        isTrue,
      );
    });

    test('rejects merchant/financial types and malformed order ids', () {
      expect(
        PushOrderHint.fromData({
          'type': 'MERCHANT_ORDER_CREATED',
          'orderId': _order,
        }),
        isNull,
      );
      expect(
        PushOrderHint.fromData({
          'type': 'PAYMENT_SUCCEEDED',
          'orderId': _order,
        }),
        isNull,
      );
      expect(
        PushOrderHint.fromData({
          'type': 'ORDER_READY',
          'orderId': '../../admin',
        }),
        isNull,
      );
    });
  });

  test('registers the token for the signed-in account after permission prompt',
      () async {
    final h = _Harness();
    h.gateway.auth = PushAuthorization.notDetermined;
    h.session.signIn(_accountA);
    await h.settle();

    expect(h.gateway.requestCount, 1);
    expect(h.api.registered, ['android:tok-1']);
    expect(h.store.value?.accountId, _accountA);
    expect(h.state.registration, PushRegistrationStatus.registered);
  });

  test('permission denied: no registration and stored token is deactivated',
      () async {
    final h = _Harness();
    h.store.value = (token: 'old', platform: 'android', accountId: _accountA);
    h.gateway.auth = PushAuthorization.denied;
    h.session.signIn(_accountA);
    await h.settle();

    expect(h.api.registered, isEmpty);
    expect(h.api.deactivated, ['old']);
    expect(h.store.value, isNull);
    expect(h.state.registration, PushRegistrationStatus.permissionDenied);
  });

  test('account change on the same install rotates the provider token',
      () async {
    final h = _Harness();
    h.store.value = (token: 'tok-A', platform: 'android', accountId: _accountA);
    h.session.signIn(_accountB);
    await h.settle();

    expect(h.gateway.deleteCount, 1);
    expect(h.api.registered, ['android:tok-2']);
    expect(
      h.api.deactivated,
      isEmpty,
      reason: 'B must not DELETE a token owned by A',
    );
    expect(h.store.value?.accountId, _accountB);
  });

  test('token refresh deactivates the old token and registers the new one',
      () async {
    final h = _Harness();
    h.session.signIn(_accountA);
    await h.settle();
    expect(h.api.registered, ['android:tok-1']);

    h.gateway.token = 'tok-refreshed';
    h.gateway.refresh.add('tok-refreshed');
    await h.settle();

    expect(h.api.deactivated, ['tok-1']);
    expect(h.api.registered.last, 'android:tok-refreshed');
    expect(h.store.value?.token, 'tok-refreshed');
  });

  test('409 (token still active for another account) rotates once and retries',
      () async {
    final h = _Harness();
    h.api.conflictTokens = {'tok-1'};
    h.session.signIn(_accountA);
    await h.settle();

    expect(h.gateway.deleteCount, 1);
    expect(h.api.registered, ['android:tok-2']);
    expect(h.state.registration, PushRegistrationStatus.registered);
  });

  test('logout deactivates exactly the stored token then deletes it at provider',
      () async {
    final h = _Harness();
    h.session.signIn(_accountA);
    await h.settle();

    await h.push.deactivateForSignOut(callServer: true);
    expect(h.api.deactivated, ['tok-1']);
    expect(h.store.value, isNull);
    expect(h.gateway.deleteCount, 1);
  });

  test('session controller can read the push controller (no provider cycle)',
      () async {
    final h = _Harness();
    h.session.signIn(_accountA);
    await h.settle();
    expect(h.api.registered, ['android:tok-1']);

    await h.session.signOutLikeLogout();
    expect(h.api.deactivated, ['tok-1']);
    expect(h.store.value, isNull);
  });

  test('expired session: no server call, provider token still invalidated',
      () async {
    final h = _Harness();
    h.session.signIn(_accountA);
    await h.settle();

    await h.push.deactivateForSignOut(callServer: false);
    expect(h.api.deactivated, isEmpty);
    expect(h.store.value, isNull);
    expect(h.gateway.deleteCount, 1);
  });

  test('stale generation does not register to the previous session', () async {
    final h = _Harness();
    h.session.signIn(_accountA, generation: 1);
    h.session.signOut();
    h.session.signIn(_accountB, generation: 3);
    await h.settle();

    expect(h.api.registered, ['android:tok-1']);
    expect(h.store.value?.accountId, _accountB);
  });

  test('cold-launch tap is held as pendingOpen until consumed once', () async {
    final h = _Harness();
    h.gateway.initial = const PushOrderHint(type: 'ORDER_READY', orderId: _order);
    h.container.invalidate(customerPushControllerProvider);
    h.container.read(customerPushControllerProvider);
    await h.settle();

    expect(h.state.pendingOpen?.orderId, _order);
    expect(h.push.takePendingOpen()?.orderId, _order);
    expect(h.push.takePendingOpen(), isNull);
    expect(h.state.pendingOpen, isNull);
  });

  test('background tap (onMessageOpenedApp) sets pendingOpen', () async {
    final h = _Harness();
    h.gateway.opened.add(
      const PushOrderHint(type: 'DRIVER_ASSIGNED', orderId: _order),
    );
    await h.settle();
    expect(h.state.pendingOpen?.orderId, _order);
  });

  test('no registration while signed out; re-registers on next sign-in',
      () async {
    final h = _Harness();
    await h.push.syncRegistration();
    expect(h.api.registered, isEmpty);

    h.session.signIn(_accountA);
    await h.settle();
    h.session.signOut();
    await h.push.deactivateForSignOut(callServer: true);
    h.session.signIn(_accountA, generation: 3);
    await h.settle();
    expect(h.api.registered, ['android:tok-1', 'android:tok-2']);
  });
}
