import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thyme_frontend/core/home_router.dart';
import 'package:thyme_frontend/screens/owner/p01_owner_home_page.dart';
import 'package:thyme_frontend/screens/worker/h01_part_timer_home_page.dart';
import 'package:thyme_frontend/screens/worker/h07_vacant_shift_board_page.dart';
import 'package:thyme_frontend/screens/worker/w09_shift_swap_page.dart';
import 'package:thyme_frontend/widgets/thyme_owner_tab_bar.dart';
import 'package:thyme_frontend/widgets/thyme_worker_tab_bar.dart';

import 'test_helpers.dart';

/// 하단 탭을 누르고 휴대폰·브라우저 뒤로가기를 눌러도 빈 화면이 되지 않는지 확인한다.
///
/// 뒤로가기는 앱이 처리하지 못하면 SystemNavigator.pop 을 부르고, 웹에서는 브라우저가 앱 밖(빈 화면)으로 나간다.
/// 그래서 '뒤로가기 → SystemNavigator.pop 이 불리지 않고 탭 화면이 그대로 남아 있음'을 본다.
/// (로그인하지 않은 상태라 화면들은 '매장 정보가 없어요' 오류를 띄우지만 이동 자체는 같다)
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
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> tapTab(WidgetTester tester, String label) async {
    await tester.tap(find.descendant(of: find.byType(BottomNavigationBar), matching: find.text(label)));
    await settle(tester);
  }

  Future<void> systemBack(WidgetTester tester) async {
    // ignore: invalid_use_of_protected_member
    await tester.binding.handlePopRoute();
    await settle(tester);
  }

  int currentIndex(WidgetTester tester) => tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar)).currentIndex;

  testWidgets('점주 탭: 탭마다 뒤로가기를 눌러도 앱을 나가지 않고 그 탭에 남는다', (tester) async {
    await pumpScreen(tester, rootPage(const OwnerHomePage()));
    await settle(tester);
    for (final (label, tab) in [
      ("근무표", OwnerTab.schedule),
      ("대타", OwnerTab.substitute),
      ("인건비", OwnerTab.laborCost),
      ("매장", OwnerTab.store),
      ("홈", OwnerTab.home),
    ]) {
      await tapTab(tester, label);
      expect(currentIndex(tester), tab.index, reason: "$label 탭으로 바뀌어야 함");
      await systemBack(tester);
      expect(exited, isFalse, reason: "$label 탭에서 뒤로가기가 앱을 나가면 웹에서 빈 화면이 됨");
      expect(find.byType(ThymeOwnerTabBar), findsOneWidget, reason: "$label 탭에서 뒤로가기 후에도 화면이 남아 있어야 함");
      expect(currentIndex(tester), tab.index);
      // 맨 아래 화면이라 화면 안 뒤로가기 버튼도 없어야 한다 (눌러서 빈 화면이 되지 않게)
      expect(find.byIcon(Icons.arrow_back_ios), findsNothing, reason: "$label 탭 첫 화면에 뒤로가기 버튼이 보이면 안 됨");
    }
  });

  testWidgets('근로자 탭: 다섯 탭 모두 눌리고, 뒤로가기를 눌러도 앱을 나가지 않는다', (tester) async {
    await pumpScreen(tester, rootPage(const PartTimerHomePage()));
    await settle(tester);
    for (final (label, tab) in [
      ("근무표", WorkerTab.schedule),
      ("대타·교대", WorkerTab.swap),
      ("공지·업무", WorkerTab.notice),
      ("내 정보", WorkerTab.me),
      ("홈", WorkerTab.home),
    ]) {
      await tapTab(tester, label);
      expect(currentIndex(tester), tab.index, reason: "$label 탭으로 바뀌어야 함");
      await systemBack(tester);
      expect(exited, isFalse, reason: "$label 탭에서 뒤로가기가 앱을 나가면 웹에서 빈 화면이 됨");
      expect(find.byType(ThymeWorkerTabBar), findsOneWidget);
      expect(currentIndex(tester), tab.index);
    }
  });

  testWidgets('대타·교대 탭 → 근무 바꾸기 → 뒤로가기 = 대타·교대 탭으로 돌아온다', (tester) async {
    await pumpScreen(tester, rootPage(const PartTimerHomePage()));
    await settle(tester);
    await tapTab(tester, "대타·교대");
    expect(find.byType(VacantShiftBoardPage), findsOneWidget);

    await tester.tap(find.text("근무 바꾸기"));
    await settle(tester);
    expect(find.byType(ShiftSwapPage), findsOneWidget);

    // 화면 안 뒤로가기 버튼
    await tester.tap(find.byIcon(Icons.arrow_back_ios));
    await settle(tester);
    expect(find.byType(ShiftSwapPage), findsNothing);
    expect(find.byType(VacantShiftBoardPage), findsOneWidget);

    // 휴대폰·브라우저 뒤로가기
    await tester.tap(find.text("근무 바꾸기"));
    await settle(tester);
    await systemBack(tester);
    expect(find.byType(VacantShiftBoardPage), findsOneWidget);
    expect(exited, isFalse);
  });
}
