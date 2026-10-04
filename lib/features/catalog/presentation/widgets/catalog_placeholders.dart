import 'package:flutter/material.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';

class CatalogImagePlaceholder extends StatelessWidget {
  const CatalogImagePlaceholder({
    super.key,
    required this.label,
    this.height,
    this.width,
    this.radius = 16,
    this.icon = Icons.storefront_outlined,
  });

  final String label;
  final double? height;
  final double? width;
  final double radius;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final trimmed = label.trim();
    final initial = trimmed.isEmpty
        ? '?'
        : trimmed.substring(0, 1).toUpperCase();
    final compact =
        (height != null && height! < 80) || (width != null && width! < 80);
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.surfaceContainerHigh,
            AppColors.surfaceContainer,
            Color(0xFFD9E2FC),
          ],
        ),
      ),
      child: compact
          ? Center(
              child: Text(
                initial,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : Center(
              child: Icon(
                icon,
                size: 22,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
    );
  }
}

class CatalogStatusView extends StatelessWidget {
  const CatalogStatusView({
    super.key,
    required this.message,
    this.onRetry,
    this.retryLabel = AppStrings.retry,
    this.icon,
  });

  final String message;
  final VoidCallback? onRetry;
  final String retryLabel;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 48, color: AppColors.onSurfaceVariant),
            const SizedBox(height: 12),
          ],
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge
                ?.copyWith(color: AppColors.onSurfaceVariant),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: Text(retryLabel)),
          ],
        ],
      ),
    );
  }
}

class CatalogLoadMoreBar extends StatelessWidget {
  const CatalogLoadMoreBar({
    super.key,
    required this.hasMore,
    required this.loadingMore,
    required this.loadMoreError,
    required this.onLoadMore,
  });

  final bool hasMore;
  final bool loadingMore;
  final AppException? loadMoreError;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    if (loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
        child: Column(
          children: [
            Text(
              loadMoreError!.message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.error),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: loadingMore ? null : onLoadMore,
              child: const Text(AppStrings.retry),
            ),
          ],
        ),
      );
    }
    if (!hasMore) {
      return const SizedBox.shrink();
    }
    if (loadingMore) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
      child: Center(
        child: OutlinedButton(
          onPressed: onLoadMore,
          child: const Text(AppStrings.loadMore),
        ),
      ),
    );
  }
}
