class CatalogIds {
  CatalogIds._();

  static final _uuid = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  static const fixtures = {
    'nav-branch',
    'nav-product',
    'nav-order',
    'nav-ticket',
    'nav-address',
    'nav-session',
  };

  static bool isFixture(String? id) => id != null && fixtures.contains(id);

  static bool isLiveUuid(String? id) {
    if (id == null || id.isEmpty || isFixture(id)) {
      return false;
    }
    return _uuid.hasMatch(id);
  }
}

const catalogSearchMinLength = 2;
const catalogSearchMaxLength = 100;

/// Client-side Policy B: trim, strip LIKE metacharacters (`% _ \`), re-trim.
String normalizeCatalogSearchQuery(String raw) {
  return raw.trim().replaceAll(RegExp(r'[%_\\]'), '').trim();
}
