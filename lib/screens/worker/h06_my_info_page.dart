import 'package:flutter/material.dart';
import '../../core/theme.dart';
// 행님이 이미 깎아두신 화면들 실전 임포트!
import 'h01_part_timer_home_page.dart';            // 홈으로 이동
import 'w10_preference_report_page.dart';      // 희망 반영 리포트
import 'w11_fixed_schedule_page.dart';         // 고정 일정/역량
import '../common/a06_role_selection_page.dart';// 점주 역할 추가
import '../common/a03_login_page.dart';        // 로그아웃

class MyInfoPage extends StatelessWidget {
  const MyInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg, // 라일락 그레이 바탕 위에 흰 카드
      appBar: AppBar(
        backgroundColor: ThymeColor.bg,
        elevation: 0,
        title: const Text("내 정보", style: TextStyle(color: ThymeColor.text, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // 프로필 및 요약 카드
              Container(
                color: ThymeColor.surface,
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: ThymeColor.border,
                          child: const Text("유", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("김유나", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                              const SizedBox(height: 4),
                              Text("알바 · 9/1 입사    ₩10,320/h", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {}, 
                          child: const Text("수정", style: TextStyle(color: ThymeColor.textSub, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    
                    // 스탯 박스
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: ThymeColor.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ThymeColor.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildStatItem("11월 근무", "10일"),
                          Container(width: 1, height: 40, color: ThymeColor.border),
                          _buildStatItem("누적 시간", "47h"),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(color: ThymeColor.text, borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: const [
                                Text("예상 급여", style: TextStyle(fontSize: 11, color: ThymeColor.onPrimarySub)),
                                SizedBox(height: 2),
                                Text("₩485,040", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.onPrimary)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),

              // 내 매장 관리
              Ink( // ListTile 물결이 보이도록 Container 대신 Ink
                color: ThymeColor.surface,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(padding: EdgeInsets.symmetric(horizontal: 24), child: Text("내 매장", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.textSub))),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      leading: const Icon(Icons.storefront_outlined, color: ThymeColor.text),
                      title: const Text("구시대 커피 광운대점", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                      trailing: const Text("직원 보는 중", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                      onTap: () {},
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      leading: const Icon(Icons.add, color: ThymeColor.textSub),
                      title: const Text("다른 매장 추가", style: TextStyle(fontSize: 15, color: ThymeColor.textSub)),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 8),

              // 메뉴 리스트
              Ink(
                color: ThymeColor.surface,
                child: Column(
                  children: [
                    _buildMenuRow(context, "근무 기록 · 정정", "확인 필요 2", const PartTimerHomePage()), // 일단 홈으로
                    _buildMenuRow(context, "서류함 · 임금명세서", "보건증 D-12", const PartTimerHomePage()),
                    _buildMenuRow(context, "고정 일정 · 역량", "수정 2건", const FixedSchedulePage()), // 행님 파일로!
                    _buildMenuRow(context, "희망 반영 리포트", "10/10", const PreferenceReportPage()), // 행님 파일로!
                    _buildMenuRow(context, "알림 설정", "켜짐", const PartTimerHomePage()),
                    _buildMenuRow(context, "점주 역할 추가", "", const RoleSelectionPage()), // 행님 파일로!
                    _buildMenuRow(context, "고객센터 · 약관", "", const PartTimerHomePage()),
                  ],
                ),
              ),

              // 로그아웃
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: InkWell(
                  onTap: () {
                    // 로그인 페이지로 날려버림!
                    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => const LoginPage()), (route) => false);
                  },
                  child: const Text("로그아웃", style: TextStyle(fontSize: 14, color: ThymeColor.textSub, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
      
      // 기획서 시안 그대로 하단 네비게이션 바 적용[cite: 5]
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        selectedItemColor: ThymeColor.text,
        unselectedItemColor: ThymeColor.disabled,
        currentIndex: 3, // 내 정보 탭 활성화
        selectedFontSize: 11,
        unselectedFontSize: 11,
        onTap: (index) {
          if (index == 0) Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const PartTimerHomePage()));
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: "근무표"),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: "대타·교대"),
          BottomNavigationBarItem(icon: Icon(Icons.edit_document), label: "희망 제출"),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: "내 정보"),
        ],
      ),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: ThymeColor.textSub)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
      ],
    );
  }

  Widget _buildMenuRow(BuildContext context, String title, String trailingText, Widget targetPage) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      title: Text(title, style: const TextStyle(fontSize: 15, color: ThymeColor.text)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailingText.isNotEmpty) 
            Text(trailingText, style: TextStyle(fontSize: 13, color: ThymeColor.textSub, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Icon(Icons.chevron_right, size: 20, color: ThymeColor.disabled),
        ],
      ),
      onTap: () {
        // 주석 따위 없음! 네비게이션 직행!
        Navigator.push(context, MaterialPageRoute(builder: (context) => targetPage));
      },
    );
  }
}