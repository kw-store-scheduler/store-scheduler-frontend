import 'api_service.dart';
import 'session.dart';

/// 매장 공지 한 건 (고정 공지가 먼저, 최신순으로 온다)
class Notice {
  const Notice({required this.id, required this.title, required this.content, required this.pinned, required this.createdAt});

  final int id;
  final String title;
  final String content;
  final bool pinned;
  final DateTime createdAt;

  factory Notice.fromJson(Map<String, dynamic> j) => Notice(
        id: j['id'] as int,
        title: j['title'] as String? ?? '',
        content: j['content'] as String? ?? '',
        pinned: j['pinned'] as bool? ?? false,
        createdAt: DateTime.parse(j['createdAt'] as String),
      );
}

/// 오늘 내 업무 한 건 (교대 업무면 shiftName 이 있다)
class StoreTask {
  const StoreTask({required this.id, required this.title, this.shiftName, required this.done, this.doneByName});

  final int id;
  final String title;
  final String? shiftName;
  final bool done;
  final String? doneByName;

  factory StoreTask.fromJson(Map<String, dynamic> j) => StoreTask(
        id: j['id'] as int,
        title: j['title'] as String? ?? '',
        shiftName: j['shiftName'] as String?,
        done: j['done'] as bool? ?? false,
        doneByName: j['doneByName'] as String?,
      );
}

/// H03 공지·업무. NoticeController /api/stores/{storeId}/notices · /tasks/my
class NoticeApi {
  NoticeApi({ApiService? api, Session? session})
      : _api = api ?? ApiService(),
        _session = session ?? Session.instance;

  final ApiService _api;
  final Session _session;

  String get _store => '/api/stores/${_session.requireStoreId()}';

  Future<List<Notice>> notices() async =>
      [for (final j in await _api.get('$_store/notices') as List) Notice.fromJson(j as Map<String, dynamic>)];

  /// 오늘 내 업무 (날짜를 빼면 서버가 오늘로 본다)
  Future<List<StoreTask>> myTasks() async =>
      [for (final j in await _api.get('$_store/tasks/my') as List) StoreTask.fromJson(j as Map<String, dynamic>)];

  Future<StoreTask> check(int taskId, bool done) async =>
      StoreTask.fromJson(await _api.patch('$_store/tasks/$taskId', data: {'done': done}) as Map<String, dynamic>);
}
