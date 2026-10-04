import 'package:speedygo_customer_app/core/constants/app_strings.dart';

String supportStatusLabel(String status) {
  switch (status) {
    case 'OPEN':
      return AppStrings.supportStatusOpen;
    case 'IN_PROGRESS':
      return AppStrings.supportStatusInProgress;
    case 'WAITING_CUSTOMER':
      return AppStrings.supportStatusWaitingCustomer;
    case 'RESOLVED':
      return AppStrings.supportStatusResolved;
    case 'CLOSED':
      return AppStrings.supportStatusClosed;
    default:
      return AppStrings.supportStatusUnknown;
  }
}

String supportPriorityLabel(String priority) {
  switch (priority) {
    case 'LOW':
      return AppStrings.supportPriorityLow;
    case 'NORMAL':
      return AppStrings.supportPriorityNormal;
    case 'HIGH':
      return AppStrings.supportPriorityHigh;
    default:
      return AppStrings.supportPriorityUnknown;
  }
}
