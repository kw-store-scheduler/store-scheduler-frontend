import 'package:flutter/material.dart';
import '../models/user.dart';
import 'session.dart';
import '../screens/common/a06_role_selection_page.dart';
import '../screens/owner/o01_store_registration_page.dart';
import '../screens/owner/p01_owner_home_page.dart';
import '../screens/worker/h01_part_timer_home_page.dart';
import '../screens/worker/h02_employee_home_page.dart';
import '../screens/worker/j04_approval_waiting_page.dart';

/// 로그인하거나 앱을 다시 켰을 때 GET /api/users/me 를 보고 첫 화면을 고른다 (백엔드 README 10. 인증 · 권한)
///
/// - 매장도 합류 신청도 없으면 아직 역할을 고르지 않은 계정 → A06
/// - 점주 → 매장이 있으면 P01 홈, 없으면 O01 매장 등록
/// - 근로자 → 승인된 매장이 있으면 직원 H02 / 알바 H01 홈, 승인 대기면 J04
Widget homeFor(Me me) {
  if (me.ownedStores.isEmpty && me.memberships.isEmpty) return const RoleSelectionPage();
  switch (me.role) {
    case Role.manager:
      return me.ownedStores.isEmpty ? const StoreRegistrationPage() : const OwnerHomePage();
    case Role.employee:
      final approved = me.memberships.where((m) => m.isApproved).firstOrNull;
      if (approved != null) {
        return approved.employmentType == EmploymentType.fullTime ? const EmployeeHomePage() : const PartTimerHomePage();
      }
      final pending = me.memberships.last;
      return ApprovalWaitingPage(
        fullTime: pending.employmentType == EmploymentType.fullTime,
        name: pending.displayName ?? me.username,
        storeName: pending.storeName,
      );
    case null:
      return const RoleSelectionPage();
  }
}

/// 근로자 홈: 지금 보고 있는 매장에서 직원이면 H02, 알바면 H01
Widget workerHome() => Session.instance.currentMembership?.employmentType == EmploymentType.fullTime
    ? const EmployeeHomePage()
    : const PartTimerHomePage();

/// 첫 화면으로 바꿔 끼운다 (그 아래 화면은 모두 지운다)
void goHome(BuildContext context, Me me) => resetTo(context, homeFor(me));

/// [page]를 유일한 화면으로 띄운다 (로그인 직후·홈·로그아웃 등).
/// 아래에 화면이 없으니 휴대폰·브라우저 뒤로가기가 이 화면을 꺼내 빈 화면이 되지 않게 막는다.
void resetTo(BuildContext context, Widget page) => Navigator.of(context)
    .pushAndRemoveUntil(MaterialPageRoute(builder: (_) => rootPage(page)), (route) => false);

/// 스택 맨 아래 화면용 감싸기 (스플래시에서 바꿔 끼울 때, 탭 전환 등 [resetTo]를 못 쓰는 곳)
Widget rootPage(Widget page) => PopScope(canPop: false, child: page);
