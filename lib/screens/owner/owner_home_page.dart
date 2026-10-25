import 'package:flutter/material.dart';
import '../../core/theme.dart';

class OwnerHomePage extends StatelessWidget {
  const OwnerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              "구시대 커피 광운대점",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.deepNight),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: Colors.grey.shade600),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: ThymeColor.deepNight),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [1] 상단 요약 (인건비 및 직원 수)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThymeColor.deepNight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("이번 주", style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                      Text("직원 7명 〉", style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text("₩1,640,000", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // [2] 긴급 알림 및 승인 대기
            _buildAlertTile(
              icon: Icons.warning_amber_rounded,
              title: "마감 17~22시 결원 1 · 대타 응답 대기",
              subtitle: "긴급",
              isUrgent: true,
            ),
            const SizedBox(height: 12),
            _buildAlertTile(
              icon: Icons.checklist,
              title: "승인할 것 2 · 가입 2 · 연차 1",
              subtitle: "처리 필요",
              isUrgent: false,
            ),
            const SizedBox(height: 12),
            _buildAlertTile(
              icon: Icons.calendar_today,
              title: "다음 달 희망 제출 M-7 · 마감 D-7",
              subtitle: "근무표 만들기",
              isUrgent: false,
            ),
            
            const SizedBox(height: 32),

            // [3] 오늘 교대별 인원 현황
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("오늘 11/20(금) 교대별", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                Text("명단 보기 〉", style: TextStyle(fontSize: 12, color: ThymeColor.textGrey)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThymeColor.neutralBase,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildShiftRow("오픈", "09:00~14:00", 1, 1),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Colors.white),
                  ),
                  _buildShiftRow("미들", "14:00~18:00", 2, 2),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: Colors.white),
                  ),
                  _buildShiftRow("마감", "18:00~22:00", 1, 2, isShort: true),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // [4] 출퇴근 기록 체크
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("지금 입력 체크하기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ThymeColor.deepNight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text("+ 기록", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text("10:30 현재", style: TextStyle(fontSize: 12, color: ThymeColor.textGrey)),
                const SizedBox(width: 12),
                Text("김남용 08:58", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ThymeColor.mint.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text("출근", style: TextStyle(fontSize: 10, color: ThymeColor.deepNight, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ],
        ),
      ),

      // 하단 네비게이션 바
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: ThymeColor.deepNight,
        unselectedItemColor: Colors.grey.shade400,
        showUnselectedLabels: true,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: "홈"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "근무표"),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: "직원"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "공지·업무"),
          BottomNavigationBarItem(icon: Icon(Icons.storefront), label: "매장"),
        ],
      ),
    );
  }

  // 알림 타일 공통 위젯
  Widget _buildAlertTile({required IconData icon, required String title, required String subtitle, required bool isUrgent}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUrgent ? ThymeColor.rose.withValues(alpha: 0.05) : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUrgent ? ThymeColor.rose.withValues(alpha: 0.3) : Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: isUrgent ? ThymeColor.rose : ThymeColor.deepNight, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isUrgent ? ThymeColor.rose : ThymeColor.deepNight)),
          ),
          Text(subtitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isUrgent ? ThymeColor.rose : ThymeColor.textGrey)),
        ],
      ),
    );
  }

  // 오늘 교대 현황 한 줄 위젯
  Widget _buildShiftRow(String name, String time, int current, int total, {bool isShort = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
            ),
            const SizedBox(width: 12),
            Text(time, style: TextStyle(fontSize: 13, color: ThymeColor.textGrey)),
          ],
        ),
        Text(
          "$current / $total",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isShort ? ThymeColor.rose : ThymeColor.deepNight, // 결원이면 경고색
          ),
        ),
      ],
    );
  }
}