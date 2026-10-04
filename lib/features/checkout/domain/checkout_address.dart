import 'package:speedygo_customer_app/features/addresses/application/address_controller.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_ids.dart';

/// Checkout uses the validated Home selection if it is still owned, else the
/// server default. It never invents an address and never writes PUT default.
String? resolveCheckoutAddressId({
  required AddressUiState book,
  required AddressSelectionState selection,
}) {
  final selectedId = selection.addressId;
  if (CatalogIds.isLiveUuid(selectedId) && book.byId(selectedId) != null) {
    return selectedId;
  }
  final fallback = book.defaultAddress;
  if (fallback != null && CatalogIds.isLiveUuid(fallback.id)) {
    return fallback.id;
  }
  return null;
}

String checkoutCartFingerprint({
  String? cartId,
  int? itemCount,
  String? merchandiseSubtotalMinor,
  String? updatedAt,
}) {
  return [
    cartId ?? '',
    '${itemCount ?? 0}',
    merchandiseSubtotalMinor ?? '',
    updatedAt ?? '',
  ].join(':');
}
