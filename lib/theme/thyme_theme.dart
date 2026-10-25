import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // pubspec: google_fonts
import 'thyme_colors.dart';

/// 앱 전체 테마. MaterialApp(theme: ThymeTheme.light(), darkTheme: ThymeTheme.dark())
class ThymeTheme {
  ThymeTheme._();

  static ThemeData light() => _build(ThymeTokens.light, Brightness.light);
  static ThemeData dark() => _build(ThymeTokens.dark, Brightness.dark);

  static ThemeData _build(ThymeTokens t, Brightness b) {
    // 본문은 IBM Plex Sans KR
    final base = GoogleFonts.ibmPlexSansKrTextTheme().apply(bodyColor: t.text, displayColor: t.text);
    return ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: t.bg,
      colorScheme: ColorScheme(
        brightness: b,
        primary: t.primary, onPrimary: t.onPrimary,
        secondary: t.accent, onSecondary: t.onAccent,
        error: t.danger, onError: ThymePalette.white,
        surface: t.surface, onSurface: t.text,
      ),
      textTheme: base,
      extensions: [t],
      cardTheme: CardThemeData(
        color: t.surface, elevation: 0, margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: DividerThemeData(color: t.border, thickness: 1, space: 1),
      // 주요 버튼 = 딥 나이트(다크에서는 민트)
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: t.primary, foregroundColor: t.onPrimary,
          // 조건을 못 채운 '다음' 버튼 (onPressed: null)
          disabledBackgroundColor: t.border, disabledForegroundColor: t.textSub,
          elevation: 0,
          minimumSize: const Size(64, 54), // 가이드 원본은 Size.fromHeight(폭 무한)인데 Row 안 버튼이 깨져서 폭은 부모(SizedBox)가 정함
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          // base에서 꺼내야 본문 서체(IBM Plex Sans KR)를 물려받는다 (가이드 원본은 const TextStyle)
          textStyle: base.labelLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
        ),
      ),
      // 보조 버튼 = 흰 카드 + 테두리
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          backgroundColor: t.surface, foregroundColor: t.text,
          side: BorderSide(color: t.border),
          minimumSize: const Size(64, 52),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true, fillColor: t.surface,
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: t.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: t.text, width: 2)),
      ),
    );
  }

  /// 숫자(시간·금액·코드) 전용 스타일: IBM Plex Mono
  static TextStyle mono(BuildContext context, {double size = 15, Color? color}) =>
      GoogleFonts.ibmPlexMono(fontSize: size, fontWeight: FontWeight.w600,
          color: color ?? Theme.of(context).extension<ThymeTokens>()!.text);
}

/// 최종 CTA(민트) 버튼: 한 화면에 1개만
class ThymeFinalButton extends StatelessWidget {
  const ThymeFinalButton({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).extension<ThymeTokens>()!;
    return FilledButton(
      style: FilledButton.styleFrom(backgroundColor: t.accent, foregroundColor: t.onAccent),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}
