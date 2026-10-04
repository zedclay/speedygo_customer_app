import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/features/orders/application/order_detail_controller.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';
import 'package:speedygo_customer_app/features/support/application/support_create_controller.dart';
import 'package:speedygo_customer_app/features/support/data/support_models.dart';

/// Soft lift from Stitch `signaler_un_probl_me_speedygo`.
/// Honest gaps: no issue-category chips, photo proofs, or contact-channel prefs.
const _kSupportCardShadow = BoxShadow(
  color: Color(0x0A000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

class SupportCreateScreen extends ConsumerStatefulWidget {
  const SupportCreateScreen({super.key, this.orderId});

  final String? orderId;

  @override
  ConsumerState<SupportCreateScreen> createState() =>
      _SupportCreateScreenState();
}

class _SupportCreateScreenState extends ConsumerState<SupportCreateScreen> {
  late final TextEditingController _body;

  @override
  void initState() {
    super.initState();
    _body = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderId = widget.orderId?.trim();
      if (orderId != null && orderId.isNotEmpty) {
        ref.read(supportCreateControllerProvider.notifier).setOrderId(orderId);
      }
    });
  }

  @override
  void dispose() {
    _body.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final ticket =
        await ref.read(supportCreateControllerProvider.notifier).submit();
    if (!mounted || ticket == null) {
      return;
    }
    context.pushReplacement(AppRoutes.supportTicket(ticket.id));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supportCreateControllerProvider);
    // Keep the field in sync with controller draft (retain across Back).
    if (_body.text != state.draftBody) {
      final next = state.draftBody;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _body.text == next) {
          return;
        }
        _body.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      });
    }
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final routeOrderId = widget.orderId?.trim();
    final linkedOrderId =
        routeOrderId != null && routeOrderId.isNotEmpty
            ? routeOrderId
            : state.orderId;
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        centerTitle: false,
        leading: IconButton(
          tooltip: AppStrings.back,
          onPressed: () => popOrParent(context),
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
        ),
        title: Text(
          AppStrings.supportNewTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + (bottomInset > 0 ? 0 : 8)),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, color: AppColors.secondary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      AppStrings.supportNoCancelHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (linkedOrderId != null) ...[
            const SizedBox(height: 16),
            _LinkedOrderCard(orderId: linkedOrderId),
          ],
          const SizedBox(height: 20),
          Text(
            AppStrings.supportBodyLabel,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            key: const Key('support-create-body'),
            controller: _body,
            minLines: 6,
            maxLines: 12,
            maxLength: supportBodyMaxLength,
            textInputAction: TextInputAction.newline,
            scrollPadding: const EdgeInsets.only(bottom: 140),
            style: Theme.of(context).textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: AppStrings.supportBodyHint,
              filled: true,
              fillColor: AppColors.surfaceContainerLowest,
              contentPadding: const EdgeInsets.all(16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: AppColors.outlineVariant.withValues(alpha: 0.4),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
            ),
            onChanged: (value) => ref
                .read(supportCreateControllerProvider.notifier)
                .setDraftBody(value),
          ),
          if (state.errorMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              state.errorMessage!,
              key: const Key('support-create-error'),
              style: const TextStyle(color: AppColors.error),
            ),
          ],
          if (state.phase == SupportCreatePhase.pendingVerification) ...[
            const SizedBox(height: 8),
            OutlinedButton(
              key: const Key('support-create-check-list'),
              onPressed: () async {
                await ref
                    .read(supportCreateControllerProvider.notifier)
                    .checkListAfterUncertain();
                if (!context.mounted) {
                  return;
                }
                context.push(AppRoutes.supportList);
              },
              child: const Text(AppStrings.supportCheckList),
            ),
          ],
          const SizedBox(height: 88),
        ],
      ),
      bottomNavigationBar: AnimatedPadding(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: bottomInset),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Material(
              color: AppColors.surface.withValues(alpha: 0.88),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: FilledButton(
                    key: const Key('support-create-submit'),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: state.busy ||
                            state.phase ==
                                SupportCreatePhase.pendingVerification
                        ? null
                        : _submit,
                    child: Text(
                      state.busy
                          ? AppStrings.supportSending
                          : AppStrings.supportSend,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Customer-facing linked-order chrome. [orderId] stays internal for submit.
class _LinkedOrderCard extends ConsumerWidget {
  const _LinkedOrderCard({required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(orderDetailControllerProvider(orderId));
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.outlineVariant.withValues(alpha: 0.35),
        ),
        boxShadow: const [_kSupportCardShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: detail.when(
          skipLoadingOnReload: true,
          loading: () => Text(
            AppStrings.supportOrderLinkedLoading,
            key: const Key('support-create-order-loading'),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          error: (_, _) => _fallback(context),
          data: (order) => _loaded(context, order),
        ),
      ),
    );
  }

  Widget _fallback(BuildContext context) {
    return Text(
      AppStrings.supportOrderLinkedFallback,
      key: const Key('support-create-order-fallback'),
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
  }

  Widget _loaded(BuildContext context, OrderDetail order) {
    final theme = Theme.of(context);
    // OrderDetail has merchantBranchId only — no merchant display name.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.supportOrderLinked,
          style: theme.textTheme.labelSmall?.copyWith(
            color: AppColors.outline,
            letterSpacing: 0.6,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                order.publicReference,
                key: const Key('support-create-order-reference'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              MoneyFormat.dzd(order.financial.customerTotalMinor),
              key: const Key('support-create-order-amount'),
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        const Divider(height: 1),
        const SizedBox(height: 12),
        Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.receipt_long,
                color: AppColors.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                order.status,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
