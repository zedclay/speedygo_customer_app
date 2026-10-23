/// Customer UI locales. French remains the fallback.
class AppLocale {
  AppLocale._();

  static const french = 'fr';
  static const arabic = 'ar';

  static const supported = {french, arabic};

  static bool isSupported(String? locale) => supported.contains(locale);

  /// Unknown values fall back to French. Arabic is a supported locale.
  static String sanitize(String? locale) {
    if (isSupported(locale)) {
      return locale!;
    }
    return french;
  }

  static bool isArabic(String? locale) => sanitize(locale) == arabic;
}
