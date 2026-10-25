import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/preference.dart';
import '../../widgets/thyme_step_app_bar.dart';
// 행님이 이미 만드신 제출 화면으로 연결!
import 'w14_preference_submit_page.dart'; 

class SkillsPage extends StatelessWidget {
  const SkillsPage({super.key, required this.draft});

  final PreferenceDraft draft;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: ThymeStepAppBar(step: 6, total: 7, title: '나 · 역량'),
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
                    const Text("내가 할 수 있는 일", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text, height: 1.3)),
                    const SizedBox(height: 12),
                    Text("내가 찍은 건 \"신청\"이에요. 매니저가 확인하면 배치에 쓰여요.", style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.4)),
                    const SizedBox(height: 32),

                    _buildSkillRow("영어", "상", isConfirmed: true),
                    const SizedBox(height: 16),
                    _buildSkillRow("중국어", "상", isConfirmed: false),
                    const SizedBox(height: 16),
                    _buildSkillRow("일본어", "없음", isConfirmed: true),
                    const SizedBox(height: 32),

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildTag("캐셔", true),
                        _buildTag("홀", true),
                        _buildTag("음료 제조", true),
                        _buildTag("오픈·마감 준비", false),
                        _buildTag("POS 정산", false),
                        _buildTag("발주·재고", false),
                      ],
                    ),
                    const SizedBox(height: 40),
                    const Divider(),
                    const SizedBox(height: 24),

                    const Text("혼자 맡을 수 있는 일 · 매니저가 정해요", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                    const SizedBox(height: 16),
                    _buildManagerCheckRow("혼자 오픈", "가능", true),
                    _buildManagerCheckRow("마감 정산 (POS 시제)", "아직", false),
                    _buildManagerCheckRow("매장 열쇠 보유", "가능", true),
                    _buildManagerCheckRow("발주 시스템 권한", "아직", false),
                    _buildManagerCheckRow("수습 기간", "~ 11/30", null, isDate: true),
                    
                    const SizedBox(height: 24),
                    Text(
                      "수습 기간에는 신입 1명과 같은 교대에 배치돼요. 바짝 배워야 하니 매니저에게 여쭤보세요.",
                      style: TextStyle(fontSize: 13, color: ThymeColor.textSub, height: 1.4),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => PreferenceSubmitPage(draft: draft)));
                  }, child: Text("다음")),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSkillRow(String language, String level, {required bool isConfirmed}) {
    return Row(
      children: [
        SizedBox(width: 60, child: Text(language, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text))),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ["상", "중", "하", "없음"].map((l) {
              bool isSelected = l == level;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? ThymeColor.text : ThymeColor.surfaceSub,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(l, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? ThymeColor.onPrimary : ThymeColor.textSub)),
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 72, // "확인 대기"가 들어가는 폭
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // 상태 = 원색 점 + 같은 계열 딥 글자 (가이드 1-1)
              Icon(Icons.circle, size: 6, color: isConfirmed ? ThymeColor.accent : ThymeColor.disabled),
              const SizedBox(width: 4),
              Text(isConfirmed ? "확정" : "확인 대기", style: TextStyle(fontSize: 12, color: isConfirmed ? ThymeColor.successText : ThymeColor.textSub, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTag(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? ThymeColor.text : ThymeColor.surface,
        border: Border.all(color: isSelected ? ThymeColor.text : ThymeColor.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? ThymeColor.onPrimary : ThymeColor.textSub)),
    );
  }

  Widget _buildManagerCheckRow(String title, String status, bool? isPositive, {bool isDate = false}) {
    Color statusColor = ThymeColor.textSub;
    if (isDate) {
      statusColor = ThymeColor.info; 
    } else if (isPositive == true) {
      statusColor = ThymeColor.accent;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: ThymeColor.text)),
          Row(
            children: [
              Icon(Icons.circle, size: 6, color: statusColor),
              const SizedBox(width: 6),
              Text(status, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: statusColor)),
            ],
          ),
        ],
      ),
    );
  }
}