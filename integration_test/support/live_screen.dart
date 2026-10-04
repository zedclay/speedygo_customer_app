import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';

/// Visible-screen probe for live Customer integration. No tokens, OTP, or
/// Authorization headers are collected.
Map<String, Object?> probeLiveScreen(WidgetTester tester) {
  final texts = visibleTexts(tester);
  final route = currentRoute(tester);
  return {
    'route': route,
    'screen': classifyLiveScreen(tester),
    'visibleTexts': texts.take(24).toList(),
    'hasSplashLogo': find.byKey(const Key('splash-logo')).evaluate().isNotEmpty,
    'hasHomeSearch':
        find.byKey(const Key('home-search-field')).evaluate().isNotEmpty ||
        find.text(AppStrings.searchHint).evaluate().isNotEmpty,
  };
}

String classifyLiveScreen(WidgetTester tester) {
  if (find.text(AppStrings.restoreOfflineTitle).evaluate().isNotEmpty) {
    return 'restore_retryable';
  }
  if (find.text(AppStrings.restoreLoading).evaluate().isNotEmpty ||
      find.text(AppStrings.restoreTitle).evaluate().isNotEmpty) {
    return 'restore';
  }
  if (find.byKey(const Key('home-search-field')).evaluate().isNotEmpty ||
      find.text(AppStrings.searchHint).evaluate().isNotEmpty) {
    return 'home';
  }
  if (find.text(AppStrings.profileStep).evaluate().isNotEmpty) {
    return 'profile_setup';
  }
  if (find.text(AppStrings.otpTitle).evaluate().isNotEmpty) {
    return 'otp';
  }
  if (find.text(AppStrings.phoneTitle).evaluate().isNotEmpty) {
    return 'phone';
  }
  if (find.text(AppStrings.languageTitle).evaluate().isNotEmpty) {
    return 'language';
  }
  if (find.text(AppStrings.welcomeDiscoverTitle).evaluate().isNotEmpty) {
    return 'welcome';
  }
  if (find.byKey(const Key('splash-logo')).evaluate().isNotEmpty) {
    return 'splash';
  }
  return 'unknown';
}

String? currentRoute(WidgetTester tester) {
  for (final finder in <Finder>[
    find.byType(Scaffold),
    find.byType(Navigator),
  ]) {
    for (final element in finder.evaluate()) {
      try {
        return GoRouter.of(element).state.uri.path;
      } catch (_) {}
    }
  }
  return null;
}

List<String> visibleTexts(WidgetTester tester) {
  final out = <String>[];
  for (final element in find.byType(Text).hitTestable().evaluate()) {
    final widget = element.widget as Text;
    final value = widget.data ?? widget.textSpan?.toPlainText();
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      continue;
    }
    out.add(trimmed);
    if (out.length >= 40) {
      break;
    }
  }
  return out;
}
