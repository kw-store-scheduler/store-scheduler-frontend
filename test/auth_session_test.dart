import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:thyme_frontend/core/api_service.dart';
import 'package:thyme_frontend/core/session.dart';
import 'package:thyme_frontend/screens/common/a01_splash_page.dart';
import 'package:thyme_frontend/screens/common/a02_service_intro_page.dart';
import 'package:thyme_frontend/screens/common/a03_login_page.dart';
import 'package:thyme_frontend/screens/common/a05_terms_agreement_page.dart';
import 'package:thyme_frontend/screens/owner/p01_owner_home_page.dart';
import 'package:thyme_frontend/screens/worker/h01_part_timer_home_page.dart';
import 'package:thyme_frontend/widgets/thyme_back_button.dart';

import 'test_helpers.dart';

/// 로그인·회원가입·/me 만 흉내 내는 가짜 서버
class _AuthServer implements HttpClientAdapter {
  final calls = <String>[];

  /// GET /api/users/me 응답 (null 이면 401 = 토큰 만료)
  Map<String, dynamic>? me = owner;

  static const owner = {
    'id': 1,
    'username': 'owner01',
    'role': 'MANAGER',
    'ownedStores': [
      {'id': 5, 'name': '구시대 커피', 'industry': 'CAFE', 'storeCode': 'ABCD1234'},
    ],
    'memberships': [],
  };
  static const partTimer = {
    'id': 2,
    'username': 'staff01',
    'role': 'EMPLOYEE',
    'ownedStores': [],
    'memberships': [
      {'employeeId': 3, 'storeId': 5, 'storeName': '구시대 커피', 'status': 'APPROVED', 'employmentType': 'PART_TIME'},
    ],
  };
  static const fresh = {'id': 9, 'username': 'new01', 'role': 'EMPLOYEE', 'ownedStores': [], 'memberships': []};

  ResponseBody _json(Object body, int status) =>
      ResponseBody.fromString(jsonEncode(body), status, headers: {Headers.contentTypeHeader: [Headers.jsonContentType]});

  @override
  Future<ResponseBody> fetch(RequestOptions o, Stream<Uint8List>? s, Future<void>? c) async {
    calls.add('${o.method} ${o.path}');
    switch ((o.method, o.path)) {
      case ('POST', '/api/auth/signup'):
        return _json({}, 200);
      case ('POST', '/api/auth/login'):
        final body = o.data as Map;
        if (body['password'] != 'pw') return _json({'message': '아이디 또는 비밀번호가 올바르지 않습니다.'}, 400);
        return _json({'token': 'token-${body['username']}'}, 200);
      case ('GET', '/api/users/me'):
        final m = me;
        return m == null ? _json({'message': '로그인이 필요합니다.'}, 401) : _json(m, 200);
    }
    return _json({'message': '예상하지 못한 요청 ${o.method} ${o.path}'}, 500);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late _AuthServer server;
  setUp(() async {
    await loadTestFonts(); // 저장소도 비운다
    server = _AuthServer();
    ApiService().dio.httpClientAdapter = server;
    ApiService().token = null;
  });
  tearDown(() => Session.instance.logout());

  Future<void> settle(WidgetTester tester) async {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pumpAndSettle();
  }

  Future<void> loginAs(WidgetTester tester, String id, {bool signup = false}) async {
    await pumpScreen(tester, const LoginPage());
    if (signup) {
      await tester.tap(find.text('처음이에요 · 회원가입'));
      await tester.pump();
    }
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), id);
    await tester.enterText(fields.at(1), 'pw');
    if (signup) await tester.enterText(fields.at(2), 'pw');
    await tester.tap(find.text(signup ? '가입하고 시작하기' : '로그인'));
    await settle(tester);
  }

  testWidgets('로그인하면 /me 로 고른 첫 화면이 뜨고, 그 화면엔 뒤로가기가 없다', (tester) async {
    await loginAs(tester, 'owner01');
    expect(find.byType(OwnerHomePage), findsOneWidget);
    // 아래에 화면이 없으니 뒤로가기도 없고, 시스템 뒤로가기도 막힌다 (빈 화면 방지)
    expect(Navigator.canPop(tester.element(find.byType(OwnerHomePage))), isFalse);
    expect(find.byType(IconButton).evaluate().where((e) => e.findAncestorWidgetOfExactType<ThymeBackButton>() != null), isEmpty);
    final popScope = tester.widget<PopScope>(find.ancestor(of: find.byType(OwnerHomePage), matching: find.byType(PopScope)).first);
    expect(popScope.canPop, isFalse);
    // 토큰이 저장돼야 새로고침해도 이어진다
    expect((await SharedPreferences.getInstance()).getString('thyme.token'), 'token-owner01');
  });

  testWidgets('틀린 비밀번호는 서버 메시지를 보여 준다', (tester) async {
    await pumpScreen(tester, const LoginPage());
    await tester.enterText(find.byType(TextField).at(0), 'owner01');
    await tester.enterText(find.byType(TextField).at(1), 'wrong');
    await tester.tap(find.text('로그인'));
    await settle(tester);
    expect(find.text('아이디 또는 비밀번호가 올바르지 않습니다.'), findsOneWidget);
    expect(find.byType(LoginPage), findsOneWidget);
  });

  testWidgets('회원가입하면 가입 → 로그인 → A05 약관으로 (엉뚱한 화면 X)', (tester) async {
    server.me = _AuthServer.fresh;
    await loginAs(tester, 'new01', signup: true);
    expect(server.calls, containsAllInOrder(['POST /api/auth/signup', 'POST /api/auth/login', 'GET /api/users/me']));
    expect(find.byType(TermsAgreementPage), findsOneWidget);
  });

  testWidgets('새로고침(앱 재시작)해도 저장된 로그인으로 첫 화면으로 간다', (tester) async {
    SharedPreferences.setMockInitialValues({'thyme.token': 'token-staff01', 'thyme.storeId': 5});
    server.me = _AuthServer.partTimer;
    await pumpScreen(tester, const SplashPage());
    // 스플래시 대기(1.2초)는 테스트의 가짜 시간 → 시간을 흘리면서 서버 응답도 기다린다
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pumpAndSettle();
    expect(find.byType(PartTimerHomePage), findsOneWidget);
    expect(Session.instance.storeId, 5);
  });

  testWidgets('저장된 토큰이 만료(401)됐으면 지우고 처음 화면으로', (tester) async {
    SharedPreferences.setMockInitialValues({'thyme.token': 'expired'});
    server.me = null;
    await pumpScreen(tester, const SplashPage());
    // 스플래시 대기(1.2초)는 테스트의 가짜 시간 → 시간을 흘리면서 서버 응답도 기다린다
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await tester.pump(const Duration(milliseconds: 500));
    }
    await tester.pumpAndSettle();
    expect(find.byType(ServiceIntroPage), findsOneWidget);
    expect((await SharedPreferences.getInstance()).getString('thyme.token'), isNull);
  });
}
