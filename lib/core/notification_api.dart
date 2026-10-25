import 'api_service.dart';

/// 알림 한 건 (서버 알림엔 제목·본문만 있고 이동할 화면 정보는 없다)
class NotificationItem {
  const NotificationItem({required this.id, required this.title, required this.body, required this.createdAt, required this.read});

  final int id;
  final String title;
  final String body;
  final DateTime createdAt;
  final bool read;

  factory NotificationItem.fromJson(Map<String, dynamic> j) => NotificationItem(
        id: j['id'] as int,
        title: j['title'] as String? ?? '',
        body: j['body'] as String? ?? '',
        createdAt: DateTime.parse(j['createdAt'] as String),
        read: j['read'] as bool? ?? false,
      );
}

/// H04 알림 · 홈의 종 버튼 (점주·근로자 공통). UserController /api/users/me/notifications
class NotificationApi {
  NotificationApi({ApiService? api}) : _api = api ?? ApiService();

  final ApiService _api;

  Future<(int unread, List<NotificationItem> items)> list({int limit = 50}) async {
    final j = await _api.get('/api/users/me/notifications', query: {'limit': limit}) as Map<String, dynamic>;
    return (
      (j['unreadCount'] as num).toInt(),
      [for (final n in j['notifications'] as List) NotificationItem.fromJson(n as Map<String, dynamic>)],
    );
  }

  Future<void> markRead(int id) => _api.post('/api/users/me/notifications/$id/read');

  Future<void> markAllRead() => _api.post('/api/users/me/notifications/read-all');
}
