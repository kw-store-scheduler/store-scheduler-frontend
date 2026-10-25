import 'package:flutter/material.dart';
import '../../core/theme.dart';

class PreferenceReportPage extends StatelessWidget {
  const PreferenceReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: ThymeColor.deepNight, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "11월 희망 반영 결과",
          style: TextStyle(color: ThymeColor.deepNight, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 상단 요약 카드 (반영률)
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: ThymeColor.deepNight,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("희망 반영", style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                              const SizedBox(height: 8),
                              const Text("95%", style: TextStyle(color: ThymeColor.mint, fontSize: 28, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text("19개 중 18개", style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("휴무 요청 수용", style: TextStyle(color: ThymeColor.textGrey, fontSize: 13)),
                              SizedBox(height: 8),
                              Text("100%", style: TextStyle(color: ThymeColor.deepNight, fontSize: 28, fontWeight: FontWeight.bold)),
                              SizedBox(height: 4),
                              Text("필수 1 · 희망 1", style: TextStyle(color: ThymeColor.textGrey, fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 통계 차트 영역 (부담 근무 비교)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("부담 근무, 나와 팀 평균", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                      Text("최근 4주 누적", style: TextStyle(fontSize: 12, color: ThymeColor.textGrey)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  _buildStatRow("주말 근무", 2, 2.8, 5),
                  const SizedBox(height: 20),
                  _buildStatRow("마감 근무", 4, 4.3, 7),
                  const SizedBox(height: 20),
                  _buildStatRow("야간 근무", 0, 0.6, 3),

                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(width: 8, height: 8, color: ThymeColor.mint),
                      const SizedBox(width: 6),
                      const Text("민트 막대가 나", style: TextStyle(fontSize: 12, color: ThymeColor.textGrey)),
                      const SizedBox(width: 12),
                      Container(width: 2, height: 10, color: ThymeColor.deepNight),
                      const SizedBox(width: 6),
                      const Text("세로선이 팀 평균이에요.", style: TextStyle(fontSize: 12, color: ThymeColor.textGrey)),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 반영되지 못한 내역 및 보상 안내
                  const Text("반영되지 못한 1건", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ThymeColor.neutralBase,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.edit_calendar, size: 18, color: ThymeColor.deepNight),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "11/18(수) 오픈 선호 → 마감 배정",
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.deepNight),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          "오픈은 최소 인원이 찼고, 마감에 중국어 가능자가 필요했어요.\n다음 달 오픈 우선 순위가 올라가요.",
                          style: TextStyle(fontSize: 13, color: ThymeColor.deepNight.withValues(alpha: 0.8), height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 하단 버튼
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    side: const BorderSide(color: ThymeColor.deepNight, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    // W09 교대 요청 화면으로 이동
                  },
                  child: const Text(
                    "이 근무 교대 요청하기",
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.deepNight),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 커스텀 통계 바 차트 컴포넌트
  Widget _buildStatRow(String title, int myCount, double avgCount, int maxCount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
            Text("나 $myCount회 · 평균 $avgCount", style: const TextStyle(fontSize: 12, color: ThymeColor.textGrey)),
          ],
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            double totalWidth = constraints.maxWidth;
            double myWidth = (myCount / maxCount) * totalWidth;
            double avgPosition = (avgCount / maxCount) * totalWidth;

            return SizedBox(
              height: 24,
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  // 배경 바
                  Container(
                    width: totalWidth,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  // 내 근무 횟수 (민트색 바)
                  if (myCount > 0)
                    Container(
                      width: myWidth,
                      height: 8,
                      decoration: BoxDecoration(
                        color: ThymeColor.mint,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  // 팀 평균선 (세로선)
                  Positioned(
                    left: avgPosition,
                    child: Container(
                      width: 2,
                      height: 16,
                      color: ThymeColor.deepNight,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}