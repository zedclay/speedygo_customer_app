/// Exact DZD display from integer minor units (centimes).
///
/// Contract: 100 minor units = 1 DZD. Example: `220000` → `2 200,00 DZD`.
/// JSON transport remains the integer decimal string; this class only formats.
/// Never uses [double] or [num] arithmetic.
class MoneyFormat {
  MoneyFormat._();

  static final _nonNegative = RegExp(r'^[0-9]+$');

  /// 100 centimes per DZD (DOMAIN_MODEL / TECH_STACK / ERD).
  static final centimesPerDzd = BigInt.from(100);

  static bool isMinorString(String raw) => _nonNegative.hasMatch(raw);

  /// `1200` → `12,00 DZD`; `220000` → `2 200,00 DZD`.
  static String dzd(String minor) {
    if (!isMinorString(minor)) {
      throw FormatException('Invalid money minor string', minor);
    }
    final value = BigInt.parse(minor);
    final whole = value ~/ centimesPerDzd;
    final fraction = value.remainder(centimesPerDzd);
    return '${_group(whole.toString())},${_twoDigits(fraction)} DZD';
  }

  static String _twoDigits(BigInt fraction) {
    final raw = fraction.toString();
    if (raw.length >= 2) {
      return raw;
    }
    return raw.padLeft(2, '0');
  }

  static String _group(String digits) {
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final remaining = digits.length - i;
      if (i > 0 && remaining % 3 == 0) {
        buffer.write(' ');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
