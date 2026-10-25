import 'package:flutter/material.dart';
import '../../widgets/thyme_back_button.dart';
import '../../core/home_router.dart';
import '../../core/theme.dart';
import '../../theme/thyme_theme.dart';
import 'h01_part_timer_home_page.dart'; // 처리 후 홈으로 직행!

class CoverAcceptPage extends StatelessWidget {
  const CoverAcceptPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: AppBar(
        backgroundColor: ThymeColor.bg,
        elevation: 0,
        leading: ThymeBackButton(icon: Icons.close),
        title: const Text("대타 요청", style: TextStyle(color: ThymeColor.text, fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
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
                    Row(
                      children: [
                        const Icon(Icons.circle, size: 8, color: ThymeColor.danger), // Rose 컬러
                        const SizedBox(width: 8),
                        Text("11월 25일 마감에 결원이 생겼어요", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text("유나님, 이날 마감\n가능하세요?", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text, height: 1.3)),
                    const SizedBox(height: 32),

                    // 급여 및 근무 스탯 박스
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text("이 근무 예상 급여", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                                SizedBox(height: 4),
                                Text("₩51,600", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                              ],
                            ),
                          ),
                          Container(width: 1, height: 40, color: ThymeColor.border),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text("이번 주 근무", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                                  SizedBox(height: 4),
                                  Text("4일 ➔ 5일", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 추천 사유
                    const Text("왜 나에게 왔나요?", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                    const SizedBox(height: 16),
                    _buildReasonRow("이 시간이 가능하다고 신청했어요"),
                    const SizedBox(height: 10),
                    _buildReasonRow("주 52시간·연속 근무 한도 안이에요"),
                    const SizedBox(height: 10),
                    _buildReasonRow("오후에 필요한 응대 역량이 있어요"),
                    
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: ThymeColor.textSub),
                          const SizedBox(width: 8),
                          Expanded(child: Text("가능한 직원 2명에게 보냈어요 · 먼저 수락한 1명으로 확정", style: TextStyle(fontSize: 12, color: ThymeColor.textSub))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 하단 액션 버튼
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: ThymeColor.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.maybePop(context),
                      child: const Text("어려워요", style: TextStyle(color: ThymeColor.textSub, fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ThymeFinalButton(label: "수락하기", onPressed: () {
                        // 수락 완료 후 홈으로 복귀
                        resetTo(context, const PartTimerHomePage());
                      }),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonRow(String text) {
    return Row(
      children: [
        const Icon(Icons.check, size: 18, color: ThymeColor.text),
        const SizedBox(width: 8),
        Text(text, style: TextStyle(fontSize: 14, color: ThymeColor.charcoal)),
      ],
    );
  }
}