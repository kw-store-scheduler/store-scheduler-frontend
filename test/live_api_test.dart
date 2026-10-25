// 실제 백엔드에 화면을 붙여 사용자가 누르는 순서 그대로 따라가는 E2E. 평소 `flutter test`에서는 건너뛴다.
//
// 백엔드를 띄운 뒤 (Docker 없이: store-scheduler-backend/Store_Scheduler_Backend 에서 ./gradlew bootTestRun → H2 메모리 DB)
//   THYME_LIVE_API=http://localhost:8080 flutter test test/live_api_test.dart
// 매번 새 아이디로 가입하므로 같은 서버에서 여러 번 돌려도 된다.

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thyme_frontend/core/api_service.dart';
import 'package:thyme_frontend/core/session.dart';
import 'package:thyme_frontend/screens/common/a02_service_intro_page.dart';
import 'package:thyme_frontend/screens/common/a05_terms_agreement_page.dart';
import 'package:thyme_frontend/screens/common/a06_role_selection_page.dart';
import 'package:thyme_frontend/screens/owner/o02_schedule_cycle_page.dart';
import 'package:thyme_frontend/screens/owner/o03_store_shift_setup_page.dart';
import 'package:thyme_frontend/screens/owner/o04_curation_page.dart';
import 'package:thyme_frontend/screens/owner/o05_labor_law_page.dart';
import 'package:thyme_frontend/screens/owner/o06_exception_days_page.dart';
import 'package:thyme_frontend/screens/owner/p02_registration_complete_page.dart';
import 'package:thyme_frontend/screens/worker/e01_employee_leave_page.dart';
import 'package:thyme_frontend/screens/worker/h02_employee_home_page.dart';
import 'package:thyme_frontend/screens/worker/j02_employment_type_page.dart';
import 'package:thyme_frontend/screens/worker/j03_join_profile_page.dart';
import 'package:thyme_frontend/screens/worker/j04_approval_waiting_page.dart';
import 'package:thyme_frontend/screens/worker/w04_shift_attitude_page.dart';

import 'test_helpers.dart';

final _server = Platform.environment['THYME_LIVE_API'];

void main() {
  setUpAll(() async {
    await loadTestFonts();
    // flutter_test는 기본으로 모든 HTTP를 막는다 → 실제 서버로 보내도록 푼다
    HttpOverrides.global = null;
    ApiService().dio.options.baseUrl = _server ?? '';
    // 화면(테스트의 가짜 시간)과 runAsync(실제 시간)가 keep-alive 연결을 나눠 쓰면 서로 막힌다 → 요청마다 새 연결
    ApiService().dio.options.persistentConnection = false;
  });
  tearDown(() => Session.instance.logout());

  // 요청 시간 제한 타이머가 가짜 시간에 남지 않게 흘려보낸다
  Future<void> finish(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(minutes: 2));
  }

  final stamp = DateTime.now().millisecondsSinceEpoch % 1000000;
  final owner = 'owner$stamp';
  final staff = 'staff$stamp';
  const password = 'password123';
  String? storeCode;
  int? storeId;

  /// 실제 네트워크를 기다리며 조건이 될 때까지 화면을 갱신한다
  /// 조건을 기다리는 최대 시간 ≈ maxTries × 0.15초 (원격 무료 서버는 요청 하나에 수 초~1분이 걸린다)
  Future<void> settle(WidgetTester tester, {bool Function()? until, int maxTries = 600}) async {
    for (var i = 0; i < maxTries; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100)));
      await tester.pump(const Duration(milliseconds: 50));
      if (until == null ? i >= 3 : until()) break;
    }
    // pumpAndSettle 은 쓰지 않는다: 로딩 스피너처럼 끝없는 애니메이션이 있으면 가짜 시간을 몇 분씩 흘려
    // 실제로 진행 중인 요청을 '연결 시간 초과'로 만든다. 화면 전환(약 300ms)만 끝내 준다.
    for (var i = 0; i < 4; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  String screenText(WidgetTester tester) =>
      tester.widgetList<Text>(find.byType(Text)).map((t) => t.data ?? t.textSpan?.toPlainText()).join(' | ');

  Future<void> tap(WidgetTester tester, Finder f, {bool Function()? until}) async {
    await tester.pump();
    if (f.evaluate().isEmpty) fail('$f 를 찾지 못함. 화면: ${screenText(tester)}');
    await tester.ensureVisible(f.first);
    await tester.tap(f.first);
    await settle(tester, until: until);
  }

  bool shows(Type page) => find.byType(page).evaluate().isNotEmpty;
  bool has(String text) => find.text(text).evaluate().isNotEmpty;

  // 확인용 조회는 새 연결로 보낸다. 화면이 만든 연결은 테스트의 가짜 시간에 묶여 있어서 runAsync 안에서 끝나지 않는다
  Future<dynamic> liveGet(WidgetTester tester, String path, [Map<String, dynamic>? query]) => tester.runAsync(() async {
        final dio = Dio(BaseOptions(baseUrl: _server!, headers: {'Authorization': 'Bearer ${ApiService().token}'}));
        return (await dio.get(path, queryParameters: query)).data;
      });

  /// A02 시작하기 → 회원가입 → A05 약관 → A06 역할 선택까지 (화면으로)
  Future<void> signUpToRoleSelection(WidgetTester tester, String id) async {
    await pumpScreen(tester, const ServiceIntroPage());
    await tap(tester, find.text('시작하기'), until: () => has('가입하고 시작하기'));
    final fields = find.byType(TextField);
    await tester.enterText(fields.at(0), id);
    await tester.enterText(fields.at(1), password);
    await tester.enterText(fields.at(2), password);
    await tap(tester, find.text('가입하고 시작하기'), until: () => shows(TermsAgreementPage));
    expect(find.text('필수 항목에 동의해 주세요'), findsOneWidget); // 필수 동의 전엔 못 넘어감
    await tap(tester, find.text('전체 동의'));
    await tap(tester, find.text('동의하고 계속하기'), until: () => shows(RoleSelectionPage));
    expect(find.text('반가워요, $id님'), findsOneWidget);
  }

  testWidgets('점주: A02 → 회원가입 → A05 → A06 점주 → O01~O05 → P02 (서버에 실제로 저장)', (tester) async {
    await signUpToRoleSelection(tester, owner);
    await tap(tester, find.text('점주 · 매니저'));
    await tap(tester, find.text('매장 등록하기'), until: () => has('어떤 매장인가요?'));

    // O01: 이름이 없으면 못 넘어감 → 매장 생성 (업종 기본 교대·역량은 서버가 만든다)
    expect(find.text('매장 이름을 입력해 주세요'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, '테스트 카페 $stamp');
    await tap(tester, find.text('다음'), until: () => shows(ScheduleCyclePage));
    storeId = Session.instance.storeId;
    expect(storeId, isNotNull);

    // O02: 월간을 누르면 바로 저장되고, 서버가 계산한 일정이 보인다
    await settle(tester, until: () => has('월간'));
    await tap(tester, find.text('월간'), until: () => has('월간을 고르면 직원은 날짜별로 가능 여부를 체크해요. 지난달 패턴이 미리 채워져요.'));
    // 저장이 끝나야 버튼이 '저장 중…'에서 '다음'으로 돌아온다
    await settle(tester, until: () => has('다음') && find.textContaining('생성 3일 전').evaluate().isNotEmpty);
    expect(find.textContaining('생성 3일 전'), findsOneWidget);
    await tap(tester, find.text('다음').last, until: () => shows(StoreShiftSetupPage)); // 전환 중엔 O01의 '다음'도 남아 있다

    // O03: 서버 교대(카페 3교대, 7요일 모두 1명)가 그려진다
    await settle(tester, until: () => has('09:00–14:00'));
    expect(find.text('1'), findsNWidgets(21));

    // '시간 자유 (30분 단위)' 탭이 눌리고, 오픈 끝 시간을 30분 늦춘다
    await tap(tester, find.text('시간 자유 (30분 단위)'), until: () => find.byTooltip('끝 30분 뒤로').evaluate().isNotEmpty);
    await tap(tester, find.byTooltip('끝 30분 뒤로').first);
    expect(find.text('14:30'), findsOneWidget);
    await tap(tester, find.text('정해진 교대'), until: () => has('09:00–14:30'));

    // 칸: + 버튼 (마감 월요일 1 → 2)
    await tap(tester, find.text('1').at(14), until: () => has('마감 · 월요일')); // 표: 3교대 × 7요일, 15번째 칸 = 마감 월요일
    await tap(tester, find.byTooltip('1명 늘리기'));
    await tap(tester, find.text('적용'), until: () => !has('마감 · 월요일'));
    // 칸: 직접 입력 (오픈 월요일 3명)
    await tap(tester, find.text('1').first, until: () => has('오픈 · 월요일'));
    await tester.enterText(find.byType(TextField).last, '3');
    await tap(tester, find.text('적용'), until: () => !has('오픈 · 월요일'));
    expect(find.text('3'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    // 교대 추가 (야간 · 시트 기본 09:00–13:00) → 서버에 바로 생긴다
    await tap(tester, find.text('교대 추가'), until: () => has('이름 (예: 오전, 오후, 야간)'));
    await tester.enterText(find.byType(TextField).last, '야간');
    // 교대 목록과 인원 표 두 곳에 '야간'이 생기고 저장이 끝나야 한다 (입력창 글자도 find.text 에 걸린다)
    await tap(tester, find.text('추가'), until: () => has('다음 · 예외일') && find.text('야간').evaluate().length >= 2);
    await tap(tester, find.text('다음 · 예외일'), until: () => shows(ExceptionDaysPage));

    // O06: 달력 날짜(15일)를 누르면 그날 예외일 추가 시트가 열린다 (기본: 세일 행사 · 모든 교대 +1명)
    await settle(tester, until: () => has('이 달엔 예외일이 없어요. 평소와 같으면 그냥 넘어가도 돼요.'));
    await tap(tester, find.text('15'), until: () => has('예외일 추가'));
    await tap(tester, find.text('추가'), until: () => find.textContaining('모든 교대 +1명').evaluate().isNotEmpty);
    // 같은 날을 다시 누르면 그날 목록 (삭제·더 추가)
    await tap(tester, find.text('15'), until: () => has('이 날 예외일 더 추가'));
    await tester.tapAt(const Offset(195, 40)); // 시트 바깥을 눌러 닫기
    await settle(tester);
    await tap(tester, find.text('다음 · 필요한 역량'), until: () => shows(CurationPage));

    // O04: 매장 역량이 서버 값으로 보이고, 시간대별 필요 역량을 하나 추가
    await settle(tester, until: () => find.textContaining('아직 없어요').evaluate().isNotEmpty);
    expect(find.text('음료 제조'), findsOneWidget);
    await tap(tester, find.text('+ 필요한 역량 추가'), until: () => has('필요한 역량 추가'));
    await tap(tester, find.text('추가'), until: () => find.textContaining('· 필수').evaluate().isNotEmpty);
    await tap(tester, find.text('다음'), until: () => shows(LaborLawPage));

    // O05: 서버 기본값 4일 → + 로 5일 → 저장 → P02
    await settle(tester, until: () => has('4일'));
    await tap(tester, find.byTooltip('하루 늘리기'));
    expect(find.text('5일'), findsOneWidget);
    await tap(tester, find.text('매장 등록 완료'), until: () => shows(RegistrationCompletePage));
    await settle(tester, until: () => has('교대 시간대 4개'));
    storeCode = Session.instance.currentOwnedStore!.storeCode;
    expect(find.text(storeCode!), findsOneWidget); // 서버가 발급한 8자리 코드
    expect(storeCode!.length, 8);
    expect(find.text('조건 1개'), findsOneWidget);

    // 서버에 정말 저장됐는지 API로 다시 읽어 본다
    final stores = await liveGet(tester, '/api/stores') as List;
    final store = stores.firstWhere((s) => s['id'] == storeId) as Map;
    expect(store['scheduleCycle'], 'MONTHLY');
    expect(store['autoGenerate'], true);
    expect(store['maxConsecutiveDays'], 5);
    expect(store['fivePlusBusiness'], isNull); // 건드리지 않으면 서버가 직원 수로 판단
    final shifts = await liveGet(tester, '/api/stores/$storeId/shifts') as List;
    Map shift(String name) => shifts.firstWhere((s) => s['name'] == name) as Map;
    Map monday(String name) => (shift(name)['dayStaffing'] as List).firstWhere((d) => d['dayOfWeek'] == 'MONDAY') as Map;
    expect(shift('오픈')['endTime'], '14:30:00');
    expect(monday('오픈')['minStaff'], 3);
    expect(monday('마감')['minStaff'], 2);
    expect(monday('마감')['targetStaff'], 3); // 목표 = 최소 +1
    expect(shift('야간')['startTime'], '09:00:00');
    final next = DateTime(DateTime.now().year, DateTime.now().month + 1);
    String d(DateTime x) => '${x.year}-${x.month.toString().padLeft(2, '0')}-${x.day.toString().padLeft(2, '0')}';
    final exceptions = await liveGet(tester, '/api/stores/$storeId/staffing-exceptions',
        {'from': d(next), 'to': d(DateTime(next.year, next.month + 1, 0))}) as List;
    expect(exceptions.single['date'], d(DateTime(next.year, next.month, 15)));
    expect(exceptions.single['deltaStaff'], 1);
    final windows = await liveGet(tester, '/api/stores/$storeId/skill-windows') as List;
    expect(windows, hasLength(1));
    await finish(tester);
  }, skip: _server == null); // THYME_LIVE_API 가 없으면 건너뜀

  testWidgets('근로자: 회원가입 → J01 → J02 직원 → J03 달력 → J04 → 승인 → E01 날짜·대안 → W04 → W14 → H02', (tester) async {
    expect(storeCode, isNotNull, reason: '점주 테스트가 먼저 매장을 만들어야 한다');
    await signUpToRoleSelection(tester, staff);
    await tap(tester, find.text('매장 코드 입력하기'), until: () => has('매장 코드'));

    // J01: 틀린 코드는 서버 메시지, 맞는 코드는 서버 매장 이름 (칸 뒤의 입력창에 넣는다)
    await tester.enterText(find.byType(TextField), 'ZZZZZZZZ');
    await settle(tester, until: () => has('유효하지 않은 매장 코드입니다.'));
    expect(find.text('유효하지 않은 매장 코드입니다.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), storeCode!);
    await settle(tester, until: () => has('테스트 카페 $stamp'));
    await tap(tester, find.text('이 매장으로 계속'), until: () => shows(EmploymentTypePage));

    // J02 직원 → J03
    await tap(tester, find.text('직원').first); // 위쪽 카드 (아래 비교표에도 '직원'이 있다)
    await tap(tester, find.text('직원으로 계속'), until: () => shows(JoinProfilePage));
    expect(find.text('이름을 입력해 주세요'), findsOneWidget); // 이름 없으면 못 보냄
    await tester.enterText(find.byType(TextField).first, '김지수');
    await tester.pump();

    // 근무 시작일: 누르면 달력이 열린다 (예전엔 안 열렸음)
    await tap(tester, find.byIcon(Icons.calendar_today), until: () => has('확인'));
    await tap(tester, find.text('1').last);
    await tap(tester, find.text('확인'));
    final now = DateTime.now();
    expect(find.textContaining('${now.year}. ${now.month.toString().padLeft(2, '0')}. 01'), findsOneWidget);

    await tap(tester, find.text('가입 요청 보내기'), until: () => shows(ApprovalWaitingPage));
    expect(find.text('테스트 카페 $stamp'), findsOneWidget);
    expect(Session.instance.me!.memberships.single.status, 'PENDING');

    // 승인 전 확인 → 아직
    await settle(tester, until: () => has('승인 확인'));
    await tap(tester, find.text('승인 확인'), until: () => find.textContaining('아직 승인 전').evaluate().isNotEmpty);

    // 점주가 승인 (점주 토큰으로 직접 호출)
    await tester.runAsync(() async {
      final dio = Dio(BaseOptions(baseUrl: _server!, headers: {'Content-Type': 'application/json'}));
      final token = (await dio.post('/api/auth/login', data: {'username': owner, 'password': password})).data['token'];
      dio.options.headers['Authorization'] = 'Bearer $token';
      final pending = (await dio.get('/api/stores/$storeId/employees/pending')).data as List;
      await dio.post('/api/stores/$storeId/employees/${pending.single['id']}/approve', data: {'hourlyWage': 10320, 'employmentType': 'FULL_TIME'});
    });
    await tester.pump(const Duration(seconds: 5)); // 스낵바 닫히기
    await tap(tester, find.text('승인 확인'), until: () => has('승인됐어요'));
    expect(Session.instance.storeId, storeId);

    // E01: 날짜 추가(달력) → 대안 '연차'를 2순위로 → 최대 사용 1일
    await tap(tester, find.text('첫 근무 희망 내기'), until: () => shows(EmployeeLeavePage));
    await settle(tester, until: () => has('+ 날짜 추가'));
    await tap(tester, find.text('+ 날짜 추가'), until: () => has('확인'));
    await tap(tester, find.text('15').last);
    await tap(tester, find.text('확인'));
    expect(find.textContaining('/15 ('), findsOneWidget);
    await tap(tester, find.text('연차'));
    expect(find.text('1순위 휴무 요청 → 2순위 연차'), findsOneWidget);
    await tap(tester, find.text('다음 · 선호 시간대'), until: () => shows(ShiftAttitudePage));

    // 서버에 휴무 신청이 저장됐는지
    final dayOffs = await liveGet(tester, '/api/stores/$storeId/day-offs/my') as List;
    expect(dayOffs, hasLength(1));
    expect(dayOffs.single['fallbacks'], ['ANNUAL_LEAVE']);

    // W04(서버 교대) → W14 제출 → H02
    expect(find.text('오픈'), findsOneWidget);
    await tap(tester, find.text('선호')); // 오픈 = 선호
    await tap(tester, find.text('다음 · 우선순위'));
    await tap(tester, find.text('신청 제출'), until: () => shows(EmployeeHomePage));

    final month = DateTime(now.year, now.month + 1);
    final monthParam = '${month.year}-${month.month.toString().padLeft(2, '0')}';
    final mine = await liveGet(tester, '/api/stores/$storeId/preferences/my', {'month': monthParam}) as Map;
    expect(mine['submitted'], true);
    final attitudes = (mine['submission'] as Map)['shiftAttitudes'] as Map;
    expect(attitudes.values, contains('PREFER'));
    await finish(tester);
  }, skip: _server == null);
}
