import 'dart:ui';

import 'package:flutter/material.dart';
import '../core/theme.dart';

/// 가이드 4-5 잎 모티프. 근무 한 칸 = 잎 (`border-radius: 100% 0`, 두 모서리만 둥근 모양)
///
/// 채워진 잎 = 확정(민트), 점선 잎 = 결원(로즈) 또는 아직 안 정함(쿨 그레이). 상태 표시에만 쓴다.
class ThymeLeaf extends StatelessWidget {
  const ThymeLeaf({super.key, this.size = 16, this.color = ThymeColor.accent, this.dashed = false, this.flip = false});

  final double size;
  final Color color;
  final bool dashed;

  /// 좌우를 뒤집어 두 장을 마주 보게 놓을 때
  final bool flip;

  @override
  Widget build(BuildContext context) {
    return Transform.flip(
      flipX: flip,
      child: CustomPaint(size: Size.square(size), painter: _LeafPainter(color: color, dashed: dashed)),
    );
  }
}

class _LeafPainter extends CustomPainter {
  _LeafPainter({required this.color, required this.dashed});

  final Color color;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    // 왼쪽 위·오른쪽 아래만 둥근 사각형 = 잎
    final r = Radius.circular(size.width);
    final leaf = Path()..addRRect(RRect.fromRectAndCorners(Offset.zero & size, topLeft: r, bottomRight: r));
    if (!dashed) {
      canvas.drawPath(leaf, Paint()..color = color);
      return;
    }
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width / 16;
    final dash = size.width / 8;
    for (final PathMetric m in leaf.computeMetrics()) {
      for (double d = 0; d < m.length; d += dash * 2) {
        canvas.drawPath(m.extractPath(d, d + dash), stroke);
      }
    }
  }

  @override
  bool shouldRepaint(_LeafPainter old) => old.color != color || old.dashed != dashed;
}
