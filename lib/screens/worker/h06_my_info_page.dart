import 'package:flutter/material.dart';
import '../../core/home_router.dart';
import '../../core/theme.dart';
import '../../widgets/thyme_worker_tab_bar.dart';
import 'j01_store_code_page.dart';             // 다른 매장 추가
// 행님이 이미 깎아두신 화면들 실전 임포트!
import 'w10_preference_report_page.dart';      // 희망 반영 리포트
import 'w11_fixed_schedule_page.dart';         // 고정 일정/역량
import '../../core/session.dart';
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
                          onPressed: () => _soon(context, "프로필 수정"),
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
                    ),
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
                      leading: const Icon(Icons.add, color: ThymeColor.textSub),
                      title: const Text("다른 매장 추가", style: TextStyle(fontSize: 15, color: ThymeColor.textSub)),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreCodePage())),
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
                    // 화면이 없는 메뉴(null)는 홈을 한 장 더 쌓지 않고 '준비 중' 안내만 띄운다
                    _buildMenuRow(context, "근무 기록 · 정정", "", null),
                    _buildMenuRow(context, "서류함 · 임금명세서", "", null),
                    _buildMenuRow(context, "고정 일정 · 역량", "", const FixedSchedulePage()), // 행님 파일로!
                    _buildMenuRow(context, "희망 반영 리포트", "", const PreferenceReportPage()), // 행님 파일로!
                    _buildMenuRow(context, "알림 설정", "", null),
                    // 점주 역할 추가: 매장에 합류한 계정은 서버가 역할 변경을 막는다 (PATCH /users/me/role)
                    _buildMenuRow(context, "점주 역할 추가", "", null),
                    _buildMenuRow(context, "고객센터 · 약관", "", null),
                  ],
                ),
              ),

              // 로그아웃
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: InkWell(
                  onTap: () async {
                    // 저장된 로그인까지 지워야 새로고침해도 다시 로그인되지 않는다
                    await Session.instance.logout();
                    if (!context.mounted) return;
                    resetTo(context, const LoginPage());
                  },
                  child: const Text("로그아웃", style: TextStyle(fontSize: 14, color: ThymeColor.textSub, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
      
      // 근로자 공통 하단 탭 (가이드 4-0)
      bottomNavigationBar: const ThymeWorkerTabBar(current: WorkerTab.me),
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

  Widget _buildMenuRow(BuildContext context, String title, String trailingText, Widget? targetPage) {
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
        if (targetPage == null) return _soon(context, title);
        Navigator.push(context, MaterialPageRoute(builder: (context) => targetPage));
      },
    );
  }

  void _soon(BuildContext context, String what) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$what은(는) 준비 중이에요")));
}