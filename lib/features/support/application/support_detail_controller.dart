import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/support/application/support_list_controller.dart';
import 'package:speedygo_customer_app/features/support/data/support_api.dart';
import 'package:speedygo_customer_app/features/support/data/support_models.dart';

enum SupportDetailPhase {
  loading,
  ready,
  sending,
  pendingVerification,
  error,
}

class SupportDetailState {
  const SupportDetailState({
    this.phase = SupportDetailPhase.loading,
    this.ticket,
    this.draftBody = '',
    this.errorMessage,
    this.errorCode,
    this.lastConfirmedMessageId,
  });

  final SupportDetailPhase phase;
  final SupportTicketDetail? ticket;
  final String draftBody;
  final String? errorMessage;
  final String? errorCode;
  final String? lastConfirmedMessageId;

  bool get busy =>
      phase == SupportDetailPhase.loading ||
      phase == SupportDetailPhase.sending;

  bool get canReply => ticket?.canCustomerReply == true;

  SupportDetailState copyWith({
    SupportDetailPhase? phase,
    SupportTicketDetail? ticket,
    String? draftBody,
    String? errorMessage,
    String? errorCode,
    bool clearError = false,
    String? lastConfirmedMessageId,
  }) {
    return SupportDetailState(
      phase: phase ?? this.phase,
      ticket: ticket ?? this.ticket,
      draftBody: draftBody ?? this.draftBody,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      lastConfirmedMessageId:
          lastConfirmedMessageId ?? this.lastConfirmedMessageId,
    );
  }
}

class SupportDetailController extends Notifier<SupportDetailState> {
  SupportDetailController(this.ticketId);

  final String ticketId;
  var _generation = 0;
  var _inFlight = false;

  @override
  SupportDetailState build() {
    ref.watch(catalogScopeProvider);
    _generation += 1;
    _inFlight = false;
    Future<void>.microtask(() async {
      if (!ref.mounted) {
        return;
      }
      await refresh();
    });
    return const SupportDetailState();
  }

  void setDraftBody(String value) {
    state = state.copyWith(draftBody: value, clearError: true);
  }

  Future<void> refresh() async {
    final generation = _generation;
    state = state.copyWith(
      phase: SupportDetailPhase.loading,
      clearError: true,
    );
    try {
      final ticket = await ref.read(supportApiProvider).getTicket(ticketId);
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(
        phase: SupportDetailPhase.ready,
        ticket: ticket,
      );
    } on AppException catch (error) {
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(
        phase: SupportDetailPhase.error,
        errorMessage: error.message,
        errorCode: error.code,
      );
    } catch (_) {
      if (generation != _generation) {
        return;
      }
      state = state.copyWith(
        phase: SupportDetailPhase.error,
        errorMessage: AppStrings.supportDetailLoadError,
      );
    }
  }

  Future<SupportMessage?> sendReply() async {
    if (_inFlight ||
        state.phase == SupportDetailPhase.pendingVerification ||
        !state.canReply) {
      return null;
    }
    final body = state.draftBody.trim();
    if (body.length < supportBodyMinLength ||
        body.length > supportBodyMaxLength) {
      state = state.copyWith(
        phase: SupportDetailPhase.ready,
        errorMessage: AppStrings.supportBodyInvalid,
        errorCode: 'SUPPORT_INVALID_INPUT',
      );
      return null;
    }
    _inFlight = true;
    final generation = _generation;
    state = state.copyWith(
      phase: SupportDetailPhase.sending,
      clearError: true,
    );
    try {
      final message =
          await ref.read(supportApiProvider).reply(ticketId, body);
      if (generation != _generation) {
        return null;
      }
      // Confirm by server message id, then refresh detail — do not claim
      // success from matching draft text alone.
      await refresh();
      if (generation != _generation) {
        return null;
      }
      final confirmed = state.ticket?.messages.any((m) => m.id == message.id);
      if (confirmed != true) {
        state = state.copyWith(
          phase: SupportDetailPhase.pendingVerification,
          errorMessage: AppStrings.supportReplyUncertain,
          errorCode: 'SUPPORT_REPLY_UNCERTAIN',
          lastConfirmedMessageId: null,
        );
        return null;
      }
      state = state.copyWith(
        phase: SupportDetailPhase.ready,
        draftBody: '',
        lastConfirmedMessageId: message.id,
      );
      await ref.read(supportListControllerProvider.notifier).refresh();
      return message;
    } on AppException catch (error) {
      if (generation != _generation) {
        return null;
      }
      if (isSupportMutationUncertain(error)) {
        state = state.copyWith(
          phase: SupportDetailPhase.pendingVerification,
          errorMessage: AppStrings.supportReplyUncertain,
          errorCode: error.code,
        );
        return null;
      }
      state = state.copyWith(
        phase: SupportDetailPhase.ready,
        errorMessage: error.message,
        errorCode: error.code,
      );
      return null;
    } catch (_) {
      if (generation != _generation) {
        return null;
      }
      state = state.copyWith(
        phase: SupportDetailPhase.pendingVerification,
        errorMessage: AppStrings.supportReplyUncertain,
        errorCode: 'SUPPORT_REPLY_UNCERTAIN',
      );
      return null;
    } finally {
      _inFlight = false;
    }
  }

  Future<void> reconcileAfterUncertain() async {
    await refresh();
    if (state.ticket != null) {
      state = state.copyWith(
        phase: SupportDetailPhase.ready,
        clearError: true,
      );
    }
  }
}

final supportDetailControllerProvider = NotifierProvider.family<
  SupportDetailController,
  SupportDetailState,
  String
>(SupportDetailController.new);
