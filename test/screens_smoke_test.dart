import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thyme_frontend/models/preference.dart';
import 'package:thyme_frontend/screens/common/a03_login_page.dart';
import 'package:thyme_frontend/screens/common/a04_phone_verification_page.dart';
import 'package:thyme_frontend/screens/common/a06_role_selection_page.dart';
import 'package:thyme_frontend/screens/common/a02_service_intro_page.dart';
import 'package:thyme_frontend/screens/common/a01_splash_page.dart';
import 'package:thyme_frontend/screens/common/a05_terms_agreement_page.dart';
import 'package:thyme_frontend/screens/owner/o04_curation_page.dart';
import 'package:thyme_frontend/screens/owner/p06_substitute_manage_page.dart';
import 'package:thyme_frontend/screens/owner/p03_generating_schedule_page.dart';
import 'package:thyme_frontend/screens/owner/o05_labor_law_page.dart';
import 'package:thyme_frontend/screens/owner/p01_owner_home_page.dart';
import 'package:thyme_frontend/screens/owner/m05_proposal_compare_page.dart';
import 'package:thyme_frontend/screens/owner/m02_labor_cost_page.dart';
import 'package:thyme_frontend/screens/owner/owner_notice_task_page.dart';
import 'package:thyme_frontend/screens/owner/owner_attendance_page.dart';
import 'package:thyme_frontend/screens/owner/owner_staffing_suggestion_page.dart';
import 'package:thyme_frontend/screens/worker/worker_attendance_page.dart';
import 'package:thyme_frontend/screens/owner/owner_schedule_page.dart';
import 'package:thyme_frontend/models/owner.dart';
import 'package:thyme_frontend/screens/owner/p02_registration_complete_page.dart';
import 'package:thyme_frontend/screens/owner/o02_schedule_cycle_page.dart';
import 'package:thyme_frontend/screens/owner/p04_share_complete_page.dart';
import 'package:thyme_frontend/screens/owner/o01_store_registration_page.dart';
import 'package:thyme_frontend/screens/owner/o03_store_shift_setup_page.dart';
import 'package:thyme_frontend/screens/owner/m01_worker_approval_page.dart';
import 'package:thyme_frontend/screens/owner/p07_worker_list_page.dart';
import 'package:thyme_frontend/screens/owner/p11_worker_profile_confirm_page.dart';
import 'package:thyme_frontend/screens/worker/h12_absence_report_page.dart';
import 'package:thyme_frontend/screens/worker/j04_approval_waiting_page.dart';
import 'package:thyme_frontend/screens/worker/w08_cover_accept_page.dart';
import 'package:thyme_frontend/screens/worker/e01_employee_leave_page.dart';
import 'package:thyme_frontend/screens/worker/j02_employment_type_page.dart';
import 'package:thyme_frontend/screens/worker/w11_fixed_schedule_page.dart';
import 'package:thyme_frontend/screens/worker/w00_load_last_month_page.dart';
import 'package:thyme_frontend/screens/worker/h06_my_info_page.dart';
import 'package:thyme_frontend/screens/worker/w07_my_schedule_page.dart';
import 'package:thyme_frontend/screens/worker/h03_notice_task_page.dart';
import 'package:thyme_frontend/screens/worker/h04_notification_page.dart';
import 'package:thyme_frontend/screens/worker/w10_preference_report_page.dart';
import 'package:thyme_frontend/screens/worker/w14_preference_submit_page.dart';
import 'package:thyme_frontend/screens/worker/h13_fill_vacancy_page.dart';
import 'package:thyme_frontend/screens/worker/w03_rest_day_preference_page.dart';
import 'package:thyme_frontend/screens/worker/w02_date_shift_page.dart';
import 'package:thyme_frontend/screens/worker/w09_shift_swap_page.dart';
import 'package:thyme_frontend/screens/worker/w05_skills_page.dart';
import 'package:thyme_frontend/screens/worker/j01_store_code_page.dart';
import 'package:thyme_frontend/screens/worker/h07_vacant_shift_board_page.dart';
import 'package:thyme_frontend/screens/worker/w06_work_hours_page.dart';
import 'package:thyme_frontend/screens/worker/h01_part_timer_home_page.dart';
import 'package:thyme_frontend/screens/worker/j03_join_profile_page.dart';

import 'package:thyme_frontend/screens/owner/m03_skill_matching_page.dart';
import 'package:thyme_frontend/screens/owner/o06_exception_days_page.dart';
import 'package:thyme_frontend/screens/owner/p08_store_settings_page.dart';
import 'package:thyme_frontend/screens/owner/p09_open_shift_post_page.dart';
import 'package:thyme_frontend/screens/worker/h02_employee_home_page.dart';
import 'package:thyme_frontend/screens/worker/w04_shift_attitude_page.dart';

import 'fixtures/preference_fixture.dart';
import 'test_helpers.dart';

/// 희망 신청 단계 화면용 시연 초안
PreferenceDraft _draft() {
  final month = DateTime(2026, 11);
  return PreferenceDraft(month: month)..view = samplePreferenceMonth(month);
}

/// 모든 화면이 예외(레이아웃 오버플로 포함) 없이 그려지는지 확인하는 스모크 테스트
/// M05·P04 화면용 후보안 (서버 응답과 같은 모양)
Proposal _proposal() => Proposal.fromJson({
      'proposalId': 1,
      'success': true,
      'weekStart': '2026-12-01',
      'periodEnd': '2026-12-31',
      'solveMs': 2700,
      'candidates': [
        for (final (i, label) in [(0, '공정 우선'), (1, '인건비 우선'), (2, '희망 우선')])
          {
            'index': i,
            'label': label,
            'estimatedCost': 7208928 - i * 100000,
            'metrics': {'preferenceRate': 98.8, 'weekendGap': 1 + i, 'laborLawViolations': 0, 'minStaffCoverage': 100.0, 'warnings': []},
            'assignments': [],
          },
      ],
    });

void main() {
  setUpAll(loadTestFonts);

  final pages = <String, Widget Function()>{
    'LoginPage': () => const LoginPage(),
    'PhoneVerificationPage': () => const PhoneVerificationPage(),
    'RoleSelectionPage': () => const RoleSelectionPage(),
    'ServiceIntroPage': () => const ServiceIntroPage(),
    'SplashPage': () => const SplashPage(),
    'TermsAgreementPage': () => const TermsAgreementPage(),
    'CurationPage': () => const CurationPage(),
    'SubstituteManagePage': () => const SubstituteManagePage(),
    'GeneratingSchedulePage': () => const GeneratingSchedulePage(),
    'LaborLawPage': () => const LaborLawPage(),
    'OwnerHomePage': () => const OwnerHomePage(),
    'ProposalComparePage': () => ProposalComparePage(proposal: _proposal()),
    'RegistrationCompletePage': () => const RegistrationCompletePage(),
    'ScheduleCyclePage': () => const ScheduleCyclePage(),
    'ShareCompletePage': () => ShareCompletePage(proposalId: 1, letter: 'A', period: '12월', candidate: _proposal().candidates.first),
    'StoreRegistrationPage': () => const StoreRegistrationPage(),
    'StoreShiftSetupPage': () => const StoreShiftSetupPage(),
    'WorkerApprovalPage': () => const WorkerApprovalPage(),
    'WorkerListPage': () => const WorkerListPage(),
    'WorkerProfileConfirmPage': () => const WorkerProfileConfirmPage(employeeId: 1),
    'LaborCostPage': () => const LaborCostPage(),
    'NoticeTaskManagePage': () => const NoticeTaskManagePage(),
    'OwnerAttendancePage': () => const OwnerAttendancePage(),
    'StaffingSuggestionPage': () => const StaffingSuggestionPage(),
    'WorkerAttendancePage': () => const WorkerAttendancePage(),
    'OwnerSchedulePage': () => const OwnerSchedulePage(),
    'AbsenceReportPage': () => const AbsenceReportPage(),
    'ApprovalWaitingPage': () => const ApprovalWaitingPage(fullTime: false, name: '유나', storeName: '테스트 카페'),
    'CoverAcceptPage': () => const CoverAcceptPage(),
    'EmployeeLeavePage': () => const EmployeeLeavePage(),
    'EmploymentTypePage': () => const EmploymentTypePage(storeCode: 'ABCD1234', storeName: '테스트 카페'),
    'FixedSchedulePage': () => const FixedSchedulePage(),
    'LoadLastMonthPage': () => const LoadLastMonthPage(),
    'MyInfoPage': () => const MyInfoPage(),
    'MySchedulePage': () => const MySchedulePage(),
    'NoticeTaskPage': () => const NoticeTaskPage(),
    'NotificationPage': () => const NotificationPage(),
    'PreferenceReportPage': () => const PreferenceReportPage(),
    'PreferenceSubmitPage': () => PreferenceSubmitPage(draft: _draft()),
    'FillVacancyPage': () => FillVacancyPage(
          request: SwapRequestInfo.fromJson({
            'id': 1, 'workDate': '2026-11-20', 'startTime': '09:00:00', 'endTime': '14:00:00',
            'requesterName': '유나', 'reasonCategory': 'PERSONAL', 'status': 'REQUESTED',
          }),
        ),
    'RestDayPreferencePage': () => RestDayPreferencePage(draft: _draft()),
    'DateShiftPage': () => DateShiftPage(draft: _draft()),
    'ShiftSwapPage': () => const ShiftSwapPage(),
    'SkillsPage': () => SkillsPage(draft: _draft()),
    'StoreCodePage': () => const StoreCodePage(),
    'VacantShiftBoardPage': () => const VacantShiftBoardPage(),
    'WorkHoursPage': () => WorkHoursPage(draft: _draft()),
    'PartTimerHomePage': () => const PartTimerHomePage(),
    'JoinProfilePage': () => const JoinProfilePage(fullTime: false, storeCode: 'ABCD1234', storeName: '테스트 카페'),
    // 플로우맵에서 빠져 있던 화면 (2026-10-26 추가)
    'ShiftAttitudePage': () => ShiftAttitudePage(draft: _draft()),
    'EmployeeHomePage': () => const EmployeeHomePage(),
    'ExceptionDaysPage': () => const ExceptionDaysPage(),
    'SkillMatchingPage': () => const SkillMatchingPage(),
    'OpenShiftPostPage': () => const OpenShiftPostPage(),
    'StoreSettingsPage': () => const StoreSettingsPage(),
  };

  for (final entry in pages.entries) {
    testWidgets(entry.key, (tester) async {
      await pumpScreen(tester, entry.value());
      // 레이아웃 오류가 나면 프레임워크가 위치와 함께 테스트를 실패시킨다
      await tester.pump(const Duration(milliseconds: 100));

      // 스플래시처럼 자동으로 넘어가는 화면의 타이머를 정리
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 10));
    });
  }
}
