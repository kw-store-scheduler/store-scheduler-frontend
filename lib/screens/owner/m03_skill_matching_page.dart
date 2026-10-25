import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_leaf.dart';
import '../../widgets/thyme_owner_header.dart';
import 'p06_substitute_manage_page.dart';

/// 시간대 하나의 필요 역량과 배치 결과 (백엔드 GET /skill-coverage 와 같은 내용)
class _SkillSlot {
  const _SkillSlot(this.time, this.name, this.skills, this.people, {this.shortage});

  final String time;
  final String name;
  final List<String> skills; // "응대 상 · 필수"처럼 등급·필수/우선까지
  final String people;
  final String? shortage; // 결원이면 사유
}

/// M03 역량 매칭. 그날 시간대별 필요 역량을 채운 사람과 결원
///
/// 시안은 카드 왼쪽 세로줄로 상태를 보이지만, 가이드 1-1(왼쪽 세로줄 카드 X)과
/// 5장(M03: 결원 행만 로즈 점·테두리)을 따라 결원 카드만 로즈 테두리 + 점으로 표시한다.
class SkillMatchingPage extends StatelessWidget {
  const SkillMatchingPage({super.key});

  static const _slots = [
    _SkillSlot("09–12", "오픈", ["오픈·마감"], "지수 · 하준"),
    _SkillSlot("12–14", "피크", ["응대 상 · 필수", "중국어 · 필수"], "지수 · 서연 · 하준(중국어 상)"),
    _SkillSlot("17–22", "마감", ["응대"], "", shortage: "민호 결원 · 가능한 2명에게 대타 요청 중"),
    _SkillSlot("18–20", "저녁 피크", ["영어 · 우선"], "태윤(영어 상) · 서연"),
    _SkillSlot("20–22", "마감", ["정산 · 필수"], "서연(정산 중) · 태윤(POS)"),
  ];

  @override
  Widget build(BuildContext context) {
    final covered = _slots.where((s) => s.shortage == null).length;
    final shortage = _slots.firstWhere((s) => s.shortage != null);
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: Column(
        children: [
          const ThymeOwnerHeader(title: "역량 매칭", showBack: true),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("11월 25일 수요일", style: TextStyle(fontSize: 15, color: ThymeColor.textSub)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const ThymeLeaf(size: 14),
                      const SizedBox(width: 6),
                      Text("역량 충족 $covered", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                      const SizedBox(width: 12),
                      const Icon(Icons.circle, size: 8, color: ThymeColor.danger),
                      const SizedBox(width: 6),
                      const Text("결원 1", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.dangerText)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  for (final s in _slots) ...[
                    _buildSlot(context, s),
                    const SizedBox(height: 10),
                  ],
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubstituteManagePage())),
                      child: Text("${shortage.name} ${shortage.time} 대타 요청 현황 보기"),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSlot(BuildContext context, _SkillSlot s) {
    final short = s.shortage != null;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThymeColor.surface,
        borderRadius: BorderRadius.circular(18),
        border: short ? Border.all(color: ThymeColor.danger, width: 1.5) : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(s.time, style: ThymeTheme.mono(context, size: 16)),
              const SizedBox(width: 8),
              Text(s.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              const Spacer(),
              if (short) const Icon(Icons.circle, size: 8, color: ThymeColor.danger),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final skill in s.skills)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(99)),
                  child: Text(skill, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            s.shortage ?? s.people,
            style: TextStyle(fontSize: 14, color: short ? ThymeColor.dangerText : ThymeColor.textSub),
          ),
        ],
      ),
    );
  }
}
