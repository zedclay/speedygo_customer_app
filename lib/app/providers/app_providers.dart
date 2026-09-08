import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/constants/app_constants.dart';

final appNameProvider = Provider<String>((ref) => AppConstants.appName);
