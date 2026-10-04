import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/notifications/application/notification_inbox_controller.dart';
import 'package:speedygo_customer_app/features/notifications/application/notification_navigation.dart';
import 'package:speedygo_customer_app/features/notifications/data/notification_models.dart';
import 'package:speedygo_customer_app/features/notifications/presentation/notification_inbox_screen.dart';

import '../../helpers/notification_support_fakes.dart';

NotificationItem item({
  String id = 'n1',
  String type = 'ORDER_ACCEPTED',
  String sourceId = '11111111-1111-4111-8111-111111111111',
  bool read = false,
  String title = 'Title',
  String body = 'Body',
}) {
  return NotificationItem(
    id: id,
    type: type,
    sourceId: sourceId,
    title: title,
    body: body,
    read: read,
    createdAt: '2026-09-10T00:00:00.000Z',
  );
}

ProviderContainer notifContainer(FakeNotificationsClient client) {
  return ProviderContainer(
    overrides: [
      catalogScopeProvider.overrideWithValue('scope-a'),
      notificationsApiProvider.overrideWithValue(client),
    ],
  );
}

void main() {
  test('maps order types to internal order routes only', () {
    const orderId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
    final accepted = resolveNotificationDestination(
      item(type: 'ORDER_ACCEPTED', sourceId: orderId),
    );
    expect(accepted.canOpen, isTrue);
    expect(accepted.location, AppRoutes.orderTracking(orderId));

    final cancelled = resolveNotificationDestination(
      item(type: 'ORDER_CANCELLED', sourceId: orderId),
    );
    expect(cancelled.location, AppRoutes.order(orderId));

    final payment = resolveNotificationDestination(
      item(
        type: 'PAYMENT_SUCCEEDED',
        sourceId: 'bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb',
      ),
    );
    expect(payment.canOpen, isFalse);

    final bad = resolveNotificationDestination(
      item(type: 'ORDER_ACCEPTED', sourceId: 'https://evil.example/x'),
    );
    expect(bad.canOpen, isFalse);

    final unknown = resolveNotificationDestination(
      item(type: 'SOMETHING_NEW', sourceId: orderId),
    );
    expect(unknown.canOpen, isFalse);
  });

  test('pagination appends without inventing unread from page alone', () async {
    final seed = [
      for (var i = 0; i < 25; i++)
        item(
          id: 'n$i',
          title: 'T$i',
          read: i.isEven,
        ),
    ];
    final client = FakeNotificationsClient(seed: seed);
    final container = notifContainer(client);
    addTearDown(container.dispose);
    container.listen(notificationInboxControllerProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    var state = container.read(notificationInboxControllerProvider);
    expect(state.items.length, 20);
    expect(state.total, 25);
    expect(state.hasMore, isTrue);
    expect(state.unreadCount, 12);

    await container
        .read(notificationInboxControllerProvider.notifier)
        .loadMore();
    state = container.read(notificationInboxControllerProvider);
    expect(state.items.length, 25);
    expect(state.hasMore, isFalse);
  });

  test('mark-read updates local state and reconciles unread', () async {
    final client = FakeNotificationsClient(
      seed: [item(id: 'a'), item(id: 'b')],
    );
    final container = notifContainer(client);
    addTearDown(container.dispose);
    container.listen(notificationInboxControllerProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    await container
        .read(notificationInboxControllerProvider.notifier)
        .markRead('a');
    final state = container.read(notificationInboxControllerProvider);
    expect(state.items.firstWhere((e) => e.id == 'a').read, isTrue);
    expect(client.markReadCalls, 1);
    expect(state.unreadCount, 1);
  });

  test('uncertain mark-read reconciles via list refresh', () async {
    final client = FakeNotificationsClient(seed: [item(id: 'a')])
      ..markReadError = const ApiException(
        'uncertain',
        code: 'NOTIFICATION_READ_UNCERTAIN',
        statusCode: 503,
      );
    final container = notifContainer(client);
    addTearDown(container.dispose);
    container.listen(notificationInboxControllerProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    final beforeLists = client.listCalls;
    await container
        .read(notificationInboxControllerProvider.notifier)
        .markRead('a');
    expect(client.listCalls, greaterThan(beforeLists));
  });

  test('catalog scope isolates inbox between accounts', () async {
    final client = FakeNotificationsClient(seed: [item(id: 'a')]);
    final a = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('scope-a'),
        notificationsApiProvider.overrideWithValue(client),
      ],
    );
    addTearDown(a.dispose);
    a.listen(notificationInboxControllerProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(a.read(notificationInboxControllerProvider).items, isNotEmpty);

    final b = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('scope-b'),
        notificationsApiProvider.overrideWithValue(
          FakeNotificationsClient(seed: const []),
        ),
      ],
    );
    addTearDown(b.dispose);
    b.listen(notificationInboxControllerProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(b.read(notificationInboxControllerProvider).items, isEmpty);
  });

  testWidgets('inbox empty and populated UI', (tester) async {
    final empty = FakeNotificationsClient();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogScopeProvider.overrideWithValue('ui-empty'),
          notificationsApiProvider.overrideWithValue(empty),
        ],
        child: const MaterialApp(home: NotificationInboxScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notifications-empty')), findsOneWidget);

    final populated = FakeNotificationsClient(
      seed: [
        item(id: 'n1', title: 'Commande acceptée', read: false),
        item(id: 'n2', title: 'Lu', read: true),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogScopeProvider.overrideWithValue('ui-full'),
          notificationsApiProvider.overrideWithValue(populated),
        ],
        child: const MaterialApp(home: NotificationInboxScreen()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Commande acceptée'), findsOneWidget);
    expect(find.byKey(const Key('notifications-mark-all')), findsOneWidget);
  });

  testWidgets('malformed destination shows graceful snackbar', (tester) async {
    final messengerKey = GlobalKey<ScaffoldMessengerState>();
    final client = FakeNotificationsClient(
      seed: [
        item(
          id: 'bad',
          type: 'ORDER_ACCEPTED',
          sourceId: '../../etc/passwd',
          title: 'Bad',
        ),
      ],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogScopeProvider.overrideWithValue('ui-bad'),
          notificationsApiProvider.overrideWithValue(client),
        ],
        child: MaterialApp(
          scaffoldMessengerKey: messengerKey,
          home: const NotificationInboxScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('notification-tile-bad')));
    await tester.pumpAndSettle();
    expect(find.textContaining('ne peut pas être ouverte'), findsOneWidget);
  });
}
