import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/features/cart/application/cart_controller.dart';
import 'package:speedygo_customer_app/features/cart/data/cart_models.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';

import '../../helpers/catalog_fixtures.dart';
import '../../helpers/fakes.dart';

ProviderContainer _container(FakeCartClient cart, {String scope = '1:p'}) {
  return ProviderContainer(
    overrides: [
      catalogScopeProvider.overrideWithValue(scope),
      cartApiProvider.overrideWithValue(cart),
    ],
  );
}

AddCartItemRequest get _doubleShot => const AddCartItemRequest(
  productId: espressoProductId,
  quantity: 1,
  optionIds: [sizeDoubleId],
);

void main() {
  test('add/update/remove/clear keep server totals', () async {
    final api = FakeCartClient(
      products: {espressoProductId: espressoCartOffer()},
    );
    final container = _container(api);
    addTearDown(container.dispose);
    final cart = container.read(cartControllerProvider.notifier);
    await cart.refresh();
    expect(container.read(cartControllerProvider).cartExists, isFalse);

    expect(await cart.addItem(_doubleShot), isTrue);
    expect(
      container.read(cartControllerProvider).cart!.cartSubtotalMinor,
      '1400',
    );
    expect(container.read(cartControllerProvider).badgeCount, 1);

    final itemId = container.read(cartControllerProvider).cart!.items.single.id;
    await cart.updateQuantity(cartItemId: itemId, quantity: 2);
    expect(
      container.read(cartControllerProvider).cart!.cartSubtotalMinor,
      '2800',
    );

    await cart.removeItem(itemId);
    expect(container.read(cartControllerProvider).cartExists, isFalse);

    expect(await cart.addItem(_doubleShot), isTrue);
    await cart.clearCart();
    expect(container.read(cartControllerProvider).cartExists, isFalse);
    expect(api.clearCount, 1);
  });

  test('double tap does not start a second add', () async {
    final api = FakeCartClient(
      products: {espressoProductId: espressoCartOffer()},
    )..gateAdd = Completer<void>();
    final container = _container(api);
    addTearDown(container.dispose);
    final cart = container.read(cartControllerProvider.notifier);
    await cart.refresh();
    final first = cart.addItem(_doubleShot);
    final second = await cart.addItem(_doubleShot);
    expect(second, isFalse);
    expect(api.addCount, 1);
    api.gateAdd!.complete();
    expect(await first, isTrue);
    expect(api.addCount, 1);
    expect(
      container.read(cartControllerProvider).cart!.items.single.quantity,
      1,
    );
  });

  test('uncertain add reconciles with GET and does not retry POST', () async {
    final offer = espressoCartOffer();
    final seeded = FakeCartClient(products: {espressoProductId: offer});
    await seeded.addItem(_doubleShot);
    final api = FakeCartClient(products: {espressoProductId: offer})
      ..addError = const CartUncertainException();
    final container = _container(api);
    addTearDown(container.dispose);
    final cart = container.read(cartControllerProvider.notifier);
    await cart.refresh();
    api.bootstrap = seeded.bootstrap;
    expect(await cart.addItem(_doubleShot), isTrue);
    expect(api.addCount, 1);
    expect(api.getCount, greaterThanOrEqualTo(2));
    expect(
      container.read(cartControllerProvider).cart!.cartSubtotalMinor,
      '1400',
    );
  });

  test('uncertain add without matching line is not success', () async {
    final api = FakeCartClient(
      products: {espressoProductId: espressoCartOffer()},
    )..addError = const CartUncertainException();
    final container = _container(api);
    addTearDown(container.dispose);
    final cart = container.read(cartControllerProvider.notifier);
    await cart.refresh();
    expect(await cart.addItem(_doubleShot), isFalse);
    expect(api.addCount, 1);
    expect(container.read(cartControllerProvider).actionError, isNotNull);
  });

  test('cross-branch add keeps the existing cart', () async {
    final api = FakeCartClient(
      products: {
        espressoProductId: espressoCartOffer(),
        otherProductId: const FakeCartProduct(
          productId: otherProductId,
          branchId: otherBranchId,
          merchantId: merchantId,
          name: 'Other',
          priceMinor: '500',
        ),
      },
    );
    final container = _container(api);
    addTearDown(container.dispose);
    final cart = container.read(cartControllerProvider.notifier);
    await cart.refresh();
    expect(await cart.addItem(_doubleShot), isTrue);
    final subtotal = container
        .read(cartControllerProvider)
        .cart!
        .cartSubtotalMinor;
    expect(
      await cart.addItem(
        const AddCartItemRequest(productId: otherProductId, quantity: 1),
      ),
      isFalse,
    );
    expect(api.addCount, 2);
    expect(
      container.read(cartControllerProvider).cart!.cartSubtotalMinor,
      subtotal,
    );
    expect(container.read(cartControllerProvider).cart!.branchId, cafeBranchId);
  });

  test('late add from a disposed session does not fill another cart', () async {
    final aliceApi = FakeCartClient(
      products: {espressoProductId: espressoCartOffer()},
    )..gateAdd = Completer<void>();
    final alice = _container(aliceApi, scope: '1:alice');
    final aliceCart = alice.read(cartControllerProvider.notifier);
    await aliceCart.refresh();
    final pending = aliceCart.addItem(_doubleShot);

    final bobApi = FakeCartClient();
    final bob = _container(bobApi, scope: '2:bob');
    addTearDown(bob.dispose);
    await bob.read(cartControllerProvider.notifier).refresh();

    alice.dispose();
    aliceApi.gateAdd!.complete();
    expect(await pending, isFalse);
    expect(bob.read(cartControllerProvider).cartExists, isFalse);
  });
}
