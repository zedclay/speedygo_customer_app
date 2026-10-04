import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/money/money_calc.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';

void main() {
  test('adds and multiplies minor units with BigInt only', () {
    expect(MoneyCalc.add('1200', '200'), '1400');
    expect(MoneyCalc.sum(['1200', '200', '100']), '1500');
    expect(MoneyCalc.times('1400', 2), '2800');
    expect(MoneyFormat.dzd(MoneyCalc.times('1400', 2)), '28,00 DZD');
  });

  test('rejects negative or invalid minors', () {
    expect(() => MoneyCalc.parse('-1'), throwsFormatException);
    expect(() => MoneyCalc.times('100', 0), throwsFormatException);
  });
}
