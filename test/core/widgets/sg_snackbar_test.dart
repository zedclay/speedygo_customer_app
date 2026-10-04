import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/widgets/sg_snackbar.dart';
import 'package:speedygo_customer_app/features/cart/presentation/widgets/sticky_qty_action_bar.dart';

void main() {
  setUp(() {
    addTearDown(SgSnack.debugResetDedupe);
  });

  Widget harness({
    required Widget body,
    Widget? bottomNavigationBar,
    double textScale = 1.0,
    double keyboardInset = 0,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: const Size(390, 844),
        textScaler: TextScaler.linear(textScale),
        viewInsets: EdgeInsets.only(bottom: keyboardInset),
        padding: const EdgeInsets.only(bottom: 34),
      ),
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: body,
          bottomNavigationBar: bottomNavigationBar,
        ),
      ),
    );
  }

  testWidgets('success add-to-cart shows action and navigates on tap', (
    tester,
  ) async {
    var openedCart = false;
    await tester.pumpWidget(
      harness(
        body: Builder(
          builder: (context) {
            return Center(
              child: FilledButton(
                onPressed: () {
                  SgSnack.success(
                    context,
                    message: AppStrings.cartAdded,
                    actionLabel: AppStrings.viewCart,
                    onAction: () => openedCart = true,
                  );
                },
                child: const Text('add'),
              ),
            );
          },
        ),
        bottomNavigationBar: StickyQtyActionBar(
          quantity: 1,
          onQuantityChanged: (_) {},
          actionLabel: AppStrings.addToCart,
          priceLabel: '120 DA',
          onAction: () {},
          actionKey: const Key('sticky'),
        ),
      ),
    );

    await tester.tap(find.text('add'));
    await tester.pump(); // show overlay
    await tester.pump(); // paint probe → chrome microtask
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text(AppStrings.cartAdded), findsOneWidget);
    expect(find.text(AppStrings.viewCart), findsOneWidget);

    final snackTop = tester.getTopLeft(find.text(AppStrings.cartAdded)).dy;
    final stickyTop = tester.getTopLeft(find.byKey(const Key('sticky'))).dy;
    expect(snackTop, lessThan(stickyTop));

    await tester.tap(find.text(AppStrings.viewCart));
    await tester.pump();
    expect(openedCart, isTrue);
  });

  testWidgets('promo copy uses information tone, not success wording', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        body: Builder(
          builder: (context) {
            return Center(
              child: FilledButton(
                onPressed: () =>
                    SgSnack.info(context, message: AppStrings.promoCodeCopied),
                child: const Text('copy'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('copy'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text(AppStrings.promoCodeCopied), findsOneWidget);
    expect(find.textContaining('appliqué'), findsNothing);
    expect(find.textContaining('Succès'), findsNothing);
  });

  testWidgets('identical info snacks do not queue', (tester) async {
    await tester.pumpWidget(
      harness(
        body: Builder(
          builder: (context) {
            return Center(
              child: FilledButton(
                onPressed: () {
                  SgSnack.info(context, message: AppStrings.helpUnavailable);
                  SgSnack.info(context, message: AppStrings.helpUnavailable);
                  SgSnack.info(context, message: AppStrings.helpUnavailable);
                },
                child: const Text('spam'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('spam'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text(AppStrings.helpUnavailable), findsOneWidget);
  });

  testWidgets('uncertain warning never uses success kind copy', (tester) async {
    await tester.pumpWidget(
      harness(
        body: Builder(
          builder: (context) {
            return Center(
              child: FilledButton(
                onPressed: () => SgSnack.warning(
                  context,
                  message: AppStrings.cartAddUnconfirmed,
                ),
                child: const Text('warn'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('warn'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text(AppStrings.cartAddUnconfirmed), findsOneWidget);
    expect(find.text(AppStrings.cartAdded), findsNothing);
  });

  testWidgets('snack sits above sticky bar with keyboard and textScale 1.3', (
    tester,
  ) async {
    await tester.pumpWidget(
      harness(
        textScale: 1.3,
        keyboardInset: 280,
        body: Builder(
          builder: (context) {
            return Center(
              child: FilledButton(
                onPressed: () => SgSnack.success(
                  context,
                  message: AppStrings.addressSaved,
                ),
                child: const Text('save'),
              ),
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton(
              key: const Key('save-sticky'),
              onPressed: () {},
              child: const Text(AppStrings.saveAddress),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('save'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(find.text(AppStrings.addressSaved), findsOneWidget);
    final snackBottom =
        tester.getBottomLeft(find.text(AppStrings.addressSaved)).dy;
    final stickyTop = tester.getTopLeft(find.byKey(const Key('save-sticky'))).dy;
    expect(snackBottom, lessThanOrEqualTo(stickyTop + 1));
  });

  testWidgets('snack clears body-embedded sticky (configure layout)', (
    tester,
  ) async {
    // Reproduce product configure: sticky in body Column, not bottomNavigationBar.
    for (final size in const [Size(375, 667), Size(402, 874)]) {
      SgSnack.debugResetDedupe();
      var openedCart = false;
      var stickyTapped = false;

      await tester.pumpWidget(
        MediaQuery(
          data: MediaQueryData(
            size: size,
            padding: const EdgeInsets.only(bottom: 34),
            textScaler: const TextScaler.linear(1.0),
          ),
          child: MaterialApp(
            theme: AppTheme.light,
            home: Scaffold(
              appBar: AppBar(title: const Text('Configure')),
              body: Column(
                children: [
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        return Center(
                          child: FilledButton(
                            onPressed: () {
                              SgSnack.success(
                                context,
                                message: AppStrings.cartAdded,
                                actionLabel: AppStrings.viewCart,
                                onAction: () => openedCart = true,
                              );
                            },
                            child: const Text('add'),
                          ),
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
                    onAction: () => stickyTapped = true,
                    actionKey: const Key('body-sticky'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Before snack: sticky is visible and usable.
      expect(find.byKey(const Key('body-sticky')), findsOneWidget);
      await tester.tap(find.byKey(const Key('body-sticky')));
      await tester.pump();
      expect(stickyTapped, isTrue);
      stickyTapped = false;

      await tester.tap(find.text('add'));
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text(AppStrings.cartAdded), findsOneWidget);
      expect(find.byKey(const Key('body-sticky')), findsOneWidget);

      final snackBottom =
          tester.getBottomLeft(find.text(AppStrings.cartAdded)).dy;
      final stickyTop =
          tester.getTopLeft(find.byKey(const Key('body-sticky'))).dy;
      expect(
        snackBottom,
        lessThanOrEqualTo(stickyTop + 1),
        reason: 'snack must sit above body sticky on ${size.width}',
      );

      await tester.tap(find.text(AppStrings.viewCart));
      await tester.pump();
      expect(openedCart, isTrue);

      // After action dismiss: sticky still usable.
      expect(find.text(AppStrings.cartAdded), findsNothing);
      await tester.tap(find.byKey(const Key('body-sticky')));
      await tester.pump();
      expect(stickyTapped, isTrue);
    }
  });

  testWidgets('long French copy wraps without overflow at 1.3', (tester) async {
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      if (details.toString().contains('A RenderFlex overflowed')) {
        fail(details.toString());
      }
      originalOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = originalOnError);

    await tester.pumpWidget(
      harness(
        textScale: 1.3,
        body: Builder(
          builder: (context) {
            return Center(
              child: FilledButton(
                onPressed: () => SgSnack.warning(
                  context,
                  message: AppStrings.addressSaveUnconfirmed,
                ),
                child: const Text('go'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text(AppStrings.addressSaveUnconfirmed), findsOneWidget);
  });
}
