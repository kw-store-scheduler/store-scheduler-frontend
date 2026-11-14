import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thyme_frontend/core/api_service.dart';
import 'package:thyme_frontend/core/session.dart';
import 'package:thyme_frontend/screens/worker/w11_fixed_schedule_page.dart';

import 'test_helpers.dart';

/// W11 아래 '평소 일할 수 있는 시간' (백엔드 AvailabilityController, 요일마다 한 건)
class _Server implements HttpClientAdapter {
  final requests = <(String, String, Object?)>[];
  var avail = <Map<String, dynamic>>[
    {'id': 3, 'employeeId': 5, 'employeeName': '권가은', 'dayOfWeek': 'TUESDAY', 'startTime': '09:00:00', 'endTime': '18:00:00'},
    {'id': 4, 'employeeId': 5, 'employeeName': '권가은', 'dayOfWeek': 'SUNDAY', 'startTime': '12:00:00', 'endTime': '20:00:00'},
  ];
  var _next = 10;

  ResponseBody _json(Object? body, int status) =>
      ResponseBody.fromString(jsonEncode(body), status, headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    requests.add((o.method, o.path, o.data));
    switch ((o.method, o.path)) {
      case ('GET', '/api/stores/7/fixed-schedules/my'):
      case ('GET', '/api/stores/7/unavailable-periods/my'):
        return _json([], 200);
      case ('PUT', '/api/stores/7/fixed-schedules/my'):
      case ('PUT', '/api/stores/7/unavailable-periods/my'):
        return _json([], 200);
      case ('GET', '/api/availabilities/my'):
        return _json(avail, 200);
      case ('POST', '/api/availabilities'):
        final a = {'id': _next++, 'employeeId': 5, ...(o.data as Map).cast<String, dynamic>()};
        avail.add(a);
        return _json(a, 200);
    }
    final m = RegExp(r'^/api/availabilities/(\d+)$').firstMatch(o.path);
    if (m != null && o.method == 'DELETE') {
      avail.removeWhere((a) => a['id'] == int.parse(m[1]!));
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

  testWidgets('요일마다 정하고, 밤샘(끝 00:00)은 23:59 로, 빈 요일에 복사, 지운 요일은 DELETE', (tester) async {
    await pumpScreen(tester, const FixedSchedulePage());
    await settle(tester);
    final card = find.text('평소 일할 수 있는 시간 (선택)');
    await tester.scrollUntilVisible(card, 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('09:00–18:00'), findsOneWidget); // 화 (서버에 있던 것)
    expect(find.text('12:00–20:00'), findsOneWidget); // 일

    // 월: 10:00 ~ 밤새
    await tester.tap(find.text('안 돼요 · 눌러서 정하기').first);
    await tester.pumpAndSettle();
    expect(find.text('월요일 일할 수 있는 시간'), findsOneWidget);
    await tester.tap(find.text('직접 입력'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '1000');
    await tester.enterText(find.byType(TextField).at(1), '0000');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('10:00–24:00 (밤샘 가능)'), findsOneWidget);

    // 빈 요일(수·목·금·토)에 같은 시간, 일요일은 지운다
    final copy = find.textContaining('을 비어 있는 요일에 모두');
    await Scrollable.ensureVisible(tester.element(copy), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(copy);
    await tester.pump();
    expect(find.text('10:00–24:00 (밤샘 가능)'), findsNWidgets(5));
    await Scrollable.ensureVisible(tester.element(find.byTooltip('일요일 지우기')), alignment: 0.5);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('일요일 지우기'));
    await tester.pump();

    await tester.tap(find.text('저장'));
    await settle(tester);
    final posts = server.requests.where((r) => r.$1 == 'POST' && r.$2 == '/api/availabilities').map((r) => r.$3 as Map).toList();
    expect(posts.map((p) => p['dayOfWeek']), ['MONDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY']);
    expect(posts.first, {'storeId': 7, 'dayOfWeek': 'MONDAY', 'startTime': '10:00', 'endTime': '23:59'});
    expect(server.requests.where((r) => r.$1 == 'DELETE').map((r) => r.$2), ['/api/availabilities/4']);
    expect(server.requests.where((r) => r.$1 == 'PUT' && r.$2.startsWith('/api/availabilities')), isEmpty); // 화는 그대로
  });

  testWidgets('끝이 시작보다 이르면 저장하지 않고 알려 준다', (tester) async {
    await pumpScreen(tester, const FixedSchedulePage());
    await settle(tester);
    await tester.scrollUntilVisible(find.text('평소 일할 수 있는 시간 (선택)'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('안 돼요 · 눌러서 정하기').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('직접 입력'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '1800');
    await tester.enterText(find.byType(TextField).at(1), '0900');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.textContaining('끝이 시작보다 늦어야 해요'), findsOneWidget);
    expect(find.text('안 돼요 · 눌러서 정하기'), findsNWidgets(5)); // 월은 그대로 비어 있음
  });
}
