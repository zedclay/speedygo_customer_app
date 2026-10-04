import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/features/cart/data/cart_models.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';

import '../../helpers/catalog_fixtures.dart';
import '../../helpers/fakes.dart';
import '../customer_navigation_test.dart';

void main() {
  testWidgets('configure add cart quantity update and remove', (tester) async {
    final cart = FakeCartClient(
      products: {espressoProductId: espressoCartOffer()},
    );
    final catalog = FakeCatalogClient(
      storefronts: CatalogPage(
        items: [cafeStorefront()],
        limit: 50,
        offset: 0,
        total: 1,
      ),
      storefrontDetail: cafeStorefrontDetail(),
      categories: const [
        CatalogCategory(
          categoryId: drinksCategoryId,
          name: 'Boissons',
          sortOrder: 1,
        ),
      ],
      products: CatalogPage(
        items: [espresso()],
        limit: 50,
        offset: 0,
        total: 1,
      ),
      productDetail: espressoDetail(),
    );
    await tester.pumpWidget(readyApp(catalog: catalog, cart: cart));
    await tester.pumpAndSettle();

    final cafeCard = find.byKey(const ValueKey(cafeBranchId));
    await tester.ensureVisible(cafeCard);
    await tester.pumpAndSettle();
    await tester.tap(cafeCard);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Espresso'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('customize-product-button')), findsOneWidget);
    await tester.tap(find.byKey(const Key('customize-product-button')));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('add-to-cart-button')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('option-$sizeDoubleId')));
    await tester.pump();
    expect(
      tester
          .widget<FilledButton>(find.byKey(const Key('add-to-cart-button')))
          .onPressed,
      isNotNull,
    );
    expect(find.text(MoneyFormat.dzd('1400')), findsWidgets);

    await tester.tap(find.byKey(const Key('add-to-cart-button')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.cartAdded), findsOneWidget);
    expect(cart.addCount, 1);
    expect(cart.adds.single.optionIds, [sizeDoubleId]);

    await tester.tap(find.text(AppStrings.viewCart));
    await tester.pumpAndSettle();
    expect(find.text('Espresso'), findsWidgets);
    expect(find.text(MoneyFormat.dzd('1400')), findsWidgets);
    expect(find.text(AppStrings.cartMerchandiseSubtotal), findsOneWidget);
    expect(find.text(AppStrings.cartSubtotalHint), findsWidgets);
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, AppStrings.checkoutAction),
          )
          .onPressed,
      isNotNull,
    );

    final qtyPlus = find.descendant(
      of: find.byKey(Key('cart-qty-${cart.bootstrap!.cart!.items.single.id}')),
      matching: find.byTooltip('Augmenter la quantité'),
    );
    await tester.tap(qtyPlus);
    await tester.pumpAndSettle();
    expect(cart.updateCount, 1);
    expect(find.text(MoneyFormat.dzd('2800')), findsWidgets);

    await tester.tap(
      find.byKey(
        Key('remove-cart-item-${cart.bootstrap!.cart!.items.single.id}'),
      ),
    );
    await tester.pumpAndSettle();
    expect(cart.removeCount, 1);
    expect(find.text(AppStrings.cartEmpty), findsOneWidget);

    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.customizeTitle), findsOneWidget);
    await tester.tap(find.byTooltip(AppStrings.back));
    await tester.pumpAndSettle();
    expect(find.text('Espresso'), findsWidgets);
  });

  testWidgets('cross-branch conflict keeps cart and does not clear', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final other = espresso(productId: otherProductId, branchId: otherBranchId);
    final cart = FakeCartClient(
      products: {
        espressoProductId: espressoCartOffer(),
        otherProductId: const FakeCartProduct(
          productId: otherProductId,
          branchId: otherBranchId,
          merchantId: merchantId,
          name: 'Other espresso',
          priceMinor: '900',
        ),
      },
    );
    await cart.addItem(
      const AddCartItemRequest(
        productId: espressoProductId,
        quantity: 1,
        optionIds: [sizeDoubleId],
      ),
    );
    final catalog = FakeCatalogClient(
      storefronts: CatalogPage(
        items: [
          cafeStorefront(),
          cafeStorefront(branchId: otherBranchId, branchName: 'Autre Cafe'),
        ],
        limit: 50,
        offset: 0,
        total: 2,
      ),
      products: CatalogPage(items: [other], limit: 50, offset: 0, total: 1),
      productDetail: espressoDetail(
        productId: otherProductId,
        branchId: otherBranchId,
        priceMinor: '900',
      ),
    );
    await tester.pumpWidget(readyApp(catalog: catalog, cart: cart));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Autre Cafe'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.text('Autre Cafe'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Autre Cafe').hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Espresso'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('customize-product-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('option-$sizeNormalId')));
    await tester.pump();
    await tester.tap(find.byKey(const Key('add-to-cart-button')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.cartBranchConflict), findsWidgets);
    expect(cart.bootstrap!.cart!.branchId, cafeBranchId);
    expect(cart.bootstrap!.cart!.items, hasLength(1));
    await tester.tap(find.text(AppStrings.cartKeepExisting));
    await tester.pumpAndSettle();
    expect(cart.clearCount, 0);
  });
}
