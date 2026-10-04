import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/orders/application/order_detail_controller.dart';
import 'package:speedygo_customer_app/features/ratings/application/order_rating_controller.dart';
import 'package:speedygo_customer_app/features/ratings/application/rating_providers.dart';
import 'package:speedygo_customer_app/features/ratings/data/rating_api.dart';
import 'package:speedygo_customer_app/features/ratings/data/rating_models.dart';
import 'package:speedygo_customer_app/features/ratings/presentation/order_rate_screen.dart';

import '../../helpers/order_fixtures.dart';

class FakeOrderRatingsClient implements RatingsClient {
  OrderRating? merchant;
  OrderRating? driver;
  Object? merchantCreateError;
  Object? driverCreateError = const ApiException(
    'driver unavailable',
    code: 'RATING_INVALID_STATE',
    statusCode: 409,
  );
  int merchantCreateCount = 0;
  int driverCreateCount = 0;
  CreateRatingRequest? lastMerchantRequest;
  CreateRatingRequest? lastDriverRequest;
  Duration? createDelay;

  @override
  Future<OrderRating?> getOwnDriverRating(String orderId) async => driver;

  @override
  Future<OrderRating?> getOwnMerchantRating(String orderId) async => merchant;

  @override
  Future<RatingSummary> merchantSummary(String merchantId) async {
    return RatingSummary(
      targetType: 'MERCHANT',
      targetId: merchantId,
      count: 0,
    );
  }

  @override
  Future<List<RatingSummary>> merchantSummaries(
    List<String> merchantIds,
  ) async {
    return [for (final id in merchantIds) await merchantSummary(id)];
  }

  @override
  Future<OrderRating> rateDriver(
    String orderId,
    CreateRatingRequest request,
  ) async {
    driverCreateCount += 1;
    lastDriverRequest = request;
    if (driverCreateError != null) {
      throw driverCreateError!;
    }
    driver = OrderRating(
      id: 'driver-rating-1',
      orderId: orderId,
      targetType: 'DRIVER',
      targetId: 'driver-1',
      score: request.score,
      comment: null,
      createdAt: '2026-09-10T00:00:00.000Z',
    );
    return driver!;
  }

  @override
  Future<OrderRating> rateMerchant(
    String orderId,
    CreateRatingRequest request,
  ) async {
    merchantCreateCount += 1;
    lastMerchantRequest = request;
    if (createDelay != null) {
      await Future<void>.delayed(createDelay!);
    }
    if (merchantCreateError != null) {
      throw merchantCreateError!;
    }
    merchant = OrderRating(
      id: 'merchant-rating-1',
      orderId: orderId,
      targetType: 'MERCHANT',
      targetId: 'merchant-1',
      score: request.score,
      comment: request.comment,
      createdAt: '2026-09-10T00:00:00.000Z',
    );
    return merchant!;
  }
}

ProviderContainer ratingContainer(
  FakeOrderRatingsClient ratings, {
  String status = 'COMPLETED',
}) {
  return ProviderContainer(
    overrides: [
      catalogScopeProvider.overrideWithValue('scope-a'),
      ratingsApiProvider.overrideWithValue(ratings),
      orderDetailControllerProvider('order-1').overrideWith(
        (ref) async => sampleOrderDetail(id: 'order-1', status: status),
      ),
    ],
  );
}

void main() {
  test('payload maps score and optional comment only', () {
    expect(
      const CreateRatingRequest(score: 5, comment: '  Hello  ').toJson(),
      {'score': 5, 'comment': 'Hello'},
    );
    expect(const CreateRatingRequest(score: 4).toJson(), {'score': 4});
  });

  test('score and comment validation', () {
    expect(isValidRatingScore(0), isFalse);
    expect(isValidRatingScore(5), isTrue);
    expect(isValidRatingComment('x' * 2001), isFalse);
  });

  test('ineligible order is not writable', () async {
    final ratings = FakeOrderRatingsClient();
    final container = ratingContainer(ratings, status: 'CANCELLED');
    addTearDown(container.dispose);
    container.listen(orderRatingControllerProvider('order-1'), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(orderRatingControllerProvider('order-1')).phase,
      OrderRatingPhase.ineligible,
    );
  });

  test('double submit ignored while in flight', () async {
    final ratings = FakeOrderRatingsClient()
      ..createDelay = const Duration(milliseconds: 40);
    final container = ratingContainer(ratings);
    addTearDown(container.dispose);
    container.listen(orderRatingControllerProvider('order-1'), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    final notifier =
        container.read(orderRatingControllerProvider('order-1').notifier);
    notifier.setMerchantScore(5);
    await Future.wait([notifier.submit(), notifier.submit()]);
    expect(ratings.merchantCreateCount, 1);
  });

  test('uncertain write keeps draft and does not auto-retry', () async {
    final ratings = FakeOrderRatingsClient()
      ..merchantCreateError = const ApiException(
        'uncertain',
        code: 'RATING_MERCHANT_UNCERTAIN',
        statusCode: 503,
      );
    final container = ratingContainer(ratings);
    addTearDown(container.dispose);
    container.listen(orderRatingControllerProvider('order-1'), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    final notifier =
        container.read(orderRatingControllerProvider('order-1').notifier);
    notifier.setMerchantScore(4);
    notifier.setComment('Keep me');
    await notifier.submit();
    expect(ratings.merchantCreateCount, 1);
    expect(
      container.read(orderRatingControllerProvider('order-1')).phase,
      OrderRatingPhase.pendingVerification,
    );
    expect(
      container.read(orderRatingControllerProvider('order-1')).comment,
      'Keep me',
    );
    await notifier.submit();
    expect(ratings.merchantCreateCount, 1);
  });

  test('already-rated state loads existing scores', () async {
    final ratings = FakeOrderRatingsClient()
      ..merchant = const OrderRating(
        id: 'm1',
        orderId: 'order-1',
        targetType: 'MERCHANT',
        targetId: 'merchant-1',
        score: 5,
        comment: 'Great',
        createdAt: '2026-09-10T00:00:00.000Z',
      );
    final container = ratingContainer(ratings);
    addTearDown(container.dispose);
    container.listen(orderRatingControllerProvider('order-1'), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(
      container.read(orderRatingControllerProvider('order-1')).merchantNeedsWrite,
      isFalse,
    );
  });

  test('duplicate create reconciles via own-read', () async {
    final ratings = FakeOrderRatingsClient()
      ..merchantCreateError = const ApiException(
        'exists',
        code: 'RATING_ALREADY_EXISTS',
        statusCode: 409,
      );
    final container = ratingContainer(ratings);
    addTearDown(container.dispose);
    container.listen(orderRatingControllerProvider('order-1'), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    final notifier =
        container.read(orderRatingControllerProvider('order-1').notifier);
    notifier.setMerchantScore(5);
    ratings.merchant = const OrderRating(
      id: 'm1',
      orderId: 'order-1',
      targetType: 'MERCHANT',
      targetId: 'merchant-1',
      score: 5,
      comment: null,
      createdAt: '2026-09-10T00:00:00.000Z',
    );
    expect(await notifier.submit(), isTrue);
  });

  test('catalog scope clears rating draft on rebuild', () async {
    final ratings = FakeOrderRatingsClient();
    final a = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('scope-a'),
        ratingsApiProvider.overrideWithValue(ratings),
        orderDetailControllerProvider('order-1').overrideWith(
          (ref) async => sampleOrderDetail(id: 'order-1', status: 'COMPLETED'),
        ),
      ],
    );
    addTearDown(a.dispose);
    a.listen(orderRatingControllerProvider('order-1'), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    a.read(orderRatingControllerProvider('order-1').notifier).setMerchantScore(3);
    expect(a.read(orderRatingControllerProvider('order-1')).merchantScore, 3);

    final b = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('scope-b'),
        ratingsApiProvider.overrideWithValue(ratings),
        orderDetailControllerProvider('order-1').overrideWith(
          (ref) async => sampleOrderDetail(id: 'order-1', status: 'COMPLETED'),
        ),
      ],
    );
    addTearDown(b.dispose);
    b.listen(orderRatingControllerProvider('order-1'), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(b.read(orderRatingControllerProvider('order-1')).merchantScore, isNull);
  });

  testWidgets('stars submit confirmation gestures', (tester) async {
    final ratings = FakeOrderRatingsClient();
    final detail = sampleOrderDetail(status: 'COMPLETED');
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          catalogScopeProvider.overrideWithValue('scope-ui'),
          ratingsApiProvider.overrideWithValue(ratings),
          orderDetailControllerProvider(detail.id).overrideWith(
            (ref) async => detail,
          ),
          storefrontDetailProvider(detail.merchantBranchId).overrideWith(
            (ref) async {
              throw const ApiException('skip storefront', code: 'SKIP');
            },
          ),
        ],
        child: MaterialApp(home: OrderRateScreen(orderId: detail.id)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('rating-star-5')).first);
    await tester.pump();
    await tester.tap(find.byKey(const Key('rating-submit-scores')));
    await tester.pumpAndSettle();
    expect(ratings.merchantCreateCount, 1);
    expect(ratings.lastMerchantRequest?.score, 5);
    expect(find.textContaining('Merci'), findsWidgets);
  });

  test('write-review comment is included in merchant payload', () async {
    final ratings = FakeOrderRatingsClient();
    final container = ratingContainer(ratings);
    addTearDown(container.dispose);
    container.listen(orderRatingControllerProvider('order-1'), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    final notifier =
        container.read(orderRatingControllerProvider('order-1').notifier);
    notifier.setMerchantScore(5);
    notifier.setComment('Test rating Revue');
    expect(await notifier.submit(), isTrue);
    expect(ratings.merchantCreateCount, 1);
    expect(ratings.lastMerchantRequest?.comment, 'Test rating Revue');
    expect(
      container.read(orderRatingControllerProvider('order-1')).phase,
      OrderRatingPhase.succeeded,
    );
  });

  test(
    'partial success keeps merchant and retries only driver',
    () async {
      final ratings = FakeOrderRatingsClient()
        ..driverCreateError = const ApiException(
          'driver failed',
          code: 'RATING_DRIVER_FAILED',
          statusCode: 500,
        );
      final container = ratingContainer(ratings);
      addTearDown(container.dispose);
      container.listen(orderRatingControllerProvider('order-1'), (_, _) {});
      await Future<void>.delayed(Duration.zero);
      final notifier =
          container.read(orderRatingControllerProvider('order-1').notifier);
      notifier.setMerchantScore(5);
      notifier.setDriverScore(4);
      expect(await notifier.submit(), isTrue);
      expect(ratings.merchantCreateCount, 1);
      expect(ratings.driverCreateCount, 1);
      final after = container.read(orderRatingControllerProvider('order-1'));
      expect(after.merchantConfirmed, isTrue);
      expect(after.merchantStatus, RatingTargetStatus.confirmed);
      expect(after.driverStatus, RatingTargetStatus.failed);
      expect(after.phase, OrderRatingPhase.ready);
      expect(after.canSubmitMerchant, isFalse);
      expect(after.canSubmitDriver, isTrue);

      ratings.driverCreateError = null;
      expect(await notifier.submit(), isTrue);
      expect(ratings.merchantCreateCount, 1, reason: 'never resend merchant');
      expect(ratings.driverCreateCount, 2);
      final done = container.read(orderRatingControllerProvider('order-1'));
      expect(done.driverConfirmed, isTrue);
      expect(done.phase, OrderRatingPhase.succeeded);
    },
  );
}
