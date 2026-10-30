import 'package:flutter/material.dart';
import '../core/home_router.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../models/user.dart';
import '../screens/worker/h03_notice_task_page.dart';
import '../screens/worker/h06_my_info_page.dart';
import '../screens/worker/h07_vacant_shift_board_page.dart';
import '../screens/worker/w07_my_schedule_page.dart';

/// 근로자 하단 탭 (가이드 4-0: 홈 · 근무표 · 대타·교대(직원은 연차·교대) · 공지·업무 · 내 정보)
enum WorkerTab { home, schedule, swap, notice, me }

class ThymeWorkerTabBar extends StatelessWidget {
  const ThymeWorkerTabBar({super.key, required this.current});

  final WorkerTab current;

  /// 지금 보고 있는 매장에서 직원(정규직)인지. 직원이면 홈이 H02, 세 번째 탭 이름이 '연차·교대'
  static bool get fullTime => Session.instance.currentMembership?.employmentType == EmploymentType.fullTime;

  static Widget pageFor(WorkerTab tab) => switch (tab) {
        WorkerTab.home => workerHome(),
        WorkerTab.schedule => const MySchedulePage(),
        WorkerTab.swap => const VacantShiftBoardPage(),
        WorkerTab.notice => const NoticeTaskPage(),
        WorkerTab.me => const MyInfoPage(),
      };

  /// 탭 화면으로 바꿔 끼운다 (쌓지 않음 → 탭 화면은 스택 맨 아래라 뒤로가기로 빈 화면이 되지 않는다)
  static void go(BuildContext context, WorkerTab tab) => Navigator.pushAndRemoveUntil(
        context,
        PageRouteBuilder(pageBuilder: (_, _, _) => rootPage(pageFor(tab)), transitionDuration: Duration.zero),
        (route) => false,
      );

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      backgroundColor: ThymeColor.surface,
      currentIndex: current.index,
      selectedItemColor: ThymeColor.text,
      unselectedItemColor: ThymeColor.disabled,
      showUnselectedLabels: true,
      selectedFontSize: 11,
      unselectedFontSize: 11,
      onTap: (i) {
        final tab = WorkerTab.values[i];
        // 탭 아래로 들어간 화면에서 같은 탭을 누르면 그 탭 첫 화면으로
        if (tab == current && !Navigator.canPop(context)) return;
        go(context, tab);
      },
      items: [
        const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "홈"),
        const BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "근무표"),
        BottomNavigationBarItem(icon: const Icon(Icons.sync_alt), label: fullTime ? "연차·교대" : "대타·교대"),
        const BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "공지·업무"),
        const BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "내 정보"),
      ],
    );
  }
}
