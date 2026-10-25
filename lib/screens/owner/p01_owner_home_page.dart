import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/thyme_owner_tab_bar.dart';
import 'm01_worker_approval_page.dart';
import 'm03_skill_matching_page.dart';
import 'p03_generating_schedule_page.dart';
import 'p06_substitute_manage_page.dart';
import 'p07_worker_list_page.dart';

class OwnerHomePage extends StatelessWidget {
  const OwnerHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: AppBar(
        backgroundColor: ThymeColor.bg,
        elevation: 0,
        title: Row(
          children: [
            const Text(
              "구시대 커피 광운대점",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text),
            ),
            const SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: ThymeColor.textSub),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: ThymeColor.text),
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
                color: ThymeColor.text,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("이번 주", style: TextStyle(color: ThymeColor.onPrimary.withValues(alpha: 0.7), fontSize: 13)),
                      GestureDetector(
                        onTap: () => _push(context, const WorkerListPage()),
                        child: Text("직원 7명 〉", style: TextStyle(color: ThymeColor.onPrimary.withValues(alpha: 0.7), fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text("₩1,640,000", style: TextStyle(color: ThymeColor.onPrimary, fontSize: 32, fontWeight: FontWeight.bold)),
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
              onTap: () => _push(context, const SubstituteManagePage()),
            ),
            const SizedBox(height: 12),
            _buildAlertTile(
              icon: Icons.checklist,
              title: "승인할 것 2 · 가입 2 · 연차 1",
              subtitle: "처리 필요",
              isUrgent: false,
              onTap: () => _push(context, const WorkerApprovalPage()),
            ),
            const SizedBox(height: 12),
            _buildAlertTile(
              icon: Icons.calendar_today,
              title: "다음 달 희망 제출 M-7 · 마감 D-7",
              subtitle: "근무표 만들기",
              isUrgent: false,
              onTap: () => _push(context, const GeneratingSchedulePage()),
            ),
            
            const SizedBox(height: 32),

            // [3] 오늘 교대별 인원 현황
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("오늘 11/20(금) 교대별", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                GestureDetector(
                  onTap: () => _push(context, const SkillMatchingPage()),
                  child: Text("명단 보기 〉", style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ThymeColor.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildShiftRow("오픈", "09:00~14:00", 1, 1),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: ThymeColor.surface),
                  ),
                  _buildShiftRow("미들", "14:00~18:00", 2, 2),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Divider(height: 1, color: ThymeColor.surface),
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
                const Text("지금 입력 체크하기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: ThymeColor.text,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text("+ 기록", style: TextStyle(color: ThymeColor.onPrimary, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text("10:30 현재", style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
                const SizedBox(width: 12),
                Text("김남용 08:58", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: ThymeColor.accent.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text("출근", style: TextStyle(fontSize: 10, color: ThymeColor.text, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ],
        ),
      ),

      // 점주 하단 탭 (가이드 4-0)
      bottomNavigationBar: const ThymeOwnerTabBar(current: OwnerTab.home),
    );
  }

  static void _push(BuildContext context, Widget page) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  // 알림 타일 공통 위젯
  Widget _buildAlertTile({required IconData icon, required String title, required String subtitle, required bool isUrgent, VoidCallback? onTap}) {
    final tile = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUrgent ? ThymeColor.danger.withValues(alpha: 0.05) : ThymeColor.surfaceSub,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUrgent ? ThymeColor.danger.withValues(alpha: 0.3) : ThymeColor.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: isUrgent ? ThymeColor.dangerText : ThymeColor.text, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isUrgent ? ThymeColor.dangerText : ThymeColor.text)),
          ),
          Text(subtitle, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isUrgent ? ThymeColor.dangerText : ThymeColor.textSub)),
        ],
      ),
    );
    return onTap == null ? tile : GestureDetector(onTap: onTap, child: tile);
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
              child: Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            ),
            const SizedBox(width: 12),
            Text(time, style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
          ],
        ),
        Text(
          "$current / $total",
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isShort ? ThymeColor.dangerText : ThymeColor.text, // 결원 글자 = dangerText (로즈 원색은 글자 X)
          ),
        ),
      ],
    );
  }
}