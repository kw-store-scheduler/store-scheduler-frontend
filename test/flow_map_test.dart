import 'package:flutter_test/flutter_test.dart';
import 'package:thyme_frontend/screens/common/a06_role_selection_page.dart';
import 'package:thyme_frontend/screens/owner/o02_schedule_cycle_page.dart';
import 'package:thyme_frontend/screens/owner/o03_store_shift_setup_page.dart';
import 'package:thyme_frontend/screens/owner/o04_curation_page.dart';
import 'package:thyme_frontend/screens/owner/o05_labor_law_page.dart';
import 'package:thyme_frontend/screens/owner/o06_exception_days_page.dart';
import 'package:thyme_frontend/screens/owner/p01_owner_home_page.dart';
import 'package:thyme_frontend/screens/owner/p02_registration_complete_page.dart';
import 'package:thyme_frontend/screens/worker/e01_employee_leave_page.dart';
import 'package:thyme_frontend/screens/worker/h02_employee_home_page.dart';
import 'package:thyme_frontend/screens/worker/j02_employment_type_page.dart';
import 'package:thyme_frontend/screens/worker/j03_join_profile_page.dart';
import 'package:thyme_frontend/screens/worker/j04_approval_waiting_page.dart';
import 'package:thyme_frontend/screens/worker/w00_load_last_month_page.dart';
import 'package:thyme_frontend/screens/worker/w04_shift_attitude_page.dart';
import 'package:thyme_frontend/screens/worker/w14_preference_submit_page.dart';

import 'test_helpers.dart';

/// 디자인 레포 screens-all.md 플로우맵(00_flow-map.png)의 줄을 실제로 눌러서 따라간다
void main() {
  setUpAll(loadTestFonts);

  Future<void> tap(WidgetTester tester, String label) async {
    final target = find.text(label).last;
    await tester.ensureVisible(target);
    await tester.tap(target);
    // 시연 모드 초안 만들기처럼 비동기가 끼는 버튼도 있다
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pumpAndSettle();
  }

  testWidgets('O 점주 매장 등록: A06 → O01 → O02 → O03 → O06 → O04 → O05 → P02 → P01', (tester) async {
    await pumpScreen(tester, const RoleSelectionPage());
    await tap(tester, '점주 · 매니저');
    await tap(tester, '매장 등록하기'); // A06 → O01
    await tap(tester, '다음');
    expect(find.byType(ScheduleCyclePage), findsOneWidget); // O02 (예전엔 건너뜀)
    await tap(tester, '다음');
    expect(find.byType(StoreShiftSetupPage), findsOneWidget); // O03
    await tap(tester, '다음 · 예외일');
    expect(find.byType(ExceptionDaysPage), findsOneWidget); // O06 (예전엔 근로자 W07로 감)
    await tap(tester, '다음 · 필요한 역량');
    expect(find.byType(CurationPage), findsOneWidget); // O04
    await tap(tester, '다음');
    expect(find.byType(LaborLawPage), findsOneWidget); // O05
    await tap(tester, '매장 등록 완료');
    expect(find.byType(RegistrationCompletePage), findsOneWidget); // P02
    await tap(tester, '매장 홈으로');
    expect(find.byType(OwnerHomePage), findsOneWidget); // P01
  });

  testWidgets('J 근로자 가입: J02 직원 → J03 → J04 → 승인 → E01', (tester) async {
    await pumpScreen(tester, const EmploymentTypePage());
    await tester.tap(find.text('직원').first); // 위쪽 카드 (아래 비교표에도 '직원'이 있다)
    await tester.pump();
    await tap(tester, '직원으로 계속');
    expect(find.byType(JoinProfilePage), findsOneWidget);
    await tap(tester, '가입 요청 보내기');
    expect(find.byType(ApprovalWaitingPage), findsOneWidget); // 예전엔 W07 근무표로 감
    expect(find.text('직원 (월급제)'), findsOneWidget); // J02에서 고른 형태가 이어진다
    await tap(tester, '승인된 화면 보기');
    await tap(tester, '첫 근무 희망 내기');
    expect(find.byType(EmployeeLeavePage), findsOneWidget); // 직원 → E01
  });

  testWidgets('J04 알바는 승인 뒤 W00으로', (tester) async {
    await pumpScreen(tester, const ApprovalWaitingPage());
    await tap(tester, '승인된 화면 보기');
    await tap(tester, '첫 근무 희망 내기');
    expect(find.byType(LoadLastMonthPage), findsOneWidget);
  });

  testWidgets('W 직원 3단계: E01 → W04 → W14 → H02 직원 홈', (tester) async {
    await pumpScreen(tester, EmployeeLeavePage(month: DateTime(2026, 11)));
    await tap(tester, '다음 · 교대 선호');
    expect(find.byType(ShiftAttitudePage), findsOneWidget);
    expect(find.textContaining('2 / 3', findRichText: true), findsOneWidget);
    await tap(tester, '다음 · 우선순위');
    expect(find.byType(PreferenceSubmitPage), findsOneWidget);
    expect(find.textContaining('3 / 3', findRichText: true), findsOneWidget); // 직원은 3단계의 마지막
    await tap(tester, '신청 제출');
    expect(find.byType(EmployeeHomePage), findsOneWidget);
  });
}
