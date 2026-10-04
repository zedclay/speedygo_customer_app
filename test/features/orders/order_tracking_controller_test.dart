import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/orders/application/order_tracking_controller.dart';
import 'package:speedygo_customer_app/features/orders/data/tracking_models.dart';
import 'package:speedygo_customer_app/features/orders/presentation/order_tracking_screen.dart';

import '../../helpers/fakes.dart';
import '../../helpers/order_fixtures.dart';

void main() {
  test('refresh loads order and treats missing delivery as pre-delivery', () async {
    final detail = sampleOrderDetail(
      status: 'ACTIVE',
      fulfillmentStatus: 'READY',
    );
    final orders = FakeOrdersClient()
      ..details[detail.id] = detail
      ..delivery = null;
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('track:a'),
        ordersApiProvider.overrideWithValue(orders),
      ],
    );
    addTearDown(container.dispose);

    container.listen(orderTrackingControllerProvider(detail.id), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    final state = container.read(orderTrackingControllerProvider(detail.id));
    expect(state.order?.id, detail.id);
    expect(state.deliveryNotFound, isTrue);
    expect(state.stage, OrderTrackingStage.readyAwaitingDelivery);
    expect(orders.trackingCount, 0);
  });

  test('cancelled order is terminal without inventing delivery search', () async {
    final detail = sampleOrderDetail(status: 'CANCELLED');
    final orders = FakeOrdersClient()
      ..details[detail.id] = detail
      ..delivery = null;
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('track:b'),
        ordersApiProvider.overrideWithValue(orders),
      ],
    );
    addTearDown(container.dispose);

    container.listen(orderTrackingControllerProvider(detail.id), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 30));

    final state = container.read(orderTrackingControllerProvider(detail.id));
    expect(state.stage, OrderTrackingStage.cancelled);
    expect(orderTrackingStageIsTerminal(state.stage), isTrue);
  });

  testWidgets('cancelled tracking UI shows cancelled copy', (tester) async {
    final detail = sampleOrderDetail(status: 'CANCELLED');
    final orders = FakeOrdersClient()..details[detail.id] = detail;
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('track:ui'),
        ordersApiProvider.overrideWithValue(orders),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: OrderTrackingScreen(orderId: detail.id),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(AppStrings.orderStatusCancelled), findsWidgets);
    expect(find.text(AppStrings.trackingCancelledBody), findsOneWidget);
    expect(find.text(AppStrings.trackingCompletedTitle), findsNothing);
    expect(find.byKey(const Key('tracking-reference')), findsOneWidget);
    expect(find.text('#${detail.publicReference}'), findsOneWidget);
    expect(find.text(detail.publicReference), findsNothing);
  });

  test('ORDER_NOT_FOUND on delivery surfaces error', () async {
    final detail = sampleOrderDetail();
    final orders = FakeOrdersClient(
      deliveryError: const ApiException(
        'Cette commande est introuvable.',
        code: 'ORDER_NOT_FOUND',
        statusCode: 404,
      ),
    )..details[detail.id] = detail;
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('track:d'),
        ordersApiProvider.overrideWithValue(orders),
      ],
    );
    addTearDown(container.dispose);

    container.listen(orderTrackingControllerProvider(detail.id), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 30));
    final state = container.read(orderTrackingControllerProvider(detail.id));
    expect(state.errorMessage, isNotNull);
  });

  testWidgets('waiting merchant keeps one hashed public reference', (
    tester,
  ) async {
    final detail = sampleOrderDetail();
    final orders = FakeOrdersClient()
      ..details[detail.id] = detail
      ..delivery = null;
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('track:wait'),
        ordersApiProvider.overrideWithValue(orders),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: OrderTrackingScreen(orderId: detail.id),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(AppStrings.trackingAwaitingMerchantTitle), findsOneWidget);
    expect(find.byKey(const Key('tracking-reference')), findsOneWidget);
    expect(find.text('#${detail.publicReference}'), findsOneWidget);
    expect(find.text(detail.publicReference), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
    container.dispose();
    await tester.pump();
  });

  test('searching stage loads tracking snapshot when delivery exists', () async {
    final detail = sampleOrderDetail(
      status: 'ACTIVE',
      fulfillmentStatus: 'READY',
    );
    final delivery = sampleDelivery(status: 'SEARCHING_DRIVER');
    final orders = FakeOrdersClient(
      trackingResult: TrackingSnapshot(
        deliveryId: delivery.id,
        orderId: detail.id,
        driverAssigned: false,
        status: 'NO_DRIVER',
        isStale: false,
      ),
    )
      ..details[detail.id] = detail
      ..delivery = delivery;
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('track:e'),
        ordersApiProvider.overrideWithValue(orders),
      ],
    );
    addTearDown(container.dispose);

    container.listen(orderTrackingControllerProvider(detail.id), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(const Duration(milliseconds: 40));
    final state = container.read(orderTrackingControllerProvider(detail.id));
    expect(state.stage, OrderTrackingStage.searchingDriver);
    expect(state.tracking?.status, 'NO_DRIVER');
    expect(orders.trackingCount, greaterThan(0));
  });

  test('disconnect reconnect resubscribes, resume refreshes, dispose closes socket', () async {
    final detail = sampleOrderDetail(
      status: 'ACTIVE',
      fulfillmentStatus: 'READY',
    );
    final delivery = sampleDelivery(status: 'SEARCHING_DRIVER');
    final snapshot = TrackingSnapshot(
      deliveryId: delivery.id,
      orderId: detail.id,
      driverAssigned: false,
      status: 'NO_DRIVER',
      isStale: false,
    );
    final socket = FakeTrackingSocketClient(subscribeSnapshot: snapshot);
    final orders = FakeOrdersClient(trackingResult: snapshot)
      ..details[detail.id] = detail
      ..delivery = delivery;
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('track:socket'),
        ordersApiProvider.overrideWithValue(orders),
        trackingSocketFactoryProvider.overrideWithValue((_) => socket),
      ],
    );

    container.listen(orderTrackingControllerProvider(detail.id), (_, _) {});
    container.read(orderTrackingControllerProvider(detail.id));
    for (var i = 0; i < 40 && socket.subscribeCount == 0; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 20));
    }
    final loaded = container.read(orderTrackingControllerProvider(detail.id));
    expect(loaded.order?.id, detail.id, reason: loaded.errorMessage);
    expect(loaded.stage, OrderTrackingStage.searchingDriver);
    expect(
      container.read(trackingSocketFactoryProvider)(() async => 'x'),
      same(socket),
    );
    expect(socket.subscribeCount, 1);
    expect(
      container.read(orderTrackingControllerProvider(detail.id)).socketConnected,
      isTrue,
    );

    socket.simulateDisconnect();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(
      container.read(orderTrackingControllerProvider(detail.id)).socketConnected,
      isFalse,
    );

    await socket.simulateReconnect();
    await Future<void>.delayed(const Duration(milliseconds: 20));
    expect(socket.subscribeCount, 2);
    expect(socket.subscribed, everyElement(detail.id));
    expect(
      container.read(orderTrackingControllerProvider(detail.id)).socketConnected,
      isTrue,
    );

    final getsBeforeResume = orders.getCount;
    container.read(orderTrackingControllerProvider(detail.id).notifier).onAppResumed();
    await Future<void>.delayed(const Duration(milliseconds: 40));
    expect(orders.getCount, greaterThan(getsBeforeResume));

    container.dispose();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(socket.disposeCount, 1);
    expect(socket.disconnectCount, greaterThan(0));
  });

  testWidgets('every timeline step is reachable by scrolling on SE and Pro', (
    tester,
  ) async {
    Future<void> pumpAt(Size logical, double dpr) async {
      tester.view.physicalSize = logical * dpr;
      tester.view.devicePixelRatio = dpr;
      tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
      final detail = sampleOrderDetail();
      final orders = FakeOrdersClient()
        ..details[detail.id] = detail
        ..delivery = null;
      final container = ProviderContainer(
        overrides: [
          catalogScopeProvider.overrideWithValue('track:scroll:${logical.width}'),
          ordersApiProvider.overrideWithValue(orders),
        ],
      );
      addTearDown(container.dispose);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPadding);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: OrderTrackingScreen(orderId: detail.id),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(find.byKey(const Key('tracking-timeline')), findsOneWidget);
      final list = find.byKey(const Key('tracking-overview-list'));
      expect(list, findsOneWidget);
      final sticky = find.byKey(const Key('tracking-sticky-actions'));
      expect(sticky, findsOneWidget);
      final listRect = tester.getRect(list);
      for (var i = 0; i < 5; i++) {
        final step = find.byKey(Key('tracking-timeline-step-$i'));
        expect(step, findsOneWidget);
        await Scrollable.ensureVisible(
          tester.element(step),
          alignment: 0.2,
          duration: Duration.zero,
        );
        await tester.pump();
        final box = tester.getRect(step);
        expect(
          box.top,
          greaterThanOrEqualTo(listRect.top - 0.5),
          reason: 'step $i scrolled above the list viewport',
        );
        expect(
          box.bottom,
          lessThanOrEqualTo(listRect.bottom + 0.5),
          reason: 'step $i must sit in the list, above sticky actions',
        );
        expect(box.bottom, lessThanOrEqualTo(tester.getRect(sticky).top + 0.5));
      }
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      container.dispose();
      await tester.pump(const Duration(milliseconds: 1));
    }

    await pumpAt(const Size(375, 667), 2);
    await pumpAt(const Size(402, 874), 3);
  });
}
