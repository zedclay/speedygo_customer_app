import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/navigation/nav_actions.dart';
import 'package:speedygo_customer_app/core/navigation/nav_catalog.dart';
import 'package:speedygo_customer_app/core/navigation/nav_models.dart';
import 'package:speedygo_customer_app/core/navigation/nav_preview.dart';
import 'package:speedygo_customer_app/core/widgets/sg_primary_button.dart';

class NavScaffold extends ConsumerWidget {
  const NavScaffold({
    super.key,
    required this.entry,
    this.params = const {},
    this.extraChildren = const [],
  });

  NavScaffold.route({
    super.key,
    required String route,
    this.params = const {},
    this.extraChildren = const [],
  }) : entry =
           NavCatalog.byRoute(route) ??
           NavEntry(
             id: route,
             designDir: '',
             title: route,
             route: route,
             capability: NavCapability.navigationOnly,
             surface: NavSurface.screen,
             purpose: AppStrings.navOnlyBadge,
           );

  final NavEntry entry;
  final Map<String, String> params;
  final List<Widget> extraChildren;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preview = NavPreview.isEnabled(ref.watch(navPreviewEnabledProvider));
    final links = entry.links.where((link) {
      final location = link.location;
      if (location == null || !NavPreview.isPreviewPath(location)) {
        return true;
      }
      return preview;
    }).toList();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.back,
          onPressed: () => popOrParent(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(entry.title),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              label: Text(capabilityLabel(entry.capability)),
              backgroundColor: AppColors.surfaceContainerLow,
              side: BorderSide.none,
            ),
          ),
          if (entry.designDir.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              entry.designDir,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 12),
          Text(entry.purpose, style: Theme.of(context).textTheme.bodyLarge),
          if (params.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              AppStrings.navFixtureNote,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: params.entries
                  .map(
                    (e) => Chip(
                      label: Text('${e.key}: ${e.value}'),
                      backgroundColor: AppColors.surfaceContainerHigh,
                      side: BorderSide.none,
                    ),
                  )
                  .toList(),
            ),
          ],
          ...extraChildren,
          if (links.isNotEmpty) ...[
            const SizedBox(height: 24),
            for (final link in links) ...[
              SgPrimaryButton(
                label: link.label,
                onPressed: () => openNavLink(context, link),
              ),
              const SizedBox(height: 10),
            ],
          ],
        ],
      ),
    );
  }
}

class NavDirectoryScreen extends StatelessWidget {
  const NavDirectoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final groups = NavCatalog.grouped();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: AppStrings.back,
          onPressed: () => popOrParent(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(AppStrings.allScreens),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(AppStrings.previewBanner),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(AppStrings.allScreensHint),
          ),
          for (final group in groups.entries) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                group.key,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            for (final entry in group.value)
              ListTile(
                title: Text(entry.title),
                subtitle: Text(
                  '${capabilityLabel(entry.capability)} · ${entry.designDir}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (entry.route.isEmpty) {
                    return;
                  }
                  context.push(entry.route);
                },
              ),
          ],
        ],
      ),
    );
  }
}
