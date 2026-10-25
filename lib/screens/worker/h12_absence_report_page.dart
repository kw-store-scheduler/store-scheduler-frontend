import 'package:flutter/material.dart';
import '../../widgets/thyme_back_button.dart';
import '../../core/theme.dart';
import 'h13_fill_vacancy_page.dart';

class AbsenceReportPage extends StatefulWidget {
  const AbsenceReportPage({super.key});

  @override
  State<AbsenceReportPage> createState() => _AbsenceReportPageState();
}

class _AbsenceReportPageState extends State<AbsenceReportPage> {
  int _selectedReasonIndex = 0;
  final TextEditingController _memoController = TextEditingController();

  final List<String> _reasons = [
    "갑작스러운 건강 악화 (발열, 몸살 등)",
    "개인 사정 / 집안 행사",
    "학교 일정 변경 (시험, 보강 등)",
    "기타 사유"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: AppBar(
        backgroundColor: ThymeColor.bg,
        elevation: 0,
        leading: ThymeBackButton(size: 20),
        title: const Text(
          "결원 신고",
          style: TextStyle(color: ThymeColor.text, fontSize: 16, fontWeight: FontWeight.bold),
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
                  // 상단 안내 문구
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ThymeColor.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: ThymeColor.dangerText),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "오늘 예정된 근무에 사정이 생기셨나요?\n신고 즉시 점주님과 대타 후보들에게 알림이 갑니다.",
                            style: TextStyle(fontSize: 13, color: ThymeColor.text.withValues(alpha: 0.8), height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 대상 근무 정보 카드
                  const Text("대상 근무", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: ThymeColor.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("11월 18일 (수)", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                            SizedBox(height: 4),
                            Text("오픈 교대 (09:00 - 14:00)", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: ThymeColor.text,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text("근무 중", style: TextStyle(color: ThymeColor.onPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 사유 선택 라디오 리스트
                  const Text("불참 사유를 선택해주세요", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
                  const SizedBox(height: 12),
                  ...List.generate(_reasons.length, (index) {
                    bool isSelected = _selectedReasonIndex == index;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedReasonIndex = index),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ThymeColor.surface,
                          border: Border.all(
                            color: isSelected ? ThymeColor.text : ThymeColor.border,
                            width: isSelected ? 2 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                              color: isSelected ? ThymeColor.text : ThymeColor.disabled,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _reasons[index],
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                color: ThymeColor.text,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 24),

                  // 상세 메모 입력
                  const Text("상세 메모 (선택)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _memoController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "점주님께 전달할 특이사항이 있다면 적어주세요.",
                      hintStyle: TextStyle(color: ThymeColor.disabled, fontSize: 14),
                      filled: true,
                      fillColor: ThymeColor.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 하단 신고하기 버튼
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                // POST /schedules/{scheduleId}/swap-requests 연결할 자리 → H13 빈자리 채우기
                child: FilledButton(onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const FillVacancyPage()));
                  }, child: Text("결원 신고 및 대타 찾기 요청")),
              ),
            ),
          ),
        ],
      ),
    );
  }
}