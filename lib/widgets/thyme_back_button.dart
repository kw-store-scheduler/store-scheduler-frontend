import 'package:flutter/material.dart';
import '../core/theme.dart';

/// 화면 왼쪽 위 뒤로가기. 아래에 화면이 없으면(로그인 직후 첫 화면 등) 아예 보이지 않는다.
///
/// 첫 화면에서 Navigator.pop 을 부르면 화면이 하나도 없어져 빈 화면이 되기 때문에,
/// 뒤로가기는 항상 이 위젯(또는 Navigator.maybePop)을 쓴다.
class ThymeBackButton extends StatelessWidget {
  const ThymeBackButton({super.key, this.icon = Icons.arrow_back_ios, this.color = ThymeColor.text, this.size});

  final IconData icon;
  final Color color;
  final double? size;

  @override
  Widget build(BuildContext context) {
    if (!Navigator.canPop(context)) return const SizedBox.shrink();
    return IconButton(
      icon: Icon(icon, color: color, size: size),
      onPressed: () => Navigator.maybePop(context),
    );
  }
}
