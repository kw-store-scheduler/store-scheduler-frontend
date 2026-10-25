import 'package:flutter/material.dart';
import '../../core/theme.dart';

class WorkerHomePage extends StatelessWidget {
  const WorkerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("구시대 커피 광운대점 · 알바", style: TextStyle(fontSize: 12, color: ThymeColor.textGrey)),
            const SizedBox(height: 2),
            const Text("유나님, 좋은 아침이에요", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: ThymeColor.deepNight),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // [1] 오늘 근무 카드 (메인)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThymeColor.mint.withValues(alpha: 0.2), // 시안의 민트색 배경
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "오늘 11/20(금) · 오픈",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.deepNight),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text("확정", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "09:00~14:00",
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: ThymeColor.deepNight, letterSpacing: -1),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "함께: 지수 · 하준 · 피크에 중국어 단체 손님",
                    style: TextStyle(fontSize: 13, color: ThymeColor.textGrey),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // H12 오늘 못 나가요 진입점
                      GestureDetector(
                        onTap: () {
                          // AbsenceReportPage(H12) 이동
                        },
                        child: const Text(
                          "오늘 못 나가요 〉",
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.rose),
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ThymeColor.deepNight,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          // 출근 체크 로직
                        },
                        child: const Text("출근하기", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // [2] 알림 요약 리스트
            _buildAlertTile(
              icon: Icons.swap_horiz,
              title: "대타 요청이 왔어요",
              subtitle: "오늘 마감 17~22시 · 예상 ₩51,600",
              isUrgent: true,
            ),
            const SizedBox(height: 12),
            _buildAlertTile(
              icon: Icons.calendar_month,
              title: "12월 희망 제출 · 아직 안 냈어요",
              subtitle: "D-7",
              isUrgent: false,
            ),
            const SizedBox(height: 12),
            _buildAlertTile(
              icon: Icons.campaign_outlined,
              title: "새 공지 · 겨울 신메뉴 레시피",
              subtitle: "08:12",
              isUrgent: false,
            ),
            
            const SizedBox(height: 32),

            // [3] 이번 주 일정 요약
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("이번 주", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                Text("전체 근무표 〉", style: TextStyle(fontSize: 12, color: ThymeColor.textGrey)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildDayCircle("16", "월", isActive: true, label: "오픈"),
                _buildDayCircle("17", "화", isActive: false),
                _buildDayCircle("18", "수", isActive: true, label: "마감"),
                _buildDayCircle("19", "목", isActive: true, label: "마감"),
                _buildDayCircle("20", "금", isActive: true, label: "오픈", isToday: true),
                _buildDayCircle("21", "토", isActive: false),
                _buildDayCircle("22", "일", isActive: true, label: "미들"),
              ],
            ),

            const SizedBox(height: 32),

            // [4] 하단 예상 급여 요약
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThymeColor.deepNight,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("11월 예상 급여 · 60.5시간 · 주휴 포함", style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12)),
                      const SizedBox(height: 4),
                      const Text("₩710,016", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text("기록 〉", style: TextStyle(color: Colors.white, fontSize: 13)),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
      
      // 하단 네비게이션 바 (공통 뼈대)
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
          BottomNavigationBarItem(icon: Icon(Icons.sync_alt), label: "대타·교대"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "공지·업무"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "내 정보"),
        ],
      ),
    );
  }

  // 알림 타일 컴포넌트
  Widget _buildAlertTile({required IconData icon, required String title, required String subtitle, required bool isUrgent}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThymeColor.neutralBase,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: isUrgent ? ThymeColor.rose : ThymeColor.deepNight, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                    if (isUrgent) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(color: ThymeColor.rose, shape: BoxShape.circle),
                      )
                    ]
                  ],
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(fontSize: 12, color: isUrgent ? ThymeColor.rose : ThymeColor.textGrey)),
              ],
            ),
          ),
          if (isUrgent)
            const Text("응답 필요", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ThymeColor.rose))
        ],
      ),
    );
  }

  // 주간 캘린더 동그라미 컴포넌트
  Widget _buildDayCircle(String day, String weekday, {bool isActive = false, String? label, bool isToday = false}) {
    return Column(
      children: [
        Text(weekday, style: TextStyle(fontSize: 12, color: isToday ? ThymeColor.deepNight : ThymeColor.textGrey, fontWeight: isToday ? FontWeight.bold : FontWeight.normal)),
        const SizedBox(height: 8),
        Text(day, style: TextStyle(fontSize: 14, color: isToday ? ThymeColor.deepNight : (isActive ? ThymeColor.deepNight : Colors.grey.shade300), fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (isActive && label != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: ThymeColor.mint.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(label, style: const TextStyle(fontSize: 10, color: ThymeColor.deepNight, fontWeight: FontWeight.bold)),
          )
        else if (!isActive)
          const SizedBox(height: 16),
      ],
    );
  }
}