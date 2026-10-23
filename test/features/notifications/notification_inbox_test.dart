import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_chrome.dart';
import 'package:speedygo_customer_app/features/notifications/application/notification_copy.dart';
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
  String createdAt = '2026-09-10T00:00:00.000Z',
}) {
  return NotificationItem(
    id: id,
    type: type,
    sourceId: sourceId,
    title: title,
    body: body,
    read: read,
    createdAt: createdAt,
  );
}

ProviderContainer notifContainer(
  FakeNotificationsClient client, {
  String scope = 'scope-a',
}) {
  return ProviderContainer(
    overrides: [
      catalogScopeProvider.overrideWithValue(scope),
      notificationsApiProvider.overrideWithValue(client),
    ],
  );
}

Future<NotificationInboxState> settleInbox(ProviderContainer container) async {
  container.listen(notificationInboxControllerProvider, (_, _) {});
  container.listen(notificationUnreadCountProvider, (_, _) {});
  await Future<void>.delayed(Duration.zero);
  await Future<void>.delayed(Duration.zero);
  return container.read(notificationInboxControllerProvider);
}

Widget inboxApp({
  required FakeNotificationsClient client,
  required String scope,
  String locale = 'fr',
  double textScale = 1,
}) {
  AppStrings.bind(locale);
  final rtl = locale == 'ar';
  return ProviderScope(
    overrides: [
      catalogScopeProvider.overrideWithValue(scope),
      notificationsApiProvider.overrideWithValue(client),
    ],
    child: MaterialApp(
      locale: Locale(locale),
      home: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: Directionality(
          textDirection: rtl ? TextDirection.rtl : TextDirection.ltr,
          child: const NotificationInboxScreen(),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() => AppStrings.bind('fr'));
  tearDown(() => AppStrings.bind('fr'));

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

    final match = resolveNotificationDestination(
      item(
        type: 'MATCH_OFFER',
        sourceId: 'cccccccc-cccc-4ccc-8ccc-cccccccccccc',
      ),
    );
    expect(match.canOpen, isFalse);

    final bad = resolveNotificationDestination(
      item(type: 'ORDER_ACCEPTED', sourceId: 'https://evil.example/x'),
    );
    expect(bad.canOpen, isFalse);

    final unknown = resolveNotificationDestination(
      item(type: 'SOMETHING_NEW', sourceId: orderId),
    );
    expect(unknown.canOpen, isFalse);
  });

  test('relative timestamps follow FR and AR', () {
    final now = DateTime(2026, 10, 23, 12, 0);
    AppStrings.bind('fr');
    expect(
      formatNotificationTimestamp(
        now.subtract(const Duration(seconds: 20)).toIso8601String(),
        now: now,
      ),
      'À l’instant',
    );
    expect(
      formatNotificationTimestamp(
        now.subtract(const Duration(minutes: 12)).toIso8601String(),
        now: now,
      ),
      'Il y a 12 min',
    );
    AppStrings.bind('ar');
    expect(
      formatNotificationTimestamp(
        now.subtract(const Duration(seconds: 20)).toIso8601String(),
        now: now,
      ),
      'الآن',
    );
    expect(
      formatNotificationTimestamp(
        now.subtract(const Duration(hours: 3)).toIso8601String(),
        now: now,
      ),
      'منذ 3 س',
    );
    expect(
      formatNotificationTimestamp(
        DateTime(2026, 1, 5, 8).toIso8601String(),
        now: now,
      ),
      '05/01/2026',
    );
  });

  test('system copy localizes from type and keeps public references', () {
    AppStrings.bind('fr');
    final fr = resolveSystemNotificationCopy(
      type: 'ORDER_ACCEPTED',
      storedTitle: 'Order accepted',
      storedBody: 'Your order sgo_fixture was accepted by the merchant.',
    );
    expect(fr.localized, isTrue);
    expect(fr.title, 'Commande acceptée');
    expect(fr.body, contains('sgo_fixture'));
    expect(fr.body, isNot(contains('Order accepted')));
    expect(fr.publicReference, 'sgo_fixture');

    AppStrings.bind('ar');
    final ar = resolveSystemNotificationCopy(
      type: 'ORDER_ACCEPTED',
      storedTitle: 'Order accepted',
      storedBody: 'Your order sgo_fixture was accepted by the merchant.',
    );
    expect(ar.title, 'تم قبول الطلب');
    expect(ar.body, contains('sgo_fixture'));
    expect(ar.body, isNot(contains('accepted')));
  });

  test('unknown types keep stored copy; cancel does not invent refund status', () {
    AppStrings.bind('fr');
    final unknown = resolveSystemNotificationCopy(
      type: 'ADMIN_SUPPORT_TICKET',
      storedTitle: 'Ticket #12',
      storedBody: 'Ada opened a ticket about Dar El Bahja 650,00 DZD.',
    );
    expect(unknown.localized, isFalse);
    expect(unknown.title, 'Ticket #12');
    expect(unknown.body, contains('Dar El Bahja'));
    expect(unknown.body, contains('650,00 DZD'));

    final cancelled = resolveSystemNotificationCopy(
      type: 'ORDER_CANCELLED',
      storedTitle: 'Order cancelled',
      storedBody:
          'Your order sgo_fixture was cancelled. A refund has been requested and is processing — this does not mean money has been returned yet.',
    );
    expect(cancelled.body, contains('sgo_fixture'));
    expect(cancelled.body, isNot(contains('refund')));
    expect(cancelled.body, isNot(contains('Remboursement')));
  });

  test('direction guess is independent of surrounding layout', () {
    expect(guessTextDirection('Order accepted'), TextDirectionGuess.ltr);
    expect(guessTextDirection('تم قبول الطلب'), TextDirectionGuess.rtl);
    expect(
      guessTextDirection('تم قبول طلبك sgo_fixture'),
      TextDirectionGuess.rtl,
    );
    expect(guessTextDirection('650,00 DZD'), TextDirectionGuess.ltr);
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
    var state = await settleInbox(container);
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
    expect(state.unreadCount, 12);
  });

  test('load-more overlapping ids are deduplicated', () async {
    final seed = [
      for (var i = 0; i < 25; i++) item(id: 'n$i', title: 'T$i'),
    ];
    final client = FakeNotificationsClient(seed: seed)..overlapOnLoadMore = true;
    final container = notifContainer(client);
    addTearDown(container.dispose);
    await settleInbox(container);
    await container
        .read(notificationInboxControllerProvider.notifier)
        .loadMore();
    final state = container.read(notificationInboxControllerProvider);
    final ids = state.items.map((e) => e.id).toSet();
    expect(state.items.length, ids.length);
    expect(state.items.length, 20);
  });

  test('refresh replaces the list instead of appending duplicates', () async {
    final client = FakeNotificationsClient(
      seed: [item(id: 'a'), item(id: 'b')],
    );
    final container = notifContainer(client);
    addTearDown(container.dispose);
    await settleInbox(container);
    await container.read(notificationInboxControllerProvider.notifier).refresh();
    final state = container.read(notificationInboxControllerProvider);
    expect(state.items.map((e) => e.id).toList(), ['a', 'b']);
  });

  test('mark-read updates local state and reconciles unread', () async {
    final client = FakeNotificationsClient(
      seed: [item(id: 'a'), item(id: 'b')],
    );
    final container = notifContainer(client);
    addTearDown(container.dispose);
    await settleInbox(container);
    await container
        .read(notificationInboxControllerProvider.notifier)
        .markRead('a');
    final state = container.read(notificationInboxControllerProvider);
    expect(state.items.firstWhere((e) => e.id == 'a').read, isTrue);
    expect(client.markReadCalls, 1);
    expect(state.unreadCount, 1);
    expect(container.read(notificationUnreadCountProvider), 1);
  });

  test('mark-all-read clears unread then reconciles the backend count', () async {
    final client = FakeNotificationsClient(
      seed: [item(id: 'a'), item(id: 'b')],
    );
    final container = notifContainer(client);
    addTearDown(container.dispose);
    await settleInbox(container);
    await container
        .read(notificationInboxControllerProvider.notifier)
        .markAllRead();
    final state = container.read(notificationInboxControllerProvider);
    expect(state.items.every((e) => e.read), isTrue);
    expect(client.markAllCalls, 1);
    expect(state.unreadCount, 0);
    expect(container.read(notificationUnreadCountProvider), 0);
  });

  test('opening the list does not mark all read', () async {
    final client = FakeNotificationsClient(
      seed: [item(id: 'a'), item(id: 'b')],
    );
    final container = notifContainer(client);
    addTearDown(container.dispose);
    await settleInbox(container);
    expect(client.markAllCalls, 0);
    expect(client.markReadCalls, 0);
    expect(
      container.read(notificationInboxControllerProvider).unreadCount,
      2,
    );
  });

  test('certain mark-read failure rolls back and keeps unread', () async {
    final client = FakeNotificationsClient(seed: [item(id: 'a'), item(id: 'b')])
      ..markReadError = const ApiException(
        'Impossible de mettre à jour l’état de lecture.',
        code: 'NOTIFICATION_NOT_FOUND',
        statusCode: 404,
      );
    final container = notifContainer(client);
    addTearDown(container.dispose);
    await settleInbox(container);
    await container
        .read(notificationInboxControllerProvider.notifier)
        .markRead('a');
    final state = container.read(notificationInboxControllerProvider);
    expect(state.items.firstWhere((e) => e.id == 'a').read, isFalse);
    expect(state.unreadCount, 2);
    expect(container.read(notificationUnreadCountProvider), 2);
    expect(state.errorMessage, isNotNull);
    expect(client.items.firstWhere((e) => e.id == 'a').read, isFalse);
  });

  test('certain mark-all failure restores unread rows', () async {
    final client = FakeNotificationsClient(seed: [item(id: 'a'), item(id: 'b')])
      ..markAllError = const ApiException(
        'Impossible de mettre à jour l’état de lecture.',
        code: 'HTTP_ERROR',
        statusCode: 400,
      );
    final container = notifContainer(client);
    addTearDown(container.dispose);
    await settleInbox(container);
    await container
        .read(notificationInboxControllerProvider.notifier)
        .markAllRead();
    final state = container.read(notificationInboxControllerProvider);
    expect(state.items.every((e) => e.read), isFalse);
    expect(state.unreadCount, 2);
    expect(state.errorMessage, isNotNull);
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
    await settleInbox(container);
    final beforeLists = client.listCalls;
    await container
        .read(notificationInboxControllerProvider.notifier)
        .markRead('a');
    expect(client.listCalls, greaterThan(beforeLists));
    final state = container.read(notificationInboxControllerProvider);
    expect(state.items.first.read, isFalse);
    expect(state.unreadCount, 1);
  });

  test('uncertain mark-read keeps snapshot if refresh also fails', () async {
    final client = FakeNotificationsClient(seed: [item(id: 'a')])
      ..markReadError = const ApiException(
        'uncertain',
        code: 'NOTIFICATION_READ_UNCERTAIN',
        statusCode: 503,
      );
    final container = notifContainer(client);
    addTearDown(container.dispose);
    await settleInbox(container);
    client.listError = const ApiException(
      'Impossible de charger les notifications.',
      code: 'NETWORK_TIMEOUT',
    );
    await container
        .read(notificationInboxControllerProvider.notifier)
        .markRead('a');
    final state = container.read(notificationInboxControllerProvider);
    expect(state.items, isNotEmpty);
    expect(state.items.first.read, isFalse);
    expect(state.unreadCount, 1);
    expect(state.errorMessage, isNotNull);
  });

  test('repeated mark-read taps do not duplicate the mutation', () async {
    final client = FakeNotificationsClient(seed: [item(id: 'a')]);
    client.markReadGate = Completer<void>();
    final container = notifContainer(client);
    addTearDown(container.dispose);
    await settleInbox(container);
    final first = container
        .read(notificationInboxControllerProvider.notifier)
        .markRead('a');
    await Future<void>.delayed(Duration.zero);
    await container
        .read(notificationInboxControllerProvider.notifier)
        .markRead('a');
    client.markReadGate!.complete();
    await first;
    expect(client.markReadCalls, 1);
  });

  test('unread badge uses dedicated count not page length', () async {
    final seed = [
      for (var i = 0; i < 25; i++) item(id: 'n$i', read: i > 4),
    ];
    final client = FakeNotificationsClient(seed: seed);
    final container = notifContainer(client);
    addTearDown(container.dispose);
    await settleInbox(container);
    final pageUnread = container
        .read(notificationInboxControllerProvider)
        .items
        .where((e) => !e.read)
        .length;
    expect(pageUnread, 5);
    expect(container.read(notificationInboxControllerProvider).unreadCount, 5);
    expect(container.read(notificationUnreadCountProvider), 5);
  });

  test('load-more failure keeps loaded rows and sets pagination error', () async {
    final seed = [
      for (var i = 0; i < 25; i++) item(id: 'n$i', title: 'T$i'),
    ];
    final client = FakeNotificationsClient(seed: seed)
      ..listErrorForOffset = (offset) {
        if (offset > 0) {
          return const ApiException(
            'Impossible de charger les notifications.',
            code: 'NETWORK_TIMEOUT',
          );
        }
        return null;
      };
    final container = notifContainer(client);
    addTearDown(container.dispose);
    await settleInbox(container);
    await container
        .read(notificationInboxControllerProvider.notifier)
        .loadMore();
    final state = container.read(notificationInboxControllerProvider);
    expect(state.items.length, 20);
    expect(state.loadMoreError, isNotNull);
    expect(state.errorMessage, isNull);
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
    await settleInbox(a);
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
    await settleInbox(b);
    expect(b.read(notificationInboxControllerProvider).items, isEmpty);
  });

  test('stale list response cannot overwrite a newer session', () async {
    final client = FakeNotificationsClient(
      seed: [item(id: 'old-account', title: 'Old')],
    )..listDelayForCall = (call) {
        return call == 1
            ? const Duration(milliseconds: 80)
            : const Duration(milliseconds: 10);
      };
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWith(
          (ref) => ref.watch(_inboxScopeProvider),
        ),
        notificationsApiProvider.overrideWithValue(client),
      ],
    );
    addTearDown(container.dispose);
    container.listen(notificationInboxControllerProvider, (_, _) {});
    container.listen(notificationUnreadCountProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    client.items = [item(id: 'new-account', title: 'New')];
    container.read(_inboxScopeProvider.notifier).switchTo('scope-b');
    await Future<void>.delayed(const Duration(milliseconds: 150));
    final state = container.read(notificationInboxControllerProvider);
    expect(state.items.map((e) => e.id).toList(), ['new-account']);
  });

  testWidgets('inbox empty and populated UI', (tester) async {
    final empty = FakeNotificationsClient();
    await tester.pumpWidget(
      inboxApp(client: empty, scope: 'ui-empty'),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('notifications-empty')), findsOneWidget);
    expect(find.text('Aucune notification pour le moment.'), findsOneWidget);

    final populated = FakeNotificationsClient(
      seed: [
        item(id: 'n1', title: 'Commande acceptée', read: false),
        item(id: 'n2', title: 'Lu', read: true),
      ],
    );
    await tester.pumpWidget(
      inboxApp(client: populated, scope: 'ui-full'),
    );
    await tester.pumpAndSettle();
    expect(find.text('Commande acceptée'), findsWidgets);
    expect(find.byKey(const Key('notifications-mark-all')), findsOneWidget);
    expect(find.byKey(const Key('notification-unread-n1')), findsOneWidget);
    expect(find.byKey(const Key('notification-unread-n2')), findsNothing);
  });

  testWidgets('French and Arabic empty inbox stay RTL-safe', (tester) async {
    await tester.pumpWidget(
      inboxApp(
        client: FakeNotificationsClient(),
        scope: 'ui-empty-fr',
        locale: 'fr',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aucune notification pour le moment.'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(NotificationInboxScreen))),
      TextDirection.ltr,
    );

    await tester.pumpWidget(
      inboxApp(
        client: FakeNotificationsClient(),
        scope: 'ui-empty-ar',
        locale: 'ar',
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('لا توجد إشعارات حاليًا.'), findsOneWidget);
    expect(find.text('ستظهر تنبيهات الطلب هنا عند توفّرها.'), findsOneWidget);
    expect(
      Directionality.of(tester.element(find.byType(NotificationInboxScreen))),
      TextDirection.rtl,
    );
  });

  testWidgets('Arabic populated inbox keeps mixed Latin titles', (tester) async {
    final populated = FakeNotificationsClient(
      seed: [
        item(
          id: 'n1',
          title: 'Order accepted',
          body: 'Your order sgo_fixture was accepted by the merchant.',
          read: false,
        ),
        item(
          id: 'n2',
          type: 'ADMIN_SUPPORT_TICKET',
          title: 'Ticket Dar El Bahja',
          body: 'Ada — 650,00 DZD remains as confirmed.',
          read: true,
        ),
      ],
    );
    await tester.pumpWidget(
      inboxApp(
        client: populated,
        scope: 'ui-ar-full',
        locale: 'ar',
        textScale: 1.6,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Alertes'), findsNothing);
    expect(find.text('التنبيهات'), findsWidgets);
    expect(find.text('تعليم الكل كمقروء'), findsOneWidget);
    expect(find.text('تم قبول الطلب'), findsOneWidget);
    expect(find.textContaining('sgo_fixture'), findsOneWidget);
    expect(find.textContaining('Dar El Bahja'), findsOneWidget);
    expect(find.textContaining('650,00 DZD'), findsOneWidget);
  });

  testWidgets('English unknown copy stays LTR inside Arabic layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      inboxApp(
        client: FakeNotificationsClient(
          seed: [
            item(
              type: 'ADMIN_SUPPORT_TICKET',
              title: 'Ticket #12',
              body: 'Ada opened a ticket about Dar El Bahja.',
            ),
          ],
        ),
        scope: 'ui-ar-ltr-body',
        locale: 'ar',
      ),
    );
    await tester.pumpAndSettle();
    expect(
      Directionality.of(
        tester.element(find.byType(NotificationInboxScreen)),
      ),
      TextDirection.rtl,
    );
    expect(
      tester.widget<Text>(find.text('Ticket #12')).textDirection,
      TextDirection.ltr,
    );
    expect(
      tester
          .widget<Text>(find.text('Ada opened a ticket about Dar El Bahja.'))
          .textDirection,
      TextDirection.ltr,
    );
  });

  testWidgets('pagination error offers retry without dropping rows', (
    tester,
  ) async {
    final seed = [
      for (var i = 0; i < 25; i++)
        item(id: 'n$i', type: 'ADMIN_SUPPORT_TICKET', title: 'T$i'),
    ];
    final client = FakeNotificationsClient(seed: seed)
      ..listErrorForOffset = (offset) {
        if (offset > 0) {
          return const ApiException(
            'Impossible de charger les notifications.',
            code: 'NETWORK_TIMEOUT',
          );
        }
        return null;
      };
    await tester.pumpWidget(
      inboxApp(client: client, scope: 'ui-page-err'),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('notifications-load-more')),
      400,
    );
    await tester.tap(find.byKey(const Key('notifications-load-more')));
    await tester.pumpAndSettle();
    expect(find.text('T19'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const Key('notifications-pagination-error')),
      200,
    );
    expect(find.byKey(const Key('notifications-pagination-error')), findsOneWidget);
    expect(find.byKey(const Key('notifications-pagination-retry')), findsOneWidget);
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

  testWidgets('home bell badge uses the unread count', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: HomeHeader(
            addressLabel: 'Sidi Bel Abbès',
            onAddressTap: () {},
            onAlertsTap: () {},
            unreadCount: 3,
          ),
        ),
      ),
    );
    expect(find.byKey(const Key('home-alerts-bell')), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });
}

class _InboxScope extends Notifier<String> {
  @override
  String build() => 'scope-a';

  void switchTo(String value) => state = value;
}

final _inboxScopeProvider = NotifierProvider<_InboxScope, String>(
  _InboxScope.new,
);
