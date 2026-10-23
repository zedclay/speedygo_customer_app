import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/features/auth/application/session_controller.dart';

/// Account-scoped cache key. Logout / switch account increments generation.
final catalogScopeProvider = Provider<String>((ref) {
  final session = ref.watch(sessionControllerProvider);
  return '${session.generation}:${session.customer?.profile?.id ?? ''}';
});

/// Launch wilaya for discovery only. Does not enable administrative coverage.
class LaunchWilaya extends Notifier<String> {
  static const sidiBelAbbes = '22';

  @override
  String build() {
    ref.watch(catalogScopeProvider);
    return sidiBelAbbes;
  }

  void select(String code) {
    if (RegExp(r'^\d{2}$').hasMatch(code)) {
      state = code;
    }
  }
}

final launchWilayaCodeProvider = NotifierProvider<LaunchWilaya, String>(
  LaunchWilaya.new,
);
