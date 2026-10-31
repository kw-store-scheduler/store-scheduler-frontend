import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thyme_frontend/core/api_service.dart';
import 'package:thyme_frontend/core/session.dart';
import 'package:thyme_frontend/screens/owner/m01_worker_approval_page.dart';
import 'package:thyme_frontend/screens/owner/owner_notice_task_page.dart';
import 'package:thyme_frontend/screens/owner/owner_schedule_page.dart';
import 'package:thyme_frontend/screens/owner/p06_substitute_manage_page.dart';

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

    testWidgets('규칙에 걸리면(400) 사유를 보여 주고, 그래도 배정하면 force: true 로 다시 보낸다', (tester) async {
      final entries = <Map<String, Object?>>[];
      routes(entries);
      server.routes['POST $_store/schedules'] = (o) {
        final b = o.data as Map;
        if (b['force'] != true) return ({'message': '유나님은 이날 휴무를 신청했습니다.'}, 400);
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

  group('4. 계약 초과 근무량 승인 (M01)', () {
    testWidgets('다음 달 희망에서 계약 상한을 넘긴 사람만 보이고, 승인하면 contract-exceed approved=true', (tester) async {
      _ownerBasics(server);
      var needs = true;
      server.routes['GET $_store/preferences'] = (_) => {
            'month': '2026-11',
            'employees': [
              {'employeeId': 3, 'name': '유나', 'submitted': true, 'late': false, 'needsContractApproval': needs},
              {'employeeId': 4, 'name': '하준', 'submitted': true, 'late': false, 'needsContractApproval': false},
            ],
          };
      server.routes['POST $_store/preferences/3/contract-exceed'] = (_) {
        needs = false;
        return {};
      };
      await pumpScreen(tester, const WorkerApprovalPage());
      await settle(tester);

      expect(server.sent('GET', '$_store/preferences?month=2026-11'), hasLength(1));
      expect(find.text('11월 계약보다 많이 일하기 1'), findsOneWidget);
      expect(find.text('유나'), findsOneWidget);
      expect(find.text('하준'), findsNothing);
      await tapText(tester, '승인');
      expect(server.sent('POST', '$_store/preferences/3/contract-exceed?month=2026-11&approved=true'), hasLength(1));
      expect(find.text('11월 계약보다 많이 일하기 1'), findsNothing);
    });
  });
}
