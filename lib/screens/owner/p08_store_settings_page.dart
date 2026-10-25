import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_owner_header.dart';
import '../../widgets/thyme_owner_tab_bar.dart';
import 'm01_worker_approval_page.dart';
import 'o03_store_shift_setup_page.dart';
import 'o04_curation_page.dart';
import 'o05_labor_law_page.dart';
import 'p07_worker_list_page.dart';
import 'p09_open_shift_post_page.dart';

/// 설정 메뉴 한 줄. [count]는 할 일 수(딥 나이트 숫자 배지), [value]는 현재 설정값(회색 글자)
class _MenuItem {
  const _MenuItem(this.label, {this.value, this.count, this.page});

  final String label;
  final String? value;
  final int? count;
  final Widget Function()? page;
}

/// P08 매장 설정. 근무 규칙 · 사람 · 계정
class StoreSettingsPage extends StatelessWidget {
  const StoreSettingsPage({super.key});

  static final _sections = <(String, List<_MenuItem>)>[
    ("근무 규칙", [
      const _MenuItem("매장 정보 · 업종 · 주기"),
      _MenuItem("교대 시간대 · 인원", value: "3개", page: () => const StoreShiftSetupPage()),
      _MenuItem("리테일 큐레이션", count: 1, page: () => const CurationPage()),
      _MenuItem("노동법 한도 · 수당", value: "5인 이상", page: () => const LaborLawPage()),
    ]),
    ("사람", [
      _MenuItem("근무자 목록 · 직원/알바", page: () => const WorkerListPage()),
      _MenuItem("가입 · 연차 승인", count: 3, page: () => const WorkerApprovalPage()),
      const _MenuItem("공지 · 업무 작성"), // P05 부수 서비스(X)
      _MenuItem("빈 근무 게시판", count: 3, page: () => const OpenShiftPostPage()),
      const _MenuItem("기록 · 명세서 · 서류", count: 2), // P10 부수 서비스(X)
    ]),
    ("계정", [
      const _MenuItem("구독 · 요금제", value: "베이직"),
      const _MenuItem("근로자 역할도 쓰기"),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: Column(
        children: [
          ThymeOwnerHeader(title: "매장", child: _buildStoreCard(context)),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                for (final (title, items) in _sections) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 20, 8, 10),
                    child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
                  ),
                  Container(
                    decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(18)),
                    child: Column(
                      children: [
                        for (var i = 0; i < items.length; i++) ...[
                          if (i > 0) const Divider(indent: 16, endIndent: 16),
                          _buildRow(context, items[i]),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ThymeOwnerTabBar(current: OwnerTab.store),
    );
  }

  // 매장 이름·요금제 + 매장 코드 (어두운 배경 위 금액·코드 = 민트)
  Widget _buildStoreCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ThymeColor.indigoSurface, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("구시대 커피 광운대점", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.onPrimary)),
                SizedBox(height: 4),
                Text("베이직 · 월 2,900원 · 다음 결제 12/1", style: TextStyle(fontSize: 13, color: ThymeColor.onPrimarySub)),
              ],
            ),
          ),
          Text("NLXAYE", style: ThymeTheme.mono(context, size: 18, color: ThymeColor.accent)),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, _MenuItem item) {
    return InkWell(
      onTap: item.page == null ? null : () => Navigator.push(context, MaterialPageRoute(builder: (_) => item.page!())),
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            Expanded(child: Text(item.label, style: const TextStyle(fontSize: 15, color: ThymeColor.text))),
            if (item.value != null)
              Text(item.value!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
            // 메뉴의 할 일 수 = 경보가 아니라 딥 나이트 숫자 배지 (가이드 1-1)
            if (item.count != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(color: ThymeColor.primary, borderRadius: BorderRadius.circular(99)),
                child: Text("${item.count}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ThymeColor.onPrimary)),
              ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: item.page == null ? ThymeColor.border : ThymeColor.icon),
          ],
        ),
      ),
    );
  }
}
