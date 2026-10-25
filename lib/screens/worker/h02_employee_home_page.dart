import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../theme/thyme_theme.dart';
import '../owner/p06_substitute_manage_page.dart';
import 'h04_notification_page.dart';
import 'h06_my_info_page.dart';
import 'h12_absence_report_page.dart';
import 'w07_my_schedule_page.dart';

/// H02 직원 홈. 이번 주 근무시간, 남은 연차, 오늘 결원, 오픈·마감 업무 체크리스트 (가이드 4-0 직원 vs 알바)
class EmployeeHomePage extends StatefulWidget {
  const EmployeeHomePage({super.key});

  @override
  State<EmployeeHomePage> createState() => _EmployeeHomePageState();
}

class _EmployeeHomePageState extends State<EmployeeHomePage> {
  // [임시 데이터] 오늘 오픈 업무 (백엔드 GET /tasks/my 로 바꿀 자리)
  final List<(String, bool)> _tasks = [
    ("POS 시재 확인", true),
    ("원두 입고 확인", true),
    ("냉장고 온도 기록", false),
    ("겨울 신메뉴 POP 붙이기", false),
  ];

  @override
  Widget build(BuildContext context) {
    final done = _tasks.where((t) => t.$2).length;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 인사 + 알림
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("구시대 커피 광운대점 · 직원 · 매니저", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                        SizedBox(height: 4),
                        Text("지수님, 오늘 오픈 책임이에요", style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                      ],
                    ),
                  ),
                  _buildBell(context),
                ],
              ),
              const SizedBox(height: 16),

              // [1] 오늘 근무 (민트 카드)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: ThymeColor.accent, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("오늘 11/20(금) · 오픈~피크", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.onAccent)),
                          const SizedBox(height: 4),
                          Text("09:00–18:00", style: ThymeTheme.mono(context, size: 28, color: ThymeColor.onAccent)),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AbsenceReportPage())),
                            child: const Text(
                              "오늘 못 나가요 ›",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.onAccent, decoration: TextDecoration.underline),
                            ),
                          ),
                        ],
                      ),
                    ),
                    FilledButton(
                      style: FilledButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 18)),
                      onPressed: () {}, // H05 출근 체크는 부수 서비스(X) 범위 밖
                      child: const Text("출근하기"),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // [2] 이번 주 근무 · 남은 연차
              Container(
                decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(18)),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      Expanded(child: _buildWeekHours(context, worked: 32, contract: 40)),
                      const VerticalDivider(width: 1, color: ThymeColor.border),
                      Expanded(child: _buildLeft(context)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // [3] 오늘 결원 (화면에서 가장 급한 카드 1장만 rose-50)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: ThymeColor.dangerBg, borderRadius: BorderRadius.circular(18)),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("오늘 마감 17–22시 결원 1", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                          SizedBox(height: 4),
                          Text("민호 · 대타 2명에게 요청, 아직 응답 없음", style: TextStyle(fontSize: 13, color: ThymeColor.dangerText)),
                        ],
                      ),
                    ),
                    // 매니저 직원은 대타 현황을 보고 승인한다 (P06)
                    FilledButton(
                      style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 14)),
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SubstituteManagePage())),
                      child: const Text("대타 보기", style: TextStyle(fontSize: 14)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // [4] 오늘 오픈 업무 체크리스트
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("오늘 오픈 업무", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                        Text("$done / ${_tasks.length}", style: ThymeTheme.mono(context, size: 14, color: ThymeColor.successText)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    for (var i = 0; i < _tasks.length; i++) _buildTask(i),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      // 직원 하단 탭 (가이드 4-0: 홈 · 근무표 · 연차·교대 · 공지·업무 · 내 정보)
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: ThymeColor.text,
        unselectedItemColor: ThymeColor.disabled,
        showUnselectedLabels: true,
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (i) {
          final page = switch (i) {
            1 => const MySchedulePage(),
            4 => const MyInfoPage(),
            _ => null, // 연차·교대, 공지·업무 탭 화면은 아직 없음
          };
          if (page != null) Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "홈"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "근무표"),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: "연차·교대"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "공지·업무"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "내 정보"),
        ],
      ),
    );
  }

  Widget _buildBell(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationPage())),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(14)),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.notifications_none, color: ThymeColor.text),
            // 안 읽은 알림 = 로즈 점
            Positioned(
              top: 10,
              right: 10,
              child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: ThymeColor.danger, shape: BoxShape.circle)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeekHours(BuildContext context, {required int worked, required int contract}) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("이번 주 근무", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
          const SizedBox(height: 10),
          Text.rich(TextSpan(children: [
            TextSpan(text: "$worked", style: ThymeTheme.mono(context, size: 22)),
            TextSpan(text: " / ${contract}h", style: ThymeTheme.mono(context, size: 14, color: ThymeColor.textSub)),
          ])),
          const SizedBox(height: 10),
          // 진행 = 페리윙클 (남은 칸 peri-100)
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: worked / contract,
              minHeight: 6,
              color: ThymeColor.info,
              backgroundColor: ThymeColor.infoBg,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeft(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("남은 연차", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
          const SizedBox(height: 10),
          Text.rich(TextSpan(children: [
            TextSpan(text: "11", style: ThymeTheme.mono(context, size: 22)),
            const TextSpan(text: "일", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
          ])),
          const SizedBox(height: 6),
          // 상태 = 원색 점 + 딥 글자
          const Row(
            children: [
              Icon(Icons.circle, size: 8, color: ThymeColor.accent),
              SizedBox(width: 6),
              Text("11/13 승인됨", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ThymeColor.successText)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTask(int i) {
    final (label, checked) = _tasks[i];
    return InkWell(
      onTap: () => setState(() => _tasks[i] = (label, !checked)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: checked ? ThymeColor.accent : ThymeColor.surface,
                border: Border.all(color: checked ? ThymeColor.accent : ThymeColor.border),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(Icons.check, size: 16, color: checked ? ThymeColor.onAccent : ThymeColor.textSub),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                color: checked ? ThymeColor.textSub : ThymeColor.text,
                decoration: checked ? TextDecoration.lineThrough : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
