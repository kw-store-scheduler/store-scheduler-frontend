import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/home_router.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../models/user.dart';
import 'a02_service_intro_page.dart'; // 다음 화면

/// A01 스플래시. 저장된 로그인이 있으면 /me 로 확인해서 첫 화면으로, 없으면 A02 서비스 소개로
/// (새로고침해도 로그인이 풀리지 않게 하는 곳)
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() => _error = null);
    try {
      // 로고를 잠깐은 보여 준다 (서버 확인과 동시에)
      // (Future.wait 로 묶어야 서버 확인이 먼저 실패해도 놓치지 않는다)
      final results = await Future.wait<Object?>([
        Session.instance.restore(),
        Future<void>.delayed(const Duration(milliseconds: 1200)),
      ]);
      final me = results.first as Me?;
      if (!mounted) return;
      if (me != null) {
        goHome(context, me);
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => rootPage(const ServiceIntroPage())));
      }
    } on ApiException catch (e) {
      // 서버에 닿지 못함 (잠든 무료 서버, 오프라인). 저장된 로그인은 그대로 두고 다시 시도하게 한다
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _toLogin() async {
    await Session.instance.logout();
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => rootPage(const ServiceIntroPage())));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.primary,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "thyme.",
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: ThymeColor.surface, letterSpacing: -1.5),
              ),
              if (_error != null) ...[
                const SizedBox(height: 32),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    "$_error\n서버를 깨우는 중이면 30초~1분 걸릴 수 있어요.",
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 14, color: ThymeColor.onPrimarySub, height: 1.5),
                  ),
                ),
                const SizedBox(height: 20),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: ThymeColor.accent, foregroundColor: ThymeColor.onAccent),
                  onPressed: _start,
                  child: const Text("다시 시도"),
                ),
                TextButton(
                  onPressed: _toLogin,
                  child: const Text("다른 계정으로 로그인", style: TextStyle(color: ThymeColor.onPrimarySub)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
