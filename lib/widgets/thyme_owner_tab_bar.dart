import 'package:flutter/material.dart';
import '../core/home_router.dart';
import '../core/theme.dart';
import '../screens/owner/p01_owner_home_page.dart';
import '../screens/owner/p06_substitute_manage_page.dart';
import '../screens/owner/p08_store_settings_page.dart';

/// 점주 하단 탭 (가이드 4-0: 홈 · 근무표 · 대타 · 인건비 · 매장)
enum OwnerTab { home, schedule, substitute, laborCost, store }

class ThymeOwnerTabBar extends StatelessWidget {
  const ThymeOwnerTabBar({super.key, required this.current});

  final OwnerTab current;

  /// 화면이 있는 탭만 이동한다. 근무표·인건비(M02, 범위 밖) 화면은 아직 없다
  static Widget? _pageFor(OwnerTab tab) => switch (tab) {
        OwnerTab.home => const OwnerHomePage(),
        OwnerTab.substitute => const SubstituteManagePage(),
        OwnerTab.store => const StoreSettingsPage(),
        OwnerTab.schedule || OwnerTab.laborCost => null,
      };

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
        final page = _pageFor(tab);
        if (tab == current || page == null) return;
        // 탭 전환은 쌓지 않고 바꿔 끼운다 (탭 화면은 스택 맨 아래 → 뒤로가기로 빈 화면이 되지 않게)
        Navigator.pushAndRemoveUntil(
          context,
          PageRouteBuilder(pageBuilder: (_, _, _) => rootPage(page), transitionDuration: Duration.zero),
          (route) => false,
        );
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
