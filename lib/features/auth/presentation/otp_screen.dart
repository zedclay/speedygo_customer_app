import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_constants.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/utils/phone_input.dart';
import 'package:speedygo_customer_app/core/widgets/sg_primary_button.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';

class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final code = _controller.text.replaceAll(RegExp(r'\D'), '');
    await ref.read(sessionControllerProvider.notifier).verifyOtp(code);
  }

  Future<void> _resend() async {
    await ref.read(sessionControllerProvider.notifier).resendOtp();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final phone = session.pendingPhone ?? '';
    final code = _controller.text.replaceAll(RegExp(r'\D'), '');
    final seconds = session.otpResendSecondsRemaining;
    final clock = '00:${seconds.toString().padLeft(2, '0')}';
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 64,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: AppStrings.back,
                      onPressed: () => context.go('/phone'),
                      icon: const Icon(Icons.arrow_back),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: AppStrings.needHelp,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(AppStrings.helpUnavailable),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.help_outline,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                children: [
                  Text(
                    AppStrings.otpTitle,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        AppStrings.otpSentTo(
                          PhoneInput.maskInternational(phone),
                        ),
                        style: Theme.of(context).textTheme.bodyLarge
                            ?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                      TextButton(
                        onPressed: () => context.go('/phone'),
                        child: const Text(AppStrings.editNumber),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _OtpBoxes(
                    code: code,
                    onTap: () => _focus.requestFocus(),
                    child: TextField(
                      controller: _controller,
                      focusNode: _focus,
                      autofocus: true,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(
                          AppConstants.otpLength,
                        ),
                      ],
                      style: const TextStyle(
                        color: Colors.transparent,
                        fontSize: 1,
                      ),
                      cursorColor: Colors.transparent,
                      showCursor: false,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (_) => setState(() {}),
                      onSubmitted: (_) {
                        if (code.length == AppConstants.otpLength) {
                          _verify();
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  seconds > 0
                      ? Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 18,
                              color: AppColors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                AppStrings.resendIn(clock),
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                              ),
                            ),
                          ],
                        )
                      : Center(
                          child: TextButton(
                            onPressed: session.busy ? null : _resend,
                            child: const Text(AppStrings.resend),
                          ),
                        ),
                  if (session.errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      session.errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset > 0 ? 8 : 24),
              child: SgPrimaryButton(
                label: AppStrings.verify,
                loading: session.busy,
                onPressed: code.length == AppConstants.otpLength
                    ? _verify
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpBoxes extends StatelessWidget {
  const _OtpBoxes({
    required this.code,
    required this.onTap,
    required this.child,
  });

  final String code;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: List.generate(AppConstants.otpLength, (index) {
              final filled = index < code.length;
              final focused =
                  index == code.length ||
                  (code.length == AppConstants.otpLength &&
                      index == AppConstants.otpLength - 1);
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: index == AppConstants.otpLength - 1 ? 0 : 8,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 56,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: focused
                            ? AppColors.primaryContainer
                            : AppColors.outlineVariant,
                        width: focused ? 2 : 1,
                      ),
                    ),
                    child: Text(
                      filled ? code[index] : '',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              );
            }),
          ),
          Positioned.fill(child: Opacity(opacity: 0.01, child: child)),
        ],
      ),
    );
  }
}
