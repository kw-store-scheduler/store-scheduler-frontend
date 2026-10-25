import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import 'p01_owner_home_page.dart'; // 행님의 점주 홈 화면으로 완벽 귀환!

class RegistrationCompletePage extends StatelessWidget {
  const RegistrationCompletePage({super.key});

  @override
  Widget build(BuildContext context) {
    // 방금 등록한 매장 (시연 중이면 시안 값)
    final store = Session.instance.currentOwnedStore;
    final storeName = store?.name ?? "구시대 커피 광운대점";
    final storeCode = store?.storeCode ?? "NLXAYE";
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),

              // 나뭇잎(Thyme) 아이콘
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: ThymeColor.successBg,
                  shape: BoxShape.circle
                ),
                child: const Icon(Icons.eco, size: 40, color: ThymeColor.successText),
              ),
              const SizedBox(height: 24),

              const Text(
                "OWNER · 매장 등록 완료",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ThymeColor.textSub)
              ),
              const SizedBox(height: 8),
              Text(
                "$storeName이\n준비됐어요",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ThymeColor.text, height: 1.3)
              ),
              const SizedBox(height: 12),
              Text(
                "이제 직원들을 초대하면 희망 제출이 시작돼요.",
                style: TextStyle(fontSize: 15, color: ThymeColor.textSub)
              ),
              const SizedBox(height: 40),

              // 매장 코드 박스
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: ThymeColor.text,
                  borderRadius: BorderRadius.circular(16)
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("매장 코드", style: TextStyle(color: ThymeColor.onPrimarySub, fontSize: 13)),
                    const SizedBox(height: 8),
                    Text(
                      storeCode,
                      style: const TextStyle(color: ThymeColor.onPrimary, fontSize: 32, letterSpacing: 4.0, fontWeight: FontWeight.w900)
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        // 초대 링크는 서버에 없어서 매장 코드를 복사한다 (근로자는 J01에 코드를 넣는다)
                        Expanded(
                          child: GestureDetector(
                            onTap: () async {
                              await Clipboard.setData(ClipboardData(text: storeCode));
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("매장 코드를 복사했어요")));
                              }
                            },
                            child: _buildActionBtn(Icons.copy, "코드 복사"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: _buildActionBtn(Icons.chat_bubble_outline, "메시지 공유")),
                        const SizedBox(width: 8),
                        Expanded(child: _buildActionBtn(Icons.qr_code, "QR 보기")),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // 요약 리스트
              _buildSummaryRow(Icons.access_time, "교대 시간대 3개", "오픈 · 미들 · 마감"),
              const SizedBox(height: 16),
              _buildSummaryRow(Icons.gavel, "노동법 한도 · 수당 자동", "5인 이상"),
              const SizedBox(height: 16),
              _buildSummaryRow(Icons.tune, "리테일 큐레이션", "나중에 하드 제약"),

              const Spacer(),

              // 하단 홈으로 버튼
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: () {
                    // 점주 대시보드로 싹 갈아엎으면서 이동! (주석 절대 없음!)
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const OwnerHomePage()),
                      (route) => false,
                    );
                  }, child: Text("매장 홈으로")),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionBtn(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: ThymeColor.surface.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8)
      ),
      child: Column(
        children: [
          Icon(icon, color: ThymeColor.onPrimary, size: 20),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: ThymeColor.onPrimary, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(IconData icon, String title, String trailing) {
    return Row(
      children: [
        Icon(icon, size: 20, color: ThymeColor.successText),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text))
        ),
        Text(trailing, style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
      ],
    );
  }
}