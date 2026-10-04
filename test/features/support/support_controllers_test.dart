import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/support/application/support_create_controller.dart';
import 'package:speedygo_customer_app/features/support/application/support_detail_controller.dart';
import 'package:speedygo_customer_app/features/support/application/support_list_controller.dart';
import 'package:speedygo_customer_app/features/support/data/support_models.dart';

import '../../helpers/notification_support_fakes.dart';

void main() {
  test('create payload maps body and optional orderId only', () async {
    final api = FakeSupportClient();
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('scope-a'),
        supportApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    container.listen(supportCreateControllerProvider, (_, _) {});
    container.listen(supportListControllerProvider, (_, _) {});
    final notifier = container.read(supportCreateControllerProvider.notifier);
    notifier.setDraftBody('Test support Revue');
    notifier.setOrderId('11111111-1111-4111-8111-111111111111');
    final ticket = await notifier.submit();
    expect(ticket, isNotNull);
    expect(api.createCount, 1);
    expect(api.lastCreate!.body, 'Test support Revue');
    expect(api.lastCreate!.orderId, '11111111-1111-4111-8111-111111111111');
    expect(api.lastCreate!.toJson().keys.toList(), ['body', 'orderId']);
  });

  test('create without orderId omits orderId key', () {
    const request = CreateSupportTicketRequest(body: 'Hello');
    expect(request.toJson(), {'body': 'Hello'});
  });

  test('invalid body is rejected without network call', () async {
    final api = FakeSupportClient();
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('scope-a'),
        supportApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    container.listen(supportCreateControllerProvider, (_, _) {});
    await container.read(supportCreateControllerProvider.notifier).submit();
    expect(api.createCount, 0);
    expect(
      container.read(supportCreateControllerProvider).errorCode,
      'SUPPORT_INVALID_INPUT',
    );
  });

  test('double submit is ignored while in flight', () async {
    final api = FakeSupportClient()
      ..createDelay = const Duration(milliseconds: 40);
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('scope-a'),
        supportApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    container.listen(supportCreateControllerProvider, (_, _) {});
    container.listen(supportListControllerProvider, (_, _) {});
    final notifier = container.read(supportCreateControllerProvider.notifier);
    notifier.setDraftBody('Hello');
    final first = notifier.submit();
    final second = notifier.submit();
    await Future.wait([first, second]);
    expect(api.createCount, 1);
  });

  test('uncertain create keeps draft and does not auto-retry', () async {
    final api = FakeSupportClient()
      ..createError = const ApiException(
        'uncertain',
        code: 'SUPPORT_CREATE_UNCERTAIN',
        statusCode: 503,
      );
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('scope-a'),
        supportApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    container.listen(supportCreateControllerProvider, (_, _) {});
    final notifier = container.read(supportCreateControllerProvider.notifier);
    notifier.setDraftBody('Keep me');
    await notifier.submit();
    expect(api.createCount, 1);
    final state = container.read(supportCreateControllerProvider);
    expect(state.phase, SupportCreatePhase.pendingVerification);
    expect(state.draftBody, 'Keep me');
    await notifier.submit();
    expect(api.createCount, 1);
  });

  test('reply eligibility blocks RESOLVED tickets', () async {
    final api = FakeSupportClient();
    api.tickets['ticket-1'] = const SupportTicketDetail(
      id: 'ticket-1',
      publicReference: 'sgt_x',
      status: 'RESOLVED',
      priority: 'NORMAL',
      orderId: null,
      createdAt: '2026-09-10T00:00:00.000Z',
      updatedAt: '2026-09-10T00:00:00.000Z',
      createdByAccountId: 'account-1',
      order: null,
      messages: [],
    );
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('scope-a'),
        supportApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    container.listen(supportDetailControllerProvider('ticket-1'), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    final notifier =
        container.read(supportDetailControllerProvider('ticket-1').notifier);
    notifier.setDraftBody('Nope');
    final message = await notifier.sendReply();
    expect(message, isNull);
    expect(api.replyCount, 0);
    expect(
      container.read(supportDetailControllerProvider('ticket-1')).canReply,
      isFalse,
    );
  });

  test('OPEN IN_PROGRESS WAITING_CUSTOMER allow reply', () {
    for (final status in ['OPEN', 'IN_PROGRESS', 'WAITING_CUSTOMER']) {
      expect(
        SupportTicketDetail(
          id: 't',
          publicReference: 'r',
          status: status,
          priority: 'NORMAL',
          orderId: null,
          createdAt: 'x',
          updatedAt: 'x',
          createdByAccountId: 'a',
          order: null,
          messages: const [],
        ).canCustomerReply,
        isTrue,
      );
    }
    for (final status in ['RESOLVED', 'CLOSED']) {
      expect(
        SupportTicketDetail(
          id: 't',
          publicReference: 'r',
          status: status,
          priority: 'NORMAL',
          orderId: null,
          createdAt: 'x',
          updatedAt: 'x',
          createdByAccountId: 'a',
          order: null,
          messages: const [],
        ).canCustomerReply,
        isFalse,
      );
    }
  });

  test('confirmed reply requires server message id', () async {
    final api = FakeSupportClient();
    await api.createTicket(
      const CreateSupportTicketRequest(body: 'Test support Revue'),
    );
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('scope-a'),
        supportApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    container.listen(supportDetailControllerProvider('ticket-1'), (_, _) {});
    container.listen(supportListControllerProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    final notifier =
        container.read(supportDetailControllerProvider('ticket-1').notifier);
    notifier.setDraftBody('Test follow-up Revue');
    final message = await notifier.sendReply();
    expect(message, isNotNull);
    expect(api.replyCount, 1);
    expect(
      container
          .read(supportDetailControllerProvider('ticket-1'))
          .lastConfirmedMessageId,
      message!.id,
    );
    expect(
      container.read(supportDetailControllerProvider('ticket-1')).draftBody,
      '',
    );
  });

  test('uncertain reply keeps draft and does not claim success', () async {
    final api = FakeSupportClient();
    await api.createTicket(
      const CreateSupportTicketRequest(body: 'Test support Revue'),
    );
    api.replyError = const ApiException(
      'uncertain',
      code: 'SUPPORT_REPLY_UNCERTAIN',
      statusCode: 503,
    );
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('scope-a'),
        supportApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    container.listen(supportDetailControllerProvider('ticket-1'), (_, _) {});
    await Future<void>.delayed(Duration.zero);
    final notifier =
        container.read(supportDetailControllerProvider('ticket-1').notifier);
    notifier.setDraftBody('Unconfirmed draft');
    final message = await notifier.sendReply();
    expect(message, isNull);
    final state = container.read(supportDetailControllerProvider('ticket-1'));
    expect(state.phase, SupportDetailPhase.pendingVerification);
    expect(state.draftBody, 'Unconfirmed draft');
    expect(state.lastConfirmedMessageId, isNull);
    await notifier.sendReply();
    expect(api.replyCount, 1);
  });

  test('list pagination appends pages', () async {
    final api = FakeSupportClient();
    api.page = SupportTicketPage(
      items: List.generate(
        3,
        (i) => SupportTicketSummary(
          id: 't$i',
          publicReference: 'sgt_$i',
          status: 'OPEN',
          priority: 'NORMAL',
          orderId: null,
          createdAt: '2026-09-10T00:00:00.000Z',
          updatedAt: '2026-09-10T00:00:00.000Z',
        ),
      ),
      total: 3,
      limit: 50,
      offset: 0,
    );
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('scope-a'),
        supportApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    container.listen(supportListControllerProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(container.read(supportListControllerProvider).items.length, 3);
    expect(container.read(supportListControllerProvider).hasMore, isFalse);
  });

  test('catalog scope rebuild clears list items for account isolation', () async {
    final api = FakeSupportClient();
    await api.createTicket(
      const CreateSupportTicketRequest(body: 'A'),
    );
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('scope-a'),
        supportApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    container.listen(supportListControllerProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(container.read(supportListControllerProvider).items, isNotEmpty);

    api.page = const SupportTicketPage(
      items: [],
      total: 0,
      limit: 50,
      offset: 0,
    );
    container.updateOverrides([
      catalogScopeProvider.overrideWithValue('scope-b'),
      supportApiProvider.overrideWithValue(api),
    ]);
    container.listen(supportListControllerProvider, (_, _) {});
    await Future<void>.delayed(Duration.zero);
    expect(container.read(supportListControllerProvider).items, isEmpty);
  });

  test('stale create result is rejected after account scope change', () async {
    final api = FakeSupportClient()
      ..createDelay = const Duration(milliseconds: 50);
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('scope-a'),
        supportApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    container.listen(supportCreateControllerProvider, (_, _) {});
    container.listen(supportListControllerProvider, (_, _) {});
    final notifier = container.read(supportCreateControllerProvider.notifier);
    notifier.setDraftBody('Stale');
    final pending = notifier.submit();
    container.updateOverrides([
      catalogScopeProvider.overrideWithValue('scope-b'),
      supportApiProvider.overrideWithValue(api),
    ]);
    container.listen(supportCreateControllerProvider, (_, _) {});
    final ticket = await pending;
    expect(ticket, isNull);
    expect(
      container.read(supportCreateControllerProvider).createdTicket,
      isNull,
    );
    expect(
      container.read(supportCreateControllerProvider).draftBody,
      '',
    );
  });
}
