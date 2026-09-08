import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/utils/phone_input.dart';
import 'package:speedygo_customer_app/core/widgets/sg_primary_button.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';

class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});

  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final pending = ref.read(sessionControllerProvider).pendingPhone;
    if (pending != null && pending.isNotEmpty) {
      _controller.text = PhoneInput.formatLocal(pending);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final current = ref.read(sessionControllerProvider);
    if (current.pendingPhone != null && !current.canRequestOtp) {
      context.go('/otp');
      return;
    }
    await ref
        .read(sessionControllerProvider.notifier)
        .requestOtp(_controller.text);
    if (!mounted) {
      return;
    }
    final next = ref.read(sessionControllerProvider);
    if (next.pendingPhone != null && next.errorMessage == null) {
      context.go('/otp');
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final valid = PhoneInput.isValid(_controller.text);

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    child: Text(
                      AppStrings.appName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 16),
                children: [
                  Text(
                    AppStrings.phoneTitle,
                    style: Theme.of(context).textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.phoneSubtitle,
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  const SizedBox(height: 32),
                  Semantics(
                    label: AppStrings.phoneTitle,
                    textField: true,
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.outlineVariant),
                      ),
                      child: Row(
                        children: [
                          const SizedBox(width: 16),
                          const _AlgeriaFlag(),
                          const SizedBox(width: 8),
                          Text(
                            AppStrings.phonePrefix,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(width: 12),
                          Container(
                            width: 1,
                            height: 28,
                            color: AppColors.outlineVariant,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [
                                AutofillHints.telephoneNumber,
                              ],
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: const InputDecoration(
                                hintText: AppStrings.phoneHint,
                                border: InputBorder.none,
                                enabledBorder: InputBorder.none,
                                focusedBorder: InputBorder.none,
                                filled: false,
                              ),
                              onChanged: (value) {
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
                                if (valid && !session.busy) {
                                  _submit();
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppStrings.phoneSmsNote,
                    style: Theme.of(context).textTheme.labelMedium
                        ?.copyWith(color: AppColors.onSurfaceVariant),
                  ),
                  if (session.errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      session.errorMessage!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, bottomInset > 0 ? 8 : 16),
              child: Column(
                children: [
                  SgPrimaryButton(
                    label: AppStrings.continueLabel,
                    icon: Icons.arrow_forward,
                    loading: session.busy,
                    onPressed: valid ? _submit : null,
                  ),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(AppStrings.helpUnavailable),
                        ),
                      );
                    },
                    child: const Text(AppStrings.needHelp),
                  ),
                ],
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
