import 'package:flutter/material.dart';
import '../core/theme.dart';

/// 점주 운영 화면 상단의 딥 나이트 띠 + `OWNER` 라벨 (가이드 5장: 모든 점주 운영 화면 공통)
///
/// [child]는 띠 안쪽 아래에 붙는 요약 카드 (예: 매장 코드 카드, 결원 근무 카드).
class ThymeOwnerHeader extends StatelessWidget {
  const ThymeOwnerHeader({super.key, required this.title, this.label = 'OWNER', this.subtitle, this.showBack = false, this.onTitleTap, this.trailing, this.child});

  final String title;

  /// 제목 위 작은 글자 (예: "OWNER · 근무자")
  final String label;

  /// 제목 옆 작은 글자 (예: "알바 · 9/1 입사")
  final String? subtitle;
  final bool showBack;

  /// 제목을 누르면 (예: 매장 고르기 ▼)
  final VoidCallback? onTitleTap;
  final Widget? trailing;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 16, 20, 24),
      decoration: const BoxDecoration(
        color: ThymeColor.primary,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (showBack && Navigator.canPop(context))
                IconButton(
                  padding: EdgeInsets.zero,
                  alignment: Alignment.centerLeft,
                  icon: const Icon(Icons.arrow_back_ios, color: ThymeColor.onPrimary, size: 20),
                  onPressed: () => Navigator.maybePop(context),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(color: ThymeColor.onPrimarySub, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: onTitleTap,
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(text: title, style: const TextStyle(color: ThymeColor.onPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                          if (onTitleTap != null)
                            const WidgetSpan(
                              alignment: PlaceholderAlignment.middle,
                              child: Icon(Icons.arrow_drop_down, color: ThymeColor.onPrimary, size: 28),
                            ),
                          if (subtitle != null)
                            TextSpan(text: "  $subtitle", style: const TextStyle(color: ThymeColor.onPrimarySub, fontSize: 14)),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
              ?trailing,
            ],
          ),
          if (child != null) ...[
            const SizedBox(height: 20),
            child!,
          ],
        ],
      ),
    );
  }
}
