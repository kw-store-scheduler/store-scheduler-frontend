import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'm05_proposal_compare_page.dart'; // 행님의 M05 화면으로 찐 연결!

class GeneratingSchedulePage extends StatelessWidget {
  const GeneratingSchedulePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.primary, // 배경 어둡게!
      appBar: AppBar(
        backgroundColor: ThymeColor.primary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: ThymeColor.onPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("OWNER · 11월 근무표", style: TextStyle(color: ThymeColor.onPrimarySub, fontSize: 13, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text("모두가 납득할 수 있는\n조합을 찾고 있어요", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.onPrimary, height: 1.3)),
              const SizedBox(height: 12),
              const Text("보통 2분 안에 끝나요", style: TextStyle(fontSize: 14, color: ThymeColor.onPrimarySub)),
              const SizedBox(height: 60),

              // 진행 단계 리스트
              _buildStepRow(Icons.check_circle, "희망 7명 불러오기", "고정 일정 · 휴무 · 선호 · 수당 상한", "완료", true),
              _buildStepRow(Icons.check_circle, "규칙을 제약으로 바꾸기", "주 52시간 · 최소 인원 · 필수 휴무", "완료", true),
              _buildStepRow(Icons.sync, "가장 공정한 조합 찾기", "CP-SAT · 주말/마감 4주 누적 균등", "계산 중", true, isSpinning: true),
              _buildStepRow(Icons.circle_outlined, "3안으로 정리", "공정 · 인건비 · 희망 우선", "대기", false),
              
              const Spacer(),
              
              // 정보 박스
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: ThymeColor.surface.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.info_outline, color: ThymeColor.onPrimarySub, size: 20),
                    const SizedBox(width: 12),
                    Expanded(child: Text("미제출 2명(유나,태환)은 지난달 답으로 넣었어요. 확정 전에 바꿀 수 있어요.", style: TextStyle(color: ThymeColor.onPrimary.withValues(alpha: 0.9), fontSize: 13, height: 1.4))),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              
              // 하단 버튼 (완료 시연용)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: ThymeColor.surface.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // 계산 완료됐다고 치고 행님의 3안 비교(M05)로 슝!
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const ProposalComparePage()));
                  },
                  child: const Text("결과 보기 (시연 이동)", style: TextStyle(color: ThymeColor.onPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow(IconData icon, String title, String subtitle, String status, bool isActive, {bool isSpinning = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: isActive ? ThymeColor.successText : ThymeColor.onPrimarySub, size: 24), // Mint or Grey
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isActive ? ThymeColor.onPrimary : ThymeColor.onPrimarySub)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 13, color: isActive ? ThymeColor.onPrimarySub : ThymeColor.onPrimarySub)),
              ],
            ),
          ),
          Text(status, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isActive ? ThymeColor.successText : ThymeColor.onPrimarySub)),
        ],
      ),
    );
  }
}