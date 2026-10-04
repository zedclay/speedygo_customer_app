import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_active_order_card.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';
import 'package:speedygo_customer_app/features/ratings/data/rating_models.dart';

import '../../helpers/catalog_fixtures.dart';
import '../../helpers/fakes.dart';
import '../../helpers/order_fixtures.dart';
import '../customer_navigation_test.dart';

void main() {
  test('active-order wording uses fulfillment then delivery status', () {
    expect(
      activeOrderStatusLabel(fulfillmentStatus: 'PENDING_ACCEPTANCE'),
      AppStrings.orderStatusPendingAcceptance,
    );
    expect(
      activeOrderStatusLabel(
        fulfillmentStatus: 'READY',
        deliveryStatus: 'IN_TRANSIT',
      ),
      AppStrings.orderStatusInTransit,
    );
    expect(
      activeOrderStatusLabel(fulfillmentStatus: 'UNKNOWN'),
      AppStrings.activeOrder,
    );
    expect(
      activeOrderStatusLabel(
        fulfillmentStatus: 'READY',
        orderStatus: 'COMPLETED',
      ),
      AppStrings.orderStatusCompleted,
    );
    expect(
      activeOrderStatusLabel(
        fulfillmentStatus: 'READY',
        deliveryStatus: 'DELIVERED',
      ),
      AppStrings.orderStatusCompleted,
    );
    expect(isEligibleActiveOrder(status: 'CREATED'), isTrue);
    expect(isEligibleActiveOrder(status: 'COMPLETED'), isFalse);
    expect(
      isEligibleActiveOrder(status: 'ACTIVE', deliveryStatus: 'DELIVERED'),
      isFalse,
    );
  });

  testWidgets('live Home shows the default address label from me()', (
    tester,
  ) async {
    final customer = FakeCustomerClient()
      ..meResult = const CustomerMe(
        customerProfileExists: true,
        profileComplete: true,
        addressReady: true,
        profile: CustomerProfile(id: 'p', fullName: 'Amel Benali'),
        defaultAddressId: 'addr-home',
        addresses: [
          CustomerAddress(
            id: 'addr-home',
            label: 'Domicile',
            addressText: 'Cité 120 logements',
            isDefault: true,
          ),
        ],
      );
    await tester.pumpWidget(
      readyApp(
        customer: customer,
        catalog: FakeCatalogClient(
          storefronts: CatalogPage(
            items: [cafeStorefront()],
            limit: 50,
            offset: 0,
            total: 1,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Domicile'), findsOneWidget);
    expect(find.text(AppStrings.deliverToUnset), findsNothing);
    expect(find.text(AppStrings.previewAddress), findsNothing);
    expect(find.text(AppStrings.categories), findsNothing);
    expect(find.text(AppStrings.specialOffer), findsNothing);
    expect(find.text(AppStrings.promoCode), findsNothing);
  });

  testWidgets('active-order card appears only for an open order', (
    tester,
  ) async {
    await tester.pumpWidget(
      readyApp(
        catalog: FakeCatalogClient(
          storefronts: CatalogPage(
            items: [cafeStorefront()],
            limit: 50,
            offset: 0,
            total: 1,
          ),
        ),
        orders: FakeOrdersClient(
          orders: orderPage([
            sampleOrder(status: 'ACTIVE', fulfillmentStatus: 'PREPARING'),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomeActiveOrderCard), findsOneWidget);
    expect(find.text(AppStrings.activeOrder), findsOneWidget);
    expect(find.text(activeOrderReference), findsOneWidget);
    expect(find.text(AppStrings.orderStatusPreparing), findsOneWidget);
    expect(find.text(AppStrings.previewOrderNumber), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('completed orders do not show the Home card', (tester) async {
    await tester.pumpWidget(
      readyApp(
        catalog: FakeCatalogClient(
          storefronts: CatalogPage(
            items: [cafeStorefront()],
            limit: 50,
            offset: 0,
            total: 1,
          ),
        ),
        orders: FakeOrdersClient(
          orders: orderPage([
            sampleOrder(status: 'COMPLETED', fulfillmentStatus: 'READY'),
          ]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomeActiveOrderCard), findsNothing);
    expect(find.text(AppStrings.activeOrder), findsNothing);
  });

  testWidgets('delivery status replaces fulfillment wording', (tester) async {
    await tester.pumpWidget(
      readyApp(
        catalog: FakeCatalogClient(
          storefronts: CatalogPage(
            items: [cafeStorefront()],
            limit: 50,
            offset: 0,
            total: 1,
          ),
        ),
        orders: FakeOrdersClient(
          orders: orderPage([
            sampleOrder(status: 'ACTIVE', fulfillmentStatus: 'READY'),
          ]),
          delivery: sampleDelivery(status: 'IN_TRANSIT'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.orderStatusInTransit), findsOneWidget);
    expect(find.text(AppStrings.orderStatusReady), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
  });

  testWidgets('rating chip appears only for a real summary', (tester) async {
    final ratings = FakeRatingsClient(
      summaries: {merchantId: ratedSummary(average: 4.3)},
    );
    await tester.pumpWidget(
      readyApp(
        catalog: FakeCatalogClient(
          storefronts: CatalogPage(
            items: [cafeStorefront()],
            limit: 50,
            offset: 0,
            total: 1,
          ),
        ),
        ratings: ratings,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('4.3'), findsOneWidget);
    expect(ratings.batchCount, 1);
    expect(ratings.requestedIds, [merchantId]);
    expect(find.text(AppStrings.previewRating), findsNothing);
  });

  testWidgets('zero-count summaries do not invent a rating', (tester) async {
    await tester.pumpWidget(
      readyApp(
        catalog: FakeCatalogClient(
          storefronts: CatalogPage(
            items: [cafeStorefront()],
            limit: 50,
            offset: 0,
            total: 1,
          ),
        ),
        ratings: FakeRatingsClient(
          summaries: {
            merchantId: const RatingSummary(
              targetType: 'MERCHANT',
              targetId: merchantId,
              count: 0,
            ),
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('4.7'), findsNothing);
    expect(find.text('0.0'), findsNothing);
    expect(find.byIcon(Icons.star), findsNothing);
  });

  testWidgets('tapping the active-order card opens the order route', (
    tester,
  ) async {
    await tester.pumpWidget(
      readyApp(
        catalog: FakeCatalogClient(
          storefronts: CatalogPage(
            items: [cafeStorefront()],
            limit: 50,
            offset: 0,
            total: 1,
          ),
        ),
        orders: FakeOrdersClient(orders: orderPage([sampleOrder()])),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(HomeActiveOrderCard));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.trackingTitle), findsOneWidget);
  });
}
