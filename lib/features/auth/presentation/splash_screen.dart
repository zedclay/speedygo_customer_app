import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/network/health_client.dart';
import 'package:speedygo_customer_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_providers.dart';
import 'package:speedygo_customer_app/features/auth/presentation/splash_backdrop.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _logoTurns;
  late final AnimationController _loaderTurns;
  var _readyToSpin = false;
  var _spinning = false;

  @override
  void initState() {
    super.initState();
    _logoTurns = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _loaderTurns = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _readyToSpin = true;
      _syncMotion();
      _bootstrap();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_readyToSpin) {
      _syncMotion();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _syncMotion();
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _pauseMotion();
    }
  }

  bool get _shouldAnimate {
    if (!mounted || !_readyToSpin) {
      return false;
    }
    final features =
        WidgetsBinding.instance.platformDispatcher.accessibilityFeatures;
    if (MediaQuery.disableAnimationsOf(context) || features.reduceMotion) {
      return false;
    }
    if (!TickerMode.valuesOf(context).enabled) {
      return false;
    }
    return ref.read(splashAnimateProvider);
  }

  void _pauseMotion() {
    _logoTurns.stop(canceled: false);
    _loaderTurns.stop(canceled: false);
    if (_spinning && mounted) {
      setState(() => _spinning = false);
    } else {
      _spinning = false;
    }
  }

  void _syncMotion() {
    if (!mounted) {
      return;
    }
    final animate = _shouldAnimate;
    if (animate) {
      if (!_logoTurns.isAnimating) {
        _logoTurns.repeat();
      }
      if (!_loaderTurns.isAnimating) {
        _loaderTurns.repeat();
      }
      if (!_spinning) {
        setState(() => _spinning = true);
      }
      return;
    }
    _logoTurns
      ..stop(canceled: false)
      ..value = 0;
    _loaderTurns
      ..stop(canceled: false)
      ..value = 0;
    if (_spinning) {
      setState(() => _spinning = false);
    }
  }

  Future<void> _bootstrap() async {
    final minDuration = ref.read(splashMinDurationProvider);
    final config = ref.read(apiConfigProvider);
    await Future.wait<void>([
      Future<void>.delayed(minDuration),
      HealthClient(config).ping().then((_) {}),
    ]);
    if (!mounted) {
      return;
    }
    await ref.read(sessionControllerProvider.notifier).restore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _logoTurns.dispose();
    _loaderTurns.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(splashAnimateProvider, (_, _) => _syncMotion());
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final logoSize = SplashMetrics.logoAssetSize(size);
    final glowSize = 242 * SplashMetrics.scale(size);
    final loaderBottom = SplashMetrics.loaderBottom > padding.bottom + 24
        ? SplashMetrics.loaderBottom
        : padding.bottom + 24;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: const Color(0xFF051944),
        body: Stack(
          fit: StackFit.expand,
          children: [
            const DecoratedBox(
              decoration: BoxDecoration(gradient: SplashMetrics.gradient),
            ),
            const CustomPaint(painter: SplashBackdropPainter()),
            Positioned(
              top:
                  size.height * SplashMetrics.logoVerticalFactor - logoSize / 2,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: glowSize > logoSize ? glowSize : logoSize,
                  height: glowSize > logoSize ? glowSize : logoSize,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      IgnorePointer(
                        child: Container(
                          width: glowSize,
                          height: glowSize,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              colors: [
                                Color.fromRGBO(56, 126, 245, 0.45),
                                Color.fromRGBO(20, 75, 180, 0.15),
                                Color(0x00000000),
                              ],
                              stops: [0.0, 0.55, 0.75],
                            ),
                          ),
                        ),
                      ),
                      _LogoFlip(
                        turns: _logoTurns,
                        flipping: _spinning,
                        size: logoSize,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: loaderBottom,
              child: Center(
                child: _LoaderRing(turns: _loaderTurns, spinning: _spinning),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Y-axis coin flip: front → edge → blank back → edge → front.
/// One linear 4s loop. Never shows mirrored SpeedyGo lettering.
class _LogoFlip extends StatelessWidget {
  const _LogoFlip({
    required this.turns,
    required this.flipping,
    required this.size,
  });

  final Animation<double> turns;
  final bool flipping;
  final double size;

  static const _perspective = 0.0012;

  @override
  Widget build(BuildContext context) {
    final front = Image.asset(
      SplashMetrics.assetPath,
      key: const Key('splash-logo'),
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      semanticLabel: AppStrings.appName,
    );
    if (!flipping) {
      return front;
    }
    return AnimatedBuilder(
      key: const Key('splash-logo-flip'),
      animation: turns,
      builder: (context, _) {
        final angle = turns.value * math.pi * 2;
        final showFront = math.cos(angle) >= 0;
        final tilt = showFront ? angle : angle + math.pi;
        return Transform(
          alignment: Alignment.center,
          filterQuality: FilterQuality.medium,
          transform: Matrix4.identity()
            ..setEntry(3, 2, _perspective)
            ..rotateY(tilt),
          child: showFront ? front : _LogoBackFace(size: size),
        );
      },
    );
  }
}

class _LogoBackFace extends StatelessWidget {
  const _LogoBackFace({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    final inset = size * (53 / 500);
    final inner = size - inset * 2;
    return SizedBox(
      key: const Key('splash-logo-back'),
      width: size,
      height: size,
      child: Padding(
        padding: EdgeInsets.all(inset),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(inner * 0.2237),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF3565BD), Color(0xFF15277C)],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoaderRing extends StatelessWidget {
  const _LoaderRing({required this.turns, required this.spinning});

  final Animation<double> turns;
  final bool spinning;

  @override
  Widget build(BuildContext context) {
    const ring = CustomPaint(
      key: Key('splash-loader'),
      size: Size.square(SplashMetrics.loaderSize),
      painter: SplashLoaderPainter(),
    );
    if (!spinning) {
      return ring;
    }
    return RotationTransition(turns: turns, child: ring);
  }
}
