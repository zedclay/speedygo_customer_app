import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/widgets/sg_snackbar.dart';
import 'package:speedygo_customer_app/features/cart/presentation/widgets/sticky_qty_action_bar.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_bottom_bar.dart';

/// Mocked visual captures for SpeedyGo snackbars (no live business writes).
void main() {
  final outDir = Directory(
    '/Users/mac/Downloads/speedygo_project/apps/customer_app/audit/visuals/snackbar',
  );

  setUpAll(() => outDir.createSync(recursive: true));
  setUp(() {
    addTearDown(SgSnack.debugResetDedupe);
  });

  Future<void> sizeFor(
    WidgetTester tester, {
    required Size logical,
    required double textScale,
    double keyboard = 0,
  }) async {
    tester.view.physicalSize = logical * 2;
    tester.view.devicePixelRatio = 2;
    tester.view.padding = const FakeViewPadding(top: 47, bottom: 34);
    tester.view.viewInsets = FakeViewPadding(bottom: keyboard);
    tester.platformDispatcher.textScaleFactorTestValue = textScale;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPadding);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
  }

  Future<void> settle(WidgetTester tester) async {
    await tester.pump(); // post-frame show
    await tester.pump(); // paint probe → chrome
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 400)); // entrance
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

  Future<void> pumpSnackScene(
    WidgetTester tester, {
    required void Function(BuildContext context) show,
    Widget? bottom,
  }) async {
    await tester.pumpWidget(
      RepaintBoundary(
        child: MaterialApp(
          theme: AppTheme.light,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(disableAnimations: true),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: Scaffold(
            appBar: AppBar(title: const Text('SpeedyGo')),
            body: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    show(context);
                  }
                });
                return const ColoredBox(
                  color: AppColors.surface,
                  child: SizedBox.expand(),
                );
              },
            ),
            bottomNavigationBar: bottom,
          ),
        ),
      ),
    );
    await settle(tester);
  }

  testWidgets('after: cart success above body sticky SE (configure)', (
    tester,
  ) async {
    await sizeFor(tester, logical: const Size(375, 667), textScale: 1.0);
    await tester.pumpWidget(
      RepaintBoundary(
        child: MaterialApp(
          theme: AppTheme.light,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            return MediaQuery(
              data: mq.copyWith(disableAnimations: true),
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: Scaffold(
            appBar: AppBar(title: const Text(AppStrings.customizeTitle)),
            body: Column(
              children: [
                Expanded(
                  child: Builder(
                    builder: (context) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (context.mounted) {
                          SgSnack.success(
                            context,
                            message: AppStrings.cartAdded,
                            actionLabel: AppStrings.viewCart,
                            onAction: () {},
                          );
                        }
                      });
                      return const ColoredBox(
                        color: AppColors.surface,
                        child: SizedBox.expand(),
                      );
                    },
                  ),
                ),
                StickyQtyActionBar(
                  quantity: 1,
                  onQuantityChanged: (_) {},
                  showQuantity: false,
                  actionLabel: AppStrings.addToCart,
                  priceLabel: '450 DA',
                  onAction: () {},
                  actionKey: const Key('add-to-cart-button'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await settle(tester);
    expect(find.text(AppStrings.cartAdded), findsOneWidget);
    expect(find.byKey(const Key('add-to-cart-button')), findsOneWidget);
    final snackBottom =
        tester.getBottomLeft(find.text(AppStrings.cartAdded)).dy;
    final stickyTop =
        tester.getTopLeft(find.byKey(const Key('add-to-cart-button'))).dy;
    expect(snackBottom, lessThanOrEqualTo(stickyTop + 1));
    await shot(tester, 'after-cart-success-body-sticky-configure-se');
  });

  testWidgets('after: cart success above sticky SE 1.3', (tester) async {
    await sizeFor(tester, logical: const Size(375, 667), textScale: 1.3);
    await pumpSnackScene(
      tester,
      show: (context) => SgSnack.success(
        context,
        message: AppStrings.cartAdded,
        actionLabel: AppStrings.viewCart,
        onAction: () {},
      ),
      bottom: StickyQtyActionBar(
        quantity: 1,
        onQuantityChanged: (_) {},
        actionLabel: AppStrings.addToCart,
        priceLabel: '120 DA',
        onAction: () {},
        actionKey: const Key('add'),
      ),
    );
    expect(find.text(AppStrings.cartAdded), findsOneWidget);
    expect(find.text(AppStrings.viewCart), findsOneWidget);
    await shot(tester, 'after-cart-success-sticky-se-1.3');
  });

  testWidgets('after: promo copied above home nav Pro', (tester) async {
    await sizeFor(tester, logical: const Size(402, 874), textScale: 1.0);
    await pumpSnackScene(
      tester,
      show: (context) =>
          SgSnack.info(context, message: AppStrings.promoCodeCopied),
      bottom: HomeBottomBar(selectedIndex: 0, onSelect: (_) {}),
    );
    expect(find.text(AppStrings.promoCodeCopied), findsOneWidget);
    await shot(tester, 'after-promo-copied-home-nav-pro');
  });

  testWidgets('after: address saved with keyboard SE 1.3', (tester) async {
    await sizeFor(
      tester,
      logical: const Size(375, 667),
      textScale: 1.3,
      keyboard: 280,
    );
    await pumpSnackScene(
      tester,
      show: (context) =>
          SgSnack.success(context, message: AppStrings.addressSaved),
      bottom: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton(
            key: const Key('address-save-button'),
            onPressed: () {},
            child: const Text(AppStrings.saveAddress),
          ),
        ),
      ),
    );
    expect(find.text(AppStrings.addressSaved), findsOneWidget);
    await shot(tester, 'after-address-saved-keyboard-se-1.3');
  });

  testWidgets('after: uncertain warning sticky Pro', (tester) async {
    await sizeFor(tester, logical: const Size(402, 874), textScale: 1.0);
    await pumpSnackScene(
      tester,
      show: (context) => SgSnack.warning(
        context,
        message: AppStrings.cartAddUnconfirmed,
      ),
      bottom: StickyQtyActionBar(
        quantity: 2,
        onQuantityChanged: (_) {},
        actionLabel: AppStrings.addToCart,
        priceLabel: '240 DA',
        onAction: () {},
        actionKey: const Key('add'),
      ),
    );
    expect(find.text(AppStrings.cartAddUnconfirmed), findsOneWidget);
    await shot(tester, 'after-uncertain-warning-sticky-pro');
  });

  testWidgets('before: stock Material snackbar SE', (tester) async {
    await sizeFor(tester, logical: const Size(375, 667), textScale: 1.0);
    await tester.pumpWidget(
      RepaintBoundary(
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true),
          home: Scaffold(
            appBar: AppBar(title: const Text('SpeedyGo')),
            body: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!context.mounted) {
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text(AppStrings.cartAdded),
                      action: SnackBarAction(
                        label: AppStrings.viewCart,
                        onPressed: () {},
                      ),
                    ),
                  );
                });
                return const ColoredBox(
                  color: Color(0xFFF9F9FF),
                  child: SizedBox.expand(),
                );
              },
            ),
            bottomNavigationBar: StickyQtyActionBar(
              quantity: 1,
              onQuantityChanged: (_) {},
              actionLabel: AppStrings.addToCart,
              priceLabel: '120 DA',
              onAction: () {},
              actionKey: const Key('add'),
            ),
          ),
        ),
      ),
    );
    await settle(tester);
    expect(find.text(AppStrings.cartAdded), findsOneWidget);
    await shot(tester, 'before-material-default-cart-se');
  });
}
