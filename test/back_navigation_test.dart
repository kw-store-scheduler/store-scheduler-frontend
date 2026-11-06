import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thyme_frontend/models/owner.dart';
import 'package:thyme_frontend/models/preference.dart';
import 'package:thyme_frontend/screens/common/a03_login_page.dart';
import 'package:thyme_frontend/screens/common/a05_terms_agreement_page.dart';
import 'package:thyme_frontend/screens/common/a06_role_selection_page.dart';
import 'package:thyme_frontend/screens/owner/m01_worker_approval_page.dart';
import 'package:thyme_frontend/screens/owner/m03_skill_matching_page.dart';
import 'package:thyme_frontend/screens/owner/m05_proposal_compare_page.dart';
import 'package:thyme_frontend/screens/owner/o01_store_registration_page.dart';
import 'package:thyme_frontend/screens/owner/o02_schedule_cycle_page.dart';
import 'package:thyme_frontend/screens/owner/o03_store_shift_setup_page.dart';
import 'package:thyme_frontend/screens/owner/o04_curation_page.dart';
import 'package:thyme_frontend/screens/owner/o05_labor_law_page.dart';
import 'package:thyme_frontend/screens/owner/o06_exception_days_page.dart';
import 'package:thyme_frontend/screens/owner/owner_attendance_page.dart';
import 'package:thyme_frontend/screens/owner/owner_day_off_page.dart';
import 'package:thyme_frontend/screens/owner/owner_notice_task_page.dart';
import 'package:thyme_frontend/screens/owner/owner_staffing_suggestion_page.dart';
import 'package:thyme_frontend/screens/owner/p03_generating_schedule_page.dart';
import 'package:thyme_frontend/screens/owner/p06_substitute_manage_page.dart';
import 'package:thyme_frontend/screens/owner/p07_worker_list_page.dart';
import 'package:thyme_frontend/screens/owner/p09_open_shift_post_page.dart';
import 'package:thyme_frontend/screens/owner/p11_worker_profile_confirm_page.dart';
import 'package:thyme_frontend/screens/worker/e01_employee_leave_page.dart';
import 'package:thyme_frontend/screens/worker/h04_notification_page.dart';
import 'package:thyme_frontend/screens/worker/h07_vacant_shift_board_page.dart';
import 'package:thyme_frontend/screens/worker/h12_absence_report_page.dart';
import 'package:thyme_frontend/screens/worker/h13_fill_vacancy_page.dart';
import 'package:thyme_frontend/screens/worker/j01_store_code_page.dart';
import 'package:thyme_frontend/screens/worker/j02_employment_type_page.dart';
import 'package:thyme_frontend/screens/worker/j03_join_profile_page.dart';
import 'package:thyme_frontend/screens/worker/w00_load_last_month_page.dart';
import 'package:thyme_frontend/screens/worker/w02_date_shift_page.dart';
import 'package:thyme_frontend/screens/worker/w03_rest_day_preference_page.dart';
import 'package:thyme_frontend/screens/worker/w04_shift_attitude_page.dart';
import 'package:thyme_frontend/screens/worker/w05_skills_page.dart';
import 'package:thyme_frontend/screens/worker/w06_work_hours_page.dart';
import 'package:thyme_frontend/screens/worker/w07_my_schedule_page.dart';
import 'package:thyme_frontend/screens/worker/w08_cover_accept_page.dart';
import 'package:thyme_frontend/screens/worker/w09_shift_swap_page.dart';
import 'package:thyme_frontend/screens/worker/w10_preference_report_page.dart';
import 'package:thyme_frontend/screens/worker/w11_fixed_schedule_page.dart';
import 'package:thyme_frontend/screens/worker/w14_preference_submit_page.dart';
import 'package:thyme_frontend/screens/worker/worker_attendance_page.dart';

import 'fixtures/preference_fixture.dart';
import 'test_helpers.dart';

PreferenceDraft _draft() {
  final month = DateTime(2026, 11);
  return PreferenceDraft(month: month)..view = samplePreferenceMonth(month);
}

Proposal _proposal() => Proposal.fromJson({
      'proposalId': 1,
      'success': true,
      'weekStart': '2026-12-01',
      'periodEnd': '2026-12-31',
      'solveMs': 2700,
      'candidates': [
        for (final i in [0, 1, 2])
          {
            'index': i,
            'label': '안 $i',
            'estimatedCost': 7208928,
            'metrics': {'preferenceRate': 98.8, 'weekendGap': 1, 'laborLawViolations': 0, 'minStaffCoverage': 100.0, 'warnings': []},
            'assignments': [],
          },
      ],
    });

/// 다른 화면에서 push 로 여는 화면 전부 (탭 첫 화면·완료 화면처럼 맨 아래에만 놓이는 화면은 navigation_test 에서)
final _pushed = <String, Widget Function()>{
  'A03 로그인': () => const LoginPage(),
  'A05 약관': () => const TermsAgreementPage(),
  'A06 역할 선택': () => const RoleSelectionPage(),
  'J01 매장 코드': () => const StoreCodePage(),
  'J02 고용 형태': () => const EmploymentTypePage(storeCode: 'ABCD1234', storeName: '테스트 카페'),
  'J03 가입 정보': () => const JoinProfilePage(fullTime: false, storeCode: 'ABCD1234', storeName: '테스트 카페'),
  'O01 매장 등록': () => const StoreRegistrationPage(),
  'O02 주기': () => const ScheduleCyclePage(),
  'O03 교대': () => const StoreShiftSetupPage(),
  'O06 평소와 다른 날': () => const ExceptionDaysPage(),
  'O04 큐레이션': () => const CurationPage(),
  'O05 노동법': () => const LaborLawPage(),
  'O02 주기 (P08 고치기)': () => const ScheduleCyclePage(editing: true),
  'O03 교대 (P08 고치기)': () => const StoreShiftSetupPage(editing: true),
  'O06 평소와 다른 날 (P08 고치기)': () => const ExceptionDaysPage(editing: true),
  'O04 큐레이션 (P08 고치기)': () => const CurationPage(editing: true),
  'O05 노동법 (P08 고치기)': () => const LaborLawPage(editing: true),
  'M01 승인할 것': () => const WorkerApprovalPage(),
  'M03 역량 매칭': () => const SkillMatchingPage(),
  'M05 후보안 비교': () => ProposalComparePage(proposal: _proposal()),
  'P03 근무표 만드는 중': () => const GeneratingSchedulePage(),
  'P06 대타 관리 (홈에서)': () => const SubstituteManagePage(),
  'P07 근무자 목록': () => const WorkerListPage(),
  'P09 빈 근무 게시판': () => const OpenShiftPostPage(),
  'P11 근무자 프로필': () => const WorkerProfileConfirmPage(employeeId: 1),
  '점주 출퇴근 기록': () => const OwnerAttendancePage(),
  '점주 휴무 신청': () => const OwnerDayOffPage(),
  '점주 공지·업무': () => const NoticeTaskManagePage(),
  '필요 인원 제안': () => const StaffingSuggestionPage(),
  'H04 알림': () => const NotificationPage(),
  'H07 대타 (홈에서)': () => const VacantShiftBoardPage(),
  'H12 결원 신고': () => const AbsenceReportPage(),
  'H13 빈자리 채우기': () => FillVacancyPage(
        request: SwapRequestInfo.fromJson({
          'id': 1, 'workDate': '2026-11-20', 'startTime': '09:00:00', 'endTime': '14:00:00',
          'requesterName': '유나', 'reasonCategory': 'PERSONAL', 'status': 'REQUESTED',
        }),
      ),
  'E01 직원 휴무': () => const EmployeeLeavePage(),
  'W00 지난달 불러오기': () => const LoadLastMonthPage(),
  'W11 고정 일정': () => const FixedSchedulePage(),
  'W11 고정 일정 (점주가 대신)': () => const FixedSchedulePage(employeeId: 3, employeeName: '유나'),
  'W02 날짜×교대': () => DateShiftPage(draft: _draft()),
  'W03 휴무': () => RestDayPreferencePage(draft: _draft()),
  'W06 근무량': () => WorkHoursPage(draft: _draft()),
  'W05 역량': () => SkillsPage(draft: _draft()),
  'W04 교대 태도': () => ShiftAttitudePage(draft: _draft()),
  'W14 제출': () => PreferenceSubmitPage(draft: _draft()),
  'W07 내 근무표 (홈에서)': () => const MySchedulePage(),
  'W08 대타 수락': () => const CoverAcceptPage(),
  'W09 근무 바꾸기': () => const ShiftSwapPage(),
  'W10 희망 반영 리포트': () => const PreferenceReportPage(),
  '근로자 근무 기록': () => const WorkerAttendancePage(),
};

/// 화면 안 뒤로가기가 없는 곳 (휴대폰·브라우저 뒤로가기는 된다)
/// - A03: A02 '시작하기'로 열리는데 시안에 없고, 안에서 로그인↔가입을 바꿀 수 있어 A02 로 돌아갈 일이 거의 없다
const _noBackButton = {'A03 로그인'};

const _backIcons = [Icons.arrow_back_ios, Icons.close, Icons.arrow_back];

/// 화면 위에 보이는(눌리는) 뒤로가기·닫기 버튼
Finder _backButton() => find.byWidgetPredicate((w) => w is Icon && _backIcons.contains(w.icon)).hitTestable();

class _Base extends StatelessWidget {
  const _Base(this.page);
  final Widget Function() page;

  @override
  Widget build(BuildContext context) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => page())),
            child: const Text('BASE'),
          ),
        ),
      );
}

void main() {
  setUpAll(loadTestFonts);

  late bool exited;
  setUp(() {
    exited = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'SystemNavigator.pop') exited = true;
      return null;
    });
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> open(WidgetTester tester, Widget Function() page) async {
    await pumpScreen(tester, _Base(page));
    await tester.tap(find.text('BASE'));
    await settle(tester);
    expect(find.text('BASE').hitTestable(), findsNothing, reason: '화면이 열려야 함');
  }

  Future<void> cleanUp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 10));
  }

  group('화면 안 뒤로가기 버튼 → 연 화면으로', () {
    for (final e in _pushed.entries) {
      testWidgets(e.key, skip: _noBackButton.contains(e.key), (tester) async {
        await open(tester, e.value);
        expect(_backButton(), findsWidgets, reason: '${e.key}: 왼쪽 위 뒤로가기(또는 닫기)가 보여야 함');
        await tester.tap(_backButton().first);
        await settle(tester);
        expect(find.text('BASE').hitTestable(), findsOneWidget, reason: '${e.key}: 뒤로가기를 누르면 연 화면으로 돌아가야 함');
        await cleanUp(tester);
      });
    }
  });

  group('휴대폰·브라우저 뒤로가기 → 연 화면으로', () {
    for (final e in _pushed.entries) {
      testWidgets(e.key, (tester) async {
        await open(tester, e.value);
        // ignore: invalid_use_of_protected_member
        await tester.binding.handlePopRoute();
        await settle(tester);
        expect(exited, isFalse, reason: '${e.key}: 앱을 나가면 웹에서 빈 화면');
        expect(find.text('BASE').hitTestable(), findsOneWidget, reason: '${e.key}: 연 화면으로 돌아가야 함');
        await cleanUp(tester);
      });
    }
  });
}
