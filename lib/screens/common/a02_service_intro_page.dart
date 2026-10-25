import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../theme/thyme_colors.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_leaf.dart';
import '../../widgets/thyme_logo.dart';
import 'a03_login_page.dart';

/// A02 서비스 소개. 핵심 가치 3가지 → 시작하기(회원가입) / 이미 계정이 있어요(로그인)
class ServiceIntroPage extends StatelessWidget {
  const ServiceIntroPage({super.key});

  void _toLogin(BuildContext context, {required bool signup}) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => LoginPage(startInSignup: signup)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: Column(
        children: [
          // 딥 나이트 띠: 잎 하나 = 근무 한 칸, 점선 잎 = 결원 (가이드 4-5)
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, MediaQuery.paddingOf(context).top + 32, 24, 28),
            decoration: const BoxDecoration(
              color: ThymeColor.primary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ThymeLogo(size: 28),
                const SizedBox(height: 32),
                SizedBox(
                  height: 110,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(height: 4, decoration: BoxDecoration(color: ThymeColor.accent, borderRadius: BorderRadius.circular(2))),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _VineLeaf(up: true),
                          _VineLeaf(up: false, light: true),
                          _VineLeaf(up: true, empty: true),
                          _VineLeaf(up: false),
                          _VineLeaf(up: true, light: true),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                const Text("잎 하나가 근무 한 칸이에요. 빈 잎은 결원.", style: TextStyle(fontSize: 13, color: ThymeColor.onPrimarySub)),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "모두가 납득하는\n근무표를 자동으로",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ThymeColor.text, height: 1.3),
                  ),
                  const SizedBox(height: 24),
                  _buildValue(context, "01", "희망은 1분이면 제출", "지난달 답이 미리 채워져요"),
                  _buildValue(context, "02", "주말·마감은 공평하게", "왜 그렇게 배정됐는지도 보여줘요"),
                  _buildValue(context, "03", "결원은 알아서 채우기", "가능한 동료에게 바로 대타를 요청해요"),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(onPressed: () => _toLogin(context, signup: true), child: const Text("시작하기")),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => _toLogin(context, signup: false),
                    child: const Text("이미 계정이 있어요",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text, decoration: TextDecoration.underline)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildValue(BuildContext context, String no, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 44, child: Text(no, style: ThymeTheme.mono(context, size: 15, color: ThymeColor.successText))),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                const SizedBox(height: 4),
                Text(desc, style: const TextStyle(fontSize: 15, color: ThymeColor.textSub)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 줄기 위아래로 번갈아 붙는 잎
class _VineLeaf extends StatelessWidget {
  const _VineLeaf({required this.up, this.light = false, this.empty = false});

  final bool up;
  final bool light; // 연민트 = 교대 리듬
  final bool empty; // 로즈 점선 잎 = 결원

  @override
  Widget build(BuildContext context) {
    final leaf = empty
        ? const ThymeLeaf(size: 46, dashed: true, color: ThymeColor.danger)
        : ThymeLeaf(size: 46, color: light ? ThymePalette.mint300 : ThymeColor.accent);
    return Transform.translate(offset: Offset(0, up ? -24 : 24), child: Transform.flip(flipY: !up, child: leaf));
  }
}
