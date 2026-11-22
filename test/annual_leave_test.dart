import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thyme_frontend/core/api_service.dart';
import 'package:thyme_frontend/core/session.dart';
import 'package:thyme_frontend/screens/worker/worker_annual_leave_page.dart';
import 'package:thyme_frontend/widgets/thyme_pickers.dart';

import 'test_helpers.dart';

/// 직원 연차 (백엔드 LeaveController: GET /leaves/my · POST /leaves · POST /leaves/{id}/cancel)
class _Server implements HttpClientAdapter {
  final requests = <(String, String, Object?)>[];
  int remaining = 10;
  bool fullTime = true;
  final leaves = <Map<String, dynamic>>[];
  var _nextId = 1;

  ResponseBody _json(Object? body, int status) =>
      ResponseBody.fromString(jsonEncode(body), status, headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});

  String _ymd(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    requests.add((o.method, o.path, o.data));
    if (o.method == 'GET' && o.path == '/api/holidays') return _json([], 200);
    if (o.method == 'GET' && o.path == '/api/stores/7/leaves/my') {
      final used = leaves.where((l) => l['status'] == 'PENDING' || l['status'] == 'APPROVED').length;
      return _json({
        'balance': fullTime ? {'leaveYearStart': '2026-03-01', 'entitled': remaining + used, 'used': used, 'remaining': remaining} : null,
        'requests': leaves.reversed.toList(),
      }, 200);
    }
    if (o.method == 'POST' && o.path == '/api/stores/7/leaves') {
      final b = o.data as Map;
      final l = {'id': _nextId++, 'employeeId': 3, 'employeeName': '여선우', 'date': b['date'], 'reason': b['reason'], 'status': 'PENDING'};
      leaves.add(l);
      remaining--;
      return _json(l, 200);
    }
    final cancel = RegExp(r'^/api/stores/7/leaves/(\d+)/cancel$').firstMatch(o.path);
    if (o.method == 'POST' && cancel != null) {
      final l = leaves.firstWhere((l) => l['id'] == int.parse(cancel[1]!));
      l['status'] = 'CANCELLED';
      remaining++;
      return _json(l, 200);
    }
    return _json({'message': '예상하지 못한 요청 ${o.method} ${o.path} ${_ymd(DateTime.now())}'}, 500);
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
    ApiService().token = 'employee-token';
    Session.instance.storeId = 7;
  });
  tearDown(Session.instance.logout);

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
      await tester.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('날짜 고르고 사유 적어 신청 → 목록에 승인 대기, 다시 취소', (tester) async {
    await pumpScreen(tester, const AnnualLeavePage());
    await settle(tester);
    expect(find.text('10 일', findRichText: true), findsOneWidget); // 남은 연차
    expect(find.text('아직 신청한 연차가 없어요.'), findsOneWidget);

    await tester.tap(find.text('연차 신청'));
    await tester.pumpAndSettle();
    final day = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 3));
    final cell = find.byKey(thymeDayKey(day));
    await tester.scrollUntilVisible(cell, 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(cell);
    await tester.pump();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();

    expect(find.text('${thymeMdw(day)} 연차 신청'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '가족 행사');
    await tester.tap(find.text('신청하기'));
    await settle(tester);

    final post = server.requests.singleWhere((r) => r.$1 == 'POST');
    expect(post.$3, {'date': '${day.year}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}', 'reason': '가족 행사'});
    expect(find.text('9 일', findRichText: true), findsOneWidget);
    expect(find.text('승인 대기'), findsOneWidget);
    expect(find.text('가족 행사'), findsOneWidget);

    // 같은 날은 달력에서 못 고른다
    await tester.tap(find.text('연차 신청'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.byKey(thymeDayKey(day)), 200, scrollable: find.byType(Scrollable).last);
    await tester.tap(find.byKey(thymeDayKey(day)));
    await tester.pump();
    expect(find.text('날짜를 골라 주세요'), findsOneWidget);
    await tester.tap(find.byTooltip('닫기'));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(TextButton, '취소'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('연차 취소'));
    await settle(tester);
    expect(server.requests.where((r) => r.$1 == 'POST' && r.$2 == '/api/stores/7/leaves/1/cancel'), hasLength(1));
    expect(find.text('취소함'), findsOneWidget);
    expect(find.text('10 일', findRichText: true), findsOneWidget);
  });

  testWidgets('남은 연차가 없으면 신청 버튼이 막힌다', (tester) async {
    server.remaining = 0;
    await pumpScreen(tester, const AnnualLeavePage());
    await settle(tester);
    expect(find.text('남은 연차가 없어요'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, '남은 연차가 없어요')).onPressed, isNull);
  });

  testWidgets('알바(잔여 없음)는 휴무 신청으로 안내한다', (tester) async {
    server.fullTime = false;
    await pumpScreen(tester, const AnnualLeavePage());
    await settle(tester);
    expect(find.textContaining('연차는 정규직만 신청할 수 있어요'), findsOneWidget);
    expect(find.text('연차 신청'), findsNothing);
  });
}
