import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/thyme_worker_tab_bar.dart';
import '../../widgets/thyme_step_app_bar.dart';

class FillVacancyPage extends StatefulWidget {
  const FillVacancyPage({super.key});

  @override
  State<FillVacancyPage> createState() => _FillVacancyPageState();
}

class _FillVacancyPageState extends State<FillVacancyPage> {
  bool _isDirectRequest = true; // true: 대타 직접 구하기, false: 게시판에 올리기
  final List<String> _selectedCoworkers = ["지수", "하준"]; // 시연용 기본 선택

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: ThymeStepAppBar(step: 2, total: 2, group: '결원 신고'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.check_circle, color: ThymeColor.successText, size: 20),
                        const SizedBox(width: 8),
                        Text("사장님께 결원을 알렸어요", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.charcoal)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text("  11/20(금) 09:00~14:00 · 개인 사정", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                    const SizedBox(height: 24),
                    
                    const Text("빈자리는 어떻게 채울까요?", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text, height: 1.3)),
                    const SizedBox(height: 24),

                    // 탭 버튼
                    Row(
                      children: [
                        Expanded(child: _buildTabButton("대타 직접 구하기", _isDirectRequest, () => setState(() => _isDirectRequest = true))),
                        const SizedBox(width: 12),
                        Expanded(child: _buildTabButton("게시판에 올리기", !_isDirectRequest, () => setState(() => _isDirectRequest = false))),
                      ],
                    ),
                    const SizedBox(height: 32),

                    if (_isDirectRequest) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("보낼 동료 고르기", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                          Text("가능하다고 한 사람 · 규칙 통과", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      _buildCoworkerRow("지수", "오픈 가능 · 이번 주 30h", true, isSelected: _selectedCoworkers.contains("지수")),
                      const SizedBox(height: 12),
                      _buildCoworkerRow("하준", "오픈 가능 · 이번 달 추가 근무 0회", true, isSelected: _selectedCoworkers.contains("하준")),
                      const SizedBox(height: 12),
                      _buildCoworkerRow("서준", "11시부터 가능 · 일부만", false, isSelected: _selectedCoworkers.contains("서준")),
                      
                      const SizedBox(height: 24),
                      Text(
                        "한 명이 수락하면 나머지 요청은 자동으로 닫혀요. 30분 안에 아무도 안 받으면 게시판으로 넘어가요.",
                        style: TextStyle(fontSize: 13, color: ThymeColor.textSub, height: 1.4),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            
            // 하단 버튼
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThymeColor.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // 대타 요청 보내고 홈 화면으로 싹 날려버리기!
                    ThymeWorkerTabBar.go(context, WorkerTab.home);
                  },
                  child: Text(
                    _isDirectRequest ? "${_selectedCoworkers.length}명에게 대타 요청 보내기" : "게시판에 올리기",
                    style: const TextStyle(color: ThymeColor.onPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String title, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? ThymeColor.text : ThymeColor.surface,
          border: Border.all(color: isSelected ? ThymeColor.text : ThymeColor.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isSelected ? ThymeColor.onPrimary : ThymeColor.textSub)),
      ),
    );
  }

  Widget _buildCoworkerRow(String name, String desc, bool isRecommended, {required bool isSelected}) {
    return GestureDetector(
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedCoworkers.remove(name);
          } else {
            _selectedCoworkers.add(name);
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? ThymeColor.selectedSoft : ThymeColor.surface,
          border: Border.all(color: isSelected ? ThymeColor.text : ThymeColor.border, width: isSelected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.check_circle : Icons.circle_outlined, color: isSelected ? ThymeColor.text : ThymeColor.border),
            const SizedBox(width: 12),
            CircleAvatar(radius: 18, backgroundColor: ThymeColor.border, child: Text(name[0], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub))),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
                ],
              ),
            ),
            if (isRecommended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(12)),
                child: const Text("추천", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              ),
          ],
        ),
      ),
    );
  }
}