import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thyme_frontend/core/api_service.dart';
import 'package:thyme_frontend/core/session.dart';
import 'package:thyme_frontend/models/preference.dart';
import 'package:thyme_frontend/screens/owner/o03_store_shift_setup_page.dart';
import 'package:thyme_frontend/screens/worker/w02_date_shift_page.dart';

import 'test_helpers.dart';

/// 요일별 교대: 사장님이 고른 요일에만 교대가 있고(나머지는 0명 = 서버가 그날 교대를 닫음),
/// 직원 희망 표(W02)에서는 그날 없는 교대 칸을 고를 수 없다 (서버가 "근무 칸이 아닙니다" 400 으로 제출 전체를 거절하므로)

/// 2026년 11월, 교대 2개(오픈 11, 마감 12). 마감은 주말에만 있다
PreferenceMonth _month() => PreferenceMonth.fromJson({
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
            if (shift == 11 || DateTime(2026, 11, d).weekday >= DateTime.saturday)
              {'date': '2026-11-${d.toString().padLeft(2, '0')}', 'shiftId': shift, 'level': null, 'locked': false},
      ],
      'submission': null,
    });

class _O03Server implements HttpClientAdapter {
  final requests = <(String, String, Object?)>[];
  var _next = 20;

  ResponseBody _json(Object? body, int status) =>
      ResponseBody.fromString(jsonEncode(body), status, headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    requests.add((o.method, o.path, o.data));
    switch ((o.method, o.path)) {
      case ('GET', '/api/stores/7/shifts'):
        return _json([
          {'id': 11, 'name': '오전', 'startTime': '09:00:00', 'endTime': '15:00:00', 'requiredStaff': 2, 'dayStaffing': []},
        ], 200);
      case ('GET', '/api/stores'):
        return _json([
          {'id': 7, 'name': '이층집', 'storeCode': 'ABCD1234', 'industry': 'RESTAURANT', 'allowSplitShift': false, 'scheduleCycle': 'WEEKLY'},
        ], 200);
      case ('POST', '/api/stores/7/shifts'):
        final b = (o.data as Map).cast<String, dynamic>();
        return _json({'id': _next++, ...b, 'dayStaffing': []}, 200);
    }
    if (o.method == 'PUT' && o.path.endsWith('/day-staffing')) return _json([], 200);
    return _json({'message': '예상하지 못한 요청 ${o.method} ${o.path}'}, 500);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(() async {
    await loadTestFonts();
    ApiService().token = 'test-token';
    Session.instance.storeId = 7;
  });
  tearDown(Session.instance.logout);

  test('지난달 답에 이번 달엔 없는 칸이 있으면 초안에서 뺀다', () {
    final draft = PreferenceDraft(month: DateTime(2026, 11))..view = _month();
    draft.setSlot(DateTime(2026, 11, 2), 12, PreferenceLevel.preferred); // 월요일 마감: 없는 칸
    draft.setSlot(DateTime(2026, 11, 7), 12, PreferenceLevel.available); // 토요일 마감: 있는 칸
    draft.setSlot(DateTime(2026, 11, 2), 11, PreferenceLevel.available);
    draft.trimToView();
    expect(draft.slotAt(DateTime(2026, 11, 2), 12), isNull);
    expect(draft.slotAt(DateTime(2026, 11, 7), 12), PreferenceLevel.available);
    expect(draft.slotAt(DateTime(2026, 11, 2), 11), PreferenceLevel.available);
  });

  testWidgets('W02: 그 요일엔 없는 교대 칸은 – 로 보이고 눌러도 고를 수 없다', (tester) async {
    final draft = PreferenceDraft(month: DateTime(2026, 11))..view = _month();
    await pumpScreen(tester, DateShiftPage(draft: draft));
    await tester.pump();
    // 1~7일 중 마감이 있는 날은 7일(토)·1일(일)뿐 → 월~금 5칸이 없음
    expect(find.text('–'), findsNWidgets(5));
    expect(find.text('– 은 그 요일엔 없는 교대예요'), findsOneWidget);
    await tester.tap(find.text('–').first);
    await tester.pump();
    expect(draft.slots, isEmpty);
  });

  testWidgets('O03: 교대를 추가할 때 주말을 고르면 평일은 0명으로 바로 저장하고 "주말만"으로 보인다', (tester) async {
    final server = _O03Server();
    ApiService().dio.httpClientAdapter = server;
    await pumpScreen(tester, const StoreShiftSetupPage(editing: true));
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 300));
    }
    await tester.tap(find.text('교대 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '주말 오전');
    await tester.tap(find.text('주말'));
    await tester.pump();
    await tester.tap(find.text('추가'));
    for (var i = 0; i < 3; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 300));
    }
    final put = server.requests.singleWhere((r) => r.$1 == 'PUT' && r.$2 == '/api/stores/7/shifts/20/day-staffing');
    expect([for (final d in put.$3 as List) (d as Map)['minStaff']], [0, 0, 0, 0, 0, 1, 1]);
    expect(find.text('주말만'), findsOneWidget);

    // 요일을 하나도 안 고르면 추가 버튼이 막힌다
    await tester.tap(find.text('교대 추가'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '야간');
    for (final d in ['월', '화', '수', '목', '금', '토', '일']) {
      await tester.tap(find.text(d).last);
    }
    await tester.pump();
    expect(find.text('요일을 하나 이상 골라 주세요'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, '추가')).onPressed, isNull);
  });
}
