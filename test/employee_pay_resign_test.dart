import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thyme_frontend/core/api_service.dart';
import 'package:thyme_frontend/core/session.dart';
import 'package:thyme_frontend/screens/owner/p11_worker_profile_confirm_page.dart';

import 'test_helpers.dart';

/// P11 급여 설정(공제·수습 시급)과 퇴사 예정 (백엔드 8fcafac StoreEmployeeController)
class _Server implements HttpClientAdapter {
  final requests = <(String, String, Object?)>[];

  /// 직원 목록에 실리는 값 (서버 상태)
  Map<String, dynamic> employee = {
    'id': 3,
    'name': '김지수',
    'hourlyWage': 10320,
    'probationWage': 9500,
    'deduction': 'NONE',
    'status': 'APPROVED',
    'employmentType': 'PART_TIME',
    'startDate': '2026-10-01',
    'resignedOn': null,
    'minor': false,
  };

  static const profile = {
    'employeeId': 3,
    'name': '김지수',
    'displayName': '김지수',
    'employmentType': 'PART_TIME',
    'startDate': '2026-10-01',
    'hourlyWage': 10320,
    'probationUntil': '2026-12-31',
    'promiseScore': 0,
    'skills': [],
    'permissions': [],
    'history': [],
  };

  ResponseBody _json(Object? body, int status) =>
      ResponseBody.fromString(jsonEncode(body), status, headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    requests.add((o.method, o.path, o.data));
    switch ((o.method, o.path)) {
      case ('GET', '/api/stores/7/employees/3/profile'):
        return _json(profile, 200);
      case ('GET', '/api/stores/7/employees'):
        return _json([employee], 200);
      case ('PUT', '/api/stores/7/employees/3/pay-settings'):
        final b = o.data as Map;
        // 백엔드 EmployeeService.updatePaySettings 와 같은 검사
        if (b['probationWage'] != null && (b['contractOneYearOrMore'] != true || b['simpleLabor'] == true)) {
          return _json({'message': '수습 감액은 1년 이상 근로계약이고 단순노무 직종이 아닐 때만 적용할 수 있습니다.'}, 400);
        }
        employee = {...employee, 'deduction': b['deduction'], 'probationWage': b['probationWage']};
        return _json(employee, 200);
      case ('POST', '/api/stores/7/employees/3/resign'):
        employee = {...employee, 'resignedOn': (o.data as Map)['lastWorkDate']};
        return _json({'lastWorkDate': (o.data as Map)['lastWorkDate'], 'removedShifts': 4}, 200);
      case ('DELETE', '/api/stores/7/employees/3/resign'):
        employee = {...employee, 'resignedOn': null};
        return _json(null, 204);
    }
    return _json({'message': '예상하지 못한 요청 ${o.method} ${o.path}'}, 500);
  }

  @override
  void close({bool force = false}) {}
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

  Future<void> open(WidgetTester tester) async {
    await pumpScreen(tester, const WorkerProfileConfirmPage(employeeId: 3));
    await settle(tester);
  }

  Future<void> tapText(WidgetTester tester, String text) async {
    await tester.ensureVisible(find.text(text).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text(text).last);
    await settle(tester);
  }

  testWidgets('공제만 바꿔도 수습 시급은 지워지지 않는다 (통째로 바뀌는 PUT 이라 지금 값과 요건을 같이 보낸다)', (tester) async {
    await open(tester);
    expect(find.text('₩9,500'), findsOneWidget);
    await tapText(tester, '급여 공제');
    await tapText(tester, '3.3% · 사업소득');
    final put = server.requests.singleWhere((r) => r.$1 == 'PUT');
    expect(put.$3, {'deduction': 'FREELANCE', 'probationWage': 9500, 'contractOneYearOrMore': true, 'simpleLabor': false});
    expect(find.text('3.3%'), findsOneWidget);
    expect(find.text('₩9,500'), findsOneWidget);
  });

  testWidgets('수습 감액 없애기 → probationWage null', (tester) async {
    await open(tester);
    await tapText(tester, '수습 시급');
    await tapText(tester, '수습 감액 없애기 (시급 그대로)');
    final put = server.requests.singleWhere((r) => r.$1 == 'PUT');
    expect((put.$3 as Map)['probationWage'], isNull);
    expect(find.text('감액 없음'), findsOneWidget);
  });

  testWidgets('퇴사 예정을 걸고, 다시 취소한다', (tester) async {
    await open(tester);
    await tapText(tester, '퇴사 처리');
    // 달력: 오늘에서 다음 달로 넘겨 아무 날(15일)이나 고른다 → 미래 = 퇴사 예정
    await tester.tap(find.byIcon(Icons.chevron_right).last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('15').last);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.textContaining('예정을 취소해도 지운 근무는 돌아오지 않아요'), findsOneWidget);
    await tapText(tester, '퇴사 처리');
    final post = server.requests.singleWhere((r) => r.$1 == 'POST');
    final now = DateTime.now();
    final next = DateTime(now.year, now.month + 1, 15);
    expect(post.$3, {'lastWorkDate': '${next.year}-${next.month.toString().padLeft(2, '0')}-15'});
    expect(find.text('${next.month}/15까지 근무 · 퇴사 예정'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5)); // 스낵바 닫기
    await tester.pumpAndSettle();
    await tapText(tester, '퇴사 예정 취소');
    await tapText(tester, '예정 취소');
    expect(server.requests.where((r) => r.$1 == 'DELETE'), hasLength(1));
    expect(find.text('퇴사 처리'), findsOneWidget);
  });
}
