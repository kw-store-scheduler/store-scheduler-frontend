import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

/// 로고 *thyme.* (가이드 4-2): t·h·m·e = Unbounded 300, y = Instrument Serif Italic(민트), 마침표 = 민트
class ThymeLogo extends StatelessWidget {
  const ThymeLogo({super.key, this.size = 40, this.color = ThymeColor.onPrimary});

  final double size;

  /// 글자색 (어두운 바탕이면 흰색, 밝은 바탕이면 딥 나이트)
  final Color color;

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.unbounded(fontSize: size, fontWeight: FontWeight.w300, color: color, letterSpacing: -size * 0.03);
    final y = GoogleFonts.instrumentSerif(fontSize: size * 1.12, fontStyle: FontStyle.italic, color: ThymeColor.accent);
    return Text.rich(
      TextSpan(children: [
        TextSpan(text: 'th', style: base),
        TextSpan(text: 'y', style: y),
        TextSpan(text: 'me', style: base),
        TextSpan(text: '.', style: base.copyWith(color: ThymeColor.accent)),
      ]),
      semanticsLabel: 'thyme.',
    );
  }
}
