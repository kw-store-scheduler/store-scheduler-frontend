import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thyme_frontend/core/api_service.dart';
import 'package:thyme_frontend/core/session.dart';
import 'package:thyme_frontend/screens/owner/owner_availability_page.dart';

import 'test_helpers.dart';

/// 사장님: 직원 전체의 평소 일할 수 있는 시간 (GET /stores/{id}/availabilities)
class _Server implements HttpClientAdapter {
  ResponseBody _json(Object? body, int status) =>
      ResponseBody.fromString(jsonEncode(body), status, headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    switch ((o.method, o.path)) {
      case ('GET', '/api/stores/7/roster'):
        return _json({
          'pendingApprovals': 0,
          'employees': [
            {'employeeId': 11, 'name': '권가은', 'employmentType': 'PART_TIME'},
            {'employeeId': 10, 'name': '손가은', 'employmentType': 'PART_TIME'},
            {'employeeId': 8, 'name': '여선우', 'employmentType': 'FULL_TIME'},
          ],
        }, 200);
      case ('GET', '/api/stores/7/availabilities'):
        return _json([
          {'id': 1, 'employeeId': 11, 'employeeName': '권가은', 'dayOfWeek': 'TUESDAY', 'startTime': '09:00:00', 'endTime': '23:59:00'},
          {'id': 2, 'employeeId': 10, 'employeeName': '손가은', 'dayOfWeek': 'TUESDAY', 'startTime': '14:00:00', 'endTime': '22:00:00'},
          // 퇴사한 사람 것 → 안 보여야 한다
          {'id': 3, 'employeeId': 99, 'employeeName': '퇴사자', 'dayOfWeek': 'TUESDAY', 'startTime': '00:00:00', 'endTime': '23:59:00'},
        ], 200);
      case ('GET', '/api/stores/7/shifts'):
        return _json([
          {'id': 1, 'name': '오전', 'startTime': '06:00:00', 'endTime': '14:00:00', 'requiredStaff': 1},
          {'id': 2, 'name': '오후', 'startTime': '14:00:00', 'endTime': '22:00:00', 'requiredStaff': 2},
          {'id': 3, 'name': '야간', 'startTime': '22:00:00', 'endTime': '06:00:00', 'requiredStaff': 1},
        ], 200);
    }
    return _json({'message': '예상하지 못한 요청 ${o.method} ${o.path}'}, 500);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  setUp(() async {
    await loadTestFonts();
    ApiService().dio.httpClientAdapter = _Server();
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

  testWidgets('요일을 고르면 교대별 들어갈 수 있는 인원과 직원별 시간을 보여 준다', (tester) async {
    await pumpScreen(tester, const OwnerAvailabilityPage());
    await settle(tester);
    await tester.tap(find.text('화'));
    await tester.pump();

    expect(find.text('화요일 2명'), findsOneWidget); // 퇴사자 것은 뺀다
    expect(find.text('퇴사자'), findsNothing);
    // 오전 06–14: 둘 다 못 들어감, 오후: 둘 다, 야간(밤샘): 23:59 까지인 권가은만. 여기에 시간을 안 정한 정규직 여선우(매일 가능)를 더한다
    Finder shift(String label, String n) => find.descendant(
        of: find.ancestor(of: find.text(label, findRichText: true), matching: find.byType(Row)).first, matching: find.text(n));
    expect(shift('오전  06:00–14:00', '1명'), findsOneWidget);
    expect(shift('오후  14:00–22:00', '3명'), findsOneWidget);
    expect(shift('야간  22:00–06:00', '2명'), findsOneWidget);
    expect(find.text('시간을 안 정한 정규직 1명(매일 가능으로 봄)을 포함한 수예요.'), findsOneWidget);
    expect(find.text('09:00–24:00 (밤샘 가능)'), findsOneWidget);
    expect(find.text('14:00–22:00'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('시간을 안 정한 정규직 1'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('여선우'), findsOneWidget);
    expect(find.text('매일 가능으로 보고 배정해요'), findsOneWidget);

    await tester.tap(find.text('월'));
    await tester.pump();
    await tester.scrollUntilVisible(find.text('월요일에 시간을 정한 직원이 없어요.'), -200, scrollable: find.byType(Scrollable).first);
    expect(find.text('월요일에 시간을 정한 직원이 없어요.'), findsOneWidget);
  });
}
