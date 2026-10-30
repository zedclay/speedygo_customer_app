import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/hours_badge.dart';

void main() {
  test('formats storefront clock in Africa/Algiers, not device local', () {
    // 17:00 UTC is 18:00 in Africa/Algiers (UTC+1, no DST).
    final utc = DateTime.utc(2026, 1, 15, 17, 0);
    expect(formatStorefrontClock(utc, 'Africa/Algiers'), '18:00');
    expect(formatStorefrontClock(utc, ''), '18:00');
    expect(storefrontUtcOffset('Africa/Algiers'), const Duration(hours: 1));

    final hours = StorefrontHours(
      hoursConfigured: true,
      isOpenNow: true,
      timezone: 'Africa/Algiers',
      currentClosesAt: utc,
    );
    expect(hoursLabel(hours), contains('18:00'));
    expect(hoursLabel(hours), isNot(contains(AppStrings.hoursClosed)));
  });

  test('non-Algiers device TZ does not change the Algiers clock', () {
    // 17:00 UTC is 18:00 Africa/Algiers. Device toLocal() is 12:00 in
    // America/New_York (EST) and 17:00 in UTC — never the formatter input.
    final utc = DateTime.utc(2026, 1, 15, 17, 0);
    expect(formatStorefrontClock(utc, 'Africa/Algiers'), '18:00');
    final local = utc.toLocal();
    final deviceClock =
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
    if (local.timeZoneOffset != const Duration(hours: 1)) {
      expect(deviceClock, isNot('18:00'));
    }
  });
}
