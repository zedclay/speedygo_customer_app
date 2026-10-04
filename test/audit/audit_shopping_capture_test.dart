import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/features/addresses/presentation/address_picker_screen.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/cart/data/cart_models.dart';
import 'package:speedygo_customer_app/features/cart/presentation/cart_screen.dart';
import 'package:speedygo_customer_app/features/cart/presentation/product_configure_screen.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/product_detail_screen.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/search_screen.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/storefront_detail_screen.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/storefront_list_screen.dart';
import 'package:speedygo_customer_app/features/checkout/data/checkout_models.dart';
import 'package:speedygo_customer_app/features/checkout/presentation/checkout_review_screen.dart';
import 'package:speedygo_customer_app/features/home/presentation/commerce_vertical_presentation.dart';
import 'package:speedygo_customer_app/features/home/presentation/commerce_verticals_screen.dart';
import 'package:speedygo_customer_app/features/home/presentation/home_screen.dart';
import 'package:speedygo_customer_app/features/notifications/data/notification_models.dart';
import 'package:speedygo_customer_app/features/promotions/data/promotion_models.dart';
import 'package:speedygo_customer_app/features/ratings/data/rating_models.dart';

import '../features/customer_navigation_test.dart';
import '../helpers/catalog_fixtures.dart';
import '../helpers/fakes.dart';
import '../helpers/notification_support_fakes.dart';
import '../helpers/order_fixtures.dart';

final _capture = Platform.environment['AUDIT_CAPTURE'] == '1';

const _restaurantsVerticalId = '11111111-1111-4111-8111-111111111111';
const _productImagePath =
    '/customer/catalog/product-images/bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb';
const _cafeBranchName = 'Café Central — Didouche Mourad';
const _productName = 'Croissant au beurre';
const _productDescription =
    'Viennoiserie au beurre, feuilletage doré, servie tiède.';
const _keyboardInsetPx = 280.0;
const _seSuffix = 'se-375x667';
const _proSuffix = 'iphone17pro-402x874';

Uint8List _productPhotoBytes() =>
    File('test/audit/fixtures/product-photo.jpg').readAsBytesSync();

CatalogProduct _shoppingProduct() {
  return const CatalogProduct(
    productId: espressoProductId,
    branchId: cafeBranchId,
    categoryId: drinksCategoryId,
    name: _productName,
    description: _productDescription,
    priceMinor: '1200',
    imageUrl: _productImagePath,
  );
}

CatalogProductDetail _shoppingProductDetail({
  List<CatalogOptionGroup> optionGroups = const [
    CatalogOptionGroup(
      optionGroupId: 'eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee',
      name: 'Taille',
      required: true,
      minSelections: 1,
      maxSelections: 1,
      options: [
        CatalogProductOption(
          optionId: sizeNormalId,
          name: 'Simple',
          additionalPriceMinor: '0',
          available: true,
        ),
        CatalogProductOption(
          optionId: sizeDoubleId,
          name: 'Double',
          additionalPriceMinor: '200',
          available: true,
        ),
      ],
    ),
    CatalogOptionGroup(
      optionGroupId: extraGroupId,
      name: 'Suppléments',
      required: false,
      minSelections: 0,
      maxSelections: 2,
      options: [
        CatalogProductOption(
          optionId: extraSyrupId,
          name: 'Sirop',
          additionalPriceMinor: '100',
          available: true,
        ),
      ],
    ),
  ],
}) {
  return CatalogProductDetail(
    productId: espressoProductId,
    branchId: cafeBranchId,
    categoryId: drinksCategoryId,
    name: _productName,
    description: _productDescription,
    priceMinor: '1200',
    imageUrl: _productImagePath,
    optionGroups: optionGroups,
  );
}

FakeCartProduct _shoppingCartOffer() {
  return const FakeCartProduct(
    productId: espressoProductId,
    branchId: cafeBranchId,
    merchantId: merchantId,
    name: _productName,
    priceMinor: '1200',
    options: {
      sizeNormalId: FakeCartOption(
        optionId: sizeNormalId,
        name: 'Simple',
        additionalPriceMinor: '0',
      ),
      sizeDoubleId: FakeCartOption(
        optionId: sizeDoubleId,
        name: 'Double',
        additionalPriceMinor: '200',
      ),
      extraSyrupId: FakeCartOption(
        optionId: extraSyrupId,
        name: 'Sirop',
        additionalPriceMinor: '100',
      ),
    },
  );
}

CartItem _shoppingCheckoutItem() {
  return const CartItem(
    id: checkoutItemId,
    productId: espressoProductId,
    productName: _productName,
    quantity: 1,
    baseUnitPriceMinor: '1200',
    optionUnitAdditionalMinor: '200',
    unitPriceMinor: '1400',
    lineSubtotalMinor: '1400',
    storedUnitPriceMinor: '1400',
    itemAvailable: true,
    selectedOptions: [
      CartSelectedOption(
        optionId: sizeDoubleId,
        name: 'Double',
        additionalPriceMinor: '200',
        available: true,
      ),
    ],
    warnings: [],
  );
}

StorefrontDetail _shoppingStorefrontDetail(StorefrontSummary cafe) {
  return StorefrontDetail(
    branchId: cafe.branchId,
    branchName: cafe.branchName,
    addressText: cafe.addressText,
    latitude: cafe.latitude,
    longitude: cafe.longitude,
    merchantId: cafe.merchantId,
    merchantName: cafe.merchantName,
    merchantPublicReference: cafe.merchantPublicReference,
    hours: cafe.hours,
    coverImageUrl: cafe.coverImageUrl,
    days: const [
      OpeningDay(
        dayOfWeek: 1,
        intervals: [
          OpeningInterval(
            opens: '08:00',
            closes: '18:00',
            opensMinute: 480,
            closesMinute: 1080,
            closesNextDay: false,
          ),
        ],
      ),
    ],
  );
}

CustomerCart _shoppingCheckoutCart() {
  return CustomerCart(
    id: checkoutCartId,
    status: 'ACTIVE',
    branchId: cafeBranchId,
    merchantId: merchantId,
    itemCount: 1,
    cartSubtotalMinor: '1400',
    cartReady: true,
    warnings: const [],
    items: [_shoppingCheckoutItem()],
    createdAt: '2026-09-09T00:00:00.000Z',
    updatedAt: '2026-09-09T00:00:00.000Z',
  );
}

CheckoutPreview _shoppingCheckoutPreview() {
  final base = espressoCheckoutPreview(
    merchandiseSubtotalMinor: '1400',
    deliveryFeeMinor: '500',
    customerTotalMinor: '1900',
  );
  return CheckoutPreview(
    checkoutReady: base.checkoutReady,
    warnings: base.warnings,
    cart: CheckoutCartSummary(
      id: checkoutCartId,
      branchId: cafeBranchId,
      merchantId: merchantId,
      itemCount: 1,
      merchandiseSubtotalMinor: '1400',
      items: [_shoppingCheckoutItem()],
    ),
    address: base.address,
    deliveryZone: base.deliveryZone,
    pricing: base.pricing,
    merchandiseSubtotalMinor: base.merchandiseSubtotalMinor,
    deliveryFeeMinor: base.deliveryFeeMinor,
    discountMinor: base.discountMinor,
    promoCode: base.promoCode,
    customerTotalMinor: base.customerTotalMinor,
  );
}

Widget shoppingReadyApp({
  CatalogProductDetail? productDetail,
}) {
  final photo = _productPhotoBytes();
  final cafe = cafeStorefront(
    branchName: _cafeBranchName,
    coverImageUrl: _productImagePath,
    hours: StorefrontHours(
      hoursConfigured: true,
      isOpenNow: true,
      timezone: 'Africa/Algiers',
      currentClosesAt: DateTime.utc(2026, 9, 12, 22, 30),
    ),
  );
  final product = _shoppingProduct();
  final detail = productDetail ?? _shoppingProductDetail();

  final auth = FakeAuthClient()
    ..meResult = const AuthMe(
      accountId: 'acc-1',
      phone: '+213550123456',
      status: 'ACTIVE',
      hasCustomerProfile: true,
    );
  final customer = FakeCustomerClient()
    ..meResult = const CustomerMe(
      customerProfileExists: true,
      profileComplete: true,
      addressReady: true,
      profile: CustomerProfile(id: 'p', fullName: 'Amel Benali'),
      addresses: [checkoutHomeAddress, checkoutWorkAddress],
      defaultAddressId: checkoutHomeAddressId,
    );
  final orders = FakeOrdersClient(
    orders: orderPage([sampleOrder()]),
  )..details[activeOrderId] = sampleOrderDetail();

  return readyApp(
      coverImageBytes: (path) async {
        expect(path, startsWith('/customer/'));
        return photo;
      },
      auth: auth,
      customer: customer,
      catalog: FakeCatalogClient(
        verticals: const [
          CommerceVertical(
            id: _restaurantsVerticalId,
            slug: 'restaurants',
            name: 'Restaurants',
            iconKey: 'restaurant',
            sortOrder: 0,
          ),
          CommerceVertical(
            id: '22222222-2222-4222-8222-222222222222',
            slug: 'bakeries',
            name: 'Boulangeries',
            iconKey: 'bakery_dining',
            sortOrder: 1,
          ),
          CommerceVertical(
            id: '33333333-3333-4333-8333-333333333333',
            slug: 'groceries',
            name: 'Épiceries',
            iconKey: 'local_mall',
            sortOrder: 2,
          ),
          CommerceVertical(
            id: '44444444-4444-4444-8444-444444444444',
            slug: 'pharmacies',
            name: 'Pharmacies',
            iconKey: 'medical_services',
            sortOrder: 3,
          ),
          CommerceVertical(
            id: '55555555-5555-4555-8555-555555555555',
            slug: 'desserts',
            name: 'Desserts',
            iconKey: 'icecream',
            sortOrder: 4,
          ),
        ],
        storefronts: CatalogPage(
          items: [cafe],
          limit: 50,
          offset: 0,
          total: 1,
        ),
        storefrontDetail: _shoppingStorefrontDetail(cafe),
        categories: const [
          CatalogCategory(
            categoryId: drinksCategoryId,
            name: 'Boissons',
            sortOrder: 0,
          ),
        ],
        products: CatalogPage(
          items: [product],
          limit: 50,
          offset: 0,
          total: 1,
        ),
        productDetail: detail,
        searchHits: CatalogPage(
          items: [
            CatalogSearchHit.storefront(cafe),
            CatalogSearchHit.product(product: product, storefront: cafe),
          ],
          limit: 50,
          offset: 0,
          total: 2,
        ),
      ),
      promotions: FakePromotionsClient(
        items: const [
          DiscoverablePromotion(
            id: 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaa9',
            code: 'DEMO150',
            discountKind: PromotionDiscountKind.fixedMinor,
            value: 15000,
            startsAt: '2020-01-01T00:00:00.000Z',
            endsAt: '2099-01-01T00:00:00.000Z',
            customerLabel: 'Offre Spéciale',
          ),
        ],
      ),
      ratings: FakeRatingsClient(
        summaries: {
          merchantId: const RatingSummary(
            targetType: 'MERCHANT',
            targetId: merchantId,
            count: 42,
            average: 4.7,
          ),
        },
      ),
      cart: FakeCartClient()
        ..products = {espressoProductId: _shoppingCartOffer()}
        ..bootstrap = CartBootstrap(
          cartExists: true,
          cart: _shoppingCheckoutCart(),
        ),
      checkout: FakeCheckoutClient(result: _shoppingCheckoutPreview()),
      addresses: FakeAddressClient(
        addresses: const [checkoutHomeAddress, checkoutWorkAddress],
      ),
      orders: orders,
      notifications: FakeNotificationsClient(
        seed: const [
          NotificationItem(
            id: 'n-order',
            type: 'ORDER_ACCEPTED',
            sourceId: activeOrderId,
            title: 'Commande acceptée',
            body: 'Le commerçant a accepté votre commande.',
            read: false,
            createdAt: '2026-09-10T00:00:00.000Z',
          ),
        ],
      ),
    );
}

Future<void> _sizeSe(WidgetTester tester) async {
  tester.view.physicalSize = const Size(750, 1334);
  tester.view.devicePixelRatio = 2;
  tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
}

Future<void> _sizeIphone17Pro(WidgetTester tester) async {
  tester.view.physicalSize = const Size(1206, 2622);
  tester.view.devicePixelRatio = 3;
  tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPadding);
}

Future<void> _settle(WidgetTester tester, {int pumps = 40}) async {
  for (var i = 0; i < pumps; i++) {
    await tester.pump(const Duration(milliseconds: 50));
  }
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _clear(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _waitFor(WidgetTester tester, Finder finder, {int pumps = 40}) async {
  for (var i = 0; i < pumps; i++) {
    if (tester.any(finder)) {
      return;
    }
    await tester.pump(const Duration(milliseconds: 50));
  }
  expect(finder, findsOneWidget);
}

Future<void> _assertClean(WidgetTester tester) async {
  final error = tester.takeException();
  expect(error, isNull, reason: 'Unexpected Flutter exception: $error');
}

Future<void> _assertNoLoading(WidgetTester tester) async {
  expect(
    find.byType(CircularProgressIndicator),
    findsNothing,
    reason: 'CircularProgressIndicator still visible after settle',
  );
}

Future<void> _shot(WidgetTester tester, String name) async {
  await _assertClean(tester);
  await _assertNoLoading(tester);
  await expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('../../audit/visuals/alignment/flutter/$name.png'),
  );
}

Future<void> _precacheRestaurantsHero(WidgetTester tester) async {
  if (!tester.any(find.byType(MaterialApp))) {
    return;
  }
  final host = find.byType(MaterialApp);
  await tester.runAsync(() async {
    await precacheImage(
      const AssetImage(restaurantsHeroAsset),
      tester.element(host),
    );
  });
  await tester.pump();
}

Future<void> _assertDecodedImage(WidgetTester tester, Finder finder) async {
  expect(finder, findsOneWidget);
  final image = tester.widget<Image>(finder);
  await tester.runAsync(() async {
    final completer = Completer<ImageInfo>();
    final stream = image.image.resolve(ImageConfiguration.empty);
    late final ImageStreamListener listener;
    listener = ImageStreamListener(
      (info, _) {
        if (!completer.isCompleted) {
          completer.complete(info);
        }
        stream.removeListener(listener);
      },
      onError: (error, _) {
        if (!completer.isCompleted) {
          completer.completeError(error);
        }
      },
    );
    stream.addListener(listener);
    final info = await completer.future.timeout(const Duration(seconds: 8));
    expect(info.image.width, greaterThan(8));
    expect(info.image.height, greaterThan(8));
  });
  await tester.pump();
  RenderImage? raster;
  void visit(RenderObject node) {
    if (raster != null) {
      return;
    }
    if (node is RenderImage) {
      raster = node;
      return;
    }
    node.visitChildren(visit);
  }

  visit(tester.renderObject(finder));
  expect(raster, isNotNull, reason: 'decoded Image has no RenderImage');
  expect(raster!.image, isNotNull);
  expect(raster!.size.width, greaterThan(8));
  expect(raster!.size.height, greaterThan(8));
}

Future<void> _tap(WidgetTester tester, Finder finder) async {
  expect(finder, findsWidgets);
  await tester.tap(finder.first);
  await _settle(tester, pumps: 20);
}

Future<void> _precacheProductPhoto(WidgetTester tester) async {
  final photo = _productPhotoBytes();
  expect(photo.lengthInBytes, greaterThan(20000));
  if (!tester.any(find.byType(MaterialApp))) {
    return;
  }
  final host = find.byType(MaterialApp);
  await tester.runAsync(() async {
    await precacheImage(MemoryImage(photo), tester.element(host));
  });
  await tester.pumpAndSettle();
}

Future<void> _pumpShopping(
  WidgetTester tester, {
  CatalogProductDetail? productDetail,
}) async {
  await tester.pumpWidget(shoppingReadyApp(productDetail: productDetail));
  await _settle(tester, pumps: 80);
  expect(find.byType(HomeScreen), findsOneWidget);
  final router = GoRouter.of(tester.element(find.byType(HomeScreen)));
  expect(router.state.uri.path, AppRoutes.home);
}

Future<void> _capturePlainProductDetail(
  WidgetTester tester,
  String suffix,
) async {
  await _pumpShopping(
    tester,
    productDetail: _shoppingProductDetail(optionGroups: const []),
  );

  await _tap(tester, find.text(AppStrings.seeAll));
  await _tap(tester, find.text('Restaurants'));
  await _tap(tester, find.text(_cafeBranchName));
  await _precacheProductPhoto(tester);
  await _tap(tester, find.text(_productName));
  await _settle(tester);
  expect(find.byType(ProductDetailScreen), findsOneWidget);
  expect(find.byKey(const Key('product-customize-card')), findsNothing);
  expect(find.byKey(const Key('add-to-cart-button')), findsOneWidget);
  expect(find.byKey(const Key('customize-product-button')), findsNothing);
  await _precacheProductPhoto(tester);
  await _shot(tester, 'product-detail-plain-ready-$suffix');
}

Future<void> _captureCatalogJourney(
  WidgetTester tester,
  String suffix,
) async {
  await _pumpShopping(tester);
  if (tester.any(find.byType(MaterialApp))) {
    final host = find.byType(MaterialApp);
    await tester.runAsync(() async {
      await precacheImage(
        const AssetImage('assets/branding/speedygo_logo.png'),
        tester.element(host),
      );
    });
    await tester.pump();
  }
  await _assertDecodedImage(tester, find.byKey(const Key('home-logo')));
  await _precacheProductPhoto(tester);
  await _waitFor(tester, find.byKey(const Key('authenticated-cover-image')));
  expect(find.byKey(const Key('catalog-image-loading')), findsNothing);
  await _assertDecodedImage(
    tester,
    find.byKey(const Key('authenticated-cover-image')),
  );
  expect(find.text('DEMO150'), findsOneWidget);
  final homeScroll = find.descendant(
    of: find.byType(HomeScreen),
    matching: find.byType(Scrollable),
  );
  if (tester.any(homeScroll)) {
    tester.state<ScrollableState>(homeScroll.first).position.jumpTo(0);
    await tester.pump();
  }
  await _settle(tester, pumps: 12);
  await _shot(tester, 'home-ready-$suffix');

  await _tap(tester, find.text(AppStrings.seeAll));
  expect(find.byType(CommerceVerticalsScreen), findsOneWidget);
  expect(
    GoRouter.of(tester.element(find.byType(CommerceVerticalsScreen)))
        .state
        .uri
        .path,
    AppRoutes.homeCategories,
  );
  expect(find.text(AppStrings.categoriesExploreHeading), findsOneWidget);
  expect(find.text('Épiceries'), findsOneWidget);
  expect(find.text('Pharmacies'), findsOneWidget);
  expect(find.text('Desserts'), findsOneWidget);
  await _precacheRestaurantsHero(tester);
  await _settle(tester);
  await _assertDecodedImage(
    tester,
    find.byKey(const Key('categories-restaurants-hero-image')),
  );
  await _shot(tester, 'categories-ready-$suffix');

  await _tap(tester, find.text('Restaurants'));
  expect(find.byType(StorefrontListScreen), findsOneWidget);
  expect(find.text(_cafeBranchName), findsOneWidget);
  await _precacheProductPhoto(tester);
  await _shot(tester, 'category-results-ready-$suffix');

  await _tap(tester, find.text(_cafeBranchName));
  expect(find.byType(StorefrontDetailScreen), findsOneWidget);
  expect(find.text(_productName), findsOneWidget);
  await _precacheProductPhoto(tester);
  await _shot(tester, 'storefront-ready-$suffix');

  await _tap(tester, find.text(_productName));
  await _settle(tester);
  expect(find.byType(ProductDetailScreen), findsOneWidget);
  expect(find.byTooltip(AppStrings.back), findsWidgets);
  expect(find.text(AppStrings.productDescriptionHeading), findsOneWidget);
  expect(find.byKey(const Key('product-customize-card')), findsOneWidget);
  expect(find.byKey(const Key('customize-product-button')), findsOneWidget);
  await _precacheProductPhoto(tester);
  await _shot(tester, 'product-detail-ready-$suffix');

  await _tap(tester, find.byKey(const Key('customize-product-button')));
  expect(find.byType(ProductConfigureScreen), findsOneWidget);
  expect(find.byTooltip(AppStrings.back), findsWidgets);
  expect(find.text('Double'), findsWidgets);
  expect(
    tester
        .widget<FilledButton>(find.byKey(const Key('add-to-cart-button')))
        .onPressed,
    isNull,
  );
  await _precacheProductPhoto(tester);
  await _shot(tester, 'product-options-unselected-$suffix');

  await _tap(tester, find.byKey(const Key('option-$sizeDoubleId')));
  expect(
    tester
        .widget<FilledButton>(find.byKey(const Key('add-to-cart-button')))
        .onPressed,
    isNotNull,
  );
  await _precacheProductPhoto(tester);
  await _shot(tester, 'product-options-ready-$suffix');
  await _shot(tester, 'product-options-selected-$suffix');
}

Future<void> _captureSearchJourney(WidgetTester tester, String suffix) async {
  await _pumpShopping(tester);

  await _tap(tester, find.byIcon(Icons.search_outlined));
  expect(find.byType(SearchScreen), findsOneWidget);
  await tester.enterText(find.byType(TextField), 'cr');
  await tester.pump();
  await _settle(tester, pumps: 30);
  expect(find.text(_cafeBranchName), findsWidgets);
  expect(find.text(_productName), findsWidgets);
  await _precacheProductPhoto(tester);
  await _shot(tester, 'search-results-ready-$suffix');
}

Future<void> _captureCheckoutJourney(
  WidgetTester tester,
  String suffix,
) async {
  await _pumpShopping(tester);

  GoRouter.of(tester.element(find.byType(HomeScreen))).push(AppRoutes.cart);
  await _settle(tester);
  expect(find.byType(CartScreen), findsOneWidget);
  expect(find.text(_productName), findsWidgets);
  expect(find.textContaining('Double'), findsWidgets);
  await _precacheProductPhoto(tester);
  await _shot(tester, 'cart-ready-$suffix');

  await _tap(tester, find.byKey(const Key('checkout-review-cta')));
  expect(find.byType(CheckoutReviewScreen), findsOneWidget);
  expect(find.text(AppStrings.checkoutReviewTitle), findsOneWidget);
  expect(find.byKey(const Key('checkout-sticky-total')), findsOneWidget);
  expect(find.byKey(const Key('checkout-totals')), findsOneWidget);
  await _precacheProductPhoto(tester);
  // Sticky payable stays visible; frame top of review (items + address).
  await tester.ensureVisible(find.text(_productName).first);
  await _settle(tester, pumps: 10);
  await _shot(tester, 'checkout-review-ready-$suffix');

  await tester.ensureVisible(find.byKey(const Key('checkout-promo-field')));
  await _settle(tester, pumps: 10);
  expect(find.byKey(const Key('checkout-sticky-total')), findsOneWidget);
  await _shot(tester, 'checkout-review-scrolled-$suffix');

  await tester.ensureVisible(find.byKey(const Key('checkout-address-card')));
  await _settle(tester, pumps: 10);
  await _tap(tester, find.byKey(const Key('checkout-address-card')));
  expect(find.byType(AddressPickerScreen), findsOneWidget);
  expect(find.text(checkoutHomeAddress.label), findsOneWidget);
  expect(find.text(checkoutWorkAddress.label), findsOneWidget);
  await _shot(tester, 'checkout-address-ready-$suffix');
}

void main() {
  testWidgets('shopping catalog journey SE', (tester) async {
    await _sizeSe(tester);
    await _captureCatalogJourney(tester, _seSuffix);
    await _clear(tester);
  }, skip: !_capture);

  testWidgets('shopping search SE', (tester) async {
    await _sizeSe(tester);
    await _captureSearchJourney(tester, _seSuffix);
    await _clear(tester);
  }, skip: !_capture);

  testWidgets('shopping checkout SE', (tester) async {
    await _sizeSe(tester);
    await _captureCheckoutJourney(tester, _seSuffix);
    await _clear(tester);
  }, skip: !_capture);

  testWidgets('shopping catalog journey iPhone 17 Pro', (tester) async {
    await _sizeIphone17Pro(tester);
    await _captureCatalogJourney(tester, _proSuffix);
    await _clear(tester);
  }, skip: !_capture);

  testWidgets('shopping search iPhone 17 Pro', (tester) async {
    await _sizeIphone17Pro(tester);
    await _captureSearchJourney(tester, _proSuffix);
    await _clear(tester);
  }, skip: !_capture);

  testWidgets('shopping checkout iPhone 17 Pro', (tester) async {
    await _sizeIphone17Pro(tester);
    await _captureCheckoutJourney(tester, _proSuffix);
    await _clear(tester);
  }, skip: !_capture);

  testWidgets('shopping product detail plain add-to-cart SE', (tester) async {
    await _sizeSe(tester);
    await _capturePlainProductDetail(tester, _seSuffix);
    await _clear(tester);
  }, skip: !_capture);

  testWidgets('shopping product detail plain add-to-cart iPhone 17 Pro', (
    tester,
  ) async {
    await _sizeIphone17Pro(tester);
    await _capturePlainProductDetail(tester, _proSuffix);
    await _clear(tester);
  }, skip: !_capture);

  testWidgets('shopping dense SE text 1.3', (tester) async {
    await _sizeSe(tester);
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await _pumpShopping(tester);
    if (tester.any(find.byType(MaterialApp))) {
      final host = find.byType(MaterialApp);
      await tester.runAsync(() async {
        await precacheImage(
          const AssetImage('assets/branding/speedygo_logo.png'),
          tester.element(host),
        );
      });
      await tester.pump();
    }
    await _assertDecodedImage(tester, find.byKey(const Key('home-logo')));
    await _shot(tester, 'home-ready-$_seSuffix-text-1.3');

    await _tap(tester, find.text(AppStrings.seeAll));
    expect(find.byType(CommerceVerticalsScreen), findsOneWidget);
    await _precacheRestaurantsHero(tester);
    await _assertDecodedImage(
      tester,
      find.byKey(const Key('categories-restaurants-hero-image')),
    );
    await _shot(tester, 'categories-ready-$_seSuffix-text-1.3');

    var router = GoRouter.of(
      tester.element(find.byType(CommerceVerticalsScreen)),
    );
    router.go(AppRoutes.home);
    await _settle(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    router.push(AppRoutes.productInBranch(cafeBranchId, espressoProductId));
    await _settle(tester);
    expect(find.byKey(const Key('customize-product-button')), findsOneWidget);
    expect(find.text(AppStrings.customizeProduct), findsWidgets);
    await _shot(tester, 'product-detail-ready-$_seSuffix-text-1.3');

    router = GoRouter.of(tester.element(find.byType(ProductDetailScreen)));
    router.go(AppRoutes.home);
    await _settle(tester);
    expect(find.byType(HomeScreen), findsOneWidget);
    router.push(AppRoutes.cart);
    await _settle(tester);
    expect(find.byType(CartScreen), findsOneWidget);
    await _precacheProductPhoto(tester);
    await _shot(tester, 'cart-ready-$_seSuffix-text-1.3');

    await _tap(tester, find.byKey(const Key('checkout-review-cta')));
    expect(find.byType(CheckoutReviewScreen), findsOneWidget);
    expect(find.byKey(const Key('checkout-sticky-total')), findsOneWidget);
    await _precacheProductPhoto(tester);
    await tester.ensureVisible(find.text(_productName).first);
    await _settle(tester, pumps: 10);
    await _shot(tester, 'checkout-review-ready-$_seSuffix-text-1.3');

    final promoField = find.byKey(const Key('checkout-promo-field'));
    await tester.ensureVisible(promoField);
    await tester.tap(promoField);
    await tester.showKeyboard(promoField);
    addTearDown(tester.view.resetViewInsets);
    final keyboardInsetPhysical =
        _keyboardInsetPx * tester.view.devicePixelRatio;
    tester.view.viewInsets = FakeViewPadding(
      left: 0,
      top: 0,
      right: 0,
      bottom: keyboardInsetPhysical,
    );
    await _settle(tester, pumps: 12);
    expect(
      MediaQuery.viewInsetsOf(
        tester.element(find.byType(CheckoutReviewScreen)),
      ).bottom,
      _keyboardInsetPx,
    );
    await _shot(tester, 'checkout-review-keyboard-$_seSuffix-text-1.3');
    await _clear(tester);
  }, skip: !_capture);
}
