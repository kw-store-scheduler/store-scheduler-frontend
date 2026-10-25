import 'package:flutter/material.dart';
import '../../core/theme.dart';

class FillVacancyPage extends StatefulWidget {
  const FillVacancyPage({super.key});

  @override
  State<FillVacancyPage> createState() => _FillVacancyPageState();
}

class _FillVacancyPageState extends State<FillVacancyPage> {
  // [임시 대타 후보 리스트]
  final List<Map<String, dynamic>> _candidates = [
    {
      "name": "김세연",
      "badge": "추천 1순위 (숙련자)",
      "matchRate": "주휴수당 안전",
      "status": "연락 대기 중",
      "isAvailable": true,
    },
    {
      "name": "부연후",
      "badge": "이번 주 최저 근무",
      "matchRate": "시급 동일",
      "status": "거절됨",
      "isAvailable": false,
    },
    {
      "name": "우다현",
      "badge": "희망 시간 일치",
      "matchRate": "추가 수당 없음",
      "status": "수락 완료",
      "isAvailable": false,
    },
  ];

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
          "빈자리 채우기 (대타 긴급 매칭)",
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
                  // 상단 결원 정보 요약 카드
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ThymeColor.deepNight,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "🚨 긴급 결원 발생 교대",
                          style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "11월 18일 (수) · 오픈 교대 (09:00 - 14:00)",
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: ThymeColor.rose,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text("사유: 건강 악화", style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 8),
                            const Text("신고자: 김남용", style: TextStyle(color: Colors.white70, fontSize: 13)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 대타 후보 추천 리스트 안내
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("추천 대타 후보", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                      const Text("알고리즘 최적순", style: TextStyle(fontSize: 12, color: ThymeColor.textGrey)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 후보 카드 리스트
                  ..._candidates.map((candidate) {
                    bool isAvailable = candidate["isAvailable"];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: ThymeColor.neutralBase,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    candidate["name"],
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.deepNight),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: ThymeColor.mint.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      candidate["badge"],
                                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ThymeColor.deepNight),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "${candidate["matchRate"]} · 상태: ${candidate["status"]}",
                                style: const TextStyle(fontSize: 12, color: ThymeColor.textGrey),
                              ),
                            ],
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isAvailable ? ThymeColor.deepNight : Colors.grey.shade300,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: isAvailable ? () {} : null,
                            child: Text(
                              isAvailable ? "요청 보내기" : "완료",
                              style: TextStyle(
                                color: isAvailable ? Colors.white : ThymeColor.textGrey,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // 하단 전체 공지 버튼
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
                    // 전체 오픈채팅 또는 전체 알바생 대상 긴급 공지 전송
                  },
                  child: const Text(
                    "후보 전체에게 대타 일괄 요청하기",
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
}