import 'package:flutter/material.dart';
import '../theme/thyme_colors.dart';

/// [임시] 라이트 모드 역할 토큰의 const 별칭.
///
/// 기존 화면들이 `const` 위젯 안에서 색을 쓰고 있어서 우선 라이트 값을 상수로 둔다.
/// 값은 모두 디자인 가이드(color-design-guide.md)의 ThymeTokens.light와 같다.
/// 다크모드를 붙일 때 `ThymeColor.x` → `context.tokens.x`로 옮기고 이 클래스는 지운다.
class ThymeColor {
  ThymeColor._();

  // 역할 토큰 (ThymeTokens.light와 같은 이름·값)
  static const Color bg = ThymePalette.night100;
  static const Color surface = ThymePalette.white;
  static const Color surfaceSub = ThymePalette.lavenderMist;
  static const Color border = ThymePalette.night200;
  static const Color text = ThymePalette.night900;
  static const Color textSub = ThymePalette.night500;
  static const Color primary = ThymePalette.night900;
  static const Color onPrimary = ThymePalette.white;
  static const Color accent = ThymePalette.mint400;
  static const Color onAccent = ThymePalette.night900;
  static const Color selectedSoft = ThymePalette.lavenderTint;
  static const Color successBg = ThymePalette.mint100;
  static const Color successText = ThymePalette.mint800;
  static const Color danger = ThymePalette.rose500;
  static const Color dangerBg = ThymePalette.rose50;
  static const Color dangerText = ThymePalette.rose700;
  static const Color info = ThymePalette.peri600;
  static const Color infoBg = ThymePalette.peri50;
  static const Color infoText = ThymePalette.peri700;
  static const Color warn = ThymePalette.yellow400;
  static const Color warnBg = ThymePalette.yellow50;
  static const Color warnText = ThymePalette.yellow700;

  // 보조 뉴트럴 (가이드 1-2)
  static const Color disabled = ThymePalette.night300; // 비활성 아이콘·꺼진 스위치
  static const Color icon = ThymePalette.night400; // 아이콘·점선 (글자 X)
  static const Color charcoal = ThymePalette.night600; // 긴 설명 글

  static const Color onPrimarySub = ThymePalette.softLavender; // 딥 나이트 면 위 보조 글자
  static const Color indigoSurface = ThymePalette.night700; // 딥 나이트 면 위 카드·칸 (가이드 1-3)

  /// 요일 글자색: 일요일·공휴일 = dangerText, 토요일 = infoText (가이드 2장 Do 6)
  static Color forWeekday(String day, {Color fallback = text}) =>
      day == '일' ? dangerText : (day == '토' ? infoText : fallback);

  // 외부 브랜드 지정 색 (로그인 버튼 전용, 각 사 가이드 규정이라 팔레트 예외)
  static const Color kakaoYellow = Color(0xFFFEE500);
  static const Color kakaoLabel = Color(0xD9000000);
  static const Color naverGreen = Color(0xFF03C75A);
  static const Color appleBlack = Color(0xFF000000);
}
