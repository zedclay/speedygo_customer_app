import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_promo_banner.dart';
import 'package:speedygo_customer_app/features/promotions/application/promotion_copy.dart';
import 'package:speedygo_customer_app/features/promotions/data/promotion_models.dart';

import '../../helpers/catalog_fixtures.dart';
import '../../helpers/fakes.dart';
import '../customer_navigation_test.dart';

DiscoverablePromotion fixedPromo() {
  return const DiscoverablePromotion(
    id: 'promo-fixed',
    code: 'DEMO150',
    discountKind: PromotionDiscountKind.fixedMinor,
    value: 15000,
    startsAt: '2020-01-01T00:00:00.000Z',
    endsAt: '2099-01-01T00:00:00.000Z',
    customerLabel: 'Offre Spéciale',
  );
}

DiscoverablePromotion ratePromo() {
  return const DiscoverablePromotion(
    id: 'promo-rate',
    code: 'SAVE10',
    discountKind: PromotionDiscountKind.rateBps,
    value: 1000,
    startsAt: '2020-01-01T00:00:00.000Z',
    endsAt: '2099-01-01T00:00:00.000Z',
  );
}

void main() {
  test('formats fixed centimes and rate basis points', () {
    expect(
      PromotionCopy.headline(fixedPromo()),
      AppStrings.promoFixedHeadline(MoneyFormat.dzd('15000')),
    );
    expect(
      PromotionCopy.headline(fixedPromo()),
      'Jusqu’à ${MoneyFormat.dzd('15000')} de réduction',
    );
    expect(PromotionCopy.headline(ratePromo()), '10 % de réduction');
    expect(
      PromotionCopy.headline(
        const DiscoverablePromotion(
          id: 'promo-frac',
          code: 'SAVE125',
          discountKind: PromotionDiscountKind.rateBps,
          value: 1250,
          startsAt: '2020-01-01T00:00:00.000Z',
          endsAt: '2099-01-01T00:00:00.000Z',
        ),
      ),
      '12,50 % de réduction',
    );
    expect(PromotionCopy.percentFromBps(1250), '12,50 %');
    expect(PromotionCopy.label(ratePromo()), AppStrings.specialOffer);
    expect(PromotionCopy.label(fixedPromo()), 'Offre Spéciale');
  });

  testWidgets('fixed banner uses API code and money format', (tester) async {
    await tester.pumpWidget(
      readyApp(
        catalog: FakeCatalogClient(
          storefronts: CatalogPage(
            items: [cafeStorefront()],
            limit: 50,
            offset: 0,
            total: 1,
          ),
        ),
        promotions: FakePromotionsClient(items: [fixedPromo()]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomePromoBanner), findsOneWidget);
    expect(find.text('DEMO150'), findsOneWidget);
    expect(
      find.text(AppStrings.promoFixedHeadline(MoneyFormat.dzd('15000'))),
      findsOneWidget,
    );
    expect(find.text(AppStrings.promoMerchandiseCondition), findsOneWidget);
    expect(find.text(AppStrings.promoCode), findsNothing);
    expect(find.text(AppStrings.promoHeadline), findsNothing);
    expect(find.text(AppStrings.promoCondition), findsNothing);
    expect(find.text('Café Central'), findsOneWidget);
  });

  testWidgets('percentage banner uses first server item', (tester) async {
    await tester.pumpWidget(
      readyApp(
        catalog: FakeCatalogClient(
          storefronts: CatalogPage(
            items: [cafeStorefront()],
            limit: 50,
            offset: 0,
            total: 1,
          ),
        ),
        promotions: FakePromotionsClient(items: [ratePromo(), fixedPromo()]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('SAVE10'), findsOneWidget);
    expect(find.text('10 % de réduction'), findsOneWidget);
    expect(find.text('DEMO150'), findsNothing);
  });

  testWidgets('empty and error discovery omit the banner', (tester) async {
    await tester.pumpWidget(
      readyApp(
        catalog: FakeCatalogClient(
          storefronts: CatalogPage(
            items: [cafeStorefront()],
            limit: 50,
            offset: 0,
            total: 1,
          ),
        ),
        promotions: FakePromotionsClient(),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomePromoBanner), findsNothing);
    expect(find.text(AppStrings.storefrontsTitle), findsOneWidget);

    await tester.pumpWidget(
      readyApp(
        catalog: FakeCatalogClient(
          storefronts: CatalogPage(
            items: [cafeStorefront()],
            limit: 50,
            offset: 0,
            total: 1,
          ),
        ),
        promotions: FakePromotionsClient(
          listError: const NetworkException('promotions down'),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomePromoBanner), findsNothing);
    expect(find.text('Café Central'), findsOneWidget);
  });

  testWidgets('copy writes the real code and does not claim apply', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(() {
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      );
    });

    await tester.pumpWidget(
      readyApp(
        catalog: FakeCatalogClient(
          storefronts: CatalogPage(
            items: [cafeStorefront()],
            limit: 50,
            offset: 0,
            total: 1,
          ),
        ),
        promotions: FakePromotionsClient(items: [fixedPromo()]),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppStrings.copyPromoCode));
    await tester.pump();
    expect(copied, 'DEMO150');
    expect(find.text(AppStrings.promoCodeCopied), findsOneWidget);
    expect(find.textContaining('appliqué'), findsNothing);
  });

  testWidgets('banner fits iPhone SE and larger text', (tester) async {
    tester.view.physicalSize = const Size(375, 667) * 2;
    tester.view.devicePixelRatio = 2;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(
      readyApp(
        catalog: FakeCatalogClient(
          storefronts: CatalogPage(
            items: [cafeStorefront()],
            limit: 50,
            offset: 0,
            total: 1,
          ),
        ),
        promotions: FakePromotionsClient(items: [fixedPromo()]),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(HomePromoBanner), findsOneWidget);
    expect(find.text('DEMO150'), findsOneWidget);
    expect(find.text(AppStrings.storefrontsTitle), findsOneWidget);
    expect(tester.takeException(), isNull);

    tester.view.physicalSize = const Size(430, 932) * 2;
    await tester.pumpAndSettle();
    expect(find.byType(HomePromoBanner), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
