import 'package:flutter/material.dart';
import 'core/push_service.dart';
import 'screens/common/a03_login_page.dart';
import 'theme/thyme_theme.dart';

Future<void> main() async {
  // 플러터 엔진 초기화 보장
  WidgetsFlutterBinding.ensureInitialized();
  await PushService.init();

  runApp(const ThymeApp());
}

class ThymeApp extends StatelessWidget {
  const ThymeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thyme',
      debugShowCheckedModeBanner: false,
      theme: ThymeTheme.light(),
      // 화면들이 아직 라이트 상수(ThymeColor)를 쓰고 있어서 다크모드는 토큰 전환 뒤에 켠다
      // darkTheme: ThymeTheme.dark(),
      // 앱의 첫 문을 여는 화면
      home: const LoginPage(),
    );
  }
}
