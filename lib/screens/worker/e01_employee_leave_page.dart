import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/preference_api.dart';
import '../../core/theme.dart';
import '../../models/preference.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'w04_shift_attitude_page.dart';

/// E01 직원 연차·휴무 (직원 1/3). 여기서 직원용 초안을 만들어 W04 → W14로 넘긴다
class EmployeeLeavePage extends StatefulWidget {
  const EmployeeLeavePage({super.key, this.month});

  /// 신청 대상 달. 생략하면 다음 달
  final DateTime? month;

  @override
  State<EmployeeLeavePage> createState() => _EmployeeLeavePageState();
}

class _EmployeeLeavePageState extends State<EmployeeLeavePage> {
  bool _loading = false;

  late final DateTime _month = widget.month ?? DateTime(DateTime.now().year, DateTime.now().month + 1);

  Future<void> _next() async {
    setState(() => _loading = true);
    final PreferenceDraft draft;
    try {
      // 직원은 지난달 교대 선호를 그대로 불러와 시작한다
      draft = await PreferenceApi().startDraft(_month, fromLastMonth: true, fullTime: true);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => ShiftAttitudePage(draft: draft)));
  }

  // 임시 선택된 날짜와 연차/휴무 상태 데이터 (시연용)
  final List<Map<String, dynamic>> _leaveRequests = [
    {"date": "10월 12일 (목)", "type": "휴무"},
    {"date": "10월 25일 (수)", "type": "연차"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: ThymeStepAppBar(step: 1, total: 3, group: '직원', title: '연차·휴무'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Expanded(
                          child: Text(
                            "쉬고 싶은 날의\n대안을 지정해 주세요",
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ThymeColor.text, height: 1.3),
                          ),
                        ),
                        // 남은 연차 표시
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: ThymeColor.text.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text("잔여 연차: 4.5일", style: TextStyle(color: ThymeColor.text, fontSize: 13, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "지정된 날짜에 휴무가 안 되면 연차 ➔ 반차 순으로 대안을 적용해요.",
                      style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.4),
                    ),
                    const SizedBox(height: 32),

                    // 추가 버튼 (달력 띄우는 용도)
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(color: ThymeColor.border),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          // 날짜 선택 캘린더 바텀시트 띄우기
                        },
                        icon: const Icon(Icons.add, color: ThymeColor.text, size: 20),
                        label: const Text("쉬는 날 추가하기", style: TextStyle(color: ThymeColor.text, fontSize: 15, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // 선택된 휴무/연차 리스트
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _leaveRequests.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final req = _leaveRequests[index];
                        return _buildLeaveCard(req['date'], req['type']);
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // 하단 다음 버튼
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _loading ? null : _next, child: Text(_loading ? "불러오는 중…" : "다음 · 교대 선호")),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 연차/휴무 카드 위젯
  Widget _buildLeaveCard(String date, String currentType) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: ThymeColor.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            date,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: ThymeColor.surfaceSub,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Text(
                  currentType,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text),
                ),
                const SizedBox(width: 4),
                Icon(Icons.keyboard_arrow_down, size: 16, color: ThymeColor.textSub),
              ],
            ),
          ),
        ],
      ),
    );
  }
}