import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/storefront_card.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/storefront_identity.dart';

import '../../helpers/catalog_fixtures.dart';

void main() {
  test('hides only identical merchant display names', () {
    expect(isRedundantMerchantName('Four de Didouche', 'Four de Didouche'), isTrue);
    expect(
      isRedundantMerchantName('  Four de Didouche ', 'four de didouche'),
      isTrue,
    );
    expect(
      isRedundantMerchantName('Café Central', 'Café Central SARL'),
      isFalse,
    );
  });

  testWidgets('SE card hides duplicate merchant and ellipsizes long address', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(375, 667) * 2;
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    const address =
        'Commerce fictif SpeedyGo — identité inventée pour la revue visuelle. '
        'Ne représente aucun commerce réel. 56 rue Didouche Mourad, Alger-Centre.';
    const storefront = StorefrontSummary(
      branchId: cafeBranchId,
      branchName: 'Four de Didouche',
      addressText: address,
      latitude: 36.75,
      longitude: 3.05,
      merchantId: merchantId,
      merchantName: 'Four de Didouche',
      merchantPublicReference: 'SG-M-1001',
      hours: openHours,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              StorefrontCard(storefront: storefront, onTap: () {}),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Four de Didouche'), findsOneWidget);
    expect(find.text(AppStrings.hoursOpen), findsOneWidget);
    expect(tester.takeException(), isNull);

    final preview = tester.widget<Text>(find.text(address));
    expect(preview.maxLines, storefrontCardPreviewMaxLines);
    expect(preview.overflow, TextOverflow.ellipsis);
  });

  testWidgets('keeps a distinct merchant name on the card', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StorefrontCard(storefront: cafeStorefront(), onTap: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Café Central'), findsOneWidget);
    expect(find.text('Café Central SARL'), findsOneWidget);
  });
}
