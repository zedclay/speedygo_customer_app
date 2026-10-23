import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/features/support/application/support_list_controller.dart';
import 'package:speedygo_customer_app/features/support/data/support_models.dart';
import 'package:speedygo_customer_app/features/support/presentation/support_status_label.dart';

/// Soft lift for ticket list chrome (Stitch create/detail companions).
const _kSupportCardShadow = BoxShadow(
  color: Color(0x0A000000),
  blurRadius: 8,
  offset: Offset(0, 2),
);

class SupportListScreen extends ConsumerWidget {
  const SupportListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(supportListControllerProvider);
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
          AppStrings.supportListTitle,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('support-list-new'),
        onPressed: () => context.push(AppRoutes.supportNew),
        icon: const Icon(Icons.add),
        label: Text(AppStrings.supportNewRequest),
      ),
      body: RefreshIndicator(
        onRefresh: () =>
            ref.read(supportListControllerProvider.notifier).refresh(),
        child: _body(context, ref, state),
      ),
    );
  }

  Widget _body(
    BuildContext context,
    WidgetRef ref,
    SupportListState state,
  ) {
    if (state.loading && state.items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.errorMessage != null && state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          Text(state.errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () =>
                ref.read(supportListControllerProvider.notifier).refresh(),
            child: Text(AppStrings.retry),
          ),
        ],
      );
    }
    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 48),
          const Icon(
            Icons.support_agent,
            size: 48,
            color: AppColors.outlineVariant,
          ),
          const SizedBox(height: 16),
          Text(
            AppStrings.supportEmpty,
            textAlign: TextAlign.center,
          ),
        ],
      );
    }
    final extra = state.hasMore ? 1 : 0;
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: state.items.length + extra,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        if (index >= state.items.length) {
          return TextButton(
            key: const Key('support-list-more'),
            onPressed: state.loadingMore
                ? null
                : () => ref
                      .read(supportListControllerProvider.notifier)
                      .loadMore(),
            child: Text(
              state.loadingMore
                  ? AppStrings.supportLoadingMore
                  : AppStrings.supportLoadMore,
            ),
          );
        }
        final ticket = state.items[index];
        return _TicketTile(ticket: ticket);
      },
    );
  }
}

class _TicketTile extends StatelessWidget {
  const _TicketTile({required this.ticket});

  final SupportTicketSummary ticket;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: Key('support-ticket-tile-${ticket.id}'),
      color: AppColors.surfaceContainerLowest,
      elevation: 0,
      shadowColor: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => context.push(AppRoutes.supportTicket(ticket.id)),
        borderRadius: BorderRadius.circular(16),
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
                        ticket.publicReference,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
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
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.outline),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
