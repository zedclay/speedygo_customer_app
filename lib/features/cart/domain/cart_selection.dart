import 'package:speedygo_customer_app/core/money/money_calc.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';

/// Mirrors backend `CART_QUANTITY_MAX` (API abuse cap, not business law).
const cartQuantityMin = 1;
const cartQuantityMax = 99;

class ProductConfigDraft {
  const ProductConfigDraft({
    required this.quantity,
    required this.selectedByGroup,
  });

  final int quantity;
  final Map<String, Set<String>> selectedByGroup;

  List<String> get optionIds {
    final ids = <String>[];
    for (final groupIds in selectedByGroup.values) {
      ids.addAll(groupIds);
    }
    ids.sort();
    return ids;
  }

  ProductConfigDraft copyWith({
    int? quantity,
    Map<String, Set<String>>? selectedByGroup,
  }) {
    return ProductConfigDraft(
      quantity: quantity ?? this.quantity,
      selectedByGroup:
          selectedByGroup ?? cloneSelectedByGroup(this.selectedByGroup),
    );
  }
}

Map<String, Set<String>> cloneSelectedByGroup(Map<String, Set<String>> source) {
  return {
    for (final entry in source.entries) entry.key: {...entry.value},
  };
}

ProductConfigDraft emptyProductConfig({int quantity = cartQuantityMin}) {
  final safe = quantity < cartQuantityMin
      ? cartQuantityMin
      : (quantity > cartQuantityMax ? cartQuantityMax : quantity);
  return ProductConfigDraft(quantity: safe, selectedByGroup: const {});
}

bool isCartQuantity(int quantity) {
  return quantity >= cartQuantityMin && quantity <= cartQuantityMax;
}

int clampCartQuantity(int quantity) {
  if (quantity < cartQuantityMin) {
    return cartQuantityMin;
  }
  if (quantity > cartQuantityMax) {
    return cartQuantityMax;
  }
  return quantity;
}

CatalogProductOption? _optionById(
  CatalogProductDetail product,
  String optionId,
) {
  for (final group in product.optionGroups) {
    for (final option in group.options) {
      if (option.optionId == optionId) {
        return option;
      }
    }
  }
  return null;
}

CatalogOptionGroup? _groupOfOption(
  CatalogProductDetail product,
  String optionId,
) {
  for (final group in product.optionGroups) {
    for (final option in group.options) {
      if (option.optionId == optionId) {
        return group;
      }
    }
  }
  return null;
}

int _count(ProductConfigDraft draft, String groupId) {
  return draft.selectedByGroup[groupId]?.length ?? 0;
}

/// Same rules as backend `validateCartOptionSelections`.
bool isProductConfigValid(
  CatalogProductDetail product,
  ProductConfigDraft draft,
) {
  if (!isCartQuantity(draft.quantity)) {
    return false;
  }
  final seen = <String>{};
  for (final optionId in draft.optionIds) {
    if (!seen.add(optionId)) {
      return false;
    }
    final option = _optionById(product, optionId);
    if (option == null || !option.available) {
      return false;
    }
  }
  for (final group in product.optionGroups) {
    final count = _count(draft, group.optionGroupId);
    if (group.required && count < group.minSelections) {
      return false;
    }
    if (!group.required && count < group.minSelections) {
      return false;
    }
    if (count > group.maxSelections) {
      return false;
    }
  }
  return true;
}

String estimateUnitMinor(
  CatalogProductDetail product,
  ProductConfigDraft draft,
) {
  var extra = '0';
  for (final optionId in draft.optionIds) {
    final option = _optionById(product, optionId);
    if (option == null) {
      continue;
    }
    extra = MoneyCalc.add(extra, option.additionalPriceMinor);
  }
  return MoneyCalc.add(product.priceMinor, extra);
}

String estimateLineMinor(
  CatalogProductDetail product,
  ProductConfigDraft draft,
) {
  return MoneyCalc.times(estimateUnitMinor(product, draft), draft.quantity);
}

ProductConfigDraft toggleOption(
  CatalogProductDetail product,
  ProductConfigDraft draft,
  String optionId,
) {
  final group = _groupOfOption(product, optionId);
  final option = _optionById(product, optionId);
  if (group == null || option == null || !option.available) {
    return draft;
  }
  final next = cloneSelectedByGroup(draft.selectedByGroup);
  final current = {...?next[group.optionGroupId]};
  if (group.maxSelections <= 1) {
    if (current.contains(optionId)) {
      if (group.required && group.minSelections >= 1) {
        return draft;
      }
      current.remove(optionId);
    } else {
      current
        ..clear()
        ..add(optionId);
    }
  } else if (current.contains(optionId)) {
    current.remove(optionId);
  } else {
    if (current.length >= group.maxSelections) {
      return draft;
    }
    current.add(optionId);
  }
  if (current.isEmpty) {
    next.remove(group.optionGroupId);
  } else {
    next[group.optionGroupId] = current;
  }
  return draft.copyWith(selectedByGroup: next);
}

ProductConfigDraft changeQuantity(ProductConfigDraft draft, int quantity) {
  return draft.copyWith(quantity: clampCartQuantity(quantity));
}
