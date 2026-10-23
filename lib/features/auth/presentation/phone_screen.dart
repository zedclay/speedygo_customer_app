import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/utils/phone_input.dart';
import 'package:speedygo_customer_app/core/widgets/bidi_ltr.dart';
import 'package:speedygo_customer_app/core/widgets/sg_primary_button.dart';
import 'package:speedygo_customer_app/core/widgets/sg_snackbar.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';
import 'package:speedygo_customer_app/features/auth/application/session_state.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _cooldownTicker;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
    final pending = ref.read(sessionControllerProvider).pendingPhone;
    if (pending != null && pending.isNotEmpty) {
      _controller.text = PhoneInput.formatLocal(pending);
    }
    _syncCooldownTicker(ref.read(sessionControllerProvider));
  }

  @override
  void dispose() {
    _cooldownTicker?.cancel();
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _syncCooldownTicker(SessionState session) {
    if (session.otpResendSecondsRemaining > 0) {
      _cooldownTicker ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) {
          return;
        }
        final left =
            ref.read(sessionControllerProvider).otpResendSecondsRemaining;
        setState(() {});
        if (left <= 0) {
          _cooldownTicker?.cancel();
          _cooldownTicker = null;
        }
      });
    } else {
      _cooldownTicker?.cancel();
      _cooldownTicker = null;
    }
  }

  Future<void> _submit() async {
    final current = ref.read(sessionControllerProvider);
    if (!current.canRequestOtp || current.busy) {
      return;
    }
    await ref
        .read(sessionControllerProvider.notifier)
        .requestOtp(_controller.text);
    if (!mounted) {
      return;
    }
    final next = ref.read(sessionControllerProvider);
    _syncCooldownTicker(next);
    if (next.pendingPhone != null && next.errorMessage == null) {
      context.go('/otp');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final valid = PhoneInput.isValid(_controller.text);
    final canSubmit = valid && !session.busy && session.canRequestOtp;
    final cooldown = session.otpResendSecondsRemaining;

    ref.listen(sessionControllerProvider, (_, next) {
      _syncCooldownTicker(next);
    });

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final hasError = session.errorMessage != null;
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
                    SizedBox(
                      width: 40,
                      height: 40,
                      child: session.pendingPhone != null
                          ? IconButton(
                              tooltip: AppStrings.back,
                              padding: EdgeInsets.zero,
                              onPressed: () => context.go('/otp'),
                              icon: const Icon(Icons.arrow_back),
                            )
                          : null,
                    ),
                    Expanded(
                      child: Text(
                        AppStrings.appName,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                              fontSize: 24,
                              height: 32 / 24,
                            ),
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                children: [
                  Text(
                    AppStrings.phoneTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 24,
                      height: 32 / 24,
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.phoneSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontSize: 16,
                      height: 24 / 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Semantics(
                    label: AppStrings.phoneTitle,
                    textField: true,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: hasError
                              ? AppColors.error
                              : focused
                              ? AppColors.primaryContainer
                              : AppColors.outlineVariant,
                          width: focused || hasError ? 2 : 1,
                        ),
                      ),
                      child: BidiLtr(
                        child: Row(
                        children: [
                          const SizedBox(width: 16),
                          const _AlgeriaFlag(),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.phonePrefix,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  height: 24 / 16,
                                ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 1,
                            height: 28,
                            color: AppColors.outlineVariant,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              key: const Key('phone-number-field'),
                              controller: _controller,
                              focusNode: _focus,
                              autofocus: true,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              textDirection: TextDirection.ltr,
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                    height: 24 / 16,
                                    letterSpacing: 0.4,
                                    color: AppColors.onSurface,
                                  ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: InputDecoration(
                                hintText: AppStrings.phoneHint,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (value) {
                                ref
                                    .read(sessionControllerProvider.notifier)
                                    .dismissError();
                                final formatted = PhoneInput.formatLocal(value);
                                if (formatted != value) {
                                  _controller.value = TextEditingValue(
                                    text: formatted,
                                    selection: TextSelection.collapsed(
                                      offset: formatted.length,
                                    ),
                                  );
                                }
                                setState(() {});
                              },
                              onSubmitted: (_) {
                                if (canSubmit) {
                                  _submit();
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                      ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      AppStrings.phoneSmsNote,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 12,
                        height: 16 / 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  if (cooldown > 0) ...[
                    const SizedBox(height: 12),
                    Text(
                      '${AppStrings.otpCooldownHint} ($cooldown s)',
                      key: const Key('phone-otp-cooldown'),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                  if (session.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      session.errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 32),
                  IgnorePointer(
                    child: Opacity(
                      opacity: 0.2,
                      child: Container(
                        height: 1,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0x00000000),
                              AppColors.primaryContainer,
                              Color(0x00000000),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: ColoredBox(
                  color: AppColors.surface.withValues(alpha: 0.8),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      16,
                      16,
                      16,
                      bottomInset > 0 ? 8 : 16,
                    ),
                    child: Column(
                      children: [
                        SgPrimaryButton(
                          label: AppStrings.continueLabel,
                          icon: Icons.arrow_forward,
                          loading: session.busy,
                          onPressed: canSubmit ? _submit : null,
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            SgSnack.info(
                              context,
                              message: AppStrings.helpUnavailable,
                            );
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            textStyle: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 14,
                                  height: 20 / 14,
                                ),
                          ),
                          child: Text(AppStrings.needHelp),
                        ),
                      ],
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

class _AlgeriaFlag extends StatelessWidget {
  const _AlgeriaFlag();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: SizedBox(
        width: 24,
        height: 16,
        child: Row(
          children: [
            const Expanded(child: ColoredBox(color: Color(0xFF006233))),
            Expanded(
              child: ColoredBox(
                color: Colors.white,
                child: Center(
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      border: Border.all(color: const Color(0xFFD21034)),
                      shape: BoxShape.circle,
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
