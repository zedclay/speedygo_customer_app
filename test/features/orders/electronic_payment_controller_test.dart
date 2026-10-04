import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/config/electronic_payment_config.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/orders/application/electronic_payment_controller.dart';
import 'package:speedygo_customer_app/features/checkout/application/electronic_payment_availability.dart';
import 'package:speedygo_customer_app/features/orders/data/payment_models.dart';
import 'package:speedygo_customer_app/features/orders/presentation/order_payment_screen.dart';

import '../../helpers/fakes.dart';
import '../../helpers/order_fixtures.dart';

CustomerPayment _payment({
  String status = 'PENDING',
  String method = 'ELECTRONIC',
}) {
  return CustomerPayment(
    paymentId: 'pay-1',
    method: method,
    status: status,
    amountMinor: '1700',
    currency: 'DZD',
    provider: 'test',
    createdAt: '2026-09-10T00:00:00.000Z',
    updatedAt: '2026-09-10T00:00:00.000Z',
  );
}

CustomerPaymentInitiate _initiate({
  String status = 'PROCESSING',
  String? checkoutUrl = 'https://pay.chargily.net/test/checkouts/chk_1/pay',
  String attemptId = 'attempt-1',
}) {
  return CustomerPaymentInitiate(
    paymentId: 'pay-1',
    method: 'ELECTRONIC',
    status: status,
    amountMinor: '1700',
    currency: 'DZD',
    provider: 'chargily',
    createdAt: '2026-09-10T00:00:00.000Z',
    updatedAt: '2026-09-10T00:00:01.000Z',
    attemptId: attemptId,
    checkoutUrl: checkoutUrl,
  );
}

ProviderContainer _container({
  required FakeOrdersClient orders,
  ElectronicPaymentAvailability availability = const ElectronicPaymentAvailability(
    enabledForCheckout: true,
  ),
}) {
  final container = ProviderContainer(
    overrides: [
      ordersApiProvider.overrideWithValue(orders),
      electronicPaymentAvailabilityProvider.overrideWithValue(availability),
    ],
  );
  return container;
}

void main() {
  test('payment models parse initiate without inventing expiry', () {
    final json = {
      'paymentId': 'p1',
      'method': 'ELECTRONIC',
      'status': 'PROCESSING',
      'amountMinor': '1700',
      'currency': 'DZD',
      'provider': 'test',
      'createdAt': '2026-09-10T00:00:00.000Z',
      'updatedAt': '2026-09-10T00:00:01.000Z',
      'attemptId': 'a1',
      'checkoutUrl': 'test://checkout/ref',
    };
    final initiate = CustomerPaymentInitiate.fromJson(json);
    expect(initiate.attemptId, 'a1');
    expect(initiate.isTestCheckoutUrl, isTrue);
  });

  test('normal mode rejects http, unapproved host, and test://', () {
    const availability = ElectronicPaymentAvailability.disabled;
    expect(
      evaluateCheckoutUrl('http://pay.chargily.net/x', availability),
      CheckoutUrlDecision.rejectHttp,
    );
    expect(
      evaluateCheckoutUrl('https://evil.example/pay', availability),
      CheckoutUrlDecision.rejectUnapprovedHost,
    );
    expect(
      evaluateCheckoutUrl('test://checkout/abc', availability),
      CheckoutUrlDecision.rejectTestScheme,
    );
    expect(
      evaluateCheckoutUrl(
        'https://pay.chargily.net/test/checkouts/1/pay',
        const ElectronicPaymentAvailability(enabledForCheckout: true),
      ),
      CheckoutUrlDecision.openHttps,
    );
  });

  test('test:// acknowledged only when allowTestCheckoutUrls', () {
    expect(
      evaluateCheckoutUrl(
        'test://checkout/abc',
        const ElectronicPaymentAvailability(
          enabledForCheckout: true,
          allowTestCheckoutUrls: true,
        ),
      ),
      CheckoutUrlDecision.acknowledgeTestScheme,
    );
    expect(
      checkoutUrlIsLaunchable(CheckoutUrlDecision.acknowledgeTestScheme),
      isFalse,
    );
  });

  test('duplicate initiate reuses same attempt id from backend response', () async {
    final detail = sampleOrderDetail(paymentMethod: 'ELECTRONIC');
    final orders = FakeOrdersClient()
      ..details[detail.id] = detail
      ..paymentResult = _payment()
      ..initiateResult = _initiate(attemptId: 'attempt-reuse');

    final container = _container(orders: orders);
    addTearDown(container.dispose);
    container.listen(electronicPaymentControllerProvider(detail.id), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    final notifier =
        container.read(electronicPaymentControllerProvider(detail.id).notifier);
    await notifier.initiateAndOpenCheckout();
    await notifier.initiateAndOpenCheckout();
    expect(orders.initiateCount, 2);
    expect(
      container.read(electronicPaymentControllerProvider(detail.id)).attemptId,
      'attempt-reuse',
    );
  });

  test('overlapping initiate is ignored while in flight', () async {
    final detail = sampleOrderDetail(paymentMethod: 'ELECTRONIC');
    final gate = Completer<void>();
    final orders = FakeOrdersClient()
      ..details[detail.id] = detail
      ..paymentResult = _payment()
      ..initiateResult = _initiate()
      ..gateInitiate = gate;

    final container = _container(orders: orders);
    addTearDown(container.dispose);
    container.listen(electronicPaymentControllerProvider(detail.id), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    final notifier =
        container.read(electronicPaymentControllerProvider(detail.id).notifier);
    final first = notifier.initiateAndOpenCheckout();
    final second = notifier.initiateAndOpenCheckout();
    gate.complete();
    await Future.wait([first, second]);
    expect(orders.initiateCount, 1);
  });

  test('uncertain initiate does not create a second order', () async {
    final detail = sampleOrderDetail(paymentMethod: 'ELECTRONIC');
    final orders = FakeOrdersClient()
      ..details[detail.id] = detail
      ..paymentResult = _payment()
      ..initiateError = const ApiException(
        'uncertain',
        code: 'PAYMENT_INITIATE_SERVER_UNCERTAIN',
        statusCode: 503,
      );

    final container = _container(orders: orders);
    addTearDown(container.dispose);
    container.listen(electronicPaymentControllerProvider(detail.id), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    await container
        .read(electronicPaymentControllerProvider(detail.id).notifier)
        .initiateAndOpenCheckout();
    expect(orders.createCount, 0);
    expect(orders.initiateCount, 1);
    final state = container.read(electronicPaymentControllerProvider(detail.id));
    expect(state.phase, ElectronicPaymentPhase.polling);
  });

  test('browser return hint keeps payment pending until server SUCCEEDED', () async {
    final detail = sampleOrderDetail(paymentMethod: 'ELECTRONIC');
    final orders = FakeOrdersClient()
      ..details[detail.id] = detail
      ..paymentResult = _payment(status: 'PROCESSING');

    final container = _container(orders: orders);
    addTearDown(container.dispose);
    container.listen(electronicPaymentControllerProvider(detail.id), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    container
        .read(electronicPaymentControllerProvider(detail.id).notifier)
        .onAppResumed();
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final state = container.read(electronicPaymentControllerProvider(detail.id));
    expect(state.browserReturnHint, isTrue);
    expect(state.phase, isNot(ElectronicPaymentPhase.succeeded));
    expect(state.payment?.status, 'PROCESSING');
  });

  test('server SUCCEEDED maps to succeeded phase', () async {
    final detail = sampleOrderDetail(paymentMethod: 'ELECTRONIC');
    final orders = FakeOrdersClient()
      ..details[detail.id] = detail
      ..paymentResult = _payment(status: 'SUCCEEDED');

    final container = _container(orders: orders);
    addTearDown(container.dispose);
    container.listen(electronicPaymentControllerProvider(detail.id), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    final state = container.read(electronicPaymentControllerProvider(detail.id));
    expect(state.phase, ElectronicPaymentPhase.succeeded);
  });

  test('failed payment stays failed and canInitiate allows retry path', () {
    final payment = _payment(status: 'FAILED');
    expect(payment.isTerminal, isTrue);
    expect(payment.canInitiate, isTrue);
  });

  test('existing electronic order remains readable when checkout disabled', () async {
    final detail = sampleOrderDetail(paymentMethod: 'ELECTRONIC');
    final orders = FakeOrdersClient()
      ..details[detail.id] = detail
      ..paymentResult = _payment(status: 'PROCESSING');

    final container = _container(
      orders: orders,
      availability: ElectronicPaymentAvailability.disabled,
    );
    addTearDown(container.dispose);
    container.listen(electronicPaymentControllerProvider(detail.id), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    final state = container.read(electronicPaymentControllerProvider(detail.id));
    expect(state.payment?.status, 'PROCESSING');
    expect(orders.paymentCount, greaterThan(0));
    await container
        .read(electronicPaymentControllerProvider(detail.id).notifier)
        .initiateAndOpenCheckout();
    expect(orders.initiateCount, 0);
    expect(
      container.read(electronicPaymentControllerProvider(detail.id)).errorCode,
      'PAYMENT_INITIATE_DISABLED',
    );
  });

  test('enabled mocked chargily https checkout is accepted by policy', () {
    final decision = evaluateCheckoutUrl(
      'https://pay.chargily.net/test/checkouts/chk_1/pay',
      const ElectronicPaymentAvailability(enabledForCheckout: true),
    );
    expect(decision, CheckoutUrlDecision.openHttps);
    expect(checkoutUrlIsLaunchable(decision), isTrue);
  });

  testWidgets('payment screen shows pending copy for PROCESSING', (tester) async {
    final detail = sampleOrderDetail(paymentMethod: 'ELECTRONIC');
    final orders = FakeOrdersClient()
      ..details[detail.id] = detail
      ..paymentResult = _payment(status: 'PROCESSING');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ordersApiProvider.overrideWithValue(orders),
          electronicPaymentAvailabilityProvider.overrideWithValue(
            const ElectronicPaymentAvailability(enabledForCheckout: true),
          ),
        ],
        child: MaterialApp(home: OrderPaymentScreen(orderId: detail.id)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.paymentPendingTitle), findsOneWidget);
    expect(find.text(AppStrings.paymentStatusProcessing), findsOneWidget);
    expect(find.text(AppStrings.paymentSucceededTitle), findsNothing);
  });
}
