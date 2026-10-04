import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';

import '../integration_test/support/live_screen.dart';

void main() {
  testWidgets('live probe treats Home search key as Home, not a miss', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(key: Key('home-search-field')),
              Text('Accueil'),
            ],
          ),
        ),
      ),
    );
    expect(classifyLiveScreen(tester), 'home');
    expect(probeLiveScreen(tester)['hasHomeSearch'], isTrue);
  });

  testWidgets('live probe distinguishes phone from Home', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: Text(AppStrings.phoneTitle)),
      ),
    );
    expect(classifyLiveScreen(tester), 'phone');
    expect(probeLiveScreen(tester)['hasHomeSearch'], isFalse);
  });

  testWidgets('live probe prefers restore over Home while Session restaurée shows', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              TextField(key: Key('home-search-field')),
              Text(AppStrings.restoreTitle),
              Text(AppStrings.restoreLoading),
            ],
          ),
        ),
      ),
    );
    expect(classifyLiveScreen(tester), 'restore');
  });
}
