import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/core/widgets/sg_snackbar.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/ratings/application/order_rating_controller.dart';
import 'package:speedygo_customer_app/features/ratings/data/rating_models.dart';
import 'package:speedygo_customer_app/features/ratings/presentation/star_rating_bar.dart';

/// Soft lift from Stitch `r_diger_un_avis_speedygo`.
const _kReviewCardShadow = BoxShadow(
  color: Color(0x0A000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

class OrderWriteReviewScreen extends ConsumerStatefulWidget {
  const OrderWriteReviewScreen({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<OrderWriteReviewScreen> createState() =>
      _OrderWriteReviewScreenState();
}

class _OrderWriteReviewScreenState
    extends ConsumerState<OrderWriteReviewScreen> {
  late final TextEditingController _comment;
  var _synced = false;

  @override
  void initState() {
    super.initState();
    _comment = TextEditingController();
  }

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderRatingControllerProvider(widget.orderId));
    if (!_synced && state.phase != OrderRatingPhase.loading) {
      _synced = true;
      if (_comment.text != state.comment) {
        _comment.text = state.comment;
      }
    }
    final order = state.order;
    final storefront = order == null
        ? null
        : ref.watch(storefrontDetailProvider(order.merchantBranchId));
    final merchantName = storefront?.asData?.value.merchantName;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final showSticky = state.phase != OrderRatingPhase.loading &&
        state.phase != OrderRatingPhase.ineligible &&
        state.phase != OrderRatingPhase.error;

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
          AppStrings.ratingWriteTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: state.phase == OrderRatingPhase.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 24 + (showSticky ? 100 : 0)),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.25),
                    ),
                    boxShadow: const [_kReviewCardShadow],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          merchantName ?? AppStrings.ratingWriteTitle,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        if (order != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Commande #${order.publicReference}',
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                        const SizedBox(height: 12),
                        StarRatingBar(
                          value: state.merchantScore,
                          enabled: state.merchantNeedsWrite && !state.busy,
                          size: 36,
                          onChanged: (score) => ref
                              .read(
                                orderRatingControllerProvider(
                                  widget.orderId,
                                ).notifier,
                              )
                              .setMerchantScore(score),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  AppStrings.ratingCommentLabel,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  key: const Key('rating-comment'),
                  controller: _comment,
                  minLines: 6,
                  maxLines: 12,
                  maxLength: ratingCommentMaxLength,
                  enabled: !state.busy &&
                      state.phase != OrderRatingPhase.succeeded &&
                      state.merchantNeedsWrite,
                  style: Theme.of(context).textTheme.bodyLarge,
                  decoration: InputDecoration(
                    hintText: AppStrings.ratingCommentHint,
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
                      .read(
                        orderRatingControllerProvider(widget.orderId).notifier,
                      )
                      .setComment(value),
                ),
                const SizedBox(height: 12),
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
                        const Icon(Icons.security, color: AppColors.secondary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            AppStrings.ratingPrivacyNote,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (state.errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    state.errorMessage!,
                    key: const Key('rating-write-error'),
                    style: const TextStyle(color: AppColors.error),
                  ),
                ],
                if (state.phase == OrderRatingPhase.succeeded)
                  const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      AppStrings.ratingSuccess,
                      key: Key('rating-write-success'),
                    ),
                  ),
                if (state.phase == OrderRatingPhase.pendingVerification)
                  OutlinedButton(
                    onPressed: () => ref
                        .read(
                          orderRatingControllerProvider(widget.orderId).notifier,
                        )
                        .reconcileAfterUncertain(),
                    child: const Text(AppStrings.supportRefresh),
                  ),
              ],
            ),
      bottomNavigationBar: showSticky
          ? AnimatedPadding(
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
                          key: const Key('rating-publish'),
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: state.busy ||
                                  state.phase ==
                                      OrderRatingPhase.pendingVerification ||
                                  state.phase == OrderRatingPhase.succeeded ||
                                  !state.canSubmit
                              ? null
                              : () async {
                                  FocusScope.of(context).unfocus();
                                  final ok = await ref
                                      .read(
                                        orderRatingControllerProvider(
                                          widget.orderId,
                                        ).notifier,
                                      )
                                      .submit();
                                  if (!context.mounted) {
                                    return;
                                  }
                                  if (ok) {
                                    SgSnack.success(
                                      context,
                                      message: AppStrings.ratingSuccess,
                                    );
                                  }
                                },
                          child: Text(
                            state.busy
                                ? AppStrings.ratingSending
                                : AppStrings.ratingPublish,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            )
          : null,
    );
  }
}
