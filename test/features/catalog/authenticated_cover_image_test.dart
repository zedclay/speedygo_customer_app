import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/authenticated_cover_image.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/catalog_placeholders.dart';

const _png1x1 = [
  0x89,
  0x50,
  0x4e,
  0x47,
  0x0d,
  0x0a,
  0x1a,
  0x0a,
  0x00,
  0x00,
  0x00,
  0x0d,
  0x49,
  0x48,
  0x44,
  0x52,
  0x00,
  0x00,
  0x00,
  0x01,
  0x00,
  0x00,
  0x00,
  0x01,
  0x08,
  0x02,
  0x00,
  0x00,
  0x00,
  0x90,
  0x77,
  0x53,
  0xde,
  0x00,
  0x00,
  0x00,
  0x0c,
  0x49,
  0x44,
  0x41,
  0x54,
  0x08,
  0xd7,
  0x63,
  0xf8,
  0xcf,
  0xc0,
  0x00,
  0x00,
  0x03,
  0x01,
  0x01,
  0x00,
  0x18,
  0xdd,
  0x8d,
  0xb4,
  0x00,
  0x00,
  0x00,
  0x00,
  0x49,
  0x45,
  0x4e,
  0x44,
  0xae,
  0x42,
  0x60,
  0x82,
];

void main() {
  test('resolves only relative customer catalog image paths', () {
    expect(
      resolveCustomerCatalogImagePath('/customer/branches/x/cover'),
      '/customer/branches/x/cover',
    );
    expect(
      resolveCustomerCatalogImagePath('/api/v1/customer/branches/x/cover'),
      '/customer/branches/x/cover',
    );
    expect(
      resolveCustomerCatalogImagePath('https://evil.example/x.png'),
      isNull,
    );
    expect(resolveCustomerCatalogImagePath('  '), isNull);
    expect(isCustomerCatalogImageContentType('image/jpeg'), isTrue);
    expect(
      isCustomerCatalogImageContentType('application/json; charset=utf-8'),
      isFalse,
    );
  });

  testWidgets('missing cover uses placeholder', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AuthenticatedCoverImage(
            coverImageUrl: null,
            fallbackLabel: 'Café Central',
            height: 80,
          ),
        ),
      ),
    );
    expect(find.byType(CatalogImagePlaceholder), findsOneWidget);
    expect(find.byKey(const Key('catalog-image-unbound')), findsOneWidget);
    expect(find.byKey(const Key('authenticated-cover-image')), findsNothing);
    expect(find.byKey(const Key('catalog-image-loading')), findsNothing);
    expect(find.byKey(const Key('catalog-image-failed')), findsNothing);
  });

  testWidgets('loaded cover bytes render an image', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coverImageBytesProvider.overrideWith(
            (ref, path) async => Uint8List.fromList(_png1x1),
          ),
        ],
        child: const MaterialApp(
          home: AuthenticatedCoverImage(
            coverImageUrl: '/customer/branches/x/cover',
            fallbackLabel: 'Café Central',
            height: 80,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('authenticated-cover-image')), findsOneWidget);
    expect(find.byType(CatalogImagePlaceholder), findsNothing);
  });

  testWidgets('cover load error uses placeholder', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coverImageBytesProvider.overrideWith((ref, path) async {
            throw Exception('network');
          }),
        ],
        child: const MaterialApp(
          home: AuthenticatedCoverImage(
            coverImageUrl: '/customer/branches/x/cover',
            fallbackLabel: 'Café Central',
            height: 80,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CatalogImagePlaceholder), findsOneWidget);
    expect(find.byKey(const Key('catalog-image-failed')), findsOneWidget);
    expect(find.byKey(const Key('authenticated-cover-image')), findsNothing);
    expect(find.byKey(const Key('catalog-image-loading')), findsNothing);
  });

  testWidgets('empty authenticated bytes use failed placeholder', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coverImageBytesProvider.overrideWith((ref, path) async => null),
        ],
        child: const MaterialApp(
          home: AuthenticatedCoverImage(
            coverImageUrl: '/customer/branches/x/cover',
            fallbackLabel: 'Café Central',
            height: 80,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('catalog-image-failed')), findsOneWidget);
    expect(find.byKey(const Key('catalog-image-unbound')), findsNothing);
    expect(find.byKey(const Key('catalog-image-loading')), findsNothing);
  });

  testWidgets('external image URLs use placeholder without loading', (
    tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: AuthenticatedCatalogImage(
            imageUrl: 'https://evil.example/x.png',
            fallbackLabel: 'Espresso',
            height: 80,
          ),
        ),
      ),
    );
    expect(find.byType(CatalogImagePlaceholder), findsOneWidget);
    expect(find.byKey(const Key('authenticated-catalog-image')), findsNothing);
  });
}
