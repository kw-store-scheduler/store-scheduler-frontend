import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/theme.dart';
import '../../theme/thyme_theme.dart';
import 'p04_share_complete_page.dart';

class ProposalComparePage extends StatefulWidget {
  const ProposalComparePage({super.key});

  @override
  State<ProposalComparePage> createState() => _ProposalComparePageState();
}

class _ProposalComparePageState extends State<ProposalComparePage> {
  int _selectedIndex = 0;
  final NumberFormat _currencyFormat = NumberFormat('#,###');

  // [임시 데이터: 3안 비교 리스트]
  final List<Map<String, dynamic>> _proposals = [
    {
      "title": "A안 · 공정 우선",
      "badge": "추천",
      "cost": 7208928,
      "matchRate": "98.8%",
      "weekendDiff": "1회"
    },
    {
      "title": "B안 · 인건비 우선",
      "badge": "",
      "cost": 6951200,
      "matchRate": "94.1%",
      "weekendDiff": "3회"
    },
    {
      "title": "C안 · 희망 우선",
      "badge": "",
      "cost": 7312400,
      "matchRate": "100%",
      "weekendDiff": "2회"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: AppBar(
        backgroundColor: ThymeColor.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: ThymeColor.onPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // [상단 영역: 요약 헤더]
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(left: 24, right: 24, bottom: 32),
            decoration: const BoxDecoration(
              color: ThymeColor.text,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(24),
                bottomRight: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "OWNER\n구시대 커피 광운대점 · 2.7초 만에 계산",
                  style: TextStyle(color: ThymeColor.onPrimarySub, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 16),
                const Text(
                  "11월 근무표 3안이 준비됐어요",
                  style: TextStyle(color: ThymeColor.onPrimary, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    _buildSummaryCard("노동법 위반", "0건", ThymeColor.accent),
                    const SizedBox(width: 12),
                    _buildSummaryCard("최소 인원 충족", "100%", ThymeColor.accent),
                  ],
                )
              ],
            ),
          ),

          // [중앙 영역: 3안 리스트 카드]
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: _proposals.length,
              itemBuilder: (context, index) {
                final proposal = _proposals[index];
                final isSelected = _selectedIndex == index;

                return GestureDetector(
                  onTap: () => setState(() => _selectedIndex = index),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ThymeColor.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? ThymeColor.text : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: ThymeColor.text.withValues(alpha: 0.03), // 최신 문법 적용
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Text(
                                  proposal["title"],
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text),
                                ),
                                if (proposal["badge"].toString().isNotEmpty) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: ThymeColor.selectedSoft,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      proposal["badge"],
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ThymeColor.textSub),
                                    ),
                                  ),
                                ]
                              ],
                            ),
                            Text(
                              "₩${_currencyFormat.format(proposal["cost"])}",
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildDetailInfoBox("희망 반영", proposal["matchRate"]),
                            const SizedBox(width: 8),
                            _buildDetailInfoBox("주말 근무 최대 차이", proposal["weekendDiff"]),
                          ],
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // [주의사항 알림 영역]
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ThymeColor.warn.withValues(alpha: 0.15), // 최신 문법 적용
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.circle, color: ThymeColor.warn, size: 8),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "확인 1건 · 11/25 마감 17~22시는 최소 인원만 채웠고 목표 인원은 1명 모자라요.",
                    style: TextStyle(fontSize: 13, color: ThymeColor.text.withValues(alpha: 0.8), height: 1.4), // 최신 문법 적용
                  ),
                ),
              ],
            ),
          ),

          // [하단 영역: 액션 버튼]
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: ThymeColor.surface,
                        side: const BorderSide(color: ThymeColor.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {},
                      child: const Text("배정 사유", style: TextStyle(color: ThymeColor.text, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ThymeFinalButton(label: "${_selectedIndex == 0 ? 'A' : _selectedIndex == 1 ? 'B' : 'C'}안으로 확정", onPressed: () {
                      // POST /schedules/proposals/{id}/confirm 연결할 자리 → P04 확정·공유
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const ShareCompletePage()));
                    }),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // [위젯: 상단 요약 카드]
  Widget _buildSummaryCard(String title, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: ThymeColor.surface.withValues(alpha: 0.1), // 최신 문법 적용
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(color: ThymeColor.onPrimarySub, fontSize: 12)),
            const SizedBox(height: 8),
            Text(value, style: TextStyle(color: valueColor, fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  // [위젯: 리스트 내부 상세 정보 박스]
  Widget _buildDetailInfoBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: ThymeColor.surfaceSub,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11, color: ThymeColor.textSub)),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text)),
          ],
        ),
      ),
    );
  }
}