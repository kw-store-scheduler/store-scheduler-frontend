import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/api_service.dart';
import 'core/push_service.dart';
import 'core/session.dart';
import 'screens/common/a01_splash_page.dart';
import 'screens/common/a03_login_page.dart';
import 'theme/thyme_theme.dart';

/// 어느 화면에서든 로그인 화면으로 보낼 때 (토큰 만료)
final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  // 플러터 엔진 초기화 보장
  WidgetsFlutterBinding.ensureInitialized();
  await PushService.init();

  // 토큰이 만료돼 401이 오면 저장된 로그인을 지우고 로그인 화면으로 (여러 요청이 한꺼번에 실패해도 한 번만)
  var handling = false;
  ApiService().onUnauthorized = () async {
    if (handling) return;
    handling = true;
    await Session.instance.logout();
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage(notice: "로그인이 만료됐어요. 다시 로그인해 주세요.")),
      (route) => false,
    );
    handling = false;
  };

  runApp(const ThymeApp());
}

class ThymeApp extends StatelessWidget {
  const ThymeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thyme',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      // 달력·시간 선택·복사 메뉴 등 기본 위젯을 한국어로
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThymeTheme.light(),
      // 화면들이 아직 라이트 상수(ThymeColor)를 쓰고 있어서 다크모드는 토큰 전환 뒤에 켠다
      // darkTheme: ThymeTheme.dark(),
      // A01 스플래시: 저장된 로그인이 있으면 바로 첫 화면, 없으면 A02 → A03
      home: const SplashPage(),
    );
  }
}
