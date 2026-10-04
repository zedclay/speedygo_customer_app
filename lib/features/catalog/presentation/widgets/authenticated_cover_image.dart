import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/features/auth/application/auth_infrastructure.dart';
import 'package:speedygo_customer_app/features/catalog/presentation/widgets/catalog_placeholders.dart';

/// Relative Customer catalog image path only. Never forwards Bearer tokens
/// to an arbitrary external origin.
String? resolveCustomerCatalogImagePath(String? raw) {
  final url = raw?.trim();
  if (url == null || url.isEmpty) {
    return null;
  }
  if (url.contains('://') || url.startsWith('//') || url.contains('..')) {
    return null;
  }
  var path = url;
  if (path.startsWith('/api/v1/customer/')) {
    path = path.substring('/api/v1'.length);
  }
  if (!path.startsWith('/customer/')) {
    return null;
  }
  return path;
}

bool isCustomerCatalogImageContentType(String? raw) {
  final value = raw?.split(';').first.trim().toLowerCase() ?? '';
  return value == 'image/jpeg' ||
      value == 'image/jpg' ||
      value == 'image/png';
}

final coverImageBytesProvider = FutureProvider.autoDispose
    .family<Uint8List?, String>((ref, path) async {
      final resolved = resolveCustomerCatalogImagePath(path);
      if (resolved == null) {
        return null;
      }
      final dio = ref.watch(authInfrastructureProvider).dio;
      final response = await dio.get<List<int>>(
        resolved,
        options: Options(responseType: ResponseType.bytes),
      );
      final status = response.statusCode ?? 0;
      if (status < 200 || status >= 300) {
        return null;
      }
      if (!isCustomerCatalogImageContentType(
        response.headers.value('content-type'),
      )) {
        return null;
      }
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        return null;
      }
      return Uint8List.fromList(bytes);
    });

class AuthenticatedCatalogImage extends ConsumerWidget {
  const AuthenticatedCatalogImage({
    super.key,
    required this.imageUrl,
    required this.fallbackLabel,
    required this.height,
    this.width,
    this.radius = 0,
    this.icon = Icons.storefront_outlined,
    this.imageKey = const Key('authenticated-catalog-image'),
  });

  final String? imageUrl;
  final String fallbackLabel;
  final double height;
  final double? width;
  final double radius;
  final IconData icon;
  final Key imageKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final path = resolveCustomerCatalogImagePath(imageUrl);
    if (path == null) {
      return CatalogImagePlaceholder(
        key: const Key('catalog-image-unbound'),
        label: fallbackLabel,
        height: height,
        width: width,
        radius: radius,
        icon: icon,
      );
    }
    final asyncBytes = ref.watch(coverImageBytesProvider(path));
    return asyncBytes.when(
      loading: () => SizedBox(
        key: const Key('catalog-image-loading'),
        height: height,
        width: width,
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
      ),
      error: (_, _) => CatalogImagePlaceholder(
        key: const Key('catalog-image-failed'),
        label: fallbackLabel,
        height: height,
        width: width,
        radius: radius,
        icon: icon,
      ),
      data: (bytes) {
        if (bytes == null) {
          return CatalogImagePlaceholder(
            key: const Key('catalog-image-failed'),
            label: fallbackLabel,
            height: height,
            width: width,
            radius: radius,
            icon: icon,
          );
        }
        final image = Image.memory(
          bytes,
          key: imageKey,
          height: height,
          width: width ?? double.infinity,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => CatalogImagePlaceholder(
            key: const Key('catalog-image-failed'),
            label: fallbackLabel,
            height: height,
            width: width,
            radius: radius,
            icon: icon,
          ),
        );
        if (radius <= 0) {
          return image;
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: image,
        );
      },
    );
  }
}

class AuthenticatedCoverImage extends ConsumerWidget {
  const AuthenticatedCoverImage({
    super.key,
    required this.coverImageUrl,
    required this.fallbackLabel,
    required this.height,
  });

  final String? coverImageUrl;
  final String fallbackLabel;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AuthenticatedCatalogImage(
      imageUrl: coverImageUrl,
      fallbackLabel: fallbackLabel,
      height: height,
      imageKey: const Key('authenticated-cover-image'),
    );
  }
}
