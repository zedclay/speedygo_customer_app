import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Loads production Inter weights + Material Icons so goldens are not Ahem tofu.
Future<void> loadAuditCaptureFonts() async {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<ByteData> asset(String path) => rootBundle.load(path);

  final inter = FontLoader('Inter')
    ..addFont(asset('assets/fonts/Inter-Regular.ttf'))
    ..addFont(asset('assets/fonts/Inter-Medium.ttf'))
    ..addFont(asset('assets/fonts/Inter-SemiBold.ttf'))
    ..addFont(asset('assets/fonts/Inter-Bold.ttf'));
  await inter.load();

  final materialPath =
      '${Platform.environment['FLUTTER_ROOT'] ?? '/Users/mac/flutter'}'
      '/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';
  final materialFile = File(materialPath);
  if (!materialFile.existsSync()) {
    throw StateError('MaterialIcons font missing at $materialPath');
  }
  final materialBytes = await materialFile.readAsBytes();
  final icons = FontLoader('MaterialIcons')
    ..addFont(
      Future<ByteData>.value(ByteData.sublistView(materialBytes)),
    );
  await icons.load();

  // Roboto fallback used by some Material component defaults.
  final fontsDir = Directory(
    '${Platform.environment['FLUTTER_ROOT'] ?? '/Users/mac/flutter'}'
    '/bin/cache/artifacts/material_fonts',
  );
  final roboto = FontLoader('Roboto');
  for (final name in [
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
  ]) {
    final file = File('${fontsDir.path}/$name');
    if (!file.existsSync()) {
      continue;
    }
    final bytes = await file.readAsBytes();
    roboto.addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
  }
  await roboto.load();

  // Color emoji for Home greeting (U+1F44B). Skip monochrome Noto Emoji —
  // it substitutes a raised-fist-like glyph for the waving hand.
  final colorEmoji = File('test/audit/fixtures/NotoColorEmoji.ttf');
  if (colorEmoji.existsSync()) {
    try {
      final bytes = await colorEmoji.readAsBytes();
      final emoji = FontLoader('Noto Color Emoji')
        ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
      await emoji.load();
    } catch (_) {
      // Widget tests still run; production uses the platform color emoji.
    }
  }

  final appleEmoji = File('/System/Library/Fonts/Apple Color Emoji.ttc');
  if (appleEmoji.existsSync()) {
    try {
      final bytes = await appleEmoji.readAsBytes();
      final emoji = FontLoader('Apple Color Emoji')
        ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
      await emoji.load();
    } catch (_) {
      // TTC may be unsupported by FontLoader.
    }
  }

  // Arabic labels (disabled AR tile). Production iOS uses Geeza Pro / SF Arabic.
  for (final path in [
    '/System/Library/Fonts/GeezaPro.ttc',
    '/System/Library/Fonts/Geeza Pro.ttc',
    '/System/Library/Fonts/Supplemental/NotoNaskhArabic-Regular.ttf',
  ]) {
    final file = File(path);
    if (!file.existsSync()) {
      continue;
    }
    try {
      final bytes = await file.readAsBytes();
      final arabic = FontLoader('Geeza Pro')
        ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes)));
      await arabic.load();
      break;
    } catch (_) {}
  }
}

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  await loadAuditCaptureFonts();
  await testMain();
}
