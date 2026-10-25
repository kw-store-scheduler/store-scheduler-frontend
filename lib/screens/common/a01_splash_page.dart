import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'a02_service_intro_page.dart'; // 다음 화면

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    // 2초 동안 스플래시를 보여준 뒤 서비스 소개 화면으로 자동 이동
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ServiceIntroPage()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: ThymeColor.primary,
      body: Center(
        child: Text(
          "thyme.",
          style: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w900,
            color: ThymeColor.surface,
            letterSpacing: -1.5,
          ),
        ),
      ),
    );
  }
}