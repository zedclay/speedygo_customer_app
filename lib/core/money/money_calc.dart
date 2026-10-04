import 'package:speedygo_customer_app/core/money/money_format.dart';

/// Integer minor-unit arithmetic. Never uses [double] or [num] money math.
class MoneyCalc {
  MoneyCalc._();

  static BigInt parse(String minor) {
    if (!MoneyFormat.isMinorString(minor)) {
      throw FormatException('Invalid money minor string', minor);
    }
    return BigInt.parse(minor);
  }

  static String encode(BigInt value) {
    if (value.isNegative) {
      throw FormatException('Negative money is not allowed', value.toString());
    }
    return value.toString();
  }

  static String add(String left, String right) =>
      encode(parse(left) + parse(right));

  static String sum(Iterable<String> minors) {
    var total = BigInt.zero;
    for (final minor in minors) {
      total += parse(minor);
    }
    return encode(total);
  }

  static String times(String unitMinor, int quantity) {
    if (quantity < 1) {
      throw FormatException('Quantity must be a positive integer', quantity);
    }
    return encode(parse(unitMinor) * BigInt.from(quantity));
  }
}
