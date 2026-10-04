/// Account-scoped in-app notification inbox (Notifications Foundation v1.0).
class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.type,
    required this.sourceId,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
  });

  final String id;
  final String type;
  final String sourceId;
  final String title;
  final String body;
  final bool read;
  final String createdAt;

  NotificationItem copyWith({bool? read}) {
    return NotificationItem(
      id: id,
      type: type,
      sourceId: sourceId,
      title: title,
      body: body,
      read: read ?? this.read,
      createdAt: createdAt,
    );
  }

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: _req(json, 'id'),
      type: _req(json, 'type'),
      sourceId: _req(json, 'sourceId'),
      title: _req(json, 'title'),
      body: _req(json, 'body'),
      read: json['read'] == true,
      createdAt: _req(json, 'createdAt'),
    );
  }
}

class NotificationPage {
  const NotificationPage({
    required this.items,
    required this.limit,
    required this.offset,
    required this.total,
    required this.unreadCount,
  });

  final List<NotificationItem> items;
  final int limit;
  final int offset;
  final int total;
  final int unreadCount;

  bool get hasMore => offset + items.length < total;

  factory NotificationPage.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final items = <NotificationItem>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          items.add(
            NotificationItem.fromJson(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return NotificationPage(
      items: items,
      limit: _int(json, 'limit'),
      offset: _int(json, 'offset'),
      total: _int(json, 'total'),
      unreadCount: _int(json, 'unreadCount'),
    );
  }
}

class UnreadCountResponse {
  const UnreadCountResponse({required this.unreadCount});

  final int unreadCount;

  factory UnreadCountResponse.fromJson(Map<String, dynamic> json) {
    return UnreadCountResponse(unreadCount: _int(json, 'unreadCount'));
  }
}

class MarkAllReadResponse {
  const MarkAllReadResponse({required this.marked});

  final int marked;

  factory MarkAllReadResponse.fromJson(Map<String, dynamic> json) {
    return MarkAllReadResponse(marked: _int(json, 'marked'));
  }
}

String _req(Map<String, dynamic> json, String key) {
  final value = json[key]?.toString();
  if (value == null || value.isEmpty) {
    throw FormatException('Missing notification field: $key');
  }
  return value;
}

int _int(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
