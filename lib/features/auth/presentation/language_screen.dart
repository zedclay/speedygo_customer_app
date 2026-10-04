import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_locale.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/widgets/sg_primary_button.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';

/// First-run: `s_lection_de_la_langue_speedygo_c_002`.
/// Settings: `param_tres_de_la_langue_speedygo` (FR only; AR disabled honest).
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key, this.settings = false});

  final bool settings;

  static const _title = Color(0xFF0F172A);
  static const _muted = Color(0xFF475569);
  static const _canvas = Color(0xFFF7F9FC);
  static const _brand = AppColors.primaryContainer;
  static const _checkFill = Color(0xFFD9F99D);
  static const _checkMark = Color(0xFF166534);
  static const _secondaryContainer = Color(0xFF94A6FF);
  static const _onSecondaryContainer = Color(0xFF24388B);
  static const _cardShadow = BoxShadow(
    color: Color(0x0A000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  Future<void> _continue(BuildContext context, WidgetRef ref) async {
    await ref
        .read(sessionControllerProvider.notifier)
        .markLanguageSeen(locale: AppLocale.french);
    if (settings && context.mounted) {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (settings) {
      return _SettingsLanguageBody(onSave: () => _continue(context, ref));
    }
    return _FirstRunLanguageBody(onContinue: () => _continue(context, ref));
  }
}

class _FirstRunLanguageBody extends StatelessWidget {
  const _FirstRunLanguageBody({required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    final logo = (96.0 / textScale.clamp(1.0, 1.4)).clamp(72.0, 96.0);

    return Scaffold(
      backgroundColor: LanguageScreen._canvas,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          children: [
                            SizedBox(
                              height: constraints.maxHeight < 560 ? 8 : 32,
                            ),
                            _LogoMark(size: logo),
                            SizedBox(
                              height: constraints.maxHeight < 560 ? 24 : 32,
                            ),
                            Text(
                              AppStrings.languageTitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: LanguageScreen._title,
                                    fontSize: 30,
                                    letterSpacing: -0.4,
                                    height: 1.15,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                AppStrings.languageSubtitle,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: LanguageScreen._muted,
                                      fontSize: 15,
                                      height: 1.45,
                                    ),
                              ),
                            ),
                            SizedBox(
                              height: constraints.maxHeight < 560 ? 24 : 40,
                            ),
                            const _LanguageTile(
                              selected: true,
                              enabled: true,
                              title: AppStrings.languageFrench,
                              subtitle: AppStrings.languageFrenchHint,
                              style: _LanguageTileStyle.firstRun,
                            ),
                            const SizedBox(height: 16),
                            const _LanguageTile(
                              selected: false,
                              enabled: false,
                              title: AppStrings.languageArabic,
                              subtitle: AppStrings.languageArabicHint,
                              badge: AppStrings.languageArabicDisabled,
                              rtl: true,
                              style: _LanguageTileStyle.firstRun,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              Theme(
                data: Theme.of(context).copyWith(
                  filledButtonTheme: FilledButtonThemeData(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: LanguageScreen._brand,
                      foregroundColor: AppColors.onPrimary,
                      elevation: 1,
                      shadowColor: const Color(0x1A000000),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                child: SgPrimaryButton(
                  label: AppStrings.continueLabel,
                  onPressed: onContinue,
                ),
              ),
              const SizedBox(height: 16),
              const _TermsFootnote(),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsLanguageBody extends ConsumerWidget {
  const _SettingsLanguageBody({required this.onSave});

  final VoidCallback onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final name = session.customer?.displayName?.trim();
    final first = (name == null || name.isEmpty)
        ? AppStrings.appName
        : name.split(RegExp(r'\s+')).first;
    final greeting = AppStrings.landingHello(first);

    return Scaffold(
      backgroundColor: AppColors.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: AppColors.surfaceContainerLowest,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        leading: IconButton(
          tooltip: AppStrings.back,
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        ),
        title: Text(
          AppStrings.accountLanguageLabel,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: AppColors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 24),
              children: [
                Text(
                  greeting,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.languageSettingsSubtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 32),
                const _LanguageTile(
                  selected: true,
                  enabled: true,
                  title: AppStrings.languageFrench,
                  subtitle: AppStrings.languageFrenchHintSettings,
                  style: _LanguageTileStyle.settings,
                ),
                const SizedBox(height: 16),
                const _LanguageTile(
                  selected: false,
                  enabled: false,
                  title: AppStrings.languageArabicLabel,
                  subtitle: AppStrings.languageArabicHintSettings,
                  badge: AppStrings.languageArabicDisabled,
                  style: _LanguageTileStyle.settings,
                ),
                const SizedBox(height: 40),
                Text(
                  AppStrings.languageDirectionHeading.toUpperCase(),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                const _DirectionPreview(),
                const SizedBox(height: 40),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: LanguageScreen._secondaryContainer.withValues(
                      alpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: LanguageScreen._secondaryContainer.withValues(
                        alpha: 0.4,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.info_outline,
                          size: 20,
                          color: AppColors.secondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            AppStrings.languageSessionNote,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: LanguageScreen._onSecondaryContainer,
                                  height: 1.45,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border(
                top: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: SgPrimaryButton(
                  label: AppStrings.languageSave,
                  icon: Icons.check_circle_outline,
                  onPressed: onSave,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DirectionPreview extends StatelessWidget {
  const _DirectionPreview();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(
                  Icons.format_align_left,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppStrings.languageDirectionLtr,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Container(
                  width: 48,
                  height: 2,
                  color: AppColors.outlineVariant,
                ),
                const SizedBox(width: 12),
                Opacity(
                  opacity: 0.4,
                  child: Row(
                    children: [
                      Text(
                        AppStrings.languageDirectionRtl,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.format_align_right, size: 22),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.outlineVariant.withValues(alpha: 0.5),
                ),
                boxShadow: const [LanguageScreen._cardShadow],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.home,
                        color: AppColors.onPrimaryContainer,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.languageDirectionPreviewTitle,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            AppStrings.languageDirectionPreviewSubtitle,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.outline,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TermsFootnote extends StatefulWidget {
  const _TermsFootnote();

  @override
  State<_TermsFootnote> createState() => _TermsFootnoteState();
}

class _TermsFootnoteState extends State<_TermsFootnote> {
  late final TapGestureRecognizer _termsTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()
      ..onTap = () => context.push(AppRoutes.legalTerms);
  }

  @override
  void dispose() {
    _termsTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        text: AppStrings.languageTermsPrefix,
        style: Theme.of(context).textTheme.bodySmall
            ?.copyWith(color: LanguageScreen._muted, fontSize: 12),
        children: [
          TextSpan(
            text: AppStrings.languageTermsLink,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: LanguageScreen._brand,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            recognizer: _termsTap,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          width: size,
          height: size,
          child: Transform.scale(
            scale: 1.5,
            child: Image.asset(
              'assets/branding/speedygo_logo.png',
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              semanticLabel: AppStrings.appName,
            ),
          ),
        ),
      ),
    );
  }
}

enum _LanguageTileStyle { firstRun, settings }

class _LanguageTile extends StatelessWidget {
  const _LanguageTile({
    required this.selected,
    required this.enabled,
    required this.title,
    required this.subtitle,
    required this.style,
    this.badge,
    this.rtl = false,
  });

  final bool selected;
  final bool enabled;
  final String title;
  final String subtitle;
  final String? badge;
  final bool rtl;
  final _LanguageTileStyle style;

  static const _arabicFallback = [
    'Geeza Pro',
    'Noto Naskh Arabic',
    'Noto Sans Arabic',
    'SF Arabic',
  ];

  bool get _usesArabicScript =>
      rtl || RegExp(r'[\u0600-\u06FF]').hasMatch(title);

  @override
  Widget build(BuildContext context) {
    final isSettings = style == _LanguageTileStyle.settings;
    final radius = isSettings ? 8.0 : 24.0;
    final borderColor = selected
        ? (isSettings ? AppColors.primary : LanguageScreen._brand)
        : (isSettings ? AppColors.outlineVariant : const Color(0xFFE2E8F0));
    final fill = isSettings
        ? AppColors.surfaceContainerLow
        : (selected ? AppColors.surfaceContainerLow : Colors.white);

    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(
        color: borderColor,
        width: selected || isSettings ? 2 : 1,
      ),
    );

    return Semantics(
      enabled: enabled,
      selected: selected,
      child: Opacity(
        opacity: enabled || selected ? 1 : 0.72,
        child: Material(
          color: fill,
          elevation: isSettings || selected ? 0 : 1,
          shadowColor: const Color(0x0A000000),
          shape: shape,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: rtl
                        ? CrossAxisAlignment.end
                        : CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        textDirection:
                            rtl ? TextDirection.rtl : TextDirection.ltr,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isSettings
                                  ? AppColors.onSurface
                                  : LanguageScreen._title,
                              fontSize: isSettings ? 16 : 18,
                              fontFamilyFallback:
                                  _usesArabicScript ? _arabicFallback : null,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        textDirection:
                            rtl ? TextDirection.rtl : TextDirection.ltr,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isSettings
                              ? AppColors.onSurfaceVariant
                              : LanguageScreen._muted,
                          fontSize: isSettings ? 12 : 14,
                          fontFamilyFallback:
                              _usesArabicScript ? _arabicFallback : null,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(height: 8),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            child: Text(
                              badge!,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: LanguageScreen._muted,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                if (isSettings)
                  _SettingsRadio(selected: selected)
                else if (selected)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: LanguageScreen._checkFill,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check,
                      size: 16,
                      color: LanguageScreen._checkMark,
                    ),
                  )
                else
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SettingsRadio extends StatelessWidget {
  const _SettingsRadio({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.outline,
          width: 2,
        ),
      ),
      child: selected
          ? Center(
              child: Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
            )
          : null,
    );
  }
}
