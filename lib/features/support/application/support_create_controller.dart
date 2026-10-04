import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/support/application/support_list_controller.dart';
import 'package:speedygo_customer_app/features/support/data/support_api.dart';
import 'package:speedygo_customer_app/features/support/data/support_models.dart';

enum SupportCreatePhase { editing, submitting, pendingVerification, failed }

class SupportCreateState {
  const SupportCreateState({
    this.phase = SupportCreatePhase.editing,
    this.draftBody = '',
    this.orderId,
    this.errorMessage,
    this.errorCode,
    this.createdTicket,
  });

  final SupportCreatePhase phase;
  final String draftBody;
  final String? orderId;
  final String? errorMessage;
  final String? errorCode;
  final SupportTicketDetail? createdTicket;

  bool get busy => phase == SupportCreatePhase.submitting;

  SupportCreateState copyWith({
    SupportCreatePhase? phase,
    String? draftBody,
    String? orderId,
    bool clearOrderId = false,
    String? errorMessage,
    String? errorCode,
    bool clearError = false,
    SupportTicketDetail? createdTicket,
    bool clearCreated = false,
  }) {
    return SupportCreateState(
      phase: phase ?? this.phase,
      draftBody: draftBody ?? this.draftBody,
      orderId: clearOrderId ? null : (orderId ?? this.orderId),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      errorCode: clearError ? null : (errorCode ?? this.errorCode),
      createdTicket:
          clearCreated ? null : (createdTicket ?? this.createdTicket),
    );
  }
}

class SupportCreateController extends Notifier<SupportCreateState> {
  var _inFlight = false;
  var _generation = 0;

  @override
  SupportCreateState build() {
    ref.watch(catalogScopeProvider);
    _generation += 1;
    _inFlight = false;
    return const SupportCreateState();
  }

  void setDraftBody(String value) {
    state = state.copyWith(
      draftBody: value,
      phase: SupportCreatePhase.editing,
      clearError: true,
      clearCreated: true,
    );
  }

  void setOrderId(String? orderId) {
    final trimmed = orderId?.trim();
    state = state.copyWith(
      orderId: trimmed,
      clearOrderId: trimmed == null || trimmed.isEmpty,
      clearError: true,
    );
  }

  Future<SupportTicketDetail?> submit() async {
    if (_inFlight || state.phase == SupportCreatePhase.pendingVerification) {
      return null;
    }
    final body = state.draftBody.trim();
    if (body.length < supportBodyMinLength ||
        body.length > supportBodyMaxLength) {
      state = state.copyWith(
        phase: SupportCreatePhase.failed,
        errorMessage: AppStrings.supportBodyInvalid,
        errorCode: 'SUPPORT_INVALID_INPUT',
      );
      return null;
    }
    _inFlight = true;
    final generation = _generation;
    state = state.copyWith(
      phase: SupportCreatePhase.submitting,
      clearError: true,
      clearCreated: true,
    );
    try {
      final ticket = await ref.read(supportApiProvider).createTicket(
            CreateSupportTicketRequest(body: body, orderId: state.orderId),
          );
      if (generation != _generation) {
        return null;
      }
      await ref.read(supportListControllerProvider.notifier).refresh();
      if (generation != _generation) {
        return null;
      }
      state = SupportCreateState(
        phase: SupportCreatePhase.editing,
        draftBody: '',
        createdTicket: ticket,
      );
      return ticket;
    } on AppException catch (error) {
      if (generation != _generation) {
        return null;
      }
      if (isSupportMutationUncertain(error)) {
        // Do not auto-retry. Reconcile via list by body match is unreliable;
        // keep draft and ask the user to check Mes demandes.
        state = state.copyWith(
          phase: SupportCreatePhase.pendingVerification,
          errorMessage: AppStrings.supportCreateUncertain,
          errorCode: error.code,
        );
        return null;
      }
      state = state.copyWith(
        phase: SupportCreatePhase.failed,
        errorMessage: error.message,
        errorCode: error.code,
      );
      return null;
    } catch (_) {
      if (generation != _generation) {
        return null;
      }
      state = state.copyWith(
        phase: SupportCreatePhase.pendingVerification,
        errorMessage: AppStrings.supportCreateUncertain,
        errorCode: 'SUPPORT_CREATE_UNCERTAIN',
      );
      return null;
    } finally {
      if (generation == _generation) {
        _inFlight = false;
      }
    }
  }

  Future<void> checkListAfterUncertain() async {
    await ref.read(supportListControllerProvider.notifier).refresh();
    state = state.copyWith(phase: SupportCreatePhase.editing, clearError: true);
  }
}

final supportCreateControllerProvider =
    NotifierProvider<SupportCreateController, SupportCreateState>(
      SupportCreateController.new,
    );
