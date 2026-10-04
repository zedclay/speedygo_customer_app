import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/catalog/data/catalog_models.dart';
import 'package:speedygo_customer_app/features/home/presentation/commerce_vertical_presentation.dart';
import 'package:speedygo_customer_app/features/home/presentation/widgets/home_chrome.dart';

class CommerceVerticalsScreen extends ConsumerStatefulWidget {
  const CommerceVerticalsScreen({super.key});

  @override
  ConsumerState<CommerceVerticalsScreen> createState() =>
      _CommerceVerticalsScreenState();
}

class _CommerceVerticalsScreenState
    extends ConsumerState<CommerceVerticalsScreen> {
  final _searchFocus = FocusNode();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _searchFocus.dispose();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _openVertical(CommerceVertical vertical) {
    context.push(AppRoutes.homeCategoryResults(vertical.id));
  }

  @override
  Widget build(BuildContext context) {
    final verticals = ref.watch(commerceVerticalsProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: verticals.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(CategoriesLayout.margin),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    AppStrings.categoriesLoadError,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () =>
                        ref.invalidate(commerceVerticalsProvider),
                    child: const Text(AppStrings.retry),
                  ),
                ],
              ),
            ),
          ),
          data: (items) => _CategoriesBody(
            items: items,
            searchController: _searchController,
            searchFocus: _searchFocus,
            scrollController: _scrollController,
            onBack: () => popOrParent(context),
            onFocusSearch: () => _searchFocus.requestFocus(),
            onOpen: _openVertical,
            onQueryChanged: (_) => setState(() {}),
          ),
        ),
      ),
    );
  }
}

class _CategoriesBody extends StatelessWidget {
  const _CategoriesBody({
    required this.items,
    required this.searchController,
    required this.searchFocus,
    required this.scrollController,
    required this.onBack,
    required this.onFocusSearch,
    required this.onOpen,
    required this.onQueryChanged,
  });

  final List<CommerceVertical> items;
  final TextEditingController searchController;
  final FocusNode searchFocus;
  final ScrollController scrollController;
  final VoidCallback onBack;
  final VoidCallback onFocusSearch;
  final ValueChanged<CommerceVertical> onOpen;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    final filtered = filterVerticalsByQuery(items, searchController.text);
    final queryActive = searchController.text.trim().isNotEmpty;
    final featured = queryActive
        ? null
        : featuredRestaurantsVertical(filtered);
    final explorer = queryActive
        ? filtered
        : explorerVerticals(filtered);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            CategoriesLayout.margin,
            12,
            CategoriesLayout.margin,
            0,
          ),
          child: Row(
            children: [
              _RoundIconButton(
                tooltip: AppStrings.back,
                icon: Icons.arrow_back,
                onPressed: onBack,
              ),
              Expanded(
                child: Text(
                  AppStrings.allCategoriesTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                    height: 28 / 20,
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              _RoundIconButton(
                tooltip: AppStrings.tabSearch,
                icon: Icons.search,
                onPressed: onFocusSearch,
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text(AppStrings.categoriesEmpty))
              : ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(
                    CategoriesLayout.margin,
                    CategoriesLayout.sectionGap,
                    CategoriesLayout.margin,
                    HomeLayout.listBottomGap,
                  ),
                  children: [
                    _CategorySearchField(
                      controller: searchController,
                      focusNode: searchFocus,
                      onChanged: onQueryChanged,
                    ),
                    if (featured != null) ...[
                      const SizedBox(height: CategoriesLayout.sectionGap),
                      _RestaurantsFeatureCard(
                        vertical: featured,
                        onOpen: () => onOpen(featured),
                      ),
                    ],
                    const SizedBox(height: CategoriesLayout.sectionGap),
                    Text(
                      AppStrings.categoriesExploreHeading,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        height: 24 / 18,
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: CategoriesLayout.gridGap),
                    if (explorer.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 32),
                        child: Text(
                          queryActive
                              ? AppStrings.categoriesSearchEmpty
                              : AppStrings.categoriesEmpty,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.onSurfaceVariant),
                        ),
                      )
                    else
                      _CategoryGrid(items: explorer, onOpen: onOpen),
                  ],
                ),
        ),
      ],
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({
    required this.icon,
    required this.onPressed,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: CategoriesLayout.surfaceContainer,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: CategoriesLayout.headerButton,
            height: CategoriesLayout.headerButton,
            child: Icon(icon, size: 20, color: AppColors.onSurface),
          ),
        ),
      ),
    );
  }
}

class _CategorySearchField extends StatelessWidget {
  const _CategorySearchField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      key: const Key('categories-search-field'),
      controller: controller,
      focusNode: focusNode,
      autofocus: false,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontSize: 14,
        color: AppColors.onSurface,
      ),
      decoration: InputDecoration(
        hintText: AppStrings.categoriesSearchHint,
        hintStyle: TextStyle(
          color: AppColors.onSurfaceVariant.withValues(alpha: 0.7),
          fontSize: 14,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: AppColors.onSurfaceVariant,
          size: 20,
        ),
        filled: true,
        fillColor: CategoriesLayout.surfaceContainer,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CategoriesLayout.searchRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CategoriesLayout.searchRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(CategoriesLayout.searchRadius),
          borderSide: const BorderSide(
            color: AppColors.primaryContainer,
            width: 2,
          ),
        ),
      ),
    );
  }
}

class _RestaurantsFeatureCard extends StatelessWidget {
  const _RestaurantsFeatureCard({
    required this.vertical,
    required this.onOpen,
  });

  final CommerceVertical vertical;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final subtitle = commerceVerticalSubtitle(vertical.slug);
    return Material(
      key: Key('categories-feature-${vertical.id}'),
      color: Colors.transparent,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(CategoriesLayout.cardRadius),
        child: Ink(
          height: CategoriesLayout.heroHeight,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(CategoriesLayout.cardRadius),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(CategoriesLayout.cardRadius),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  restaurantsHeroAsset,
                  key: const Key('categories-restaurants-hero-image'),
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => Container(
                    color: AppColors.primaryContainer,
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Color(0x4D000000),
                        Color(0xCC000000),
                      ],
                      stops: [0.0, 0.45, 1.0],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vertical.name,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 20,
                                    height: 28 / 20,
                                  ),
                            ),
                            if (subtitle != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                subtitle,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      fontSize: 12,
                                      height: 16 / 12,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Material(
                        color: AppColors.primaryContainer,
                        shape: const CircleBorder(),
                        elevation: 2,
                        child: InkWell(
                          key: Key('categories-feature-arrow-${vertical.id}'),
                          customBorder: const CircleBorder(),
                          onTap: onOpen,
                          child: const SizedBox(
                            width: 40,
                            height: 40,
                            child: Icon(
                              Icons.arrow_forward,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
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

class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({required this.items, required this.onOpen});

  final List<CommerceVertical> items;
  final ValueChanged<CommerceVertical> onOpen;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final tileWidth = (width - CategoriesLayout.gridGap) / 2;
        return Wrap(
          spacing: CategoriesLayout.gridGap,
          runSpacing: CategoriesLayout.gridGap,
          children: [
            for (final vertical in items)
              SizedBox(
                width: tileWidth,
                child: _CategoryTile(
                  vertical: vertical,
                  onOpen: () => onOpen(vertical),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({required this.vertical, required this.onOpen});

  final CommerceVertical vertical;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final style = commerceVerticalBadgeStyle(vertical);
    final subtitle = commerceVerticalSubtitle(vertical.slug);
    return Material(
      key: Key('categories-tile-${vertical.id}'),
      color: CategoriesLayout.surfaceContainer,
      borderRadius: BorderRadius.circular(CategoriesLayout.tileRadius),
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(CategoriesLayout.tileRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: CategoriesLayout.iconBadge,
                height: CategoriesLayout.iconBadge,
                decoration: BoxDecoration(
                  color: style.background,
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, color: style.foreground, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                vertical.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  height: 20 / 14,
                  color: AppColors.onSurface,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 10,
                    height: 14 / 10,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
