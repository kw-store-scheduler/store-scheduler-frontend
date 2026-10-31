import '../models/store.dart' show dateParam;
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

/// 업무 한 건. 교대 업무면 shiftName, 한 사람 업무면 assigneeName, 둘 다 없으면 그날 근무자 모두의 업무
class StoreTask {
  const StoreTask({required this.id, required this.title, this.shiftName, this.assigneeName, required this.done, this.doneByName});

  final int id;
  final String title;
  final String? shiftName;
  final String? assigneeName;
  final bool done;
  final String? doneByName;

  factory StoreTask.fromJson(Map<String, dynamic> j) => StoreTask(
        id: j['id'] as int,
        title: j['title'] as String? ?? '',
        shiftName: j['shiftName'] as String?,
        assigneeName: j['assigneeName'] as String?,
        done: j['done'] as bool? ?? false,
        doneByName: j['doneByName'] as String?,
      );
}

/// 공지·업무. NoticeController /api/stores/{storeId}/notices · /tasks
/// 근로자(H03): 공지 보기 · 오늘 내 업무 체크 / 점주(공지·업무 관리): 공지 쓰기·지우기 · 날짜별 업무 등록·지우기
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

  // ── 점주

  /// 공지 올리기. 직원 모두에게 알림이 간다. 고정(필독)이면 목록 맨 위
  Future<Notice> createNotice({required String title, String? content, bool pinned = false}) async => Notice.fromJson(
      await _api.post('$_store/notices', data: {'title': title, 'content': content, 'pinned': pinned}) as Map<String, dynamic>);

  Future<void> deleteNotice(int id) => _api.delete('$_store/notices/$id');

  /// 그날 매장 업무 전체
  Future<List<StoreTask>> tasks(DateTime date) async => [
        for (final j in await _api.get('$_store/tasks', query: {'date': dateParam(date)}) as List) StoreTask.fromJson(j as Map<String, dynamic>)
      ];

  /// 업무 등록. 교대(shiftId)나 사람(assigneeId)을 고르지 않으면 그날 근무자 모두의 업무
  Future<StoreTask> createTask(DateTime date, String title, {int? shiftId, int? assigneeId}) async => StoreTask.fromJson(await _api.post(
      '$_store/tasks',
      data: {'date': dateParam(date), 'title': title, 'shiftId': shiftId, 'assigneeId': assigneeId}) as Map<String, dynamic>);

  Future<void> deleteTask(int id) => _api.delete('$_store/tasks/$id');
}
