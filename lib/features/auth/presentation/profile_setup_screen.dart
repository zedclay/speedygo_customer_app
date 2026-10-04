import 'dart:ui';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/widgets/sg_primary_button.dart';
import 'package:speedygo_customer_app/core/widgets/sg_snackbar.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  String get _initials {
    final parts = _controller.text.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) {
      return '';
    }
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return '$first$last'.toUpperCase();
  }

  void _photoUnavailable() {
    SgSnack.info(context, message: AppStrings.profilePhotoUnavailable);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final canSubmit = _controller.text.trim().isNotEmpty;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final focused = _focus.hasFocus;

    return Scaffold(
      backgroundColor: AppColors.surface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            AppStrings.profileTitle,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  height: 24 / 16,
                                  color: AppColors.onSurface,
                                ),
                          ),
                          Text(
                            AppStrings.profileStep.toUpperCase(),
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: AppColors.outline,
                                  letterSpacing: 0.8,
                                  fontSize: 11,
                                  height: 16 / 11,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
                children: [
                  Center(
                    child: SizedBox(
                      width: 160,
                      height: 160,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          IgnorePointer(
                            child: Container(
                              width: 160,
                              height: 160,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Color(0x140A4096),
                                    Color(0x000A4096),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 96,
                            height: 96,
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x0F000000),
                                  blurRadius: 8,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _initials.isEmpty ? 'SG' : _initials,
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: AppColors.onPrimaryContainer,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 24,
                                    height: 32 / 24,
                                    letterSpacing: -0.4,
                                  ),
                            ),
                          ),
                          Positioned(
                            right: 28,
                            bottom: 28,
                            child: Material(
                              color: AppColors.primary,
                              shape: const CircleBorder(
                                side: BorderSide(color: Colors.white, width: 2),
                              ),
                              elevation: 4,
                              shadowColor: const Color(0x33000000),
                              child: InkWell(
                                customBorder: const CircleBorder(),
                                onTap: _photoUnavailable,
                                child: const SizedBox(
                                  width: 32,
                                  height: 32,
                                  child: Icon(
                                    Icons.photo_camera,
                                    size: 18,
                                    color: AppColors.onPrimary,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.profilePhotoUnavailable,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 14,
                      height: 20 / 14,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Text.rich(
                    TextSpan(
                      text: '${AppStrings.fullNameLabel} ',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 14,
                        height: 20 / 14,
                      ),
                      children: const [
                        TextSpan(
                          text: '*',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _controller,
                    focusNode: _focus,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.name],
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontSize: 16,
                      height: 24 / 16,
                      color: AppColors.onSurface,
                    ),
                    decoration: InputDecoration(
                      hintText: AppStrings.fullNameHint,
                      filled: true,
                      fillColor: AppColors.surfaceContainerLowest,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      suffixIcon: Icon(
                        Icons.person_outline,
                        color: session.errorMessage != null
                            ? AppColors.error
                            : focused
                            ? AppColors.primary
                            : AppColors.outline,
                      ),
                      errorText: session.errorMessage,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.outlineVariant,
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.outlineVariant,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: AppColors.primary,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (_) {
                      ref
                          .read(sessionControllerProvider.notifier)
                          .dismissError();
                      setState(() {});
                    },
                    onSubmitted: (_) {
                      if (canSubmit && !session.busy) {
                        ref
                            .read(sessionControllerProvider.notifier)
                            .submitProfile(_controller.text);
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  const _ProfileConsent(),
                ],
              ),
            ),
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest.withValues(
                      alpha: 0.8,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0D000000),
                        blurRadius: 20,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      bottomInset > 0 ? 8 : 16,
                    ),
                    child: SgPrimaryButton(
                      label: session.busy
                          ? AppStrings.profileSaving
                          : AppStrings.continueLabel,
                      icon: Icons.chevron_right,
                      loading: session.busy,
                      onPressed: canSubmit
                          ? () {
                              ref
                                  .read(sessionControllerProvider.notifier)
                                  .submitProfile(_controller.text);
                            }
                          : null,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileConsent extends StatefulWidget {
  const _ProfileConsent();

  @override
  State<_ProfileConsent> createState() => _ProfileConsentState();
}

class _ProfileConsentState extends State<_ProfileConsent> {
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()
      ..onTap = () => context.push(AppRoutes.legalTerms);
    _privacyTap = TapGestureRecognizer()
      ..onTap = () => context.push(AppRoutes.legalPrivacy);
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.bodyMedium?.copyWith(
      color: AppColors.onSurfaceVariant,
      fontSize: 14,
      height: 20 / 14,
    );
    final link = base?.copyWith(
      color: AppColors.primary,
      fontWeight: FontWeight.w600,
    );
    return Text.rich(
      TextSpan(
        text: AppStrings.profileConsentPrefix,
        style: base,
        children: [
          TextSpan(
            text: AppStrings.profileTermsLink,
            style: link,
            recognizer: _termsTap,
          ),
          TextSpan(text: AppStrings.profileConsentMid, style: base),
          TextSpan(
            text: '${AppStrings.profilePrivacyLink}.',
            style: link,
            recognizer: _privacyTap,
          ),
        ],
      ),
    );
  }
}
