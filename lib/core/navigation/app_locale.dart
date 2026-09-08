/// Customer UI locales supported in this pass.
class AppLocale {
  AppLocale._();

  static const french = 'fr';

  static const supported = {french};

  static bool isSupported(String? locale) => supported.contains(locale);

  /// Unsupported values (including Arabic) fall back to French.
  static String sanitize(String? locale) {
    if (isSupported(locale)) {
      return locale!;
    }
    return french;
  }
}
