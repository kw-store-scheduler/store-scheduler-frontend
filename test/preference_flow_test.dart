import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thyme_frontend/core/api_service.dart';
import 'package:thyme_frontend/core/session.dart';
import 'package:thyme_frontend/screens/worker/w00_load_last_month_page.dart';
import 'package:thyme_frontend/screens/worker/h01_part_timer_home_page.dart';

import 'test_helpers.dart';

/// 백엔드 대신 응답하는 가짜 서버. 받은 요청을 [requests]에 남긴다
class _FakeServer implements HttpClientAdapter {
  final requests = <(String, String, Object?)>[];

  /// 첫 달 직원: 지난달 답이 없다 (서버는 400 + 메시지)
  bool firstMonth = false;

  /// 2026년 11월, 교대 2개(오픈 11, 마감 12). 11/2 오픈은 수업으로 잠김
  static Map<String, dynamic> month({Map<String, String> levels = const {}}) => {
        'month': '2026-11',
        'deadline': '2026-10-28',
        'submitted': false,
        'shifts': [
          {'id': 11, 'name': '오픈', 'startTime': '09:00:00', 'endTime': '14:00:00'},
          {'id': 12, 'name': '마감', 'startTime': '17:00:00', 'endTime': '22:00:00'},
        ],
        'cells': [
          for (var d = 1; d <= 30; d++)
            for (final shift in [11, 12])
              {
                'date': '2026-11-${d.toString().padLeft(2, '0')}',
                'shiftId': shift,
                'level': levels['$d/$shift'],
                'locked': d == 2 && shift == 11,
                'lockLabel': d == 2 && shift == 11 ? '수업' : null,
              },
        ],
        'submission': null,
      };

  Object? _respond(String method, String path) => switch ((method, path)) {
        ('POST', '/api/auth/login') => {'token': 'test-token'},
        ('GET', '/api/users/me') => {
            'id': 1,
            'username': 'staff01',
            'role': 'EMPLOYEE',
            'ownedStores': [],
            'memberships': [
              {'employeeId': 3, 'storeId': 7, 'storeName': '구시대 커피', 'status': 'APPROVED', 'employmentType': 'PART_TIME'},
            ],
          },
        ('GET', '/api/stores/7/preferences/my') => month(),
        // 지난달 답: 11/3·11/4 오픈 선호
        ('GET', '/api/stores/7/preferences/my/draft') => month(levels: {'3/11': 'PREFERRED', '4/11': 'PREFERRED'}),
        ('PUT', '/api/stores/7/preferences/my') => month(),
        ('GET' || 'PUT', '/api/stores/7/fixed-schedules/my') => [],
        // 제출 뒤 알바 홈 (H01)
        ('GET', '/api/stores/7/home/worker') => {
            'storeName': '구시대 커피',
            'employeeName': '유나',
            'date': '2026-10-30',
            'today': {'date': '2026-10-30'},
            'coworkers': [],
            'week': [],
            'swapOffers': [],
            'monthlyPay': {'totalHours': 0, 'totalPay': 0, 'weeklyHolidayPay': 0},
            'nextMonthPreferences': {
              'month': '2026-11', 'deadline': '2026-10-28', 'daysUntilDeadline': -2,
              'submittedCount': 1, 'employeeCount': 3, 'submittedByMe': true,
            },
          },
        ('GET' || 'PUT', '/api/stores/7/unavailable-periods/my') => [],
        // 근로계약 주 15–20시간 → 11월 64–86시간 (경고 둘 다 켜서 배너도 그린다)
        ('GET', '/api/stores/7/preferences/my/workload') => {
            'contractMinWeekly': 15, 'contractMaxWeekly': 20, 'contractMinMonthly': 64, 'contractMaxMonthly': 86,
            'hourlyWage': 10320, 'minMonthly': 64, 'maxMonthly': 86, 'expectedPayMin': 660480, 'expectedPayMax': 1065024,
            'belowWeeklyHolidayThreshold': true, 'exceedsContract': true,
          },
        // 역량: 영어 확정(중), 중국어 신청 중(상), 혼자 오픈만 가능, 수습 11/30까지
        ('GET', '/api/stores/7/my-skills') => {
            'skills': [
              {'skillId': 1, 'name': '영어', 'level': 'MID', 'requestedLevel': null, 'status': 'CONFIRMED'},
              {'skillId': 2, 'name': '중국어', 'level': 'NONE', 'requestedLevel': 'HIGH', 'status': 'PENDING'},
            ],
            'permissions': [
              {'code': 'SOLO_OPEN', 'label': '혼자 오픈', 'allowed': true},
              {'code': 'ORDERING', 'label': '발주 가능자', 'allowed': false},
            ],
            'probationUntil': '2026-11-30',
          },
        ('PUT', '/api/stores/7/my-skills') => {'skills': [], 'permissions': []},
        // 이미 낸 휴무 2건 (필수 1 · 희망 1, 대안 순서 있음) → W03 카드가 그려진다
        ('GET', '/api/stores/7/day-offs/my') => [
            {'id': 1, 'date': '2026-11-07', 'type': 'MUST', 'reason': '가족 행사', 'fallbacks': [], 'downgraded': false},
            {'id': 2, 'date': '2026-11-15', 'type': 'PREFER', 'reason': '시험 공부', 'fallbacks': ['AFTERNOON_OFF', 'SWAP_DAY'], 'downgraded': false},
          ],
        _ => throw StateError('예상하지 못한 요청: $method $path'),
      };

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add((options.method, options.uri.toString(), options.data));
    if (firstMonth && options.path.endsWith('/preferences/my/draft')) {
      // 백엔드 PreferenceService.draftFromPrevious 와 같은 응답
      return ResponseBody.fromString(jsonEncode({'message': '2026-10에 제출한 희망이 없습니다.'}), 400, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      });
    }
    final body = _respond(options.method, options.path);
    return ResponseBody.fromString(jsonEncode(body), 200, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUpAll(loadTestFonts);

  late _FakeServer server;
  setUp(() {
    server = _FakeServer();
    ApiService().dio.httpClientAdapter = server;
  });
  tearDown(Session.instance.logout);

  /// 버튼을 눌러 다음 화면으로. API를 부르는 버튼이면 실제 비동기가 끝날 때까지 기다린다
  Future<void> settle(WidgetTester tester) async {
    // 저장·다시 받기처럼 요청이 여러 번 이어지는 화면도 있다 → 실제 시간을 몇 번 흘려 준다
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  Future<void> tapNext(WidgetTester tester, String label) async {
    await settle(tester); // 화면이 처음 불러오는 값(W11 고정 일정 등)이 와야 버튼이 켜진다
    final button = find.text(label);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await settle(tester);
  }

  testWidgets('로그인한 알바가 지난달 답을 불러와 고치고 제출한다', (tester) async {
    await tester.runAsync(() => Session.instance.login('staff01', 'pw'));
    expect(Session.instance.storeId, 7); // 승인된 합류 매장

    await pumpScreen(tester, LoadLastMonthPage(month: DateTime(2026, 11)));
    await tapNext(tester, '시작하기'); // W00: 지난달 답 불러오기(기본 선택)
    await tapNext(tester, '다음'); // W11

    // W02: 서버가 준 교대·잠김으로 표가 그려지고, 지난달 선호 2칸이 채워져 있다
    expect(find.text('오픈 09-14'), findsOneWidget);
    expect(find.text('수업'), findsOneWidget);
    expect(find.text('선호'), findsNWidgets(3)); // 칸 2 + 범례 1
    await tester.tap(find.text('선호').first); // 11/3 오픈: 선호 → 불가
    await tester.pump();
    expect(find.text('선호'), findsNWidgets(2));

    await tapNext(tester, '다음'); // W02
    // W03: 서버에 있던 휴무 2건이 그대로 보이고, 고치지 않았으니 다시 저장하지 않는다
    expect(find.text('필수 · 순위 없이 항상 지켜져요'), findsOneWidget);
    expect(find.textContaining('1순위 오후만 쉬기 → 2순위 다른 날과 교환'), findsOneWidget);
    await tapNext(tester, '다음'); // W03
    // W06: 계약 범위와 예상 급여는 서버 값
    expect(find.text('주 15–20시간 · 시급 ₩10,320'), findsOneWidget);
    expect(find.text('64h'), findsOneWidget);
    await tapNext(tester, '다음'); // W06
    // W05: 서버 역량이 그려지고, 영어를 '상'으로 바꾸면 그것만 신청한다
    expect(find.text('확인 대기'), findsOneWidget);
    expect(find.text('~ 11/30'), findsOneWidget);
    await tester.tap(find.text('상').first);
    await tester.pump();
    await tapNext(tester, '다음'); // W05
    final skills = server.requests.singleWhere((r) => r.$1 == 'PUT' && r.$2.contains('/my-skills'));
    expect(skills.$3, [
      {'skillId': 1, 'level': 'HIGH'},
    ]);
    // '역량을 신청했어요' 스낵바가 W14 버튼을 덮으니 닫힐 때까지
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    await tapNext(tester, '신청 제출'); // W14
    expect(find.byType(PartTimerHomePage), findsOneWidget);

    expect(server.requests.where((r) => r.$2.contains('/day-offs') && r.$1 != 'GET'), isEmpty);
    final put = server.requests.singleWhere((r) => r.$1 == 'PUT' && r.$2.contains('/preferences/my'));
    expect(put.$2, endsWith('/api/stores/7/preferences/my?month=2026-11'));
    final body = put.$3 as Map<String, dynamic>;
    expect(body['slots'], [
      {'date': '2026-11-04', 'shiftId': 11, 'level': 'PREFERRED'},
    ]);
    expect(body['maxWeekendShifts'], 2);
    expect(body['minMonthlyHours'], 64);
    expect(body['maxMonthlyHours'], 86);
    expect(body['priorities'], ['DAY_OFF', 'SHIFT', 'WEEKEND', 'HOURS', 'RHYTHM']);
  });

  testWidgets('첫 달이라 지난달 답이 없으면 W00 에서 안내하고 빈 초안으로 이어 간다', (tester) async {
    server.firstMonth = true;
    await tester.runAsync(() => Session.instance.login('staff01', 'pw'));
    await pumpScreen(tester, LoadLastMonthPage(month: DateTime(2026, 11)));
    // W00 이 열리며 지난달 답을 미리 보고, 없으면 안내하고 '처음부터 새로 쓰기'를 고른다
    await settle(tester);
    expect(find.text('10월에 낸 희망이 없어요. 처음부터 써요.'), findsOneWidget);
    await tapNext(tester, '시작하기');
    await tapNext(tester, '다음'); // W11 → W02
    expect(find.text('선호'), findsOneWidget); // 범례만 (불러온 칸 없음)
  });
}
