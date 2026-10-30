import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/preference_api.dart';
import '../../core/theme.dart';
import '../../models/preference.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'w11_fixed_schedule_page.dart'; // 다음 화면 임포트

/// W00 신청 시작 (1/7). 여기서 만든 초안을 W14까지 넘겨서 채운다
class LoadLastMonthPage extends StatefulWidget {
  const LoadLastMonthPage({super.key, this.month});

  /// 신청 대상 달. 생략하면 다음 달
  final DateTime? month;

  @override
  State<LoadLastMonthPage> createState() => _LoadLastMonthPageState();
}

class _LoadLastMonthPageState extends State<LoadLastMonthPage> {
  int _selectedValue = 1;
  bool _loading = false;

  late final DateTime _month = widget.month ?? DateTime(DateTime.now().year, DateTime.now().month + 1);

  /// 서버에서 그달 칸과 (고르면) 지난달 답을 받아 초안을 만든다
  Future<void> _start() async {
    setState(() => _loading = true);
    final PreferenceDraft draft;
    try {
      draft = await PreferenceApi().startDraft(_month, fromLastMonth: _selectedValue == 1);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    if (!mounted) return;
    if (_selectedValue == 1 && !draft.loadedPrevious) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("지난달에 낸 희망이 없어서 처음부터 써요.")));
    }
    Navigator.push(context, MaterialPageRoute(builder: (context) => FixedSchedulePage(draft: draft)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: ThymeStepAppBar(step: 1, total: 7, title: '시작', closeIcon: true),
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
                    Text("${_month.month}월 근무 희망", style: TextStyle(color: ThymeColor.textSub, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text("지난달 답을 불러올까요?", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text, height: 1.3)),
                    const SizedBox(height: 12),
                    Text("불러오면 바뀐 것만 고치면 돼요. 단계는 그대로 하나씩 확인해요.", style: TextStyle(fontSize: 15, color: ThymeColor.textSub, height: 1.4)),
                    const SizedBox(height: 32),

                    _buildRadioOption(
                      value: 1,
                      title: "지난달 답 불러오기",
                      subtitle: "추천 · 바뀐 것만 고치면 1분이면 끝나요",
                      isSelected: _selectedValue == 1,
                    ),
                    const SizedBox(height: 12),
                    _buildRadioOption(
                      value: 2,
                      title: "처음부터 새로 쓰기",
                      subtitle: "이번 달에 일정이 많이 바뀌었다면",
                      isSelected: _selectedValue == 2,
                    ),
                    const SizedBox(height: 32),

                    if (_selectedValue == 1)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(16)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("${DateTime(_month.year, _month.month - 1).month}월에 제출한 내용", style: TextStyle(fontWeight: FontWeight.bold, color: ThymeColor.text, fontSize: 15)),
                            const SizedBox(height: 16),
                            _buildSummaryRow("고정 일정", "월·목 10:30~13:30 수업 외 1건"),
                            _buildSummaryRow("날짜·교대", "평일 오픈 선호 · 미들 가능"),
                            _buildSummaryRow("주말", "한 달 2회까지 · 일요일 불가"),
                            _buildSummaryRow("근무량", "계약 주 15~20h · 이번 달 64~86h"),
                            _buildSummaryRow("역량", "중국어 상 · 영어 중 · 캐셔 · 홀"),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _loading ? null : _start, child: Text(_loading ? "불러오는 중…" : "시작하기")),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadioOption({required int value, required String title, required String subtitle, required bool isSelected}) {
    return GestureDetector(
      onTap: () => setState(() => _selectedValue = value),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? ThymeColor.text : ThymeColor.border, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? ThymeColor.text : ThymeColor.disabled),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isSelected ? ThymeColor.text : ThymeColor.text)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 70, child: Text(label, style: TextStyle(color: ThymeColor.textSub, fontSize: 13))),
          Expanded(child: Text(value, style: const TextStyle(color: ThymeColor.text, fontSize: 13, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }
}