import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_owner_header.dart';
import '../../widgets/thyme_owner_tab_bar.dart';

/// 빈 근무 지원자 (백엔드 GET /open-shifts/{id}/applications: 이번 달 추가 근무가 적은 순)
class _Applicant {
  const _Applicant(this.name, this.badge, this.detail, this.weeklyHours, this.pay, {this.overtime = false});

  final String name;
  final String badge; // 이름 옆 형태·직책 (가이드 4-0)
  final String detail;
  final int weeklyHours;
  final int pay;
  final bool overtime; // 주 40시간 넘어 연장근무 가산
}

/// P09 빈 근무 올리기 · 지원자. 규칙을 통과한 지원자만 보이고 한 명을 골라 확정한다
class OpenShiftPostPage extends StatefulWidget {
  const OpenShiftPostPage({super.key});

  @override
  State<OpenShiftPostPage> createState() => _OpenShiftPostPageState();
}

class _OpenShiftPostPageState extends State<OpenShiftPostPage> {
  static const _applicants = [
    _Applicant("김유나", "알바", "응대 중 · 이번 달 추가 근무 0회", 22, 51600),
    _Applicant("이서준", "알바", "응대 상 · 이번 달 추가 근무 2회", 26, 51600),
    _Applicant("박지호", "직원 · 주니어", "응대 상 · 주 40h 넘어 연장근무", 40, 77400, overtime: true),
  ];

  int _selected = 0;

  static String _won(int v) => "₩${v.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ',')}";

  void _confirm() {
    // POST /open-shifts/{id}/applications/{applicationId}/approve 연결할 자리
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${_applicants[_selected].name} 님으로 확정했어요")));
    Navigator.maybePop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: Column(
        children: [
          ThymeOwnerHeader(title: "빈 근무 올리기", showBack: true, child: _buildShiftCard(context)),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("지원자 ${_applicants.length}명", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                      const Text("엔진 추천 순 · 규칙 통과만", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < _applicants.length; i++) ...[
                    _buildApplicant(context, i),
                    const SizedBox(height: 10),
                  ],
                  // 안내 = 페리윙클 배너
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: ThymeColor.infoBg, borderRadius: BorderRadius.circular(14)),
                    child: const Text(
                      "이번 달 추가 근무가 적은 사람이 위로 와요. 한 사람에게 몰리지 않게.",
                      style: TextStyle(fontSize: 13, color: ThymeColor.infoText, height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _confirm, child: Text("${_applicants[_selected].name} 님으로 확정")),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const ThymeOwnerTabBar(current: OwnerTab.substitute),
    );
  }

  // 결원 근무 요약 (딥 나이트 띠 안의 인디고 카드)
  Widget _buildShiftCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ThymeColor.indigoSurface, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.circle, size: 8, color: ThymeColor.danger),
            SizedBox(width: 6),
            Text("결원", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.onPrimary)),
            SizedBox(width: 8),
            Text("11/25(수) · 민호 개인 사정", style: TextStyle(fontSize: 13, color: ThymeColor.onPrimarySub)),
          ]),
          const SizedBox(height: 8),
          Text("17:00–22:00", style: ThymeTheme.mono(context, size: 26, color: ThymeColor.onPrimary)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final label in const ["응대 중 이상", "1명", "지원 마감 11/24 18:00"])
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: ThymeColor.primary, borderRadius: BorderRadius.circular(99)),
                  child: Text(label, style: const TextStyle(fontSize: 12, color: ThymeColor.onPrimarySub)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildApplicant(BuildContext context, int i) {
    final a = _applicants[i];
    final selected = i == _selected;
    return GestureDetector(
      onTap: () => setState(() => _selected = i),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: ThymeColor.surface,
          borderRadius: BorderRadius.circular(18),
          // 선택 = 딥 나이트 (가이드 4-3)
          border: Border.all(color: selected ? ThymeColor.primary : Colors.transparent, width: 2),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: selected ? ThymeColor.primary : ThymeColor.selectedSoft,
              child: Text(a.name.substring(1, 2),
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: selected ? ThymeColor.onPrimary : ThymeColor.text)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(a.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: ThymeColor.selectedSoft, borderRadius: BorderRadius.circular(99)),
                      child: Text(a.badge, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ThymeColor.charcoal)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(a.detail, style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("주 ${a.weeklyHours}h", style: ThymeTheme.mono(context, size: 15)),
                const SizedBox(height: 4),
                // 연장근무 가산은 행동이 필요한 비용 → 로즈 글자
                Text("+${_won(a.pay)}", style: TextStyle(fontSize: 13, color: a.overtime ? ThymeColor.dangerText : ThymeColor.textSub)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
