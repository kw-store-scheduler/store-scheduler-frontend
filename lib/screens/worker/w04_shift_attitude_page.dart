import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/preference.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'w14_preference_submit_page.dart';

/// W04 직원 교대 선호 (직원 2/3). 가능 시간은 묻지 않고 교대마다 선호/상관없음/피하고 싶음만 받는다
class ShiftAttitudePage extends StatefulWidget {
  const ShiftAttitudePage({super.key, required this.draft});

  final PreferenceDraft draft;

  @override
  State<ShiftAttitudePage> createState() => _ShiftAttitudePageState();
}

class _ShiftAttitudePageState extends State<ShiftAttitudePage> {
  static const _options = [
    (ShiftAttitude.prefer, "선호"),
    (ShiftAttitude.neutral, "상관없음"),
    (ShiftAttitude.avoid, "피하고 싶음"),
  ];

  PreferenceDraft get _draft => widget.draft;
  late final List<ShiftSummary> _shifts = _draft.view!.shifts;

  static String _hm(String time) => time.substring(0, 5);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: ThymeStepAppBar(step: 2, total: 3, group: '직원', title: '교대 선호'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("어느 교대가 편해요?", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                  const SizedBox(height: 12),
                  const Text(
                    "직원은 주 5일이 기본이라 가능 시간은 묻지 않아요. 빈칸을 채울 때 이 선호를 먼저 봐요.",
                    style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.5),
                  ),
                  const SizedBox(height: 24),

                  // 교대마다 선호/상관없음/피하고 싶음
                  for (final shift in _shifts) ...[
                    _buildShiftCard(shift),
                    const SizedBox(height: 10),
                  ],

                  // 근무 리듬 (스위치 물결이 보이도록 Container 대신 Material로 칠한다)
                  Material(
                    color: ThymeColor.surface,
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Column(
                      children: [
                        _buildSwitchRow(
                          "마감 다음 날 오픈은 피할래요",
                          "22시 퇴근 → 다음 날 9시 출근 방지",
                          _draft.noOpenAfterClose,
                          (v) => setState(() => _draft.noOpenAfterClose = v),
                        ),
                        const Divider(),
                        _buildSwitchRow(
                          "쉬는 날을 이틀 붙여 주세요",
                          "주 5일 근무 중 휴무 2일 연속",
                          _draft.restDaysTogether,
                          (v) => setState(() => _draft.restDaysTogether = v),
                        ),
                        const Divider(),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            "이 매장은 쪼개기 교대가 없어서 \"하루 두 번 근무\"는 묻지 않아요.",
                            style: TextStyle(fontSize: 12, color: ThymeColor.textSub),
                          ),
                        ),
                      ],
                    ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 하단 다음 버튼
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PreferenceSubmitPage(draft: _draft))),
                  child: const Text("다음 · 우선순위"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 교대 카드: 이름 + 시간(Mono) + 3칸 세그먼트
  Widget _buildShiftCard(ShiftSummary shift) {
    final selected = _draft.shiftAttitudes[shift.id] ?? ShiftAttitude.neutral;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(shift.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              const SizedBox(width: 8),
              Text("${_hm(shift.startTime)}–${_hm(shift.endTime)}", style: ThymeTheme.mono(context, size: 14, color: ThymeColor.textSub)),
            ],
          ),
          const SizedBox(height: 12),
          // 세그먼트 바탕 = 라벤더 미스트, 고른 칸 = 흰 칸 (시안 W04)
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(12)),
            child: Row(
              children: [
                for (final (value, label) in _options)
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _draft.shiftAttitudes[shift.id] = value),
                      child: Container(
                        height: 40,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: value == selected ? ThymeColor.surface : Colors.transparent,
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: value == selected ? FontWeight.bold : FontWeight.w500,
                            color: value == selected ? ThymeColor.text : ThymeColor.textSub,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchRow(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      activeTrackColor: ThymeColor.primary, // 스위치 켜짐 = 딥 나이트
      activeThumbColor: ThymeColor.onPrimary,
      title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
      value: value,
      onChanged: onChanged,
    );
  }
}
