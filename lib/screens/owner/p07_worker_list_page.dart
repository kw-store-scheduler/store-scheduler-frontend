import 'package:flutter/material.dart';
import '../../core/theme.dart';
// 행님이 이미 깎아두신 화면 & 다음 화면 임포트!
import 'm01_worker_approval_page.dart'; 
import 'p11_worker_profile_confirm_page.dart'; 
import 'p01_owner_home_page.dart';

class WorkerListPage extends StatelessWidget {
  const WorkerListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: AppBar(
        backgroundColor: ThymeColor.bg,
        elevation: 0,
        title: const Text("근무자 7명", style: TextStyle(color: ThymeColor.text, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              style: TextButton.styleFrom(
                backgroundColor: ThymeColor.surfaceSub,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              onPressed: () {
                // 행님이 만드신 승인 화면(M01)으로 촥!
                Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkerApprovalPage()));
              },
              child: const Text("승인 대기 2", style: TextStyle(color: ThymeColor.text, fontWeight: FontWeight.bold, fontSize: 13)),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 상단 탭 (UI)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
              child: Row(
                children: [
                  _buildTab("전체 7", true),
                  const SizedBox(width: 8),
                  _buildTab("직원 2", false),
                  const SizedBox(width: 8),
                  _buildTab("알바 5", false),
                ],
              ),
            ),
            const Divider(),
            
            // 근무자 리스트
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                children: [
                  _buildWorkerRow(context, "지", "지수", "직원 · 매니저", "이번 달 30h", "오픈 09~14", true),
                  _buildWorkerRow(context, "서", "서연", "직원 · 시니어", "이번 달 14h", "수업 13~22", true),
                  _buildWorkerRow(context, "하", "하준", "알바", "이번 달 36h", "오픈 09~14", true),
                  _buildWorkerRow(context, "유", "김유나", "알바", "이번 달 58.5h", "오픈 09~14", false, hasPending: true),
                  _buildWorkerRow(context, "인", "민호", "알바", "이번 달 86h", "마감 17~22 · 거의 꽉참", true),
                  _buildWorkerRow(context, "도", "도윤", "알바 · 신입", "이번 달 46h", "마감", true),
                ],
              ),
            ),
          ],
        ),
      ),
      
      // 점주용 하단 네비게이션 바
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: ThymeColor.text,
        unselectedItemColor: ThymeColor.disabled,
        currentIndex: 4, // '근무자' 탭 활성화
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const OwnerHomePage()));
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "홈"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: "근무표"),
          BottomNavigationBarItem(icon: Icon(Icons.swap_horiz), label: "대타"),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: "인건비"),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: "근무자"),
        ],
      ),
    );
  }

  Widget _buildTab(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? ThymeColor.text : ThymeColor.surface,
        border: Border.all(color: isSelected ? ThymeColor.text : ThymeColor.border),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? ThymeColor.onPrimary : ThymeColor.textSub)),
    );
  }

  Widget _buildWorkerRow(BuildContext context, String initial, String name, String role, String hours, String desc, bool isSubmitted, {bool hasPending = false}) {
    return InkWell(
      onTap: () {
        // 개별 프로필 (P11) 화면으로 이동!
        Navigator.push(context, MaterialPageRoute(builder: (context) => const WorkerProfileConfirmPage()));
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: Row(
          children: [
            CircleAvatar(radius: 20, backgroundColor: ThymeColor.border, child: Text(initial, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.textSub))),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                      const SizedBox(width: 6),
                      Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: ThymeColor.border, borderRadius: BorderRadius.circular(4)), child: Text(role, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ThymeColor.charcoal))),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(hours, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.circle, size: 8, color: hasPending ? ThymeColor.warn : ThymeColor.accent),
                    const SizedBox(width: 4),
                    Text(hasPending ? "미제출" : "제출", style: TextStyle(fontSize: 12, color: hasPending ? ThymeColor.warnText : ThymeColor.successText)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}