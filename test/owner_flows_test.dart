import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thyme_frontend/core/api_service.dart';
import 'package:thyme_frontend/core/session.dart';
import 'package:thyme_frontend/models/owner.dart' show SwapRequestInfo;
import 'package:thyme_frontend/screens/owner/m01_worker_approval_page.dart';
import 'package:thyme_frontend/screens/owner/owner_attendance_page.dart';
import 'package:thyme_frontend/screens/owner/owner_notice_task_page.dart';
import 'package:thyme_frontend/screens/worker/h12_absence_report_page.dart';
import 'package:thyme_frontend/screens/worker/h13_fill_vacancy_page.dart';
import 'package:thyme_frontend/screens/worker/j01_store_code_page.dart';
import 'package:thyme_frontend/screens/worker/j04_approval_waiting_page.dart';
import 'package:thyme_frontend/screens/worker/w07_my_schedule_page.dart';
import 'package:thyme_frontend/screens/worker/w09_shift_swap_page.dart';
import 'package:thyme_frontend/screens/worker/w11_fixed_schedule_page.dart';
import 'package:thyme_frontend/screens/worker/worker_attendance_page.dart';
import 'package:thyme_frontend/screens/owner/owner_schedule_page.dart';
import 'package:thyme_frontend/screens/owner/owner_staffing_suggestion_page.dart';
import 'package:thyme_frontend/screens/owner/p01_owner_home_page.dart';
import 'package:thyme_frontend/screens/owner/p06_substitute_manage_page.dart';
import 'package:thyme_frontend/screens/owner/p07_worker_list_page.dart';
import 'package:thyme_frontend/screens/owner/p08_store_settings_page.dart';

import 'test_helpers.dart';

/// 점주 화면이 백엔드 API 를 끝까지 부르는지 (2026-10-31 백엔드 팀 요청 목록)
/// 가짜 서버: "METHOD 경로" → 응답 함수. 없는 경로는 500
class _Server implements HttpClientAdapter {
  final routes = <String, Object? Function(RequestOptions o)>{};
  final requests = <(String, String, Object?)>[];

  /// 경로 뒤 쿼리까지 남긴다 (contract-exceed?month=…&approved=…)
  Iterable<(String, String, Object?)> sent(String method, String path) =>
      requests.where((r) => r.$1 == method && r.$2.startsWith(path));

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    requests.add((o.method, o.uri.toString().replaceFirst(o.baseUrl, ''), o.data));
    final route = routes['${o.method} ${o.path}'];
    final (body, status) = route == null ? ({'message': '예상하지 못한 요청 ${o.method} ${o.path}'}, 500) : _split(route(o));
    return ResponseBody.fromString(jsonEncode(body), status, headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});
  }

  /// 응답 함수는 본문만 돌려주거나 (본문, 상태 코드) 를 돌려준다
  static (Object?, int) _split(Object? r) => r is (Object?, int) ? r : (r, 200);

  @override
  void close({bool force = false}) {}
}

const _store = '/api/stores/7';

/// 점주 홈·매장 목록 등 여러 점주 화면이 처음에 부르는 것
void _ownerBasics(_Server server) {
  server.routes['GET /api/stores'] = (_) => [
        {'id': 7, 'name': '구시대 커피', 'storeCode': 'ABCD1234', 'industry': 'CAFE'},
      ];
  server.routes['GET $_store/home/owner'] = (_) => {
        'storeName': '구시대 커피',
        'date': '2026-10-31',
        'weeklyLaborCost': 0,
        'employeeCount': 2,
        'pendingApprovals': 0,
        'pendingLeaves': 0,
        'activeVacancies': [],
        'todayShifts': [],
        'nextMonthPreferences': {
          'month': '2026-11', 'deadline': '2026-10-25', 'daysUntilDeadline': -6,
          'submittedCount': 2, 'employeeCount': 2, 'submittedByMe': false,
        },
      };
  server.routes['GET $_store/employees/pending'] = (_) => [];
  server.routes['GET $_store/leaves'] = (_) => [];
  server.routes['GET $_store/skill-requests'] = (_) => [];
  server.routes['GET $_store/roster'] = (_) => {'pendingApprovals': 0, 'employees': []};
}

void main() {
  late _Server server;
  setUp(() async {
    await loadTestFonts();
    server = _Server();
    ApiService().dio.httpClientAdapter = server;
    ApiService().token = 'owner-token';
    Session.instance.storeId = 7;
  });
  tearDown(Session.instance.logout);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await settle(tester);
  }

  group('1. 근무 바꾸기 점주 승인 (P06)', () {
    Map<String, Object?> trade(int id, String status, {bool exchange = false}) => {
          'id': id,
          'type': exchange ? 'EXCHANGE' : 'HANDOVER',
          'status': status,
          'requesterId': 3,
          'requesterName': '유나',
          'requesterDate': '2026-11-03',
          'requesterStart': '09:00:00',
          'requesterEnd': '14:00:00',
          'targetId': 4,
          'targetName': '하준',
          'targetDate': exchange ? '2026-11-05' : null,
          'targetStart': exchange ? '17:00:00' : null,
          'targetEnd': exchange ? '22:00:00' : null,
          'recurring': false,
          'createdAt': '2026-10-31T10:00:00',
        };

    testWidgets('동료가 수락한 요청을 승인하면 approve, 동료 응답 전 요청은 승인 버튼이 꺼져 있다', (tester) async {
      var open = [trade(1, 'REQUESTED', exchange: true), trade(2, 'PEER_ACCEPTED')];
      server.routes['GET $_store/swap-requests'] = (_) => [];
      server.routes['GET $_store/trades'] = (_) => open;
      server.routes['POST $_store/trades/2/approve'] = (_) {
        open = [open.first];
        return trade(2, 'APPROVED');
      };
      await pumpScreen(tester, const SubstituteManagePage());
      await settle(tester);

      expect(find.text('근무 바꾸기 요청'), findsOneWidget);
      expect(find.text('승인 대기 1건'), findsOneWidget);
      expect(find.text('유나 → 하준 · 11/3(화) 09–14시'), findsOneWidget);
      expect(find.text('유나 11/3(화) 09–14시 ↔ 하준 11/5(목) 17–22시'), findsOneWidget);
      // 동료 응답 전: 승인 버튼 꺼짐
      final waiting = tester.widget<FilledButton>(find.ancestor(of: find.text('동료 응답 대기').last, matching: find.byType(FilledButton)));
      expect(waiting.onPressed, isNull);

      await tapText(tester, '승인');
      expect(server.sent('POST', '$_store/trades/2/approve'), hasLength(1));
      expect(find.text('승인 대기 0건'), findsOneWidget);
    });

    testWidgets('거절은 동료 응답 전에도 할 수 있다', (tester) async {
      server.routes['GET $_store/swap-requests'] = (_) => [];
      server.routes['GET $_store/trades'] = (_) => [trade(1, 'REQUESTED')];
      server.routes['POST $_store/trades/1/reject'] = (_) => trade(1, 'REJECTED');
      await pumpScreen(tester, const SubstituteManagePage());
      await settle(tester);
      await tapText(tester, '거절');
      expect(server.sent('POST', '$_store/trades/1/reject'), hasLength(1));
    });
  });

  group('5. 점주 공지·업무 작성', () {
    String today() {
      final d = DateTime.now();
      return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    }

    testWidgets('공지를 필독으로 올리면 POST /notices, 목록에 뜬다', (tester) async {
      final notices = <Map<String, Object?>>[];
      server.routes['GET $_store/notices'] = (_) => notices;
      server.routes['GET $_store/tasks'] = (_) => [];
      server.routes['POST $_store/notices'] = (o) {
        final b = o.data as Map;
        final n = {'id': 1, 'title': b['title'], 'content': b['content'], 'pinned': b['pinned'], 'createdAt': '2026-10-31T09:00:00'};
        notices.add(n);
        return n;
      };
      await pumpScreen(tester, const NoticeTaskManagePage());
      await settle(tester);
      await tapText(tester, '공지 쓰기');
      await tester.enterText(find.byType(TextField).at(0), '11월 근무표 나왔어요');
      await tester.enterText(find.byType(TextField).at(1), '확인 부탁해요');
      await tester.tap(find.text('필독으로 맨 위에 고정'));
      await tester.pump();
      await tapText(tester, '올리기');
      expect(server.sent('POST', '$_store/notices').single.$3, {'title': '11월 근무표 나왔어요', 'content': '확인 부탁해요', 'pinned': true});
      expect(find.text('11월 근무표 나왔어요'), findsOneWidget);
      expect(find.text('필독'), findsOneWidget);
    });

    testWidgets('업무를 교대에 등록하면 POST /tasks {date, title, shiftId}', (tester) async {
      final tasks = <Map<String, Object?>>[];
      server.routes['GET $_store/notices'] = (_) => [];
      server.routes['GET $_store/tasks'] = (_) => tasks;
      server.routes['GET $_store/shifts'] = (_) => [
            {'id': 11, 'name': '오픈', 'startTime': '09:00:00', 'endTime': '14:00:00'},
          ];
      server.routes['GET $_store/roster'] = (_) => {'employees': [{'employeeId': 3, 'name': '유나'}]};
      server.routes['POST $_store/tasks'] = (o) {
        final b = o.data as Map;
        final t = {'id': 5, 'date': b['date'], 'title': b['title'], 'shiftId': 11, 'shiftName': '오픈', 'done': false};
        tasks.add(t);
        return t;
      };
      await pumpScreen(tester, const NoticeTaskManagePage());
      await settle(tester);
      await tapText(tester, '업무');
      expect(server.sent('GET', '$_store/tasks?date=${today()}'), isNotEmpty);
      await tapText(tester, '업무 추가');
      await tester.enterText(find.byType(TextField), '우유 입고 확인');
      await tester.tap(find.text('오픈 교대'));
      await tester.pump();
      await tapText(tester, '등록');
      expect(server.sent('POST', '$_store/tasks').single.$3, {'date': today(), 'title': '우유 입고 확인', 'shiftId': 11, 'assigneeId': null});
      expect(find.text('우유 입고 확인'), findsOneWidget);
      expect(find.text('오픈'), findsOneWidget);
    });
  });

  group('6. 점주 근무 직접 추가·고치기·지우기', () {
    final now = DateTime.now();
    final monday = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    String ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    void routes(List<Map<String, Object?>> entries) {
      server.routes['GET $_store/schedules'] = (_) => entries;
      server.routes['GET $_store/schedules/plan'] = (_) => {
            'cycle': 'WEEKLY', 'periodStart': ymd(monday.add(const Duration(days: 7))), 'periodEnd': ymd(monday.add(const Duration(days: 13))),
            'preferenceDeadline': ymd(monday.add(const Duration(days: 5))), 'autoGenerate': false, 'generateAt': ymd(monday.add(const Duration(days: 5))),
          };
      server.routes['GET $_store/roster'] = (_) => {'employees': [{'employeeId': 3, 'name': '유나'}, {'employeeId': 4, 'name': '하준'}]};
      server.routes['GET $_store/shifts'] = (_) => [{'id': 11, 'name': '오픈', 'startTime': '09:00:00', 'endTime': '14:00:00'}];
    }

    testWidgets('규칙에 걸리면(400 forceable) 사유를 보여 주고, 그래도 배정하면 force: true 로 다시 보낸다', (tester) async {
      final entries = <Map<String, Object?>>[];
      routes(entries);
      server.routes['POST $_store/schedules'] = (o) {
        final b = o.data as Map;
        if (b['force'] != true) return ({'message': '유나님은 이날 휴무를 신청했습니다.', 'forceable': true}, 400);
        final e = {'id': 9, 'employeeId': 3, 'employeeName': '유나', 'workDate': b['workDate'], 'startTime': '09:00:00', 'endTime': '14:00:00'};
        entries.add(e);
        return e;
      };
      await pumpScreen(tester, const OwnerSchedulePage());
      await settle(tester);
      await tester.tap(find.byTooltip('${monday.month}/${monday.day} 근무 추가'));
      await settle(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('유나'));
      await tester.tap(find.text('오픈 09–14'));
      await tester.pump();
      await tapText(tester, '넣기');
      await tester.pumpAndSettle();
      expect(find.text('근무 규칙에 걸려요'), findsOneWidget);
      expect(find.textContaining('유나님은 이날 휴무를 신청했습니다.'), findsOneWidget);
      await tapText(tester, '그래도 배정');
      final posts = server.sent('POST', '$_store/schedules').toList();
      expect(posts.map((p) => (p.$3 as Map)['force']), [false, true]);
      expect(posts.last.$3, {'employeeId': 3, 'workDate': ymd(monday), 'startTime': '09:00', 'endTime': '14:00', 'force': true});
      expect(find.text('유나 09–14'), findsOneWidget);
    });

    testWidgets('force 로 넘길 수 없는 400(forceable 없음)은 사유만 보여 주고 다시 보내지 않는다', (tester) async {
      routes([]);
      server.routes['POST $_store/schedules'] = (_) => ({'message': '퇴근 시각은 출근 시각보다 늦어야 합니다.'}, 400);
      await pumpScreen(tester, const OwnerSchedulePage());
      await settle(tester);
      await tester.tap(find.byTooltip('${monday.month}/${monday.day} 근무 추가'));
      await settle(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('유나'));
      await tester.tap(find.text('오픈 09–14'));
      await tester.pump();
      await tapText(tester, '넣기');
      await tester.pump();
      expect(find.text('근무 규칙에 걸려요'), findsNothing);
      expect(find.text('퇴근 시각은 출근 시각보다 늦어야 합니다.'), findsOneWidget);
      expect(server.sent('POST', '$_store/schedules'), hasLength(1));
    });

    testWidgets('근무를 눌러 담당자를 바꾸면 PUT, 지우기는 DELETE', (tester) async {
      final entries = [
        {'id': 9, 'employeeId': 3, 'employeeName': '유나', 'workDate': ymd(monday), 'startTime': '09:00:00', 'endTime': '14:00:00', 'reasons': ['오픈 가능']},
      ];
      routes(entries);
      server.routes['PUT $_store/schedules/9'] = (o) => {...entries.first, 'employeeId': 4, 'employeeName': '하준'};
      server.routes['DELETE $_store/schedules/9'] = (_) => null;
      await pumpScreen(tester, const OwnerSchedulePage());
      await settle(tester);
      await tester.tap(find.text('유나 09–14'));
      await tester.pumpAndSettle();
      await tapText(tester, '고치기');
      await tester.pumpAndSettle();
      await tester.tap(find.text('하준'));
      await tester.pump();
      await tapText(tester, '고치기');
      expect(server.sent('PUT', '$_store/schedules/9').single.$3,
          {'employeeId': 4, 'workDate': ymd(monday), 'startTime': '09:00', 'endTime': '14:00', 'force': false});

      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
      await tester.tap(find.text('유나 09–14'));
      await tester.pumpAndSettle();
      await tapText(tester, '지우기');
      await tapText(tester, '지우기');
      expect(server.sent('DELETE', '$_store/schedules/9'), hasLength(1));
    });
  });

  group('7. 출퇴근 기록', () {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    String ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    Map<String, Object?> record({String? clockOut}) => {
          'id': 21, 'employeeId': 3, 'employeeName': '유나', 'workDate': ymd(yesterday),
          'clockIn': '${ymd(yesterday)}T17:05:00', 'clockOut': clockOut,
          'scheduledStart': '17:00:00', 'scheduledEnd': '22:00:00', 'late': true,
        };

    testWidgets('점주: 퇴근 누락을 보여 주고, 고치면 근무표 끝 시각으로 PATCH', (tester) async {
      var r = record();
      server.routes['GET $_store/attendance'] = (_) => [r];
      server.routes['GET $_store/attendance/absences'] = (_) => [];
      server.routes['PATCH $_store/attendance/21'] = (o) {
        r = record(clockOut: (o.data as Map)['clockOut'] as String);
        return r;
      };
      await pumpScreen(tester, const OwnerAttendancePage());
      await settle(tester);
      await tester.tap(find.byTooltip('전날'));
      await settle(tester);
      expect(server.sent('GET', '$_store/attendance?date=${ymd(yesterday)}'), hasLength(1));
      expect(find.text('17:05 – 퇴근 안 찍음'), findsOneWidget);
      expect(find.text('지각'), findsOneWidget);
      await tapText(tester, '유나');
      expect(find.text('퇴근 22:00'), findsOneWidget); // 비어 있으면 근무표 끝 시각을 먼저 채움
      await tapText(tester, '저장');
      expect(server.sent('PATCH', '$_store/attendance/21').single.$3,
          {'clockIn': '${ymd(yesterday)}T17:05:00', 'clockOut': '${ymd(yesterday)}T22:00:00'});
      expect(find.text('17:05 – 22:00'), findsOneWidget);
    });

    testWidgets('점주: 출근 기록이 없는 사람을 보여 주고, 누르면 근무표 시간으로 POST /attendance', (tester) async {
      final records = <Map<String, Object?>>[];
      var absences = [
        {'employeeId': 4, 'employeeName': '하준', 'scheduledStart': '09:00:00', 'scheduledEnd': '14:00:00'},
      ];
      server.routes['GET $_store/attendance'] = (_) => records;
      server.routes['GET $_store/attendance/absences'] = (_) => absences;
      server.routes['POST $_store/attendance'] = (o) {
        final b = o.data as Map;
        final r = {
          'id': 30, 'employeeId': 4, 'employeeName': '하준', 'workDate': ymd(yesterday),
          'clockIn': b['clockIn'], 'clockOut': b['clockOut'], 'scheduledStart': '09:00:00', 'scheduledEnd': '14:00:00', 'late': false,
        };
        records.add(r);
        absences = [];
        return r;
      };
      await pumpScreen(tester, const OwnerAttendancePage());
      await settle(tester);
      await tester.tap(find.byTooltip('전날'));
      await settle(tester);
      expect(server.sent('GET', '$_store/attendance/absences?date=${ymd(yesterday)}'), hasLength(1));
      expect(find.text('출근 기록 없음 1'), findsOneWidget);
      await tapText(tester, '하준');
      expect(find.textContaining('기록 만들기'), findsWidgets); // 시트 제목
      expect(find.text('출근 09:00'), findsOneWidget);
      expect(find.text('퇴근 14:00'), findsOneWidget);
      await tapText(tester, '저장');
      expect(server.sent('POST', '$_store/attendance').single.$3,
          {'employeeId': 4, 'clockIn': '${ymd(yesterday)}T09:00:00', 'clockOut': '${ymd(yesterday)}T14:00:00'});
      expect(find.text('출근 기록 없음 1'), findsNothing);
      expect(find.text('09:00 – 14:00'), findsOneWidget);
    });

    testWidgets('근로자: 이달 내 기록을 보기만 한다 (GET /attendance/my?from&to)', (tester) async {
      server.routes['GET $_store/attendance/my'] = (_) => [record()];
      await pumpScreen(tester, const WorkerAttendancePage());
      await settle(tester);
      final first = DateTime(now.year, now.month);
      final last = DateTime(now.year, now.month + 1, 0);
      expect(server.sent('GET', '$_store/attendance/my?from=${ymd(first)}&to=${ymd(last)}'), hasLength(1));
      if (yesterday.month == now.month) {
        expect(find.text('출근 1번 · 퇴근 안 찍음 1번'), findsOneWidget);
        expect(find.text('17:05 – 퇴근 안 찍음'), findsOneWidget);
      }
      expect(find.textContaining('사장님께 고쳐 달라고'), findsOneWidget);
    });
  });

  testWidgets('8. 매장 이름·주소 고치기: PATCH /api/stores/{id} 에 이름과 주소를 같이', (tester) async {
    _ownerBasics(server);
    var store = <String, Object?>{'id': 7, 'name': '구시대 커피', 'address': '서울 노원구', 'storeCode': 'ABCD1234', 'industry': 'CAFE'};
    server.routes['GET /api/stores'] = (_) => [store];
    server.routes['GET $_store/shifts'] = (_) => [];
    server.routes['GET $_store/skill-windows'] = (_) => [];
    server.routes['GET $_store/staffing-exceptions'] = (_) => [];
    server.routes['GET $_store/open-shifts'] = (_) => {'items': []};
    server.routes['GET /api/stores/industries'] = (_) => [];
    server.routes['GET /api/users/me'] = (_) => {
          'id': 1, 'username': 'owner01', 'role': 'MANAGER',
          'ownedStores': [{'id': 7, 'name': store['name'], 'industry': 'CAFE', 'storeCode': 'ABCD1234'}], 'memberships': [],
        };
    server.routes['PATCH $_store'] = (o) {
      store = {...store, ...(o.data as Map).cast<String, Object?>()};
      return store;
    };
    await pumpScreen(tester, const StoreSettingsPage());
    await settle(tester);
    await tapText(tester, '매장 정보 · 업종 · 주기');
    await tester.pumpAndSettle();
    expect(find.textContaining('지금은 바꿀 수 없어요'), findsNothing);
    await tapText(tester, '매장 이름 · 주소');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '구시대 커피 광운대점');
    await tapText(tester, '저장');
    expect(server.sent('PATCH', _store).single.$3, {'name': '구시대 커피 광운대점', 'address': '서울 노원구'});
    expect(server.sent('GET', '/api/users/me'), isNotEmpty); // 매장 이름을 쓰는 곳도 새로
  });

  testWidgets('P08 업종 바꾸기: 고르면 PATCH /api/stores/{id} 에 industry 를 같이', (tester) async {
    _ownerBasics(server);
    var store = <String, Object?>{'id': 7, 'name': '구시대 커피', 'address': '서울 노원구', 'storeCode': 'ABCD1234', 'industry': 'CAFE'};
    server.routes['GET /api/stores'] = (_) => [store];
    server.routes['GET $_store/shifts'] = (_) => [];
    server.routes['GET $_store/skill-windows'] = (_) => [];
    server.routes['GET $_store/staffing-exceptions'] = (_) => [];
    server.routes['GET $_store/open-shifts'] = (_) => {'items': []};
    server.routes['GET /api/stores/industries'] = (_) => [
          {'code': 'CAFE', 'label': '카페', 'skills': [], 'shifts': []},
          {'code': 'RESTAURANT', 'label': '음식점', 'skills': [], 'shifts': []},
        ];
    server.routes['PATCH $_store'] = (o) {
      store = {...store, ...(o.data as Map).cast<String, Object?>()};
      return store;
    };
    await pumpScreen(tester, const StoreSettingsPage());
    await settle(tester);
    await tapText(tester, '매장 정보 · 업종 · 주기');
    await tester.pumpAndSettle();
    await tapText(tester, '업종');
    await tester.pumpAndSettle();
    expect(find.textContaining('이미 만든 역량·교대는 그대로'), findsOneWidget);
    await tapText(tester, '음식점');
    expect(server.sent('PATCH', _store).single.$3, {'name': '구시대 커피', 'address': '서울 노원구', 'industry': 'RESTAURANT'});
    await settle(tester); // 다시 불러오기 (요청 여러 개)
    await tester.pumpAndSettle();
    await tapText(tester, '매장 정보 · 업종 · 주기');
    await tester.pumpAndSettle();
    expect(find.text('음식점'), findsOneWidget);
  });

  testWidgets('3순위: P07 에 퇴사 예정 표시와 퇴사한 사람 목록', (tester) async {
    server.routes['GET $_store/roster'] = (_) => {
          'pendingApprovals': 0,
          'employees': [
            {'employeeId': 3, 'name': '유나', 'employmentType': 'PART_TIME', 'todayStatus': 'OFF', 'monthHours': 20},
          ],
        };
    server.routes['GET $_store/employees'] = (_) => [
          {'id': 3, 'name': '유나', 'status': 'APPROVED', 'resignedOn': '2026-11-20'},
        ];
    server.routes['GET $_store/employees/resigned'] = (_) => [
          {'id': 8, 'name': '민지', 'status': 'RESIGNED', 'employmentType': 'PART_TIME', 'resignedOn': '2026-09-30'},
        ];
    await pumpScreen(tester, const WorkerListPage());
    await settle(tester);
    expect(find.text('11/20 퇴사 예정'), findsOneWidget);
    await tapText(tester, '퇴사한 사람 1');
    expect(find.text('민지'), findsOneWidget);
    expect(find.text('2026. 9. 30 퇴사'), findsOneWidget);
  });

  testWidgets('3순위: 필요 인원 제안은 다음 달로 묻고, 바꿀 곳을 보여 준다', (tester) async {
    final now = DateTime.now();
    final next = DateTime(now.year, now.month + 1);
    final month = '${next.year}-${next.month.toString().padLeft(2, '0')}';
    server.routes['GET $_store/staffing-suggestions'] = (_) => {
          'month': month, 'basedOnFrom': '2026-10-04', 'basedOnTo': '2026-10-31', 'customersPerStaff': 20,
          'suggestions': [
            {'shiftId': 11, 'shiftName': '오픈', 'dayOfWeek': 'MONDAY', 'sampleDays': 4, 'averageCustomers': 58.5, 'currentRequiredStaff': 2, 'suggestedStaff': 3},
            {'shiftId': 12, 'shiftName': '마감', 'dayOfWeek': 'MONDAY', 'sampleDays': 4, 'averageCustomers': 30.0, 'currentRequiredStaff': 2, 'suggestedStaff': 2},
            {'shiftId': 11, 'shiftName': '오픈', 'dayOfWeek': 'TUESDAY', 'sampleDays': 1, 'currentRequiredStaff': 1, 'reason': '보고가 2일 미만이에요'},
          ],
        };
    await pumpScreen(tester, const StaffingSuggestionPage());
    await settle(tester);
    expect(server.sent('GET', '$_store/staffing-suggestions?month=$month'), hasLength(1));
    expect(find.text('1곳은 인원을 바꿔 보길 권해요.'), findsOneWidget);
    expect(find.text('2명 → 3명'), findsOneWidget);
    expect(find.text('2명 그대로'), findsOneWidget);
    expect(find.text('보고가 2일 미만이에요'), findsOneWidget);
  });

  group('4. 계약 초과 근무량 승인 (M01)', () {
    testWidgets('계약 상한을 넘겨 결정 전(PENDING)인 사람만 시간과 함께 보이고, 승인하면 contract-exceed approved=true', (tester) async {
      _ownerBasics(server);
      var status = 'PENDING';
      server.routes['GET $_store/preferences'] = (_) => {
            'month': '2026-11',
            'employees': [
              {'employeeId': 3, 'name': '유나', 'submitted': true, 'late': false, 'needsContractApproval': status == 'PENDING',
                'contractExceedStatus': status, 'requestedMaxMonthlyHours': 120, 'contractMaxMonthlyHours': 87},
              {'employeeId': 4, 'name': '하준', 'submitted': true, 'late': false, 'needsContractApproval': false,
                'contractExceedStatus': 'REJECTED', 'requestedMaxMonthlyHours': 100, 'contractMaxMonthlyHours': 87},
            ],
          };
      server.routes['POST $_store/preferences/3/contract-exceed'] = (_) {
        status = 'APPROVED';
        return {};
      };
      await pumpScreen(tester, const WorkerApprovalPage());
      await settle(tester);

      expect(server.sent('GET', '$_store/preferences?month=2026-11'), hasLength(1));
      expect(find.text('11월 계약보다 많이 일하기 1'), findsOneWidget);
      expect(find.text('유나'), findsOneWidget);
      expect(find.text('최대 월 120시간 신청 · 계약 상한 월 87시간'), findsOneWidget);
      expect(find.text('하준'), findsNothing); // 이미 거절한 신청은 다시 묻지 않는다
      await tapText(tester, '승인');
      expect(server.sent('POST', '$_store/preferences/3/contract-exceed?month=2026-11&approved=true'), hasLength(1));
      expect(find.text('11월 계약보다 많이 일하기 1'), findsNothing);
    });
  });

  testWidgets('P01: 승인할 것에 계약 초과 수가 더해지고, 근무 바꾸기 승인 대기는 P06 으로 가는 줄', (tester) async {
    _ownerBasics(server);
    final home = server.routes['GET $_store/home/owner']!;
    server.routes['GET $_store/home/owner'] = (o) => {
          ...home(o) as Map<String, Object?>,
          'pendingApprovals': 1, 'pendingLeaves': 0, 'pendingTrades': 2, 'pendingContractApprovals': 1,
        };
    server.routes['GET $_store/closing-reports'] = (_) => [];
    server.routes['GET /api/users/me/notifications'] = (_) => {'unreadCount': 0, 'notifications': []};
    server.routes['GET $_store/swap-requests'] = (_) => [];
    server.routes['GET $_store/trades'] = (_) => [];
    await pumpScreen(tester, const OwnerHomePage());
    await settle(tester);
    expect(find.text('승인할 것 2 · 가입 1 · 계약 초과 1'), findsOneWidget);
    await tapText(tester, '근무 바꾸기 승인 2');
    await tester.pumpAndSettle();
    expect(find.byType(SubstituteManagePage), findsOneWidget);
  });

  testWidgets('J04 가입 신청 취소: 확인하면 DELETE /stores/{id}/join, 다른 매장이 없으면 J01 로', (tester) async {
    var memberships = [
      {'employeeId': 3, 'storeId': 5, 'storeName': '구시대 커피', 'status': 'PENDING', 'employmentType': 'PART_TIME'},
    ];
    server.routes['GET /api/users/me'] = (_) => {'id': 2, 'username': 'staff01', 'role': 'EMPLOYEE', 'ownedStores': [], 'memberships': memberships};
    server.routes['DELETE /api/stores/5/join'] = (_) {
      memberships = [];
      return ('', 204);
    };
    await pumpScreen(tester, const ApprovalWaitingPage(fullTime: false, name: '유나', storeName: '구시대 커피'));
    await settle(tester);
    await tapText(tester, '가입 신청 취소');
    expect(find.text('가입 신청을 취소할까요?'), findsOneWidget);
    await tapText(tester, '신청 취소');
    await tester.pumpAndSettle();
    expect(server.sent('DELETE', '/api/stores/5/join'), hasLength(1));
    expect(find.byType(StoreCodePage), findsOneWidget);
  });

  testWidgets('P11 고정 일정 대신 입력: W11 점주 모드가 GET·PUT /employees/{id}/fixed-schedules, 예외 기간은 숨김', (tester) async {
    server.routes['GET $_store/employees/3/fixed-schedules'] = (_) => [
          {'id': 1, 'dayOfWeek': 'MONDAY', 'startTime': '09:00:00', 'endTime': '12:00:00', 'label': '전공 수업', 'category': 'STUDY'},
        ];
    server.routes['PUT $_store/employees/3/fixed-schedules'] = (o) => o.data;
    await pumpScreen(tester, const FixedSchedulePage(employeeId: 3, employeeName: '유나'));
    await settle(tester);
    expect(find.text('유나님 고정 일정'), findsOneWidget);
    expect(find.text('전공 수업'), findsOneWidget);
    expect(find.text('이번 달만 예외'), findsNothing);
    await tester.tap(find.text('수'));
    await tester.pump();
    await tapText(tester, '저장');
    expect(server.sent('GET', '$_store/unavailable-periods'), isEmpty);
    expect(server.sent('PUT', '$_store/employees/3/fixed-schedules').single.$3, [
      {'dayOfWeek': 'MONDAY', 'startTime': '09:00', 'endTime': '12:00', 'label': '전공 수업', 'category': 'STUDY'},
      {'dayOfWeek': 'WEDNESDAY', 'startTime': '09:00', 'endTime': '12:00', 'label': '전공 수업', 'category': 'STUDY'},
    ]);
  });

  testWidgets('H13 대타 요청을 보내면 화면에 남아 후보별 응답 상태를 다시 받아 본다', (tester) async {
    Map<String, Object?> cand(int id, String name, {String? status, int? waiting}) => {
          'employeeId': id, 'name': name, 'eligible': true, 'weeklyHours': 10, 'coveredSkills': [], 'reasons': [],
          'contactStatus': status, 'waitingMinutes': waiting,
        };
    var cands = [cand(4, '하준'), cand(5, '민지'), cand(6, '도윤')];
    server.routes['GET $_store/swap-requests/1/candidates'] = (_) => cands;
    server.routes['POST $_store/swap-requests/1/offers'] = (o) {
      cands = [cand(4, '하준', status: 'SENT', waiting: 0), cand(5, '민지', status: 'SENT', waiting: 0), cand(6, '도윤')];
      return {'id': 1, 'status': 'OFFERED'};
    };
    await pumpScreen(tester, FillVacancyPage(
      request: SwapRequestInfo.fromJson({
        'id': 1, 'workDate': '2026-11-20', 'startTime': '09:00:00', 'endTime': '14:00:00',
        'requesterName': '유나', 'reasonCategory': 'PERSONAL', 'status': 'REQUESTED',
      }),
    ));
    await settle(tester);
    await tapText(tester, '2명에게 대타 요청 보내기');
    expect(server.sent('POST', '$_store/swap-requests/1/offers').single.$3, {'employeeIds': [4, 5]});
    // 화면에 남아 상태를 보여 준다 (예전엔 대타·교대 탭으로 넘어감)
    expect(find.byType(FillVacancyPage), findsOneWidget);
    expect(find.text('2명이 확인 중이에요. 먼저 수락한 한 명으로 정해져요'), findsOneWidget);
    expect(find.text('확인 중 0분'), findsNWidgets(2));
    expect(find.text('홈으로'), findsOneWidget);

    // 하준이 수락 → 새로고침하면 사장님 승인 대기
    cands = [cand(4, '하준', status: 'PENDING_APPROVAL'), cand(5, '민지', status: 'CLOSED'), cand(6, '도윤')];
    await tapText(tester, '새로고침');
    expect(find.text('하준님이 수락했어요. 사장님이 승인하면 확정돼요'), findsOneWidget);
    expect(find.text('수락 · 승인 대기'), findsOneWidget);
    expect(find.text('마감'), findsOneWidget);
  });

  testWidgets('W07 시작 전 근무를 누르면 그 근무로 결원 신고(H12)·근무 바꾸기(W09)를 연다', (tester) async {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final ymd = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
    server.routes['GET $_store/schedules/my'] = (_) => [
          {'id': 31, 'workDate': ymd, 'startTime': '17:00:00', 'endTime': '22:00:00', 'reasons': ['마감 가능']},
        ];
    server.routes['GET $_store/shifts'] = (_) => [];
    await pumpScreen(tester, const MySchedulePage());
    await settle(tester);
    if (tomorrow.month != now.month) {
      await tester.tap(find.byIcon(Icons.chevron_right));
      await tester.pump();
    }
    expect(find.text('못 나가요'), findsNothing); // 날짜를 고르기 전
    await tester.tap(find.text('17–22'));
    await tester.pump();
    expect(find.text('· 마감 가능'), findsOneWidget);
    await tapText(tester, '못 나가요');
    await tester.pumpAndSettle();
    expect(find.byType(AbsenceReportPage), findsOneWidget);
    expect(tester.widget<AbsenceReportPage>(find.byType(AbsenceReportPage)).shift?.scheduleId, 31);
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
    await settle(tester);
    await tester.tap(find.text('17–22'));
    await tester.pump();
    await tapText(tester, '근무 바꾸기');
    await tester.pumpAndSettle();
    expect(tester.widget<ShiftSwapPage>(find.byType(ShiftSwapPage)).scheduleId, 31);
  });
}
