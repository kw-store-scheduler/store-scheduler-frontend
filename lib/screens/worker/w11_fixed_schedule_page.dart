import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/preference.dart';
import '../../widgets/thyme_step_app_bar.dart';
// 행님이 이미 만드신 근무 신청(날짜/교대) 페이지로 연결!
import 'w02_date_shift_page.dart'; 

class FixedSchedulePage extends StatelessWidget {
  const FixedSchedulePage({super.key, this.draft});

  /// 희망 신청 중이면 초안, 내 정보에서 고정 일정만 고치러 왔으면 null
  final PreferenceDraft? draft;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: ThymeStepAppBar(step: 2, total: 7, title: '언제 · 고정 일정'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text("매주 반복되는 일정이 있나요?", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text, height: 1.3)),
                    const SizedBox(height: 12),
                    Text("학교, 다른 직장, 돌봄처럼 매주 같은 시간에 못 나오는 일정이에요. 기간이 끝나면 자동으로 풀려요.", style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.4)),
                    const SizedBox(height: 32),

                    _buildScheduleCard(
                      icon: Icons.school_outlined,
                      type: "학업",
                      title: "전공 수업",
                      time: "10:30~13:30",
                      selectedDays: ["월", "화", "수", "목"],
                      period: "09/01 ~\n12/18",
                      tip: "종강 1주 전에 다음 학기 시간표를 물어봐요",
                    ),
                    const SizedBox(height: 16),

                    _buildScheduleCard(
                      icon: Icons.work_outline,
                      type: "다른 직장",
                      title: "편의점",
                      time: "10:00~22:00",
                      selectedDays: ["토", "일"],
                      period: "계속",
                      tip: "주 4시간 · 주당 총 근로시간에 합산해요",
                    ),
                    const SizedBox(height: 24),

                    const Text("일정 추가", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildAddButton(Icons.school_outlined, "학업"),
                        _buildAddButton(Icons.work_outline, "다른 직장"),
                        _buildAddButton(Icons.child_care, "돌봄·통학"),
                        _buildAddButton(Icons.more_horiz, "기타"),
                      ],
                    ),
                    const SizedBox(height: 40),
                    const Divider(),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeTrackColor: ThymeColor.primary, // 스위치 켜짐 = 딥 나이트
                      activeThumbColor: ThymeColor.onPrimary,
                      title: const Text("이번 달만 예외", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                      subtitle: const Text("11/09~11/13 시험 기간 · 평일 전부 불가", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                      value: true,
                      onChanged: (bool value) {},
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: () {
                    final d = draft;
                    if (d == null) {
                      Navigator.maybePop(context); // 내 정보에서 온 경우
                      return;
                    }
                    Navigator.push(context, MaterialPageRoute(builder: (context) => DateShiftPage(draft: d)));
                  }, child: Text(draft == null ? "저장" : "다음")),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScheduleCard({required IconData icon, required String type, required String title, required String time, required List<String> selectedDays, required String period, required String tip}) {
    final days = ["월", "화", "수", "목", "금", "토", "일"];
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(border: Border.all(color: ThymeColor.border), borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(icon, size: 14, color: ThymeColor.charcoal), const SizedBox(width: 4), Text(type, style: TextStyle(fontSize: 12, color: ThymeColor.charcoal, fontWeight: FontWeight.bold))])),
                  const SizedBox(width: 8),
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                ],
              ),
              Text(time, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: days.map((day) {
              bool isSelected = selectedDays.contains(day);
              return Container(
                width: 32, height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: isSelected ? ThymeColor.text : ThymeColor.surfaceSub, shape: BoxShape.circle),
                child: Text(day, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? ThymeColor.onPrimary : ThymeColor.forWeekday(day, fallback: ThymeColor.textSub))),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(period, style: const TextStyle(fontSize: 12, color: ThymeColor.text, fontWeight: FontWeight.bold, height: 1.4)),
              const SizedBox(width: 12),
              Expanded(child: Text(tip, style: TextStyle(fontSize: 12, color: ThymeColor.textSub))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddButton(IconData icon, String label) {
    return Column(
      children: [
        Container(
          width: 56, height: 56,
          decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(16), border: Border.all(color: ThymeColor.border)),
          child: Icon(icon, color: ThymeColor.textSub, size: 24),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, color: ThymeColor.charcoal, fontWeight: FontWeight.w500)),
      ],
    );
  }
}