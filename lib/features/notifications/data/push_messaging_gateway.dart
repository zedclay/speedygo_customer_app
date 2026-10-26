import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:speedygo_customer_app/features/notifications/application/notification_navigation.dart';

final _uuid = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);

/// Routing hint from a native Push payload. Never trusted for order state:
/// the app always re-fetches the order before opening a destination.
@immutable
class PushOrderHint {
  const PushOrderHint({
    required this.type,
    required this.orderId,
    this.notificationId,
  });

  final String type;
  final String orderId;
  final String? notificationId;

  static PushOrderHint? fromData(Map<String, dynamic> data) {
    final type = data['type'];
    if (type is! String || type.isEmpty) return null;
    final orderId = data['orderId'];
    if (orderId is! String || !_uuid.hasMatch(orderId)) return null;
    final dest = resolveNotificationDestinationFromParts(
      type: type,
      sourceId: orderId,
    );
    if (!dest.canOpen) return null;
    final notificationId = data['notificationId'];
    return PushOrderHint(
      type: type,
      orderId: orderId.toLowerCase(),
      notificationId: notificationId is String && _uuid.hasMatch(notificationId)
          ? notificationId.toLowerCase()
          : null,
    );
  }
}

enum PushAuthorization { authorized, provisional, denied, notDetermined }

extension PushAuthorizationX on PushAuthorization {
  bool get allowsDisplay =>
      this == PushAuthorization.authorized ||
      this == PushAuthorization.provisional;
}

/// Provider-neutral seam over the native Push SDK (testable with fakes).
abstract class PushMessagingGateway {
  bool get isAvailable;
  String get platform;
  Future<PushAuthorization> authorizationStatus();
  Future<PushAuthorization> requestAuthorization();
  Future<String?> getToken();
  Future<void> deleteToken();
  Stream<String> get onTokenRefresh;
  Stream<PushOrderHint> get onForegroundHint;
  Stream<PushOrderHint> get onOpenedHint;
  Future<PushOrderHint?> takeInitialHint();
}

class DisabledPushMessagingGateway implements PushMessagingGateway {
  const DisabledPushMessagingGateway();

  @override
  bool get isAvailable => false;
  @override
  String get platform =>
      defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android';
  @override
  Future<PushAuthorization> authorizationStatus() async =>
      PushAuthorization.notDetermined;
  @override
  Future<PushAuthorization> requestAuthorization() async =>
      PushAuthorization.notDetermined;
  @override
  Future<String?> getToken() async => null;
  @override
  Future<void> deleteToken() async {}
  @override
  Stream<String> get onTokenRefresh => const Stream.empty();
  @override
  Stream<PushOrderHint> get onForegroundHint => const Stream.empty();
  @override
  Stream<PushOrderHint> get onOpenedHint => const Stream.empty();
  @override
  Future<PushOrderHint?> takeInitialHint() async => null;
}

/// Android displays the notification payload. Do not mutate business state.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {}

class FirebasePushMessagingGateway implements PushMessagingGateway {
  FirebasePushMessagingGateway._();

  static PushMessagingGateway? _instance;

  /// Initializes Firebase on Android when `google-services.json` is present.
  /// iOS/APNs stays disabled this round. Failure never blocks startup.
  static Future<PushMessagingGateway> bootstrap() async {
    final existing = _instance;
    if (existing != null) return existing;
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return _instance = const DisabledPushMessagingGateway();
    }
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
      await FirebaseMessaging.instance
          .setForegroundNotificationPresentationOptions(
            alert: false,
            badge: false,
            sound: false,
          );
      return _instance = FirebasePushMessagingGateway._();
    } catch (e) {
      debugPrint('native push disabled: Firebase init failed ($e)');
      return _instance = const DisabledPushMessagingGateway();
    }
  }

  FirebaseMessaging get _fm => FirebaseMessaging.instance;
  bool _initialTaken = false;

  @override
  bool get isAvailable => true;

  @override
  String get platform => 'android';

  static PushAuthorization _map(AuthorizationStatus s) => switch (s) {
    AuthorizationStatus.authorized => PushAuthorization.authorized,
    AuthorizationStatus.provisional => PushAuthorization.provisional,
    AuthorizationStatus.denied ||
    AuthorizationStatus.deniedPermanently => PushAuthorization.denied,
    AuthorizationStatus.notDetermined => PushAuthorization.notDetermined,
  };

  @override
  Future<PushAuthorization> authorizationStatus() async =>
      _map((await _fm.getNotificationSettings()).authorizationStatus);

  @override
  Future<PushAuthorization> requestAuthorization() async =>
      _map((await _fm.requestPermission()).authorizationStatus);

  @override
  Future<String?> getToken() => _fm.getToken();

  @override
  Future<void> deleteToken() => _fm.deleteToken();

  @override
  Stream<String> get onTokenRefresh => _fm.onTokenRefresh;

  @override
  Stream<PushOrderHint> get onForegroundHint => FirebaseMessaging.onMessage
      .map((m) => PushOrderHint.fromData(m.data))
      .where((h) => h != null)
      .cast<PushOrderHint>();

  @override
  Stream<PushOrderHint> get onOpenedHint => FirebaseMessaging.onMessageOpenedApp
      .map((m) => PushOrderHint.fromData(m.data))
      .where((h) => h != null)
      .cast<PushOrderHint>();

  @override
  Future<PushOrderHint?> takeInitialHint() async {
    if (_initialTaken) return null;
    _initialTaken = true;
    final m = await _fm.getInitialMessage();
    return m == null ? null : PushOrderHint.fromData(m.data);
  }
}
