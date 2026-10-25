import 'package:flutter/material.dart';
import '../../widgets/thyme_back_button.dart';
import '../../core/theme.dart';
import 'w10_preference_report_page.dart';

class MySchedulePage extends StatelessWidget {
  const MySchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: AppBar(
        backgroundColor: ThymeColor.bg,
        elevation: 0,
        leading: ThymeBackButton(size: 20),
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("구시대 커피 광운대점", style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
            SizedBox(height: 2),
            Text("나의 11월 근무표", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThymeColor.text)),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16, top: 12, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: ThymeColor.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text("확정", style: TextStyle(color: ThymeColor.text, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 요일 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: ["일", "월", "화", "수", "목", "금", "토"]
                  .map((day) => Text(day, style: TextStyle(fontSize: 13, color: ThymeColor.forWeekday(day, fallback: ThymeColor.textSub))))
                  .toList(),
            ),
            const SizedBox(height: 16),
            
            // 달력 그리드 (간이 UI 구현)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 16,
                crossAxisSpacing: 8,
                childAspectRatio: 0.6,
              ),
              itemCount: 28, // 11월 샘플 일수
              itemBuilder: (context, index) {
                int day = index + 1;
                bool isWorkDay = [2, 3, 4, 5, 6, 9, 10, 11, 12, 13].contains(day);
                bool isRestDay = day == 8;
                
                String shiftLabel = "";
                if (isWorkDay) shiftLabel = (day % 2 == 0) ? "오픈" : "마감";

                return Column(
                  children: [
                    Text(
                      "$day",
                      style: TextStyle(
                        fontSize: 14,
                        color: isRestDay ? ThymeColor.danger : ThymeColor.text,
                        fontWeight: (isWorkDay || isRestDay) ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (isWorkDay)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: ThymeColor.accent.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(shiftLabel, style: const TextStyle(fontSize: 10, color: ThymeColor.text, fontWeight: FontWeight.bold)),
                      )
                    else if (isRestDay)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: ThymeColor.danger.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text("휴무", style: TextStyle(fontSize: 10, color: ThymeColor.dangerText, fontWeight: FontWeight.bold)),
                      )
                  ],
                );
              },
            ),
            
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: ThymeColor.surface),
            ),
            
            // 총 근무 시간 요약
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: ThymeColor.accent.withValues(alpha: 0.3), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text("근무", style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
                    const SizedBox(width: 12),
                    Container(width: 8, height: 8, decoration: BoxDecoration(color: ThymeColor.danger.withValues(alpha: 0.1), shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    const Text("휴무 반영", style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
                  ],
                ),
                const Text("13일 · 60.5h", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              ],
            ),
            const SizedBox(height: 32),

            // 엔진이 뱉어준 배정 사유 (CP-SAT 결과)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThymeColor.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, size: 18, color: ThymeColor.text),
                          SizedBox(width: 8),
                          Text("배정 사유", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                        ],
                      ),
                      Text("희망 반영 18/19", style: TextStyle(fontSize: 12, color: ThymeColor.textSub, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "주말 근무 2회(11/14, 11/21)는 4주 누적 공평 배분 규칙으로 정해졌어요. 팀 평균도 2회예요.",
                    style: TextStyle(fontSize: 13, color: ThymeColor.text.withValues(alpha: 0.8), height: 1.5),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(),
                  ),
                  Text(
                    "11/18(수) 마감 : 오픈을 원했지만 그날 오픈은 최소 인원이 이미 찼고, 마감에 중국어 가능자가 필요했어요.",
                    style: TextStyle(fontSize: 13, color: ThymeColor.text.withValues(alpha: 0.8), height: 1.5),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // 하단 버튼
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PreferenceReportPage()));
                }, child: Text("내 희망이 얼마나 반영됐는지 보기")),
            ),
          ],
        ),
      ),
    );
  }
}