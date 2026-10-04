import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';

/// Semantic tone for SpeedyGo floating snack notifications.
enum SgSnackKind { success, error, warning, information }

/// Compact floating snack helper.
///
/// Uses [Overlay] + [Scaffold.geometryOf] / measured body chrome /
/// [MediaQuery.viewInsets] so the card sits above bottom navigation, sticky
/// CTAs (including those embedded in the scaffold body), and the keyboard
/// without per-screen guessed offsets.
class SgSnack {
  SgSnack._();

  static OverlayEntry? _entry;
  static String? _activeMessage;
  static String? _activeActionLabel;

  /// Measured bottom chrome from body-embedded sticky bars (e.g. configure).
  /// Updated by [StickyQtyActionBar] via [reportBodyChrome] using layout
  /// geometry — not a guessed constant.
  @visibleForTesting
  static final ValueNotifier<double> bodyChromeBottom =
      ValueNotifier<double>(0);

  static Object? _bodyChromeOwner;

  /// Publishes the distance from the sticky top edge to the bottom of the
  /// screen so snacks clear body-embedded CTAs that are not in
  /// [Scaffold.bottomNavigationBar].
  static void reportBodyChrome(Object owner, double chrome) {
    _bodyChromeOwner = owner;
    if ((bodyChromeBottom.value - chrome).abs() > 0.5) {
      bodyChromeBottom.value = chrome;
    }
  }

  static void clearBodyChrome(Object owner) {
    if (!identical(_bodyChromeOwner, owner)) {
      return;
    }
    _bodyChromeOwner = null;
    bodyChromeBottom.value = 0;
  }

  /// Shows a SpeedyGo snack notification.
  ///
  /// Identical non-action messages already on screen are not re-queued.
  /// Actionable snacks always replace the current one so the action stays
  /// reachable. Callers must only use [SgSnackKind.success] after a confirmed
  /// operation (never for copy-only or uncertain results).
  static void show(
    BuildContext context, {
    required String message,
    SgSnackKind kind = SgSnackKind.information,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
    bool dedupeIdentical = true,
  }) {
    assert(
      (actionLabel == null) == (onAction == null),
      'actionLabel and onAction must both be null or both set',
    );

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      return;
    }

    final hasAction = actionLabel != null && onAction != null;
    if (dedupeIdentical &&
        !hasAction &&
        _activeMessage == message &&
        _activeActionLabel == null &&
        _entry != null) {
      return;
    }

    hide(context);

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final displayDuration =
        duration ??
        (hasAction ? const Duration(seconds: 4) : const Duration(seconds: 3));

    // Capture the caller Scaffold — OverlayEntry context is not under it.
    final scaffoldContext =
        Scaffold.maybeOf(context) != null ? context : null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) {
        return _SgSnackHost(
          scaffoldContext: scaffoldContext,
          message: message,
          kind: kind,
          actionLabel: actionLabel,
          animateEntrance: !reduceMotion,
          duration: displayDuration,
          onDismiss: () {
            if (_entry == entry) {
              hide(context);
            }
          },
          onHostDisposed: () {
            // Overlay teardown (route / pumpWidget) can dispose the host without
            // hide(); clear statics so identical messages can show again.
            if (identical(_entry, entry)) {
              _entry = null;
              _activeMessage = null;
              _activeActionLabel = null;
            }
          },
          onAction: onAction == null
              ? null
              : () {
                  hide(context);
                  onAction();
                },
        );
      },
    );

    _entry = entry;
    _activeMessage = message;
    _activeActionLabel = actionLabel;
    overlay.insert(entry);
  }

  static void success(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      kind: SgSnackKind.success,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void error(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      kind: SgSnackKind.error,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void warning(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      kind: SgSnackKind.warning,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void info(
    BuildContext context, {
    required String message,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    show(
      context,
      message: message,
      kind: SgSnackKind.information,
      actionLabel: actionLabel,
      onAction: onAction,
      duration: duration,
    );
  }

  static void hide(BuildContext context) {
    _entry?.remove();
    _entry = null;
    _activeMessage = null;
    _activeActionLabel = null;
  }

  @visibleForTesting
  static void debugResetDedupe() {
    _entry?.remove();
    _entry = null;
    _activeMessage = null;
    _activeActionLabel = null;
    _bodyChromeOwner = null;
    bodyChromeBottom.value = 0;
  }
}

class _SgSnackHost extends StatefulWidget {
  const _SgSnackHost({
    required this.message,
    required this.kind,
    required this.animateEntrance,
    required this.duration,
    required this.onDismiss,
    required this.onHostDisposed,
    this.scaffoldContext,
    this.actionLabel,
    this.onAction,
  });

  final BuildContext? scaffoldContext;
  final String message;
  final SgSnackKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool animateEntrance;
  final Duration duration;
  final VoidCallback onDismiss;
  final VoidCallback onHostDisposed;

  @override
  State<_SgSnackHost> createState() => _SgSnackHostState();
}

class _SgSnackHostState extends State<_SgSnackHost> {
  /// Space reserved by bottom nav / sticky CTA / home indicator.
  /// When derived from [ScaffoldGeometry.bottomNavigationBarTop], that value
  /// already reflects keyboard-resized scaffold layout — do not add viewInsets.
  double _chromeBottom = 0;
  bool _chromeFromGeometry = false;
  Timer? _dismissTimer;

  @override
  void initState() {
    super.initState();
    _dismissTimer = Timer(widget.duration, widget.onDismiss);
    SgSnack.bodyChromeBottom.addListener(_onBodyChrome);
  }

  @override
  void dispose() {
    SgSnack.bodyChromeBottom.removeListener(_onBodyChrome);
    _dismissTimer?.cancel();
    _dismissTimer = null;
    widget.onHostDisposed();
    super.dispose();
  }

  void _onBodyChrome() {
    if (mounted) {
      setState(() {});
    }
  }

  void _applyChrome(double chrome, {required bool fromGeometry}) {
    if (!mounted) {
      return;
    }
    if ((chrome - _chromeBottom).abs() > 0.5 ||
        fromGeometry != _chromeFromGeometry) {
      setState(() {
        _chromeBottom = chrome;
        _chromeFromGeometry = fromGeometry;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final keyboard = media.viewInsets.bottom;
    final fallback = media.padding.bottom;
    final bodyChrome = SgSnack.bodyChromeBottom.value;
    final scaffoldChrome = _chromeFromGeometry ? _chromeBottom : fallback;
    // Prefer the larger of Scaffold bottom-nav chrome and measured body sticky.
    final chrome = math.max(scaffoldChrome, bodyChrome);
    // Measured chrome already accounts for keyboard-resized layout.
    final usedMeasured = _chromeFromGeometry || bodyChrome > 0.5;
    final keyboardLift = usedMeasured ? 0.0 : keyboard;
    final bottomInset = chrome + keyboardLift + 8;

    final anchor = widget.scaffoldContext;
    final canProbe =
        anchor != null && anchor.mounted && Scaffold.maybeOf(anchor) != null;

    return Stack(
      children: [
        if (canProbe)
          // Tiny paint probe — avoid a full-screen overlay layer.
          Positioned(
            left: 0,
            top: 0,
            width: 1,
            height: 1,
            child: IgnorePointer(
              child: _ScaffoldChromeProbe(
                geometry: Scaffold.geometryOf(anchor),
                screenHeight: media.size.height,
                fallbackBottom: fallback,
                onChrome: _applyChrome,
              ),
            ),
          ),
        Positioned(
          left: 16,
          right: 16,
          bottom: bottomInset,
          // Non-action toasts must not steal taps from sticky CTAs beneath.
          child: IgnorePointer(
            ignoring: widget.onAction == null,
            child: _SgSnackCard(
              message: widget.message,
              kind: widget.kind,
              actionLabel: widget.actionLabel,
              onAction: widget.onAction,
              animateEntrance: widget.animateEntrance,
            ),
          ),
        ),
      ],
    );
  }
}

/// Reads [ScaffoldGeometry] during paint (the only legal phase) and reports
/// bottom chrome height for overlay positioning on the next frame.
class _ScaffoldChromeProbe extends StatelessWidget {
  const _ScaffoldChromeProbe({
    required this.geometry,
    required this.screenHeight,
    required this.fallbackBottom,
    required this.onChrome,
  });

  final ValueListenable<ScaffoldGeometry> geometry;
  final double screenHeight;
  final double fallbackBottom;
  final void Function(double chrome, {required bool fromGeometry}) onChrome;

  @override
  Widget build(BuildContext context) {
    // [repaint] listens without scheduling a build during Scaffold layout.
    return CustomPaint(
      painter: _ScaffoldChromePainter(
        geometry: geometry,
        screenHeight: screenHeight,
        fallbackBottom: fallbackBottom,
        onChrome: onChrome,
      ),
    );
  }
}

class _ScaffoldChromePainter extends CustomPainter {
  _ScaffoldChromePainter({
    required this.geometry,
    required this.screenHeight,
    required this.fallbackBottom,
    required this.onChrome,
  }) : super(repaint: geometry);

  final ValueListenable<ScaffoldGeometry> geometry;
  final double screenHeight;
  final double fallbackBottom;
  final void Function(double chrome, {required bool fromGeometry}) onChrome;

  @override
  void paint(Canvas canvas, Size size) {
    final top = geometry.value.bottomNavigationBarTop;
    final chrome = top != null ? screenHeight - top : fallbackBottom;
    final fromGeometry = top != null;
    // Defer host setState until after layout/paint complete.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      onChrome(chrome, fromGeometry: fromGeometry);
    });
  }

  @override
  bool shouldRepaint(covariant _ScaffoldChromePainter oldDelegate) {
    return oldDelegate.geometry != geometry ||
        oldDelegate.screenHeight != screenHeight ||
        oldDelegate.fallbackBottom != fallbackBottom;
  }
}

class _SgSnackCard extends StatelessWidget {
  const _SgSnackCard({
    required this.message,
    required this.kind,
    required this.animateEntrance,
    this.actionLabel,
    this.onAction,
  });

  final String message;
  final SgSnackKind kind;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool animateEntrance;

  static const _radius = 16.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final semantics = _semanticsFor(kind);
    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(_radius),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.55),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_radius),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _KindIcon(kind: kind),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface,
                    fontSize: 14,
                    height: 20 / 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(width: 4),
                TextButton(
                  onPressed: onAction,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(48, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      height: 20 / 14,
                    ),
                  ),
                  child: Text(actionLabel!),
                ),
              ] else
                const SizedBox(width: 4),
            ],
          ),
        ),
      ),
    );

    final labeled = Semantics(
      container: true,
      liveRegion: true,
      label: '${semantics.label}: $message',
      child: card,
    );

    if (!animateEntrance) {
      return labeled;
    }

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 10 * (1 - value)),
            child: child,
          ),
        );
      },
      child: labeled,
    );
  }

  static ({String label, IconData icon, Color accent, Color wash})
  _semanticsFor(SgSnackKind kind) {
    switch (kind) {
      case SgSnackKind.success:
        return (
          label: 'Succès',
          icon: Icons.check_circle_rounded,
          accent: const Color(0xFF3B6D11),
          wash: const Color(0xFFE8F5D3),
        );
      case SgSnackKind.error:
        return (
          label: 'Erreur',
          icon: Icons.error_rounded,
          accent: AppColors.error,
          wash: const Color(0xFFFFDAD6),
        );
      case SgSnackKind.warning:
        return (
          label: 'Attention',
          icon: Icons.warning_amber_rounded,
          accent: const Color(0xFF8B5A00),
          wash: const Color(0xFFFFEFD0),
        );
      case SgSnackKind.information:
        return (
          label: 'Information',
          icon: Icons.info_rounded,
          accent: AppColors.primary,
          wash: AppColors.surfaceContainer,
        );
    }
  }
}

class _KindIcon extends StatelessWidget {
  const _KindIcon({required this.kind});

  final SgSnackKind kind;

  @override
  Widget build(BuildContext context) {
    final s = _SgSnackCard._semanticsFor(kind);
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: s.wash,
          borderRadius: BorderRadius.circular(10),
        ),
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(s.icon, size: 20, color: s.accent),
        ),
      ),
    );
  }
}
