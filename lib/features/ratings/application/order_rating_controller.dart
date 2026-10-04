import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/orders/application/order_detail_controller.dart';
import 'package:speedygo_customer_app/features/orders/data/order_models.dart';
import 'package:speedygo_customer_app/features/ratings/application/rating_providers.dart';
import 'package:speedygo_customer_app/features/ratings/data/rating_api.dart';
import 'package:speedygo_customer_app/features/ratings/data/rating_models.dart';

enum OrderRatingPhase {
  loading,
  ready,
  submitting,
  pendingVerification,
  succeeded,
  ineligible,
  error,
}

/// Per-target write outcome — merchant and driver are independent.
enum RatingTargetStatus {
  idle,
  confirmed,
  failed,
  uncertain,
  unavailable,
}

class OrderRatingState {
  const OrderRatingState({
    this.phase = OrderRatingPhase.loading,
    this.order,
    this.merchantScore,
    this.driverScore,
    this.comment = '',
    this.existingMerchant,
    this.existingDriver,
    this.merchantStatus = RatingTargetStatus.idle,
    this.driverStatus = RatingTargetStatus.idle,
    this.merchantErrorMessage,
    this.driverErrorMessage,
    this.errorMessage,
    this.errorCode,
    this.lastMerchantRatingId,
    this.lastDriverRatingId,
  });

  final OrderRatingPhase phase;
  final OrderDetail? order;
  final int? merchantScore;
  final int? driverScore;
  final String comment;
  final OrderRating? existingMerchant;
  final OrderRating? existingDriver;
  final RatingTargetStatus merchantStatus;
  final RatingTargetStatus driverStatus;
  final String? merchantErrorMessage;
  final String? driverErrorMessage;
  final String? errorMessage;
  final String? errorCode;
  final String? lastMerchantRatingId;
  final String? lastDriverRatingId;

  bool get busy =>
      phase == OrderRatingPhase.loading ||
      phase == OrderRatingPhase.submitting;

  bool get orderEligible => order?.status == 'COMPLETED';

  bool get merchantConfirmed =>
      existingMerchant != null ||
      lastMerchantRatingId != null ||
      merchantStatus == RatingTargetStatus.confirmed;

  bool get driverConfirmed =>
      existingDriver != null ||
      lastDriverRatingId != null ||
      driverStatus == RatingTargetStatus.confirmed;

  bool get driverUnavailable =>
      driverStatus == RatingTargetStatus.unavailable;

  bool get merchantNeedsWrite =>
      orderEligible &&
      !merchantConfirmed &&
      merchantStatus != RatingTargetStatus.uncertain;

  bool get driverNeedsWrite =>
      orderEligible &&
      !driverConfirmed &&
      !driverUnavailable &&
      driverStatus != RatingTargetStatus.uncertain;

  bool get canSubmitMerchant =>
      merchantNeedsWrite && isValidRatingScore(merchantScore);

  bool get canSubmitDriver =>
      driverNeedsWrite && isValidRatingScore(driverScore);

  bool get hasUnresolvedUncertain =>
      merchantStatus == RatingTargetStatus.uncertain ||
      driverStatus == RatingTargetStatus.uncertain;

  bool get canSubmit {
    if (phase == OrderRatingPhase.succeeded) {
      return false;
    }
    // Block auto-retry while any target is uncertain until reconcile.
    if (hasUnresolvedUncertain) {
      return false;
    }
    if (!isValidRatingComment(comment)) {
      return false;
    }
    // Merchant score required only when merchant still needs a write.
    if (merchantNeedsWrite && !isValidRatingScore(merchantScore)) {
      return false;
    }
    return canSubmitMerchant || canSubmitDriver;
  }

  bool get alreadyFullyRated =>
      orderEligible && merchantConfirmed && (driverConfirmed || driverUnavailable);

  bool get partialMerchantSuccess =>
      merchantConfirmed && (driverNeedsWrite || hasUnresolvedUncertain);

  OrderRatingState copyWith({
    OrderRatingPhase? phase,
    OrderDetail? order,
    int? merchantScore,
    bool clearMerchantScore = false,
    int? driverScore,
    bool clearDriverScore = false,
    String? comment,
    OrderRating? existingMerchant,
    OrderRating? existingDriver,
    RatingTargetStatus? merchantStatus,
    RatingTargetStatus? driverStatus,
    String? merchantErrorMessage,
    String? driverErrorMessage,
    bool clearMerchantError = false,
    bool clearDriverError = false,
    String? errorMessage,
    String? errorCode,
    bool clearError = false,
    String? lastMerchantRatingId,
    String? lastDriverRatingId,
  }) {
    return OrderRatingState(
      phase: phase ?? this.phase,
      order: order ?? this.order,
      merchantScore:
          clearMerchantScore ? null : (merchantScore ?? this.merchantScore),
      driverScore: clearDriverScore ? null : (driverScore ?? this.driverScore),
      comment: comment ?? this.comment,
      existingMerchant: existingMerchant ?? this.existingMerchant,
      existingDriver: existingDriver ?? this.existingDriver,
      merchantStatus: merchantStatus ?? this.merchantStatus,
      driverStatus: driverStatus ?? this.driverStatus,
      merchantErrorMessage: clearMerchantError
          ? null
          : (merchantErrorMessage ?? this.merchantErrorMessage),
      driverErrorMessage: clearDriverError
          ? null
          : (driverErrorMessage ?? this.driverErrorMessage),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      lastMerchantRatingId:
          lastMerchantRatingId ?? this.lastMerchantRatingId,
      lastDriverRatingId: lastDriverRatingId ?? this.lastDriverRatingId,
    );
  }
}

class OrderRatingController extends Notifier<OrderRatingState> {
  OrderRatingController(this.orderId);

  final String orderId;
  var _generation = 0;
  var _inFlight = false;

  @override
  OrderRatingState build() {
    ref.watch(catalogScopeProvider);
    _generation += 1;
    _inFlight = false;
    Future<void>.microtask(() async {
      if (!ref.mounted) {
        return;
      }
      await refresh();
    });
    return const OrderRatingState();
  }

  void setMerchantScore(int score) {
    if (!isValidRatingScore(score) || merchantConfirmedLocked) {
      return;
    }
    state = state.copyWith(
      merchantScore: score,
      phase: OrderRatingPhase.ready,
      merchantStatus: RatingTargetStatus.idle,
      clearMerchantError: true,
      clearError: true,
    );
  }

  void setDriverScore(int score) {
    if (!isValidRatingScore(score) ||
        state.driverConfirmed ||
        state.driverUnavailable) {
      return;
    }
    state = state.copyWith(
      driverScore: score,
      phase: OrderRatingPhase.ready,
      driverStatus: RatingTargetStatus.idle,
      clearDriverError: true,
      clearError: true,
    );
  }

  bool get merchantConfirmedLocked => state.merchantConfirmed;

  void setComment(String value) {
    if (merchantConfirmedLocked && state.existingMerchant != null) {
      // Comment already persisted with merchant — keep draft only for display.
    }
    state = state.copyWith(
      comment: value,
      phase: state.phase == OrderRatingPhase.succeeded
          ? OrderRatingPhase.succeeded
          : OrderRatingPhase.ready,
      clearError: true,
    );
  }

  Future<void> refresh() async {
    final generation = _generation;
    state = state.copyWith(phase: OrderRatingPhase.loading, clearError: true);
    try {
      final order =
          await ref.read(orderDetailControllerProvider(orderId).future);
      if (generation != _generation) {
        return;
      }
      if (order.status != 'COMPLETED') {
        state = state.copyWith(
          phase: OrderRatingPhase.ineligible,
          order: order,
          errorMessage: AppStrings.ratingOrderIneligible,
          errorCode: 'RATING_INVALID_STATE',
        );
        return;
      }
      final api = ref.read(ratingsApiProvider);
      final merchant = await api.getOwnMerchantRating(orderId);
      final driver = await api.getOwnDriverRating(orderId);
      if (generation != _generation) {
        return;
      }
      state = OrderRatingState(
        phase: OrderRatingPhase.ready,
        order: order,
        merchantScore: merchant?.score ?? state.merchantScore,
        driverScore: driver?.score ?? state.driverScore,
        comment: merchant?.comment ?? state.comment,
        existingMerchant: merchant,
        existingDriver: driver,
        merchantStatus: merchant != null
            ? RatingTargetStatus.confirmed
            : RatingTargetStatus.idle,
        driverStatus: driver != null
            ? RatingTargetStatus.confirmed
            : RatingTargetStatus.idle,
        lastMerchantRatingId: merchant?.id,
        lastDriverRatingId: driver?.id,
      );
    } on AppException catch (error) {
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(
        phase: OrderRatingPhase.error,
        errorMessage: error.message,
        errorCode: error.code,
      );
    } catch (_) {
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(
        phase: OrderRatingPhase.error,
        errorMessage: AppStrings.ratingLoadError,
      );
    }
  }

  Future<bool> submit() async {
    if (_inFlight || !state.canSubmit) {
      return false;
    }
    if (!isValidRatingComment(state.comment)) {
      state = state.copyWith(
        phase: OrderRatingPhase.ready,
        errorMessage: AppStrings.ratingCommentInvalid,
        errorCode: 'RATING_INVALID_INPUT',
      );
      return false;
    }

    _inFlight = true;
    final generation = _generation;
    final submitMerchant = state.canSubmitMerchant;
    final submitDriver = state.canSubmitDriver;
    state = state.copyWith(
      phase: OrderRatingPhase.submitting,
      clearError: true,
      clearMerchantError: true,
      clearDriverError: true,
    );
    final api = ref.read(ratingsApiProvider);
    try {
      // Merchant — never resend if already confirmed.
      if (submitMerchant && !state.merchantConfirmed) {
        try {
          final created = await api.rateMerchant(
            orderId,
            CreateRatingRequest(
              score: state.merchantScore!,
              comment: state.comment,
            ),
          );
          if (generation != _generation) {
            return false;
          }
          state = state.copyWith(
            existingMerchant: created,
            lastMerchantRatingId: created.id,
            merchantStatus: RatingTargetStatus.confirmed,
          );
        } on AppException catch (error) {
          if (generation != _generation) {
            return false;
          }
          if (error.code == 'RATING_ALREADY_EXISTS') {
            final existing = await api.getOwnMerchantRating(orderId);
            if (generation != _generation) {
              return false;
            }
            if (existing != null) {
              state = state.copyWith(
                existingMerchant: existing,
                lastMerchantRatingId: existing.id,
                merchantStatus: RatingTargetStatus.confirmed,
              );
            }
          } else if (isRatingMutationUncertain(error)) {
            state = state.copyWith(
              phase: OrderRatingPhase.pendingVerification,
              merchantStatus: RatingTargetStatus.uncertain,
              merchantErrorMessage: AppStrings.ratingSubmitUncertain,
              errorMessage: AppStrings.ratingSubmitUncertain,
              errorCode: error.code,
            );
            return false;
          } else {
            state = state.copyWith(
              phase: OrderRatingPhase.ready,
              merchantStatus: RatingTargetStatus.failed,
              merchantErrorMessage: error.message,
              errorMessage: error.message,
              errorCode: error.code,
            );
            return false;
          }
        }
      }

      // Driver — independent; skip if merchant left uncertain.
      if (submitDriver &&
          !state.driverConfirmed &&
          !state.driverUnavailable &&
          state.merchantStatus != RatingTargetStatus.uncertain) {
        try {
          final created = await api.rateDriver(
            orderId,
            CreateRatingRequest(score: state.driverScore!),
          );
          if (generation != _generation) {
            return false;
          }
          state = state.copyWith(
            existingDriver: created,
            lastDriverRatingId: created.id,
            driverStatus: RatingTargetStatus.confirmed,
          );
        } on AppException catch (error) {
          if (generation != _generation) {
            return false;
          }
          if (isRatingMutationUncertain(error)) {
            state = state.copyWith(
              phase: OrderRatingPhase.pendingVerification,
              driverStatus: RatingTargetStatus.uncertain,
              driverErrorMessage: AppStrings.ratingSubmitUncertain,
              errorMessage: state.merchantConfirmed
                  ? AppStrings.ratingDriverUncertainPartial
                  : AppStrings.ratingSubmitUncertain,
              errorCode: error.code,
            );
            return state.merchantConfirmed;
          }
          if (error.code == 'RATING_INVALID_STATE' ||
              error.code == 'RATING_INTEGRITY') {
            state = state.copyWith(
              driverStatus: RatingTargetStatus.unavailable,
              driverErrorMessage: error.message,
            );
          } else if (error.code == 'RATING_ALREADY_EXISTS') {
            final existing = await api.getOwnDriverRating(orderId);
            if (generation != _generation) {
              return false;
            }
            state = state.copyWith(
              existingDriver: existing,
              lastDriverRatingId: existing?.id,
              driverStatus: existing != null
                  ? RatingTargetStatus.confirmed
                  : RatingTargetStatus.failed,
            );
          } else {
            state = state.copyWith(
              phase: OrderRatingPhase.ready,
              driverStatus: RatingTargetStatus.failed,
              driverErrorMessage: error.message,
              errorMessage: state.merchantConfirmed
                  ? AppStrings.ratingDriverFailedPartial
                  : error.message,
              errorCode: error.code,
            );
            return state.merchantConfirmed;
          }
        }
      }

      if (generation != _generation) {
        return false;
      }

      await _reconcileConfirmed(generation);
      if (generation != _generation) {
        return false;
      }

      final merchantIdForCache = state.existingMerchant?.targetId;
      if (merchantIdForCache != null &&
          merchantIdForCache.isNotEmpty &&
          ref.mounted) {
        ref.invalidate(merchantSummaryProvider(merchantIdForCache));
      }
      if (ref.mounted) {
        ref.invalidate(orderDetailControllerProvider(orderId));
      }

      if (state.merchantStatus == RatingTargetStatus.uncertain ||
          state.driverStatus == RatingTargetStatus.uncertain) {
        return state.merchantConfirmed;
      }

      if (state.driverStatus == RatingTargetStatus.failed) {
        state = state.copyWith(
          phase: OrderRatingPhase.ready,
          errorMessage: state.merchantConfirmed
              ? AppStrings.ratingDriverFailedPartial
              : state.driverErrorMessage,
        );
        return state.merchantConfirmed;
      }

      // Merchant confirmed; driver either confirmed, unavailable, or not attempted.
      if (state.merchantConfirmed &&
          (!submitDriver ||
              state.driverConfirmed ||
              state.driverUnavailable)) {
        state = state.copyWith(
          phase: OrderRatingPhase.succeeded,
          clearError: true,
          clearMerchantError: true,
          clearDriverError: true,
        );
        return true;
      }

      state = state.copyWith(phase: OrderRatingPhase.ready, clearError: true);
      return state.merchantConfirmed || state.driverConfirmed;
    } catch (_) {
      if (generation != _generation) {
        return false;
      }
      state = state.copyWith(
        phase: OrderRatingPhase.pendingVerification,
        merchantStatus: state.merchantConfirmed
            ? RatingTargetStatus.confirmed
            : RatingTargetStatus.uncertain,
        errorMessage: AppStrings.ratingSubmitUncertain,
        errorCode: 'RATING_MERCHANT_UNCERTAIN',
      );
      return false;
    } finally {
      if (generation == _generation) {
        _inFlight = false;
      }
    }
  }

  Future<void> reconcileAfterUncertain() async {
    final generation = _generation;
    await _reconcileConfirmed(generation);
    if (generation != _generation) {
      return;
    }
    // Clear uncertain flags when own-GET confirms; keep draft for unresolved.
    var merchantStatus = state.merchantStatus;
    var driverStatus = state.driverStatus;
    if (state.existingMerchant != null) {
      merchantStatus = RatingTargetStatus.confirmed;
    } else if (merchantStatus == RatingTargetStatus.uncertain) {
      merchantStatus = RatingTargetStatus.idle;
    }
    if (state.existingDriver != null) {
      driverStatus = RatingTargetStatus.confirmed;
    } else if (driverStatus == RatingTargetStatus.uncertain) {
      driverStatus = RatingTargetStatus.idle;
    }
    final done = state.existingMerchant != null &&
        (state.existingDriver != null ||
            driverStatus == RatingTargetStatus.unavailable ||
            state.driverScore == null);
    state = state.copyWith(
      phase: done ? OrderRatingPhase.succeeded : OrderRatingPhase.ready,
      merchantStatus: merchantStatus,
      driverStatus: driverStatus,
      clearError: true,
      clearMerchantError: true,
      clearDriverError: true,
    );
  }

  Future<void> _reconcileConfirmed(int generation) async {
    final api = ref.read(ratingsApiProvider);
    final merchant = await api.getOwnMerchantRating(orderId);
    final driver = await api.getOwnDriverRating(orderId);
    if (generation != _generation) {
      return;
    }
    state = state.copyWith(
      existingMerchant: merchant ?? state.existingMerchant,
      existingDriver: driver ?? state.existingDriver,
      lastMerchantRatingId: merchant?.id ?? state.lastMerchantRatingId,
      lastDriverRatingId: driver?.id ?? state.lastDriverRatingId,
      merchantScore: merchant?.score ?? state.merchantScore,
      driverScore: driver?.score ?? state.driverScore,
      comment: merchant?.comment ?? state.comment,
      merchantStatus: merchant != null
          ? RatingTargetStatus.confirmed
          : state.merchantStatus,
      driverStatus:
          driver != null ? RatingTargetStatus.confirmed : state.driverStatus,
    );
  }
}

final orderRatingControllerProvider = NotifierProvider.family<
  OrderRatingController,
  OrderRatingState,
  String
>(OrderRatingController.new);
