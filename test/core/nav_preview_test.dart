import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/core/navigation/app_routes.dart';
import 'package:speedygo_customer_app/core/navigation/nav_preview.dart';

void main() {
  test('live order confirmation is not a preview path', () {
    expect(
      NavPreview.isPreviewPath(
        AppRoutes.orderConfirmation('11111111-1111-4111-8111-111111111111'),
      ),
      isFalse,
    );
    expect(
      NavPreview.isPreviewPath(
        AppRoutes.orderCompleted('11111111-1111-4111-8111-111111111111'),
      ),
      isFalse,
    );
    expect(
      NavPreview.isPreviewPath(
        AppRoutes.orderNearby('11111111-1111-4111-8111-111111111111'),
      ),
      isFalse,
    );
  });

  test('fixture order confirmation remains a preview path', () {
    expect(
      NavPreview.isPreviewPath(AppRoutes.orderConfirmation(AppRoutes.navOrder)),
      isTrue,
    );
    expect(NavPreview.isPreviewPath(AppRoutes.directory), isTrue);
  });
}
