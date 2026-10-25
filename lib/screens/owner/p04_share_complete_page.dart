import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'p01_owner_home_page.dart'; // 매장 홈으로 완벽 귀환!

class ShareCompletePage extends StatelessWidget {
  const ShareCompletePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: AppBar(
        backgroundColor: ThymeColor.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: ThymeColor.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              Row(
                children: [
                  const Icon(Icons.check_circle, color: ThymeColor.successText, size: 20),
                  const SizedBox(width: 8),
                  Text("OWNER · A안 확정", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
                ],
              ),
              const SizedBox(height: 16),
              const Text("11월 근무표를 7명에게 보냈어요", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text, height: 1.3)),
              const SizedBox(height: 32),

              // 스탯 박스
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatCard("희망 반영", "98.8%"),
                  _buildStatCard("노동법 위반", "0건"),
                  _buildStatCard("예상 인건비", "₩7.21M", isDark: true),
                ],
              ),
              const SizedBox(height: 40),

              // 누가 확인했나
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("누가 확인했나요", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                  Text("5 / 7", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAvatar("지", true),
                  _buildAvatar("서", true),
                  _buildAvatar("하", true),
                  _buildAvatar("동", true),
                  _buildAvatar("윤", true),
                  _buildAvatar("해", false), // 미확인
                  _buildAvatar("태", false), // 미확인
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: TextButton(
                  onPressed: () {},
                  child: const Text("안 본 2명에게 다시 알리기", style: TextStyle(color: ThymeColor.dangerText, fontWeight: FontWeight.bold, fontSize: 14)), // Rose color
                ),
              ),
              
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("직원들이 받은 알림", style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
                    const SizedBox(height: 8),
                    Text("\"11월 근무표가 확정됐어요 · 희망 반영과 배정 사유를 확인해 보세요\"", style: TextStyle(fontSize: 14, color: ThymeColor.charcoal, height: 1.4, fontStyle: FontStyle.italic)),
                  ],
                ),
              ),

              const Spacer(),
              
              // 하단 버튼
              Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: ThymeColor.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {}, // 엑셀/PDF 다운로드 로직
                      child: const Text("PDF로 내보내기", style: TextStyle(color: ThymeColor.textSub, fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(onPressed: () {
                        // 스케줄 생성 플로우 끝! 점주 홈으로 귀환!
                        Navigator.pushAndRemoveUntil(
                          context,
                          MaterialPageRoute(builder: (context) => const OwnerHomePage()),
                          (route) => false,
                        );
                      }, child: Text("매장 홈으로")),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, {bool isDark = false}) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? ThymeColor.text : ThymeColor.surfaceSub,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 12, color: isDark ? ThymeColor.onPrimarySub : ThymeColor.textSub)),
          const SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? ThymeColor.onPrimary : ThymeColor.text)),
        ],
      ),
    );
  }

  Widget _buildAvatar(String initial, bool isChecked) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isChecked ? ThymeColor.successBg : ThymeColor.border,
          child: Text(initial, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isChecked ? ThymeColor.successText : ThymeColor.textSub)),
        ),
        const SizedBox(height: 8),
        Text(isChecked ? "확인" : "미확인", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isChecked ? ThymeColor.successText : ThymeColor.dangerText)), // Mint or Rose
      ],
    );
  }
}