import 'dart:async';

import 'package:speedygo_customer_app/core/constants/app_strings.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';
import 'package:speedygo_customer_app/features/notifications/data/notification_api.dart';
import 'package:speedygo_customer_app/features/notifications/data/notification_models.dart';
import 'package:speedygo_customer_app/features/support/data/support_api.dart';
import 'package:speedygo_customer_app/features/support/data/support_models.dart';

class FakeNotificationsClient implements NotificationsClient {
  FakeNotificationsClient({List<NotificationItem>? seed})
    : items = List.of(seed ?? const []);

  List<NotificationItem> items;
  int listCalls = 0;
  int markReadCalls = 0;
  int markAllCalls = 0;
  int unreadCalls = 0;
  Object? markReadError;
  Object? markAllError;
  Object? listError;
  Object? unreadError;
  Object? Function(int offset)? listErrorForOffset;
  Duration? listDelay;
  Duration Function(int callCount)? listDelayForCall;
  Completer<void>? markReadGate;
  bool overlapOnLoadMore = false;
  int Function(int limit, int offset)? listHook;

  @override
  Future<NotificationPage> list({int limit = 20, int offset = 0}) async {
    listCalls += 1;
    final snapshot = List.of(items);
    if (listHook != null) {
      listHook!(limit, offset);
    }
    final delay = listDelayForCall?.call(listCalls) ?? listDelay;
    if (delay != null && delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (listError != null) {
      throw listError!;
    }
    final offsetError = listErrorForOffset?.call(offset);
    if (offsetError != null) {
      throw offsetError;
    }
    final slice = overlapOnLoadMore && offset > 0
        ? snapshot.take(limit).toList()
        : snapshot.skip(offset).take(limit).toList();
    final unread = snapshot.where((e) => !e.read).length;
    return NotificationPage(
      items: slice,
      limit: limit,
      offset: offset,
      total: snapshot.length,
      unreadCount: unread,
    );
  }

  @override
  Future<UnreadCountResponse> unreadCount() async {
    unreadCalls += 1;
    if (unreadError != null) {
      throw unreadError!;
    }
    return UnreadCountResponse(
      unreadCount: items.where((e) => !e.read).length,
    );
  }

  @override
  Future<NotificationItem> markRead(String notificationId) async {
    markReadCalls += 1;
    final gate = markReadGate;
    if (gate != null) {
      await gate.future;
    }
    if (markReadError != null) {
      throw markReadError!;
    }
    final i = items.indexWhere((e) => e.id == notificationId);
    if (i < 0) {
      throw const ApiException(
        'not found',
        code: 'NOTIFICATION_NOT_FOUND',
        statusCode: 404,
      );
    }
    items[i] = items[i].copyWith(read: true);
    return items[i];
  }

  @override
  Future<MarkAllReadResponse> markAllRead() async {
    markAllCalls += 1;
    if (markAllError != null) {
      throw markAllError!;
    }
    var marked = 0;
    for (var i = 0; i < items.length; i++) {
      if (!items[i].read) {
        marked += 1;
        items[i] = items[i].copyWith(read: true);
      }
    }
    return MarkAllReadResponse(marked: marked);
  }
}

class FakeSupportClient implements SupportClient {
  final tickets = <String, SupportTicketDetail>{};
  SupportTicketPage page = const SupportTicketPage(
    items: [],
    total: 0,
    limit: 50,
    offset: 0,
  );
  Object? createError;
  Object? replyError;
  Object? listError;
  Object? getError;
  int createCount = 0;
  int replyCount = 0;
  int listCount = 0;
  CreateSupportTicketRequest? lastCreate;
  String? lastReplyBody;
  Duration? createDelay;

  @override
  Future<SupportTicketDetail> createTicket(
    CreateSupportTicketRequest request,
  ) async {
    createCount += 1;
    lastCreate = request;
    if (createDelay != null) {
      await Future<void>.delayed(createDelay!);
    }
    if (createError != null) {
      throw createError!;
    }
    final detail = SupportTicketDetail(
      id: 'ticket-1',
      publicReference: 'sgt_test1',
      status: 'OPEN',
      priority: 'NORMAL',
      orderId: request.orderId,
      createdAt: '2026-09-10T00:00:00.000Z',
      updatedAt: '2026-09-10T00:00:00.000Z',
      createdByAccountId: 'account-1',
      order: null,
      messages: [
        SupportMessage(
          id: 'msg-1',
          ticketId: 'ticket-1',
          authorAccountId: 'account-1',
          body: request.body,
          createdAt: '2026-09-10T00:00:00.000Z',
          displayName: null,
        ),
      ],
    );
    tickets[detail.id] = detail;
    page = SupportTicketPage(
      items: [
        SupportTicketSummary(
          id: detail.id,
          publicReference: detail.publicReference,
          status: detail.status,
          priority: detail.priority,
          orderId: detail.orderId,
          createdAt: detail.createdAt,
          updatedAt: detail.updatedAt,
        ),
      ],
      total: 1,
      limit: 50,
      offset: 0,
    );
    return detail;
  }

  @override
  Future<SupportTicketDetail> getTicket(
    String ticketId, {
    int limit = 50,
    int offset = 0,
  }) async {
    if (getError != null) {
      throw getError!;
    }
    final ticket = tickets[ticketId];
    if (ticket == null) {
      throw const ApiException(
        'Ce ticket est introuvable.',
        code: 'SUPPORT_NOT_FOUND',
        statusCode: 404,
      );
    }
    return ticket;
  }

  @override
  Future<SupportTicketPage> listTickets({int limit = 50, int offset = 0}) async {
    listCount += 1;
    if (listError != null) {
      throw listError!;
    }
    if (offset >= page.total) {
      return SupportTicketPage(
        items: const [],
        total: page.total,
        limit: limit,
        offset: offset,
      );
    }
    final slice = page.items.skip(offset).take(limit).toList();
    return SupportTicketPage(
      items: slice,
      total: page.total,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<SupportMessage> reply(String ticketId, String body) async {
    replyCount += 1;
    lastReplyBody = body;
    if (replyError != null) {
      throw replyError!;
    }
    final existing = tickets[ticketId];
    if (existing == null || !existing.canCustomerReply) {
      throw ApiException(
        AppStrings.supportReplyClosed,
        code: 'SUPPORT_INVALID_STATE',
        statusCode: 409,
      );
    }
    final message = SupportMessage(
      id: 'msg-reply-$replyCount',
      ticketId: ticketId,
      authorAccountId: 'account-1',
      body: body,
      createdAt: '2026-09-10T00:01:00.000Z',
      displayName: null,
    );
    tickets[ticketId] = SupportTicketDetail(
      id: existing.id,
      publicReference: existing.publicReference,
      status: existing.status == 'WAITING_CUSTOMER'
          ? 'IN_PROGRESS'
          : existing.status,
      priority: existing.priority,
      orderId: existing.orderId,
      createdAt: existing.createdAt,
      updatedAt: message.createdAt,
      createdByAccountId: existing.createdByAccountId,
      order: existing.order,
      messages: [...existing.messages, message],
    );
    return message;
  }
}
