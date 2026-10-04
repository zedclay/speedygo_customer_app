import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/features/support/application/support_detail_controller.dart';
import 'package:speedygo_customer_app/features/support/data/support_models.dart';
import 'package:speedygo_customer_app/features/support/presentation/support_status_label.dart';

/// Soft lift from Stitch `d_tails_du_ticket_support_speedygo`.
/// Honest gaps: no close-ticket action, attachments, emoji, or merchant imagery.
const _kSupportCardShadow = BoxShadow(
  color: Color(0x0A000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

class SupportDetailScreen extends ConsumerStatefulWidget {
  const SupportDetailScreen({super.key, required this.ticketId});

  final String ticketId;

  @override
  ConsumerState<SupportDetailScreen> createState() =>
      _SupportDetailScreenState();
}

class _SupportDetailScreenState extends ConsumerState<SupportDetailScreen> {
  late final TextEditingController _draft;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _draft = TextEditingController();
  }

  @override
  void dispose() {
    _draft.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    FocusScope.of(context).unfocus();
    final message = await ref
        .read(supportDetailControllerProvider(widget.ticketId).notifier)
        .sendReply();
    if (!mounted) {
      return;
    }
    if (message != null) {
      _draft.clear();
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (_scroll.hasClients) {
        await _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(
      supportDetailControllerProvider(widget.ticketId),
    );
    // Keep the field in sync with controller draft (retain across Back).
    if (_draft.text != state.draftBody) {
      final next = state.draftBody;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _draft.text == next) {
          return;
        }
        _draft.value = TextEditingValue(
          text: next,
          selection: TextSelection.collapsed(offset: next.length),
        );
      });
    }
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
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
          AppStrings.supportDetailTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            tooltip: AppStrings.supportRefresh,
            onPressed: state.busy
                ? null
                : () => ref
                      .read(
                        supportDetailControllerProvider(
                          widget.ticketId,
                        ).notifier,
                      )
                      .refresh(),
            icon: const Icon(Icons.refresh, color: AppColors.primary),
          ),
        ],
      ),
      body: state.phase == SupportDetailPhase.loading && state.ticket == null
          ? const Center(child: CircularProgressIndicator())
          : state.ticket == null
          ? _error(state)
          : Column(
              children: [
                Expanded(child: _messages(state.ticket!)),
                if (state.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: Text(
                      state.errorMessage!,
                      key: const Key('support-detail-error'),
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ),
                if (state.phase == SupportDetailPhase.pendingVerification)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: OutlinedButton(
                      key: const Key('support-detail-reconcile'),
                      onPressed: () => ref
                          .read(
                            supportDetailControllerProvider(
                              widget.ticketId,
                            ).notifier,
                          )
                          .reconcileAfterUncertain(),
                      child: const Text(AppStrings.supportRefresh),
                    ),
                  ),
                _composer(state, bottomInset),
              ],
            ),
    );
  }

  Widget _error(SupportDetailState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.errorMessage ?? AppStrings.supportDetailLoadError,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => ref
                  .read(
                    supportDetailControllerProvider(widget.ticketId).notifier,
                  )
                  .refresh(),
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      ),
    );
  }

  Widget _messages(SupportTicketDetail ticket) {
    return ListView(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.outlineVariant.withValues(alpha: 0.3),
            ),
            boxShadow: const [_kSupportCardShadow],
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer.withValues(
                                alpha: 0.12,
                              ),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              supportStatusLabel(ticket.status),
                              key: const Key('support-detail-status'),
                              style: Theme.of(context).textTheme.labelMedium
                                  ?.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            ticket.publicReference,
                            key: const Key('support-detail-reference'),
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          AppStrings.supportPriorityLabel,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                            color: AppColors.outline,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          supportPriorityLabel(ticket.priority),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (ticket.order != null) ...[
          const SizedBox(height: 12),
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.push(AppRoutes.order(ticket.order!.id)),
              child: Ink(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.outlineVariant.withValues(alpha: 0.3),
                  ),
                  boxShadow: const [_kSupportCardShadow],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.supportOrderLinked,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                color: AppColors.outline,
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              ticket.order!.publicReference,
                              key: const Key('support-detail-order'),
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.open_in_new,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 20),
        for (final message in ticket.messages) ...[
          _Bubble(
            key: Key('support-message-${message.id}'),
            message: message,
            confirmed: message.id ==
                ref
                    .watch(supportDetailControllerProvider(widget.ticketId))
                    .lastConfirmedMessageId,
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Widget _composer(SupportDetailState state, double bottomInset) {
    if (!state.canReply) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
          child: Text(
            AppStrings.supportReplyClosed,
            key: const Key('support-reply-closed'),
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ),
      );
    }
    return Material(
      color: AppColors.surface,
      elevation: 0,
      shadowColor: const Color(0x140A4096),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: Color(0x1A747783)),
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x0D0A4096),
              blurRadius: 12,
              offset: Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 10 + bottomInset),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('support-reply-body'),
                    controller: _draft,
                    minLines: 1,
                    maxLines: 5,
                    maxLength: supportBodyMaxLength,
                    style: Theme.of(context).textTheme.bodyMedium,
                    decoration: InputDecoration(
                      hintText: AppStrings.supportReplyHint,
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      isDense: true,
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: AppColors.outlineVariant.withValues(
                            alpha: 0.35,
                          ),
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
                          supportDetailControllerProvider(
                            widget.ticketId,
                          ).notifier,
                        )
                        .setDraftBody(value),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 48,
                  height: 48,
                  child: FilledButton(
                    key: const Key('support-reply-send'),
                    style: FilledButton.styleFrom(
                      padding: EdgeInsets.zero,
                      shape: const CircleBorder(),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    onPressed: state.phase == SupportDetailPhase.sending ||
                            state.phase ==
                                SupportDetailPhase.pendingVerification
                        ? null
                        : _send,
                    child: state.phase == SupportDetailPhase.sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : const Icon(Icons.send, size: 20),
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

class _Bubble extends StatelessWidget {
  const _Bubble({
    super.key,
    required this.message,
    required this.confirmed,
  });

  final SupportMessage message;
  final bool confirmed;

  @override
  Widget build(BuildContext context) {
    final fromSupport = message.isFromSupport;
    final align =
        fromSupport ? CrossAxisAlignment.start : CrossAxisAlignment.end;
    final color = fromSupport
        ? AppColors.surfaceContainerHigh
        : AppColors.primary;
    final textColor =
        fromSupport ? AppColors.onSurfaceVariant : AppColors.onPrimary;
    return Column(
      crossAxisAlignment: align,
      children: [
        if (fromSupport)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.support_agent,
                    size: 14,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  AppStrings.supportAgent,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          )
        else
          Text(
            AppStrings.supportYou,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        if (!fromSupport) const SizedBox(height: 4),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.sizeOf(context).width * 0.85,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(fromSupport ? 4 : 16),
                bottomRight: Radius.circular(fromSupport ? 16 : 4),
              ),
              border: fromSupport
                  ? Border.all(
                      color: AppColors.outlineVariant.withValues(alpha: 0.2),
                    )
                  : null,
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                message.body,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: textColor,
                ),
              ),
            ),
          ),
        ),
        if (confirmed)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              AppStrings.supportMessageConfirmed,
              key: const Key('support-message-confirmed'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primary,
              ),
            ),
          ),
      ],
    );
  }
}
