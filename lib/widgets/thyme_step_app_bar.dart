import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../theme/thyme_colors.dart';
import '../theme/thyme_theme.dart';
import 'thyme_back_button.dart';

/// 온보딩(가입·희망 신청·매장 등록) 화면 공통 상단 바.
///
/// 가이드 4-1: `← / STEP n / N` → 진행바(지난 칸 페리윙클, 남은 칸 border).
/// 점주 입력 화면은 진행바가 딥 나이트(가이드 4-0)라서 [owner]로 구분한다.
class ThymeStepAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ThymeStepAppBar({
    super.key,
    required this.step,
    required this.total,
    this.group,
    this.title,
    this.owner = false,
    this.closeIcon = false,
    this.actions,
    this.leading,
  });

  final int step;
  final int total;

  /// 단계 앞에 붙는 흐름 이름 (예: "가입", "매장 등록")
  final String? group;

  /// 가운데 작은 제목 (예: "언제 · 고정 일정")
  final String? title;
  final bool owner;

  /// 흐름의 첫 화면처럼 '닫기(X)'가 맞는 경우
  final bool closeIcon;

  /// 단계 표시 오른쪽에 붙는 버튼 (예: 건너뛰기)
  final List<Widget>? actions;

  /// 뒤로가기 대신 둘 것 (예: 매장 등록 첫 화면의 로고)
  final Widget? leading;

  static const double _barHeight = 4;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight + _barHeight);

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return AppBar(
      backgroundColor: t.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      // 아래에 화면이 없으면(첫 화면) 뒤로가기를 숨긴다
      automaticallyImplyLeading: false,
      leading: leading ?? ThymeBackButton(icon: closeIcon ? Icons.close : Icons.arrow_back_ios, color: t.text, size: 20),
      leadingWidth: leading == null ? null : 140,
      centerTitle: true,
      title: title == null
          ? null
          : Text(title!, style: TextStyle(color: t.textSub, fontSize: 14, fontWeight: FontWeight.w600)),
      actions: [
        Center(
          child: Padding(
            padding: EdgeInsets.only(right: actions == null ? 20 : 4),
            child: Text.rich(
              TextSpan(children: [
                if (group != null)
                  TextSpan(text: '$group ', style: TextStyle(color: t.textSub, fontSize: 13, fontWeight: FontWeight.w700)),
                TextSpan(text: '$step / $total', style: ThymeTheme.mono(context, size: 13, color: t.textSub)),
              ]),
            ),
          ),
        ),
        ...?actions,
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(_barHeight),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: List.generate(total, (i) {
              return Expanded(
                child: Container(
                  height: _barHeight,
                  margin: EdgeInsets.only(right: i == total - 1 ? 0 : 4),
                  decoration: BoxDecoration(
                    color: i < step ? (owner ? t.primary : t.info) : t.border,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

/// 매장 설정(P08)에서 등록 화면(O02~O06)을 고칠 때 쓰는 상단 바: ← 제목 (진행바 없음)
PreferredSizeWidget thymeEditAppBar(String title) => AppBar(
      backgroundColor: ThymeColor.bg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: const ThymeBackButton(icon: Icons.arrow_back_ios, color: ThymeColor.text, size: 20),
      centerTitle: true,
      title: Text(title, style: const TextStyle(color: ThymeColor.text, fontSize: 17, fontWeight: FontWeight.bold)),
    );
