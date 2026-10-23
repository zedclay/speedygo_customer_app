import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/authenticated_cover_image.dart';
import 'package:speedygo_customer_app/features/orders/application/active_order.dart';
import 'package:speedygo_customer_app/features/orders/presentation/order_detail_screen.dart';

import '../helpers/fakes.dart';
import '../helpers/order_fixtures.dart';

final _tinyPng = Uint8List.fromList([
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
  0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
  0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53, 0xDE, 0x00, 0x00, 0x00,
  0x0C, 0x49, 0x44, 0x41, 0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
  0x00, 0x00, 0x03, 0x00, 0x01, 0x00, 0x05, 0xFE, 0xD4, 0xEF, 0x00, 0x00,
  0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
]);

void main() {
  final outDir = Directory(
    '${Directory.current.path}/audit/visuals/ui_cleanup',
  );

  setUpAll(() => outDir.createSync(recursive: true));

  Future<void> sizeFor(WidgetTester tester, Size logical) async {
    tester.view.physicalSize = logical * 2;
    tester.view.devicePixelRatio = 2;
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
  }

  Future<void> shot(WidgetTester tester, String name) async {
    final boundary =
        tester.renderObject(find.byType(RepaintBoundary).first)
            as RenderRepaintBoundary;
    final bytes = await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.0);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      return data?.buffer.asUint8List();
    });
    expect(bytes, isNotNull);
    File('${outDir.path}/$name.png').writeAsBytesSync(bytes!);
  }

  testWidgets('capture: order detail Ma commande + item image SE', (
    tester,
  ) async {
    await sizeFor(tester, const Size(375, 667));
    final detail = sampleOrderDetail();
    final orders = FakeOrdersClient()..details[detail.id] = detail;
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('capture:order'),
        ordersApiProvider.overrideWithValue(orders),
        coverImageBytesProvider.overrideWith((ref, path) async => _tinyPng),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      RepaintBoundary(
        child: UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light,
            debugShowCheckedModeBanner: false,
            home: OrderDetailScreen(orderId: detail.id),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(AppStrings.orderDetailTitle), findsOneWidget);
    expect(find.text('Ma commande'), findsOneWidget);
    await shot(tester, 'order-detail-ma-commande-item-image-se');
  });

  testWidgets('capture: order detail payment above sticky Pro 1.3', (
    tester,
  ) async {
    await sizeFor(tester, const Size(402, 874));
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final detail = sampleOrderDetail();
    final orders = FakeOrdersClient()..details[detail.id] = detail;
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('capture:pay'),
        ordersApiProvider.overrideWithValue(orders),
        coverImageBytesProvider.overrideWith((ref, path) async => null),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      RepaintBoundary(
        child: UncontrolledProviderScope(
          container: container,
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(402, 874),
              textScaler: TextScaler.linear(1.3),
              padding: EdgeInsets.only(top: 47, bottom: 34),
            ),
            child: MaterialApp(
              theme: AppTheme.light,
              debugShowCheckedModeBanner: false,
              home: OrderDetailScreen(orderId: detail.id),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final totals = find.byKey(const Key('order-detail-totals'));
    await tester.scrollUntilVisible(
      totals,
      80,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pump();
    await shot(tester, 'order-detail-payment-above-sticky-pro-1.3');
  });
}
