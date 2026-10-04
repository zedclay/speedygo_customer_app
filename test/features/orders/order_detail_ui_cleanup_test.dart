import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/features/cart/data/cart_models.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/authenticated_cover_image.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';
import 'package:speedygo_customer_app/features/orders/presentation/order_detail_screen.dart';

import '../../helpers/catalog_fixtures.dart';
import '../../helpers/fakes.dart';
import '../../helpers/order_fixtures.dart';

/// Minimal valid 1×1 PNG so [AuthenticatedCatalogImage] can settle in tests.
final _tinyPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
  0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
  0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x05, 0xFE, 0xD4, 0xEF, 0x00, 0x00,
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  testWidgets('order detail AppBar uses Ma commande', (tester) async {
    final detail = sampleOrderDetail();
    final orders = FakeOrdersClient()..details[detail.id] = detail;
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('test:ui'),
        ordersApiProvider.overrideWithValue(orders),
        coverImageBytesProvider.overrideWith((ref, path) async => null),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: OrderDetailScreen(orderId: detail.id),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(AppStrings.orderDetailTitle), findsOneWidget);
    expect(find.text('Ma commande'), findsOneWidget);
    expect(find.textContaining('Détails de la commande'), findsNothing);
    expect(find.byKey(const Key('order-detail-support-entry')), findsOneWidget);
  });

  testWidgets(
    'order item uses authenticated product image path when productId present',
    (tester) async {
      final detail = sampleOrderDetail();
      final orders = FakeOrdersClient()..details[detail.id] = detail;
      final container = ProviderContainer(
        overrides: [
          catalogScopeProvider.overrideWithValue('test:ui'),
          ordersApiProvider.overrideWithValue(orders),
          coverImageBytesProvider.overrideWith((ref, path) async => _tinyPng),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: OrderDetailScreen(orderId: detail.id),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final expected = cartItemImageUrl(
        branchId: cafeBranchId,
        productId: espressoProductId,
      );
      expect(expected, isNotNull);
      expect(
        find.byKey(Key('order-detail-item-image-${detail.items.first.id}')),
        findsOneWidget,
      );
      expect(find.text('1x Espresso'), findsOneWidget);
      expect(find.textContaining('Double'), findsOneWidget);
    },
  );

  testWidgets(
    'order item falls back when productId is null (no invented photo)',
    (tester) async {
      final detail = OrderDetail(
        id: activeOrderId,
        publicReference: activeOrderReference,
        status: 'CREATED',
        fulfillmentStatus: 'PENDING_ACCEPTANCE',
        paymentMethod: 'COD',
        createdAt: '2026-09-09T21:00:00.000Z',
        merchantBranchId: cafeBranchId,
        financial: const OrderFinancial(
          currency: 'DZD',
          merchandiseSubtotalMinor: '1400',
          deliveryFeeMinor: '500',
          customerTotalMinor: '1900',
        ),
        items: const [
          OrderItemDetail(
            id: '33333333-3333-4333-8333-333333333333',
            productId: null,
            productNameSnapshot: 'Cornet 2 boules',
            quantity: 1,
            unitPriceMinor: '1400',
            lineTotalMinor: '1400',
            options: [],
          ),
        ],
        deliveryAddress: const OrderAddressSnapshot(
          addressText: 'Cité 120 logements',
          latitude: 36.75,
          longitude: 3.05,
        ),
      );
      final orders = FakeOrdersClient()..details[detail.id] = detail;
      final container = ProviderContainer(
        overrides: [
          catalogScopeProvider.overrideWithValue('test:ui'),
          ordersApiProvider.overrideWithValue(orders),
          coverImageBytesProvider.overrideWith((ref, path) async => null),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            home: OrderDetailScreen(orderId: detail.id),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.byKey(const Key('catalog-image-unbound')), findsOneWidget);
      expect(find.text('1x Cornet 2 boules'), findsOneWidget);
    },
  );

  testWidgets(
    'payment totals fully visible above sticky on SE and Pro at textScale 1.3',
    (tester) async {
      for (final size in const [Size(375, 667), Size(402, 874)]) {
        final detail = sampleOrderDetail();
        final orders = FakeOrdersClient()..details[detail.id] = detail;
        final container = ProviderContainer(
          overrides: [
            catalogScopeProvider.overrideWithValue('test:ui-$size'),
            ordersApiProvider.overrideWithValue(orders),
            coverImageBytesProvider.overrideWith((ref, path) async => null),
          ],
        );

        tester.view.physicalSize = size * 2;
        tester.view.devicePixelRatio = 2;
        tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
        tester.platformDispatcher.textScaleFactorTestValue = 1.3;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPadding);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(1.3),
                padding: const EdgeInsets.only(top: 47, bottom: 34),
              ),
              child: MaterialApp(
                theme: AppTheme.light,
                home: OrderDetailScreen(orderId: detail.id),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        final totals = find.byKey(const Key('order-detail-totals'));
        final sticky = find.byKey(const Key('order-detail-tracking-entry'));
        expect(totals, findsOneWidget);
        expect(sticky, findsOneWidget);

        final scrollable = find.byType(Scrollable).first;
        await tester.scrollUntilVisible(totals, 80, scrollable: scrollable);
        await tester.pump();

        final totalsBottom = tester.getBottomLeft(totals).dy;
        final stickyTop = tester.getTopLeft(sticky).dy;
        expect(
          totalsBottom,
          lessThanOrEqualTo(stickyTop + 1),
          reason: 'totals must clear sticky on ${size.width}@1.3',
        );

        expect(find.byKey(const Key('order-detail-payment')), findsOneWidget);
        final paymentBottom =
            tester.getBottomLeft(find.byKey(const Key('order-detail-payment'))).dy;
        expect(paymentBottom, lessThanOrEqualTo(stickyTop + 1));

        container.dispose();
      }
    },
  );
}
