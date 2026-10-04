import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_ids.dart';

class CartParseException implements Exception {
  const CartParseException([this.message = 'Invalid cart payload']);

  final String message;

  @override
  String toString() => message;
}

class CartUncertainException extends UnexpectedException {
  const CartUncertainException()
    : super(
        'La confirmation du panier n’a pas été reçue. Vérification en cours.',
        code: 'CART_MUTATION_UNCERTAIN',
      );
}

Map<String, dynamic> _asMap(Object? value, String label) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return Map<String, dynamic>.from(value);
  }
  throw CartParseException('$label must be an object');
}

String _reqString(Map<String, dynamic> json, String key) {
  final value = json[key]?.toString();
  if (value == null || value.isEmpty) {
    throw CartParseException('$key is required');
  }
  return value;
}

String _money(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || !MoneyFormat.isMinorString(value)) {
    throw CartParseException(
      '$key must be an exact non-negative decimal string',
    );
  }
  return value;
}

int _reqInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is String) {
    return int.parse(value);
  }
  throw CartParseException('$key must be an integer');
}

bool _reqBool(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is bool) {
    return value;
  }
  throw CartParseException('$key must be a boolean');
}

class CartSelectedOption {
  const CartSelectedOption({
    required this.optionId,
    required this.additionalPriceMinor,
    required this.available,
    this.name,
  });

  final String optionId;
  final String? name;
  final String additionalPriceMinor;
  final bool available;

  factory CartSelectedOption.fromJson(Map<String, dynamic> json) {
    final rawName = json['name']?.toString();
    return CartSelectedOption(
      optionId: _reqString(json, 'optionId'),
      name: rawName == null || rawName.isEmpty ? null : rawName,
      additionalPriceMinor: _money(json, 'additionalPriceMinor'),
      available: _reqBool(json, 'available'),
    );
  }
}

class CartItem {
  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.baseUnitPriceMinor,
    required this.optionUnitAdditionalMinor,
    required this.unitPriceMinor,
    required this.lineSubtotalMinor,
    required this.storedUnitPriceMinor,
    required this.itemAvailable,
    required this.selectedOptions,
    required this.warnings,
  });

  final String id;
  final String productId;
  final String productName;
  final int quantity;
  final String baseUnitPriceMinor;
  final String optionUnitAdditionalMinor;
  final String unitPriceMinor;
  final String lineSubtotalMinor;
  final String storedUnitPriceMinor;
  final bool itemAvailable;
  final List<CartSelectedOption> selectedOptions;
  final List<String> warnings;

  factory CartItem.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['selectedOptions'];
    if (rawOptions is! List) {
      throw const CartParseException('selectedOptions must be a list');
    }
    final rawWarnings = json['warnings'];
    if (rawWarnings is! List) {
      throw const CartParseException('warnings must be a list');
    }
    return CartItem(
      id: _reqString(json, 'id'),
      productId: _reqString(json, 'productId'),
      productName: _reqString(json, 'productName'),
      quantity: _reqInt(json, 'quantity'),
      baseUnitPriceMinor: _money(json, 'baseUnitPriceMinor'),
      optionUnitAdditionalMinor: _money(json, 'optionUnitAdditionalMinor'),
      unitPriceMinor: _money(json, 'unitPriceMinor'),
      lineSubtotalMinor: _money(json, 'lineSubtotalMinor'),
      storedUnitPriceMinor: _money(json, 'storedUnitPriceMinor'),
      itemAvailable: _reqBool(json, 'itemAvailable'),
      selectedOptions: rawOptions
          .map((item) => CartSelectedOption.fromJson(_asMap(item, 'option')))
          .toList(),
      warnings: rawWarnings.map((item) => item.toString()).toList(),
    );
  }
}

class CustomerCart {
  const CustomerCart({
    required this.id,
    required this.status,
    required this.branchId,
    required this.merchantId,
    required this.itemCount,
    required this.cartSubtotalMinor,
    required this.cartReady,
    required this.warnings,
    required this.items,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String status;
  final String branchId;
  final String merchantId;
  final int itemCount;
  final String cartSubtotalMinor;
  final bool cartReady;
  final List<String> warnings;
  final List<CartItem> items;
  final String createdAt;
  final String updatedAt;

  factory CustomerCart.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    if (rawItems is! List) {
      throw const CartParseException('items must be a list');
    }
    final rawWarnings = json['warnings'];
    if (rawWarnings is! List) {
      throw const CartParseException('warnings must be a list');
    }
    return CustomerCart(
      id: _reqString(json, 'id'),
      status: _reqString(json, 'status'),
      branchId: _reqString(json, 'branchId'),
      merchantId: _reqString(json, 'merchantId'),
      itemCount: _reqInt(json, 'itemCount'),
      cartSubtotalMinor: _money(json, 'cartSubtotalMinor'),
      cartReady: _reqBool(json, 'cartReady'),
      warnings: rawWarnings.map((item) => item.toString()).toList(),
      items: rawItems
          .map((item) => CartItem.fromJson(_asMap(item, 'item')))
          .toList(),
      createdAt: _reqString(json, 'createdAt'),
      updatedAt: _reqString(json, 'updatedAt'),
    );
  }
}

class CartBootstrap {
  const CartBootstrap({required this.cartExists, this.cart});

  final bool cartExists;
  final CustomerCart? cart;

  factory CartBootstrap.fromJson(Map<String, dynamic> json) {
    final exists = _reqBool(json, 'cartExists');
    final rawCart = json['cart'];
    if (!exists || rawCart == null) {
      return const CartBootstrap(cartExists: false);
    }
    return CartBootstrap(
      cartExists: true,
      cart: CustomerCart.fromJson(_asMap(rawCart, 'cart')),
    );
  }

  int get badgeCount => cart?.itemCount ?? 0;
}

class AddCartItemRequest {
  const AddCartItemRequest({
    required this.productId,
    required this.quantity,
    this.optionIds = const [],
  });

  final String productId;
  final int quantity;
  final List<String> optionIds;

  Map<String, dynamic> toJson() {
    if (!CatalogIds.isLiveUuid(productId)) {
      throw const CartParseException('productId must be a live UUID');
    }
    for (final optionId in optionIds) {
      if (!CatalogIds.isLiveUuid(optionId)) {
        throw const CartParseException('optionIds must be live UUIDs');
      }
    }
    return {
      'productId': productId,
      'quantity': quantity,
      'optionIds': optionIds,
    };
  }
}

class UpdateCartItemRequest {
  const UpdateCartItemRequest({required this.quantity, this.optionIds});

  final int quantity;
  final List<String>? optionIds;

  Map<String, dynamic> toJson() {
    final body = <String, dynamic>{'quantity': quantity};
    final optionIds = this.optionIds;
    if (optionIds != null) {
      for (final optionId in optionIds) {
        if (!CatalogIds.isLiveUuid(optionId)) {
          throw const CartParseException('optionIds must be live UUIDs');
        }
      }
      body['optionIds'] = optionIds;
    }
    return body;
  }
}

/// Customer image-read path already used by catalog DTOs. Cart items have no
/// `imageUrl`; this is derived from `branchId` + `productId` only.
String? cartItemImageUrl({
  required String branchId,
  required String productId,
}) {
  if (!CatalogIds.isLiveUuid(branchId) || !CatalogIds.isLiveUuid(productId)) {
    return null;
  }
  return '/customer/branches/$branchId/products/$productId/image';
}

List<String> normalizedOptionIds(Iterable<String> ids) {
  final unique = ids.toSet().toList()..sort();
  return unique;
}

bool sameOptionSet(Iterable<String> left, Iterable<String> right) {
  final a = normalizedOptionIds(left);
  final b = normalizedOptionIds(right);
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
