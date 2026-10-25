import 'package:flutter/material.dart';
import '../core/home_router.dart';
import '../core/theme.dart';
import '../screens/owner/m02_labor_cost_page.dart';
import '../screens/owner/owner_schedule_page.dart';
import '../screens/owner/p01_owner_home_page.dart';
import '../screens/owner/p06_substitute_manage_page.dart';
import '../screens/owner/p08_store_settings_page.dart';

/// 점주 하단 탭 (가이드 4-0: 홈 · 근무표 · 대타 · 인건비 · 매장)
enum OwnerTab { home, schedule, substitute, laborCost, store }

class ThymeOwnerTabBar extends StatelessWidget {
  const ThymeOwnerTabBar({super.key, required this.current});

  final OwnerTab current;

  static Widget pageFor(OwnerTab tab) => switch (tab) {
        OwnerTab.home => const OwnerHomePage(),
        OwnerTab.schedule => const OwnerSchedulePage(),
        OwnerTab.substitute => const SubstituteManagePage(),
        OwnerTab.laborCost => const LaborCostPage(),
        OwnerTab.store => const StoreSettingsPage(),
      };

  /// 탭 화면으로 바꿔 끼운다 (쌓지 않음 → 탭 화면은 스택 맨 아래라 뒤로가기로 빈 화면이 되지 않는다)
  static void go(BuildContext context, OwnerTab tab) => Navigator.pushAndRemoveUntil(
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
        final tab = OwnerTab.values[i];
        // 탭 아래로 들어간 화면(P11 등)에서 같은 탭을 누르면 그 탭 첫 화면으로
        if (tab == current && !Navigator.canPop(context)) return;
        go(context, tab);
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "홈"),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "근무표"),
        BottomNavigationBarItem(icon: Icon(Icons.sync_alt), label: "대타"),
        BottomNavigationBarItem(icon: Icon(Icons.payments_outlined), label: "인건비"),
        BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), label: "매장"),
      ],
    );
  }
}
