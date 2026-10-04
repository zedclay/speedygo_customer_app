import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';

void main() {
  test(
    'formats DZD from 100-centime minor units without double conversion',
    () {
      expect(MoneyFormat.dzd('0'), '0,00 DZD');
      expect(MoneyFormat.dzd('1'), '0,01 DZD');
      expect(MoneyFormat.dzd('50'), '0,50 DZD');
      expect(MoneyFormat.dzd('100'), '1,00 DZD');
      expect(MoneyFormat.dzd('850'), '8,50 DZD');
      expect(MoneyFormat.dzd('1200'), '12,00 DZD');
      expect(MoneyFormat.dzd('1500'), '15,00 DZD');
      expect(MoneyFormat.dzd('220000'), '2 200,00 DZD');
      expect(MoneyFormat.dzd('9007199254740993'), '90 071 992 547 409,93 DZD');
    },
  );

  test('rejects non exact decimal strings', () {
    expect(MoneyFormat.isMinorString('12.5'), isFalse);
    expect(MoneyFormat.isMinorString('-1'), isFalse);
    expect(MoneyFormat.isMinorString(''), isFalse);
    expect(() => MoneyFormat.dzd('12.00'), throwsFormatException);
  });
}
