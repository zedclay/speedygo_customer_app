/// Customer Support ticket models (SUPPORT_FOUNDATION v1.0).
class SupportTicketSummary {
  const SupportTicketSummary({
    required this.id,
    required this.publicReference,
    required this.status,
    required this.priority,
    required this.orderId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String publicReference;
  final String status;
  final String priority;
  final String? orderId;
  final String createdAt;
  final String updatedAt;

  bool get canCustomerReply =>
      status == 'OPEN' ||
      status == 'IN_PROGRESS' ||
      status == 'WAITING_CUSTOMER';

  factory SupportTicketSummary.fromJson(Map<String, dynamic> json) {
    return SupportTicketSummary(
      id: _req(json, 'id'),
      publicReference: _req(json, 'publicReference'),
      status: _req(json, 'status'),
      priority: _req(json, 'priority'),
      orderId: json['orderId']?.toString(),
      createdAt: _req(json, 'createdAt'),
      updatedAt: _req(json, 'updatedAt'),
    );
  }
}

class SupportTicketPage {
  const SupportTicketPage({
    required this.items,
    required this.total,
    required this.limit,
    required this.offset,
  });

  final List<SupportTicketSummary> items;
  final int total;
  final int limit;
  final int offset;

  bool get hasMore => offset + items.length < total;

  factory SupportTicketPage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final items = <SupportTicketSummary>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          items.add(
            SupportTicketSummary.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return SupportTicketPage(
      items: items,
      total: _int(json, 'total'),
      limit: _int(json, 'limit'),
      offset: _int(json, 'offset'),
    );
  }
}

class SupportOrderContext {
  const SupportOrderContext({
    required this.id,
    required this.publicReference,
    required this.status,
  });

  final String id;
  final String publicReference;
  final String status;

  factory SupportOrderContext.fromJson(Map<String, dynamic> json) {
    return SupportOrderContext(
      id: _req(json, 'id'),
      publicReference: _req(json, 'publicReference'),
      status: _req(json, 'status'),
    );
  }
}

class SupportMessage {
  const SupportMessage({
    required this.id,
    required this.ticketId,
    required this.authorAccountId,
    required this.body,
    required this.createdAt,
    required this.displayName,
  });

  final String id;
  final String ticketId;
  final String authorAccountId;
  final String body;
  final String createdAt;

  /// Null for customer authors; "SpeedyGo Support" for admin.
  final String? displayName;

  bool get isFromSupport => displayName != null && displayName!.isNotEmpty;

  factory SupportMessage.fromJson(Map<String, dynamic> json) {
    return SupportMessage(
      id: _req(json, 'id'),
      ticketId: _req(json, 'ticketId'),
      authorAccountId: _req(json, 'authorAccountId'),
      body: _req(json, 'body'),
      createdAt: _req(json, 'createdAt'),
      displayName: json['displayName']?.toString(),
    );
  }
}

class SupportTicketDetail {
  const SupportTicketDetail({
    required this.id,
    required this.publicReference,
    required this.status,
    required this.priority,
    required this.orderId,
    required this.createdAt,
    required this.updatedAt,
    required this.createdByAccountId,
    required this.order,
    required this.messages,
  });

  final String id;
  final String publicReference;
  final String status;
  final String priority;
  final String? orderId;
  final String createdAt;
  final String updatedAt;
  final String createdByAccountId;
  final SupportOrderContext? order;
  final List<SupportMessage> messages;

  bool get canCustomerReply =>
      status == 'OPEN' ||
      status == 'IN_PROGRESS' ||
      status == 'WAITING_CUSTOMER';

  factory SupportTicketDetail.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    final messages = <SupportMessage>[];
    if (rawMessages is List) {
      for (final item in rawMessages) {
        if (item is Map) {
          messages.add(
            SupportMessage.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    SupportOrderContext? order;
    final rawOrder = json['order'];
    if (rawOrder is Map) {
      order = SupportOrderContext.fromJson(
        Map<String, dynamic>.from(rawOrder),
      );
    }
    return SupportTicketDetail(
      id: _req(json, 'id'),
      publicReference: _req(json, 'publicReference'),
      status: _req(json, 'status'),
      priority: _req(json, 'priority'),
      orderId: json['orderId']?.toString(),
      createdAt: _req(json, 'createdAt'),
      updatedAt: _req(json, 'updatedAt'),
      createdByAccountId: _req(json, 'createdByAccountId'),
      order: order,
      messages: messages,
    );
  }
}

class CreateSupportTicketRequest {
  const CreateSupportTicketRequest({required this.body, this.orderId});

  final String body;
  final String? orderId;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'body': body};
    final order = orderId?.trim();
    if (order != null && order.isNotEmpty) {
      json['orderId'] = order;
    }
    return json;
  }
}

String _req(Map<String, dynamic> json, String key) {
  final value = json[key]?.toString();
  if (value == null || value.isEmpty) {
    throw FormatException('Missing support field $key');
  }
  return value;
}

int _int(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

const supportBodyMaxLength = 4000;
const supportBodyMinLength = 1;
