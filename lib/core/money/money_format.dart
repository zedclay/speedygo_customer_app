/// Exact DZD display from integer minor units (centimes).
///
/// Contract: 100 minor units = 1 DZD. Example: `220000` → `2 200,00 DZD`.
/// JSON transport remains the integer decimal string; this class only formats.
/// Never uses [double] or [num] arithmetic.
class MoneyFormat {
  MoneyFormat._();

  static final _nonNegative = RegExp(r'^[0-9]+$');
  static final _dzdDecimal = RegExp(r'^-?[0-9]+(\.[0-9]{1,2})?$');

  /// 100 centimes per DZD (DOMAIN_MODEL / TECH_STACK / ERD).
  static final centimesPerDzd = BigInt.from(100);

  static bool isMinorString(String raw) => _nonNegative.hasMatch(raw);

  /// Accepts legacy minor ("65000") or new DZD decimal ("650.00").
  static BigInt _toCentimes(String raw) {
    if (_dzdDecimal.hasMatch(raw) && raw.contains('.')) {
      final neg = raw.startsWith('-');
      final body = neg ? raw.substring(1) : raw;
      final parts = body.split('.');
      final whole = BigInt.parse(parts[0]);
      final frac = BigInt.parse(parts.length > 1 ? parts[1].padRight(2, '0') : '0');
      final v = whole * centimesPerDzd + frac;
      return neg ? -v : v;
    }
    if (!isMinorString(raw) && !_dzdDecimal.hasMatch(raw)) {
      throw FormatException('Invalid money string', raw);
    }
    // Bare digits: legacy minor units.
    return BigInt.parse(raw);
  }

  /// `1200` → `12,00 DZD`; `220000` → `2 200,00 DZD`; also `"650.00"`.
  /// dzd-v2 JSON amount from integer centimes.
  static String centimesToDzdV2(int centimes) {
    final value = BigInt.from(centimes);
    final neg = value < BigInt.zero;
    final abs = neg ? -value : value;
    final whole = abs ~/ centimesPerDzd;
    final fraction = abs.remainder(centimesPerDzd);
    final body = '${whole.toString()}.${_twoDigits(fraction)}';
    return neg ? '-$body' : body;
  }

  static String dzd(String minor) {
    final value = _toCentimes(minor);
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
