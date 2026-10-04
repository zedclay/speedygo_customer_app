import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speedygo_customer_app/app/theme/app_theme.dart';
import 'package:speedygo_customer_app/features/catalog/application/catalog_providers.dart';
import 'package:speedygo_customer_app/features/support/application/support_create_controller.dart';
import 'package:speedygo_customer_app/features/support/application/support_detail_controller.dart';
import 'package:speedygo_customer_app/features/support/application/support_list_controller.dart';
import 'package:speedygo_customer_app/features/support/data/support_models.dart';
import 'package:speedygo_customer_app/features/support/presentation/support_create_screen.dart';
import 'package:speedygo_customer_app/features/support/presentation/support_detail_screen.dart';

import '../../helpers/notification_support_fakes.dart';

void main() {
  testWidgets('create draft survives leave/reopen via controller state', (
    tester,
  ) async {
    final api = FakeSupportClient();
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('scope-a'),
        supportApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SupportCreateScreen(),
        ),
      ),
    );
    await tester.pump();
    const draft = 'Acceptance draft retain create';
    await tester.enterText(find.byKey(const Key('support-create-body')), draft);
    await tester.pump();
    expect(container.read(supportCreateControllerProvider).draftBody, draft);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: Text('left')),
        ),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SupportCreateScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(draft), findsOneWidget);
  });

  testWidgets('detail draft survives leave/reopen via controller state', (
    tester,
  ) async {
    final detail = const SupportTicketDetail(
      id: 'ticket-1',
      publicReference: 'sgt_test',
      status: 'OPEN',
      priority: 'NORMAL',
      orderId: null,
      createdAt: '2026-09-01T00:00:00.000Z',
      updatedAt: '2026-09-01T00:00:00.000Z',
      createdByAccountId: 'account-1',
      order: null,
      messages: const [],
    );
    final api = FakeSupportClient()..tickets['ticket-1'] = detail;
    final container = ProviderContainer(
      overrides: [
        catalogScopeProvider.overrideWithValue('scope-a'),
        supportApiProvider.overrideWithValue(api),
      ],
    );
    addTearDown(container.dispose);
    container.listen(supportDetailControllerProvider('ticket-1'), (_, _) {});

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SupportDetailScreen(ticketId: 'ticket-1'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    const draft = 'Acceptance draft retain detail';
    await tester.enterText(find.byKey(const Key('support-reply-body')), draft);
    await tester.pump();
    expect(
      container.read(supportDetailControllerProvider('ticket-1')).draftBody,
      draft,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(body: Text('left')),
        ),
      ),
    );
    await tester.pump();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: AppTheme.light,
          home: const SupportDetailScreen(ticketId: 'ticket-1'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text(draft), findsOneWidget);
  });
}
