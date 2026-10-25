import 'package:flutter/material.dart';

/// Thyme 원색 팔레트 (단계 색). 화면 코드에서는 직접 쓰지 말고
/// 아래 ThymeTokens(역할 토큰)을 통해서만 사용한다.
class ThymePalette {
  ThymePalette._();

  // 뉴트럴(Night): 보랏빛 회색. 100 = 라일락 그레이, 900 = 딥 나이트
  static const night50 = Color(0xFFF7F6FA);
  static const night100 = Color(0xFFECEAF3); // ★ 라일락 그레이 (배경)
  static const night200 = Color(0xFFDCD8EA); // 라인 그레이 (테두리)
  static const night300 = Color(0xFFC2BDD8); // 소프트 그레이 (비활성)
  static const night400 = Color(0xFF9C95BD); // 쿨 그레이 (아이콘·점선, 글자 X)
  static const night500 = Color(0xFF6B6488); // 미드 그레이 (보조 글자)
  static const night600 = Color(0xFF4A4366); // 차콜 (긴 설명)
  static const night700 = Color(0xFF3A2F6B); // 인디고 서피스
  static const night900 = Color(0xFF251B4B); // ★ 딥 나이트
  static const night950 = Color(0xFF17102F); // 나이트 블랙 (다크 배경)
  static const lavenderMist = Color(0xFFF1EFF6); // 보조 카드
  static const lavenderTint = Color(0xFFE4E0F2); // 약한 선택
  static const softLavender = Color(0xFFB9B2D6); // 어두운 배경 위 보조 글자

  // 민트: 채워짐·확정
  static const mint50 = Color(0xFFEDFBF7);
  static const mint100 = Color(0xFFD3F7EC);
  static const mint300 = Color(0xFF74E4C6);
  static const mint400 = Color(0xFF3AD9B2); // ★ 아쿠아 민트
  static const mint800 = Color(0xFF0E6B50); // 민트 계열 글자

  // 로즈: 결원·경고·빨간날 (원색은 점·선만)
  static const rose50 = Color(0xFFFDEEF1);
  static const rose100 = Color(0xFFFBD9E0);
  static const rose300 = Color(0xFFF38CA1);
  static const rose400 = Color(0xFFEF6A84);
  static const rose500 = Color(0xFFEC4C6B); // ★ 클리어 로즈
  static const rose700 = Color(0xFFB42A48); // 로즈 계열 글자

  // 페리윙클: 토요일·안내
  static const peri50 = Color(0xFFF0F1FB);
  static const peri100 = Color(0xFFE0E2F6);
  static const peri300 = Color(0xFFA3A9E2);
  static const peri600 = Color(0xFF4C55BE); // ★ 페리윙클
  static const peri700 = Color(0xFF3F47A0); // 페리윙클 계열 글자

  // 머스터드 옐로: 한 단계 눌러 둔 주의·규칙 안내 (원색은 점만, 글자는 700)
  static const yellow50 = Color(0xFFFFF8E3);
  static const yellow100 = Color(0xFFFBEDC4);
  static const yellow300 = Color(0xFFF0CD68);
  static const yellow400 = Color(0xFFE5B53A); // ★ 머스터드 옐로
  static const yellow700 = Color(0xFF7D5C0A); // 옐로 계열 글자
  static const yellow950 = Color(0xFF2E2103); // 다크 배너 배경

  static const white = Color(0xFFFFFFFF);
}

/// 역할 토큰. ThemeExtension으로 등록해서 `Theme.of(context).extension<ThymeTokens>()!`(또는 `context.tokens`)로 꺼내 쓴다.
@immutable
class ThymeTokens extends ThemeExtension<ThymeTokens> {
  const ThymeTokens({
    required this.bg,
    required this.surface,
    required this.surfaceSub,
    required this.border,
    required this.text,
    required this.textSub,
    required this.primary,
    required this.onPrimary,
    required this.accent,
    required this.onAccent,
    required this.selectedSoft,
    required this.successBg,
    required this.successText,
    required this.danger,
    required this.dangerBg,
    required this.dangerText,
    required this.info,
    required this.infoBg,
    required this.infoText,
    required this.warn,
    required this.warnBg,
    required this.warnText,
  });

  final Color bg;          // 앱 배경
  final Color surface;     // 카드
  final Color surfaceSub;  // 보조 카드·비활성 칸
  final Color border;      // 구분선·테두리
  final Color text;        // 본문·제목
  final Color textSub;     // 보조 글자·라벨
  final Color primary;     // 주요 버튼 배경
  final Color onPrimary;   // 주요 버튼 글자
  final Color accent;      // 확정·최종 CTA 배경, 금액 숫자
  final Color onAccent;    // 민트 위 글자 (항상 딥 나이트)
  final Color selectedSoft;// 약한 선택 (가능·희망·칩)
  final Color successBg;   // 확정 배지·확정 칸 배경
  final Color successText; // 확정 글자
  final Color danger;      // 결원 점·점선 잎 (글자 X)
  final Color dangerBg;    // 결원 배너 배경
  final Color dangerText;  // 결원·일요일·공휴일 글자
  final Color info;        // 안내 점·아이콘
  final Color infoBg;      // 안내 배너 배경
  final Color infoText;    // 안내 글자·토요일 숫자
  final Color warn;        // 주의 점
  final Color warnBg;      // 주의 배너 배경
  final Color warnText;    // 주의 글자

  /// 라이트 모드 값
  static const light = ThymeTokens(
    bg: ThymePalette.night100,
    surface: ThymePalette.white,
    surfaceSub: ThymePalette.lavenderMist,
    border: ThymePalette.night200,
    text: ThymePalette.night900,
    textSub: ThymePalette.night500,
    primary: ThymePalette.night900,
    onPrimary: ThymePalette.white,
    accent: ThymePalette.mint400,
    onAccent: ThymePalette.night900,
    selectedSoft: ThymePalette.lavenderTint,
    successBg: ThymePalette.mint100,
    successText: ThymePalette.mint800,
    danger: ThymePalette.rose500,
    dangerBg: ThymePalette.rose50,
    dangerText: ThymePalette.rose700,
    info: ThymePalette.peri600,
    infoBg: ThymePalette.peri50,
    infoText: ThymePalette.peri700,
    warn: ThymePalette.yellow400,
    warnBg: ThymePalette.yellow50,
    warnText: ThymePalette.yellow700,
  );

  /// 다크 모드 값: primary가 민트로 바뀌는 점에 주의
  static const dark = ThymeTokens(
    bg: ThymePalette.night950,
    surface: ThymePalette.night900,
    surfaceSub: Color(0xFF1F1742),
    border: ThymePalette.night700,
    text: ThymePalette.night100,
    textSub: ThymePalette.softLavender,
    primary: ThymePalette.mint400,
    onPrimary: ThymePalette.night900,
    accent: ThymePalette.mint400,
    onAccent: ThymePalette.night900,
    selectedSoft: ThymePalette.night700,
    successBg: Color(0xFF0A4F3C),
    successText: ThymePalette.mint300,
    danger: ThymePalette.rose400,
    dangerBg: Color(0xFF47101D),
    dangerText: ThymePalette.rose300,
    info: ThymePalette.peri300,
    infoBg: Color(0xFF1B1E44),
    infoText: ThymePalette.peri300,
    warn: ThymePalette.yellow400,
    warnBg: ThymePalette.yellow950,
    warnText: ThymePalette.yellow300,
  );

  @override
  ThymeTokens copyWith() => this; // 토큰은 고정값이라 복사 변경을 막아 둔다

  @override
  ThymeTokens lerp(ThemeExtension<ThymeTokens>? other, double t) {
    // 라이트↔다크 전환 애니메이션용 보간
    if (other is! ThymeTokens) return this;
    Color l(Color a, Color b) => Color.lerp(a, b, t)!;
    return ThymeTokens(
      bg: l(bg, other.bg), surface: l(surface, other.surface), surfaceSub: l(surfaceSub, other.surfaceSub),
      border: l(border, other.border), text: l(text, other.text), textSub: l(textSub, other.textSub),
      primary: l(primary, other.primary), onPrimary: l(onPrimary, other.onPrimary),
      accent: l(accent, other.accent), onAccent: l(onAccent, other.onAccent),
      selectedSoft: l(selectedSoft, other.selectedSoft),
      successBg: l(successBg, other.successBg), successText: l(successText, other.successText),
      danger: l(danger, other.danger), dangerBg: l(dangerBg, other.dangerBg), dangerText: l(dangerText, other.dangerText),
      info: l(info, other.info), infoBg: l(infoBg, other.infoBg), infoText: l(infoText, other.infoText),
      warn: l(warn, other.warn), warnBg: l(warnBg, other.warnBg), warnText: l(warnText, other.warnText),
    );
  }
}

/// 화면 코드에서 `context.tokens.text`처럼 역할 토큰을 꺼내는 단축 접근자
extension ThymeTokensX on BuildContext {
  ThymeTokens get tokens => Theme.of(this).extension<ThymeTokens>()!;
}
