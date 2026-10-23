import 'dart:async';

import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/addresses/data/address_api.dart';
import 'package:speedygo_customer_app/features/addresses/data/address_models.dart';
import 'package:speedygo_customer_app/features/addresses/data/location_client.dart';
import 'package:speedygo_customer_app/features/auth/data/auth_api.dart';
import 'package:speedygo_customer_app/features/auth/data/customer_api.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';
import 'package:speedygo_customer_app/features/cart/data/cart_api.dart';
import 'package:speedygo_customer_app/features/cart/data/cart_models.dart';
import 'package:speedygo_customer_app/features/checkout/data/checkout_api.dart';
import 'package:speedygo_customer_app/features/checkout/data/checkout_models.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_api.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/orders/data/order_api.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';
import 'package:speedygo_customer_app/features/orders/data/payment_models.dart';
import 'package:speedygo_customer_app/features/orders/data/tracking_models.dart';
import 'package:speedygo_customer_app/features/orders/data/tracking_socket.dart';
import 'package:speedygo_customer_app/features/promotions/data/promotion_api.dart';
import 'package:speedygo_customer_app/features/promotions/data/promotion_models.dart';
import 'package:speedygo_customer_app/features/ratings/data/rating_api.dart';
import 'package:speedygo_customer_app/features/ratings/data/rating_models.dart';

class FakeAuthClient implements AuthClient {
  FakeAuthClient();

  TokenPair pair = const TokenPair(
    accessToken: 'access-1',
    refreshToken: 'refresh-1-token-value',
    expiresIn: 900,
    tokenType: 'Bearer',
  );

  TokenPair rotated = const TokenPair(
    accessToken: 'access-2',
    refreshToken: 'refresh-2-token-value',
    expiresIn: 900,
    tokenType: 'Bearer',
  );

  int requestCount = 0;
  int verifyCount = 0;
  int refreshCount = 0;
  int logoutCount = 0;
  int meCount = 0;
  final presentedRefreshTokens = <String>[];
  String? lastIdentifier;
  String? lastCode;
  Object? requestError;
  Object? verifyError;
  Object? refreshError;
  Object? logoutError;
  Object? meError;
  Duration? meDelay;
  Duration? refreshDelay;
  AuthMe meResult = const AuthMe(
    accountId: 'acc-1',
    phone: '+213550123456',
    status: 'ACTIVE',
    hasCustomerProfile: false,
  );

  @override
  Future<void> requestOtp(String identifier) async {
    requestCount += 1;
    lastIdentifier = identifier;
    if (requestError != null) {
      throw requestError!;
    }
  }

  @override
  Future<TokenPair> verifyOtp(OtpVerifyBody body) async {
    verifyCount += 1;
    lastIdentifier = body.identifier;
    lastCode = body.code;
    if (verifyError != null) {
      throw verifyError!;
    }
    return pair;
  }

  @override
  Future<TokenPair> refresh(String refreshToken) async {
    presentedRefreshTokens.add(refreshToken);
    refreshCount += 1;
    if (refreshDelay != null) {
      await Future<void>.delayed(refreshDelay!);
    }
    if (refreshError != null) {
      throw refreshError!;
    }
    return rotated;
  }

  @override
  Future<void> logout() async {
    logoutCount += 1;
    if (logoutError != null) {
      throw logoutError!;
    }
  }

  @override
  Future<void> logoutWithAccessToken(String accessToken) async {
    logoutCount += 1;
    if (logoutError != null) {
      throw logoutError!;
    }
  }

  @override
  Future<AuthMe> me() async {
    meCount += 1;
    if (meDelay != null) {
      await Future<void>.delayed(meDelay!);
    }
    if (meError != null) {
      throw meError!;
    }
    return meResult;
  }

  List<AuthSession> sessions = const [];
  int listSessionsCount = 0;
  int revokeSessionCount = 0;
  int logoutAllCount = 0;
  Object? listSessionsError;
  Object? revokeSessionError;
  Object? logoutAllError;
  final revokedSessionIds = <String>[];

  @override
  Future<List<AuthSession>> listSessions() async {
    listSessionsCount += 1;
    if (listSessionsError != null) {
      throw listSessionsError!;
    }
    return List.of(sessions);
  }

  @override
  Future<void> revokeSession(String sessionId) async {
    revokeSessionCount += 1;
    if (revokeSessionError != null) {
      throw revokeSessionError!;
    }
    revokedSessionIds.add(sessionId);
    sessions = [
      for (final s in sessions)
        if (s.id == sessionId)
          AuthSession(
            id: s.id,
            deviceId: s.deviceId,
            platform: s.platform,
            deviceName: s.deviceName,
            createdAt: s.createdAt,
            expiresAt: s.expiresAt,
            revoked: true,
            currentSession: s.currentSession,
          )
        else
          s,
    ];
  }

  @override
  Future<void> logoutAll() async {
    logoutAllCount += 1;
    if (logoutAllError != null) {
      throw logoutAllError!;
    }
    sessions = [
      for (final s in sessions)
        AuthSession(
          id: s.id,
          deviceId: s.deviceId,
          platform: s.platform,
          deviceName: s.deviceName,
          createdAt: s.createdAt,
          expiresAt: s.expiresAt,
          revoked: true,
          currentSession: s.currentSession,
        ),
    ];
  }
}

class FakeCustomerClient implements CustomerClient {
  int meCount = 0;
  int createCount = 0;
  String? lastFullName;
  Object? meError;
  Object? createError;
  CustomerMe meResult = const CustomerMe(
    customerProfileExists: false,
    profileComplete: false,
    addressReady: false,
  );

  @override
  Future<CustomerMe> me() async {
    meCount += 1;
    if (meError != null) {
      throw meError!;
    }
    return meResult;
  }

  @override
  Future<CustomerProfile> createProfile({required String fullName}) async {
    createCount += 1;
    lastFullName = fullName;
    if (createError != null) {
      throw createError!;
    }
    meResult = CustomerMe(
      customerProfileExists: true,
      profileComplete: true,
      addressReady: false,
      profile: CustomerProfile(id: 'p1', fullName: fullName),
    );
    return CustomerProfile(id: 'p1', fullName: fullName);
  }
}

class FakeCatalogClient implements CatalogClient {
  FakeCatalogClient({
    this.storefronts = const CatalogPage(
      items: [],
      limit: 50,
      offset: 0,
      total: 0,
    ),
    this.searchHits = const CatalogPage(
      items: [],
      limit: 50,
      offset: 0,
      total: 0,
    ),
    this.verticals = const [],
    this.categories = const [],
    this.products = const CatalogPage(
      items: [],
      limit: 50,
      offset: 0,
      total: 0,
    ),
    this.storefrontDetail,
    this.productDetail,
    this.listError,
    this.searchError,
    this.searchDelay,
    this.searchResultFor,
    this.testPageCap,
    this.loadMoreError,
    this.duplicateFirstOnLoadMore = false,
    this.listDelay,
  });

  CatalogPage<StorefrontSummary> storefronts;
  CatalogPage<CatalogSearchHit> searchHits;
  List<CommerceVertical> verticals;
  List<CatalogCategory> categories;
  CatalogPage<CatalogProduct> products;
  StorefrontDetail? storefrontDetail;
  CatalogProductDetail? productDetail;
  Object? listError;
  Object? searchError;
  Object? detailError;
  Object? productError;
  Duration? searchDelay;
  CatalogPage<CatalogSearchHit> Function(String q)? searchResultFor;
  int? testPageCap;
  Object? loadMoreError;
  bool duplicateFirstOnLoadMore;
  Duration? listDelay;
  Completer<void>? gateList;
  int listCount = 0;
  CatalogQuery? lastStorefrontQuery;
  int searchCount = 0;
  int productListCount = 0;
  int getProductCount = 0;
  String? lastSearchQ;

  CatalogPage<T> _slice<T>(List<T> all, int total, CatalogQuery query) {
    final params = query.toParams();
    final limit = params['limit'] as int;
    final offset = params['offset'] as int;
    final take = testPageCap != null && testPageCap! < limit
        ? testPageCap!
        : limit;
    final end = offset + take > all.length ? all.length : offset + take;
    final start = offset > all.length ? all.length : offset;
    return CatalogPage(
      items: all.sublist(start, end),
      limit: take,
      offset: offset,
      total: total,
    );
  }

  @override
  Future<List<CommerceVertical>> listCommerceVerticals() async {
    return verticals;
  }

  @override
  Future<CatalogPage<StorefrontSummary>> listStorefronts({
    CatalogQuery query = const CatalogQuery(),
  }) async {
    listCount += 1;
    lastStorefrontQuery = query;
    if (query.offset > 0 && listDelay != null) {
      await Future<void>.delayed(listDelay!);
    }
    if (gateList != null) {
      await gateList!.future;
    }
    if (query.offset > 0 && loadMoreError != null) {
      throw loadMoreError!;
    }
    if (listError != null) {
      throw listError!;
    }
    var source = storefronts.items;
    if (query.openNow) {
      source = [
        for (final item in source)
          if (item.hours.isOpenNow) item,
      ];
    }
    final page = _slice(source, source.length, query);
    if (query.offset > 0 &&
        duplicateFirstOnLoadMore &&
        source.isNotEmpty) {
      return CatalogPage(
        items: [source.first, ...page.items],
        limit: page.limit,
        offset: page.offset,
        total: page.total,
      );
    }
    return page;
  }

  @override
  Future<StorefrontDetail> getStorefront(String branchId) async {
    if (detailError != null) {
      throw detailError!;
    }
    StorefrontSummary? match;
    for (final item in storefronts.items) {
      if (item.branchId == branchId) {
        match = item;
        break;
      }
    }
    if (storefrontDetail != null && storefrontDetail!.branchId == branchId) {
      return storefrontDetail!;
    }
    if (match == null) {
      throw const CatalogParseException('missing storefront');
    }
    return StorefrontDetail(
      branchId: match.branchId,
      branchName: match.branchName,
      addressText: match.addressText,
      latitude: match.latitude,
      longitude: match.longitude,
      merchantId: match.merchantId,
      merchantName: match.merchantName,
      merchantPublicReference: match.merchantPublicReference,
      hours: match.hours,
      coverImageUrl: match.coverImageUrl,
      days: const [],
    );
  }

  @override
  Future<List<CatalogCategory>> listCategories(String branchId) async {
    return categories;
  }

  @override
  Future<CatalogPage<CatalogProduct>> listProducts(
    String branchId, {
    CatalogQuery query = const CatalogQuery(),
  }) async {
    productListCount += 1;
    if (query.offset > 0 && loadMoreError != null) {
      throw loadMoreError!;
    }
    var items = products.items;
    final categoryId = query.categoryId;
    if (categoryId != null && categoryId.isNotEmpty) {
      items = items.where((item) => item.categoryId == categoryId).toList();
    }
    return _slice(items, items.length, query);
  }

  @override
  Future<CatalogProductDetail> getProduct({
    required String branchId,
    required String productId,
  }) async {
    getProductCount += 1;
    if (productError != null) {
      throw productError!;
    }
    if (productDetail != null) {
      return productDetail!;
    }
    throw const CatalogParseException('missing product');
  }

  @override
  Future<CatalogPage<CatalogSearchHit>> search(
    String q, {
    CatalogQuery query = const CatalogQuery(),
  }) async {
    searchCount += 1;
    lastSearchQ = q;
    final delay = searchDelay;
    if (delay != null) {
      await Future<void>.delayed(delay);
    }
    if (searchError != null) {
      throw searchError!;
    }
    if (query.offset > 0 && loadMoreError != null) {
      throw loadMoreError!;
    }
    final page = searchResultFor?.call(q) ?? searchHits;
    return _slice(page.items, page.total, query);
  }
}

class FakePromotionsClient implements PromotionsClient {
  FakePromotionsClient({this.items = const [], this.listError, this.listDelay});

  List<DiscoverablePromotion> items;
  Object? listError;
  Duration? listDelay;
  int listCount = 0;

  @override
  Future<List<DiscoverablePromotion>> listDiscoverable() async {
    listCount += 1;
    if (listDelay != null) {
      await Future<void>.delayed(listDelay!);
    }
    if (listError != null) {
      throw listError!;
    }
    return items;
  }
}

class FakeOrdersClient implements OrdersClient {
  FakeOrdersClient({
    this.orders = const OrderPage(items: [], limit: 20, offset: 0, total: 0),
    this.delivery,
    this.listError,
    this.deliveryError,
    this.createError,
    this.getError,
    this.cancelError,
    this.refundsError,
    this.createDelay,
    this.cancelDelay,
    this.createResult,
    this.cancelResult,
    this.trackingResult,
  });

  OrderPage orders;
  CustomerDeliveryDetail? delivery;
  Object? listError;
  Object? deliveryError;
  Object? createError;
  Object? getError;
  Object? cancelError;
  Object? refundsError;
  Object? trackingError;
  Object? paymentError;
  Object? initiateError;
  Duration? createDelay;
  Duration? cancelDelay;
  int listCount = 0;
  int lastListLimit = 0;
  int lastListOffset = 0;
  List<OrderSummary>? pagedItems;
  int deliveryCount = 0;
  int createCount = 0;
  int getCount = 0;
  int cancelCount = 0;
  int refundsCount = 0;
  int trackingCount = 0;
  int paymentCount = 0;
  int initiateCount = 0;
  String? lastDeliveryOrderId;
  String? lastCancelOrderId;
  String? lastCancelReason;
  CreateOrderRequest? lastCreateRequest;
  OrderDetail? createResult;
  OrderCancellationResult? cancelResult;
  TrackingSnapshot? trackingResult;
  CustomerPayment? paymentResult;
  CustomerPaymentInitiate? initiateResult;
  final details = <String, OrderDetail>{};
  final refundsByOrder = <String, CustomerOrderRefunds>{};
  final paymentsByOrder = <String, CustomerPayment>{};
  Completer<void>? gateCreate;
  Completer<void>? gateCancel;
  Completer<void>? gateInitiate;

  @override
  Future<OrderPage> listOrders({int limit = 20, int offset = 0}) async {
    listCount += 1;
    lastListLimit = limit;
    lastListOffset = offset;
    if (listError != null) {
      throw listError!;
    }
    final source = pagedItems;
    if (source != null) {
      return OrderPage(
        items: source.skip(offset).take(limit).toList(),
        limit: limit,
        offset: offset,
        total: source.length,
      );
    }
    return orders;
  }

  @override
  Future<OrderDetail> getOrder(String orderId) async {
    getCount += 1;
    if (getError != null) {
      throw getError!;
    }
    final detail = details[orderId] ?? createResult;
    if (detail == null) {
      throw const ApiException(
        'Cette commande est introuvable.',
        code: 'ORDER_NOT_FOUND',
        statusCode: 404,
      );
    }
    return detail;
  }

  @override
  Future<OrderDetail> createOrder(CreateOrderRequest request) async {
    createCount += 1;
    lastCreateRequest = request;
    if (gateCreate != null) {
      await gateCreate!.future;
    }
    if (createDelay != null) {
      await Future<void>.delayed(createDelay!);
    }
    if (createError != null) {
      throw createError!;
    }
    final result = createResult;
    if (result == null) {
      throw const ApiException(
        'Une erreur s’est produite. Réessayez.',
        code: 'HTTP_ERROR',
        statusCode: 500,
      );
    }
    details[result.id] = result;
    return result;
  }

  @override
  Future<OrderCancellationResult> cancelOrder(
    String orderId, {
    String? reason,
  }) async {
    cancelCount += 1;
    lastCancelOrderId = orderId;
    lastCancelReason = reason;
    if (gateCancel != null) {
      await gateCancel!.future;
    }
    if (cancelDelay != null) {
      await Future<void>.delayed(cancelDelay!);
    }
    if (cancelError != null) {
      throw cancelError!;
    }
    final result =
        cancelResult ??
        OrderCancellationResult(
          orderId: orderId,
          orderStatus: 'CANCELLED',
          cancellationAccepted: true,
          refundRequired: false,
          cancelledAt: DateTime.now().toUtc().toIso8601String(),
        );
    final existing = details[orderId];
    if (existing != null) {
      details[orderId] = OrderDetail(
        id: existing.id,
        publicReference: existing.publicReference,
        status: 'CANCELLED',
        fulfillmentStatus: existing.fulfillmentStatus,
        paymentMethod: existing.paymentMethod,
        createdAt: existing.createdAt,
        merchantBranchId: existing.merchantBranchId,
        financial: existing.financial,
        items: existing.items,
        deliveryAddress: existing.deliveryAddress,
      );
    }
    orders = OrderPage(
      items: [
        for (final item in orders.items)
          if (item.id == orderId)
            OrderSummary(
              id: item.id,
              publicReference: item.publicReference,
              status: 'CANCELLED',
              fulfillmentStatus: item.fulfillmentStatus,
              paymentMethod: item.paymentMethod,
              createdAt: item.createdAt,
              financial: item.financial,
            )
          else
            item,
      ],
      limit: orders.limit,
      offset: orders.offset,
      total: orders.total,
    );
    return result;
  }

  @override
  Future<CustomerOrderRefunds> listRefunds(String orderId) async {
    refundsCount += 1;
    if (refundsError != null) {
      throw refundsError!;
    }
    return refundsByOrder[orderId] ??
        CustomerOrderRefunds(
          orderId: orderId,
          originalPaidMinor: '0',
          reservedRefundMinor: '0',
          successfulRefundMinor: '0',
          remainingRefundableMinor: '0',
          currency: 'DZD',
          refunds: const [],
        );
  }

  @override
  Future<CustomerDeliveryDetail?> getDelivery(String orderId) async {
    deliveryCount += 1;
    lastDeliveryOrderId = orderId;
    if (deliveryError != null) {
      throw deliveryError!;
    }
    return delivery;
  }

  @override
  Future<TrackingSnapshot?> getTracking(String orderId) async {
    trackingCount += 1;
    if (trackingError != null) {
      throw trackingError!;
    }
    return trackingResult;
  }

  @override
  Future<CustomerPayment> getPayment(String orderId) async {
    paymentCount += 1;
    if (paymentError != null) {
      throw paymentError!;
    }
    final payment = paymentsByOrder[orderId] ?? paymentResult;
    if (payment == null) {
      throw const ApiException(
        'Le paiement de cette commande est introuvable.',
        code: 'PAYMENT_NOT_FOUND',
        statusCode: 404,
      );
    }
    return payment;
  }

  @override
  Future<CustomerPaymentInitiate> initiatePayment(String orderId) async {
    initiateCount += 1;
    if (gateInitiate != null) {
      await gateInitiate!.future;
    }
    if (initiateError != null) {
      throw initiateError!;
    }
    final result = initiateResult;
    if (result == null) {
      throw const ApiException(
        'Une erreur s’est produite. Réessayez.',
        code: 'HTTP_ERROR',
        statusCode: 500,
      );
    }
    paymentsByOrder[orderId] = result.asPayment;
    paymentResult = result.asPayment;
    return result;
  }
}

class FakeRatingsClient implements RatingsClient {
  FakeRatingsClient({this.summaries = const {}});

  Map<String, RatingSummary> summaries;
  int summaryCount = 0;
  final requestedIds = <String>[];

  int batchCount = 0;
  OrderRating? ownMerchant;
  OrderRating? ownDriver;

  @override
  Future<RatingSummary> merchantSummary(String merchantId) async {
    summaryCount += 1;
    requestedIds.add(merchantId);
    return summaries[merchantId] ??
        RatingSummary(targetType: 'MERCHANT', targetId: merchantId, count: 0);
  }

  @override
  Future<List<RatingSummary>> merchantSummaries(
    List<String> merchantIds,
  ) async {
    batchCount += 1;
    final items = <RatingSummary>[];
    for (final id in merchantIds.toSet()) {
      requestedIds.add(id);
      items.add(
        summaries[id] ??
            RatingSummary(targetType: 'MERCHANT', targetId: id, count: 0),
      );
    }
    return items;
  }

  @override
  Future<OrderRating?> getOwnMerchantRating(String orderId) async =>
      ownMerchant;

  @override
  Future<OrderRating?> getOwnDriverRating(String orderId) async => ownDriver;

  @override
  Future<OrderRating> rateMerchant(
    String orderId,
    CreateRatingRequest request,
  ) async {
    throw UnimplementedError('rateMerchant');
  }

  @override
  Future<OrderRating> rateDriver(
    String orderId,
    CreateRatingRequest request,
  ) async {
    throw UnimplementedError('rateDriver');
  }
}

class FakeCartProduct {
  const FakeCartProduct({
    required this.productId,
    required this.branchId,
    required this.merchantId,
    required this.name,
    required this.priceMinor,
    this.options = const {},
  });

  final String productId;
  final String branchId;
  final String merchantId;
  final String name;
  final String priceMinor;
  final Map<String, FakeCartOption> options;
}

class FakeCartOption {
  const FakeCartOption({
    required this.optionId,
    required this.name,
    required this.additionalPriceMinor,
    this.available = true,
  });

  final String optionId;
  final String name;
  final String additionalPriceMinor;
  final bool available;
}

class FakeCartClient implements CartClient {
  FakeCartClient({
    this.products = const {},
    this.bootstrap,
    this.getError,
    this.addError,
  });

  Map<String, FakeCartProduct> products;
  CartBootstrap? bootstrap;
  Object? getError;
  Object? addError;
  Object? updateError;
  Object? removeError;
  Object? clearError;
  Duration? addDelay;
  Completer<void>? gateAdd;
  int getCount = 0;
  int addCount = 0;
  int updateCount = 0;
  int removeCount = 0;
  int clearCount = 0;
  final adds = <AddCartItemRequest>[];
  var _seq = 0;

  CartBootstrap get _empty => const CartBootstrap(cartExists: false);

  @override
  Future<CartBootstrap> getCart() async {
    getCount += 1;
    if (getError != null) {
      throw getError!;
    }
    return bootstrap ?? _empty;
  }

  @override
  Future<CustomerCart> addItem(AddCartItemRequest request) async {
    addCount += 1;
    adds.add(request);
    if (gateAdd != null) {
      await gateAdd!.future;
    }
    if (addDelay != null) {
      await Future<void>.delayed(addDelay!);
    }
    if (addError != null) {
      throw addError!;
    }
    final offer = products[request.productId];
    if (offer == null) {
      throw const ApiException(
        'Ce produit n’est pas disponible pour le panier.',
        code: 'CART_PRODUCT_NOT_AVAILABLE',
        statusCode: 404,
      );
    }
    final current = bootstrap?.cart;
    if (current != null && current.branchId != offer.branchId) {
      throw ApiException(
        AppStrings.cartBranchConflict,
        code: 'CART_BRANCH_MISMATCH',
        statusCode: 409,
      );
    }
    var extra = BigInt.zero;
    final selected = <CartSelectedOption>[];
    for (final optionId in request.optionIds) {
      final option = offer.options[optionId];
      if (option == null || !option.available) {
        throw const ApiException(
          'Cette option n’est plus disponible.',
          code: 'CART_OPTION_NOT_AVAILABLE',
          statusCode: 409,
        );
      }
      extra += BigInt.parse(option.additionalPriceMinor);
      selected.add(
        CartSelectedOption(
          optionId: option.optionId,
          name: option.name,
          additionalPriceMinor: option.additionalPriceMinor,
          available: option.available,
        ),
      );
    }
    final unit = (BigInt.parse(offer.priceMinor) + extra).toString();
    final line = (BigInt.parse(unit) * BigInt.from(request.quantity))
        .toString();
    final items = [...?current?.items];
    final matchIndex = items.indexWhere(
      (item) =>
          item.productId == request.productId &&
          sameOptionSet(
            item.selectedOptions.map((option) => option.optionId),
            request.optionIds,
          ),
    );
    if (matchIndex >= 0) {
      final existing = items[matchIndex];
      final quantity = existing.quantity + request.quantity;
      items[matchIndex] = CartItem(
        id: existing.id,
        productId: existing.productId,
        productName: existing.productName,
        quantity: quantity,
        baseUnitPriceMinor: offer.priceMinor,
        optionUnitAdditionalMinor: extra.toString(),
        unitPriceMinor: unit,
        lineSubtotalMinor: (BigInt.parse(unit) * BigInt.from(quantity))
            .toString(),
        storedUnitPriceMinor: unit,
        itemAvailable: true,
        selectedOptions: selected,
        warnings: const [],
      );
    } else {
      _seq += 1;
      items.add(
        CartItem(
          id: '00000000-0000-4000-8000-${_seq.toString().padLeft(12, '0')}',
          productId: offer.productId,
          productName: offer.name,
          quantity: request.quantity,
          baseUnitPriceMinor: offer.priceMinor,
          optionUnitAdditionalMinor: extra.toString(),
          unitPriceMinor: unit,
          lineSubtotalMinor: line,
          storedUnitPriceMinor: unit,
          itemAvailable: true,
          selectedOptions: selected,
          warnings: const [],
        ),
      );
    }
    final cart = _view(
      id: current?.id ?? '11111111-1111-4111-8111-111111111111',
      branchId: offer.branchId,
      merchantId: offer.merchantId,
      items: items,
    );
    bootstrap = CartBootstrap(cartExists: true, cart: cart);
    return cart;
  }

  @override
  Future<CustomerCart> updateItem({
    required String cartItemId,
    required UpdateCartItemRequest request,
  }) async {
    updateCount += 1;
    if (updateError != null) {
      throw updateError!;
    }
    final current = bootstrap?.cart;
    if (current == null) {
      throw const ApiException(
        'Cet article n’est plus dans le panier.',
        code: 'CART_ITEM_NOT_FOUND',
        statusCode: 404,
      );
    }
    final items = [...current.items];
    final index = items.indexWhere((item) => item.id == cartItemId);
    if (index < 0) {
      throw const ApiException(
        'Cet article n’est plus dans le panier.',
        code: 'CART_ITEM_NOT_FOUND',
        statusCode: 404,
      );
    }
    final existing = items[index];
    items[index] = CartItem(
      id: existing.id,
      productId: existing.productId,
      productName: existing.productName,
      quantity: request.quantity,
      baseUnitPriceMinor: existing.baseUnitPriceMinor,
      optionUnitAdditionalMinor: existing.optionUnitAdditionalMinor,
      unitPriceMinor: existing.unitPriceMinor,
      lineSubtotalMinor:
          (BigInt.parse(existing.unitPriceMinor) *
                  BigInt.from(request.quantity))
              .toString(),
      storedUnitPriceMinor: existing.storedUnitPriceMinor,
      itemAvailable: existing.itemAvailable,
      selectedOptions: existing.selectedOptions,
      warnings: existing.warnings,
    );
    final cart = _view(
      id: current.id,
      branchId: current.branchId,
      merchantId: current.merchantId,
      items: items,
    );
    bootstrap = CartBootstrap(cartExists: true, cart: cart);
    return cart;
  }

  @override
  Future<CartBootstrap> removeItem(String cartItemId) async {
    removeCount += 1;
    if (removeError != null) {
      throw removeError!;
    }
    final current = bootstrap?.cart;
    if (current == null) {
      return _empty;
    }
    final items = current.items.where((item) => item.id != cartItemId).toList();
    if (items.isEmpty) {
      bootstrap = _empty;
      return _empty;
    }
    final cart = _view(
      id: current.id,
      branchId: current.branchId,
      merchantId: current.merchantId,
      items: items,
    );
    bootstrap = CartBootstrap(cartExists: true, cart: cart);
    return bootstrap!;
  }

  @override
  Future<CartBootstrap> clearCart() async {
    clearCount += 1;
    if (clearError != null) {
      throw clearError!;
    }
    bootstrap = _empty;
    return _empty;
  }

  CustomerCart _view({
    required String id,
    required String branchId,
    required String merchantId,
    required List<CartItem> items,
  }) {
    var subtotal = BigInt.zero;
    for (final item in items) {
      subtotal += BigInt.parse(item.lineSubtotalMinor);
    }
    return CustomerCart(
      id: id,
      status: 'ACTIVE',
      branchId: branchId,
      merchantId: merchantId,
      itemCount: items.length,
      cartSubtotalMinor: subtotal.toString(),
      cartReady: items.every((item) => item.itemAvailable),
      warnings: const [],
      items: items,
      createdAt: '2026-09-09T00:00:00.000Z',
      updatedAt: '2026-09-09T00:00:00.000Z',
    );
  }
}

class FakeAddressClient implements AddressClient {
  FakeAddressClient({List<CustomerAddress> addresses = const []})
    : addresses = [...addresses];

  List<CustomerAddress> addresses;
  Object? listError;
  Object? createError;
  Object? updateError;
  Object? deleteError;
  Object? defaultError;
  Duration? createDelay;
  Completer<void>? gateCreate;
  int listCount = 0;
  int createCount = 0;
  int updateCount = 0;
  int deleteCount = 0;
  int defaultCount = 0;
  final creates = <CreateAddressRequest>[];
  var _seq = 0;

  ApiException get _notFound => ApiException(
    AppStrings.addressNotFound,
    code: 'CUSTOMER_ADDRESS_NOT_FOUND',
    statusCode: 404,
  );

  @override
  Future<List<CustomerAddress>> list() async {
    listCount += 1;
    if (listError != null) {
      throw listError!;
    }
    return [...addresses];
  }

  @override
  Future<CustomerAddress> create(CreateAddressRequest request) async {
    createCount += 1;
    creates.add(request);
    if (gateCreate != null) {
      await gateCreate!.future;
    }
    if (createDelay != null) {
      await Future<void>.delayed(createDelay!);
    }
    if (createError != null) {
      throw createError!;
    }
    _seq += 1;
    final created = CustomerAddress(
      id: 'addr-created-$_seq',
      label: request.label,
      addressText: request.addressText,
      latitude: request.latitude,
      longitude: request.longitude,
      isDefault: addresses.isEmpty,
    );
    addresses = [...addresses, created];
    return created;
  }

  @override
  Future<CustomerAddress> update({
    required String addressId,
    required UpdateAddressRequest request,
  }) async {
    updateCount += 1;
    if (updateError != null) {
      throw updateError!;
    }
    final index = addresses.indexWhere((item) => item.id == addressId);
    if (index < 0) {
      throw _notFound;
    }
    final current = addresses[index];
    final updated = current.copyWith(
      label: request.label ?? current.label,
      addressText: request.addressText ?? current.addressText,
      latitude: request.latitude ?? current.latitude,
      longitude: request.longitude ?? current.longitude,
    );
    addresses = [...addresses]..[index] = updated;
    return updated;
  }

  @override
  Future<void> delete(String addressId) async {
    deleteCount += 1;
    if (deleteError != null) {
      throw deleteError!;
    }
    final exists = addresses.any((item) => item.id == addressId);
    if (!exists) {
      throw _notFound;
    }
    addresses = addresses.where((item) => item.id != addressId).toList();
  }

  @override
  Future<CustomerAddress> setDefault(String addressId) async {
    defaultCount += 1;
    if (defaultError != null) {
      throw defaultError!;
    }
    final index = addresses.indexWhere((item) => item.id == addressId);
    if (index < 0) {
      throw _notFound;
    }
    addresses = [
      for (final item in addresses)
        item.copyWith(isDefault: item.id == addressId),
    ];
    return addresses[index];
  }
}

class FakeLocationClient implements LocationClient {
  FakeLocationClient({this.access = LocationAccess.denied, this.position});

  LocationAccess access;
  DeviceLocation? position;
  Object? readError;
  int requestCount = 0;
  int readCount = 0;

  @override
  Future<LocationAccess> requestAccess() async {
    requestCount += 1;
    return access;
  }

  @override
  Future<DeviceLocation> readCurrent() async {
    readCount += 1;
    if (readError != null) {
      throw readError!;
    }
    final current = position;
    if (current == null) {
      throw const LocationUnavailableException();
    }
    return current;
  }
}

class FakeCheckoutClient implements CheckoutClient {
  FakeCheckoutClient({this.result, this.builder, this.error});

  CheckoutPreview? result;
  CheckoutPreview Function(CheckoutPreviewRequest request)? builder;
  Object? error;
  Completer<void>? gate;
  Completer<void>? holdFirst;
  CheckoutPreview? firstHeldResult;
  Duration? delay;
  int previewCount = 0;
  final requests = <CheckoutPreviewRequest>[];

  @override
  Future<CheckoutPreview> preview(CheckoutPreviewRequest request) async {
    previewCount += 1;
    requests.add(request);
    if (holdFirst != null && previewCount == 1) {
      await holdFirst!.future;
      final held = firstHeldResult;
      if (held != null) {
        return held;
      }
    }
    if (gate != null) {
      await gate!.future;
    }
    if (delay != null) {
      await Future<void>.delayed(delay!);
    }
    if (error != null) {
      throw error!;
    }
    if (builder != null) {
      return builder!(request);
    }
    final current = result;
    if (current != null) {
      return current;
    }
    throw const ApiException(
      'Votre panier est vide ou n’existe plus.',
      code: 'CHECKOUT_CART_REQUIRED',
      statusCode: 409,
    );
  }
}

class FakeTrackingSocketClient implements TrackingRealtimeClient {
  FakeTrackingSocketClient({this.subscribeSnapshot});

  TrackingSnapshot? subscribeSnapshot;
  var subscribeCount = 0;
  var unsubscribeCount = 0;
  var disconnectCount = 0;
  var disposeCount = 0;
  final subscribed = <String>[];
  var _connected = false;
  String? _subscribedOrderId;

  final _locationController = StreamController<TrackingLocation>.broadcast();
  final _statusController = StreamController<TrackingSnapshot>.broadcast();
  final _errorController = StreamController<String>.broadcast();
  final _connectionController = StreamController<bool>.broadcast();

  @override
  Stream<TrackingLocation> get locations => _locationController.stream;
  @override
  Stream<TrackingSnapshot> get statuses => _statusController.stream;
  @override
  Stream<String> get errors => _errorController.stream;
  @override
  Stream<bool> get connection => _connectionController.stream;
  @override
  bool get isConnected => _connected;
  @override
  String? get subscribedOrderId => _subscribedOrderId;

  @override
  Future<TrackingSnapshot?> subscribe(String orderId) async {
    subscribeCount += 1;
    subscribed.add(orderId);
    _subscribedOrderId = orderId;
    _connected = true;
    _connectionController.add(true);
    return subscribeSnapshot;
  }

  @override
  Future<void> unsubscribe() async {
    unsubscribeCount += 1;
    _subscribedOrderId = null;
  }

  @override
  Future<void> disconnect() async {
    disconnectCount += 1;
    _connected = false;
    _connectionController.add(false);
    _subscribedOrderId = null;
  }

  @override
  Future<void> dispose() async {
    disposeCount += 1;
    await disconnect();
    await _locationController.close();
    await _statusController.close();
    await _errorController.close();
    await _connectionController.close();
  }

  void simulateDisconnect() {
    _connected = false;
    _connectionController.add(false);
  }

  Future<void> simulateReconnect() async {
    _connected = true;
    _connectionController.add(true);
    final orderId = _subscribedOrderId;
    if (orderId != null) {
      await subscribe(orderId);
    }
  }
}
