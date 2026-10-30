import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/preference.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'w03_rest_day_preference_page.dart';

/// W02 날짜 × 교대 (3/7). 초안의 view(서버의 그달 칸)로 표를 그리고, 누른 칸을 초안에 바로 적는다
class DateShiftPage extends StatefulWidget {
  const DateShiftPage({super.key, required this.draft});

  final PreferenceDraft draft;

  @override
  State<DateShiftPage> createState() => _DateShiftPageState();
}

class _DateShiftPageState extends State<DateShiftPage> {
  static const _weekdays = ["월", "화", "수", "목", "금", "토", "일"];

  PreferenceDraft get _draft => widget.draft;
  late final PreferenceMonth _view = _draft.view!;

  // [UI 상태용 변수]
  int _selectedWeek = 0;
  late int _maxWeekendWork = _draft.maxWeekendShifts ?? 2;

  /// (날짜, 교대 id) → 잠긴 사유 (고정 일정과 겹치는 칸)
  late final Map<(DateTime, int), String> _locks = {
    for (final c in _view.cells)
      if (c.locked) (c.date, c.shiftId): c.lockLabel ?? "고정",
  };

  /// 그달 날짜를 7일씩 끊은 주차 (1~7, 8~14, …)
  late final List<List<DateTime>> _weeks = () {
    final days = DateTime(_draft.month.year, _draft.month.month + 1, 0).day;
    final all = [for (var d = 1; d <= days; d++) DateTime(_draft.month.year, _draft.month.month, d)];
    return [for (var i = 0; i < all.length; i += 7) all.sublist(i, (i + 7).clamp(0, all.length))];
  }();

  // 0: 불가(빈칸), 1: 가능, 2: 선호, 3: 고정일정(잠김)
  int _stateOf(DateTime date, int shiftId) {
    if (_locks.containsKey((date, shiftId))) return 3;
    return switch (_draft.slotAt(date, shiftId)) {
      PreferenceLevel.available => 1,
      PreferenceLevel.preferred => 2,
      null => 0,
    };
  }

  void _toggleShiftState(DateTime date, int shiftId) {
    final state = _stateOf(date, shiftId);
    if (state == 3) return; // 잠긴 칸은 터치 무시
    setState(() {
      // 0 -> 1 -> 2 -> 0 순환
      _draft.setSlot(date, shiftId, switch (state) {
        0 => PreferenceLevel.available,
        1 => PreferenceLevel.preferred,
        _ => null,
      });
    });
  }

  void _next() {
    _draft.maxWeekendShifts = _maxWeekendWork;
    Navigator.push(context, MaterialPageRoute(builder: (_) => RestDayPreferencePage(draft: _draft)));
  }

  static String _hour(String time) => time.substring(0, 2);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: ThymeStepAppBar(step: 3, total: 7),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("언제, 어느 교대에\n나올 수 있어요?", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text, height: 1.3)),
                  const SizedBox(height: 12),
                  const Text("한 번 누르면 가능, 두 번 누르면 선호예요. 고정 일정과 겹치는 칸은 미리 잠겼어요.", style: TextStyle(fontSize: 13, color: ThymeColor.textSub, height: 1.4)),
                  const SizedBox(height: 24),

                  // [상단 주차 탭]
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      for (var i = 0; i < _weeks.length; i++) _buildWeekTab(i, "${_weeks[i].first.day}~${_weeks[i].last.day}"),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // [매트릭스 달력 헤더]
                  Row(
                    children: [
                      const SizedBox(width: 50), // 날짜 열 여백
                      ..._view.shifts.map((shift) => Expanded(
                        child: Center(
                          child: Text("${shift.name} ${_hour(shift.startTime)}-${_hour(shift.endTime)}",
                              style: const TextStyle(fontSize: 11, color: ThymeColor.textSub, fontWeight: FontWeight.bold)),
                        ),
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // [매트릭스 달력 바디]
                  ..._weeks[_selectedWeek].map((date) {
                    final weekday = _weekdays[date.weekday - 1];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 50,
                            child: Text("${date.month}/${date.day} $weekday",
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: date.weekday >= DateTime.saturday ? FontWeight.bold : FontWeight.normal,
                                    color: ThymeColor.forWeekday(weekday))),
                          ),
                          ..._view.shifts.map((shift) => Expanded(
                            child: _buildShiftCell(date, shift.id),
                          )),
                        ],
                      ),
                    );
                  }),

                  const SizedBox(height: 16),
                  
                  // [범례 아이콘]
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(0, "불가"),
                      const SizedBox(width: 12),
                      _buildLegendItem(1, "가능"),
                      const SizedBox(width: 12),
                      _buildLegendItem(2, "선호"),
                      const SizedBox(width: 12),
                      _buildLegendItem(3, "고정 일정"),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // [주말 근무 한도 설정 박스]
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("주말 근무, 한 달 최대", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                              SizedBox(height: 4),
                              Text("주말은 4주 누적으로 팀이 공평하게 나눠요", style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
                            ],
                          ),
                        ),
                        Row(
                          children: [
                            _buildCounterButton(Icons.remove, () {
                              if (_maxWeekendWork > 0) setState(() => _maxWeekendWork--);
                            }),
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text("$_maxWeekendWork회", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                            ),
                            _buildCounterButton(Icons.add, () => setState(() => _maxWeekendWork++)),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "${_draft.month.month}월 전체 · 가능 ${_draft.slots.values.where((l) => l == PreferenceLevel.available).length}칸"
                    " · 선호 ${_draft.slots.values.where((l) => l == PreferenceLevel.preferred).length}칸",
                    style: const TextStyle(fontSize: 12, color: ThymeColor.textSub),
                  ),
                  const SizedBox(height: 32), // 하단 여백
                ],
              ),
            ),
          ),
          
          // [하단 고정 버튼]
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _next, child: Text("다음")),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // [위젯: 주차 탭]
  Widget _buildWeekTab(int index, String label) {
    bool isSelected = _selectedWeek == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedWeek = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? ThymeColor.text : ThymeColor.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? ThymeColor.onPrimary : ThymeColor.textSub)),
      ),
    );
  }

  // [위젯: 매트릭스 달력 셀]
  Widget _buildShiftCell(DateTime date, int shiftId) {
    final state = _stateOf(date, shiftId);
    
    Color bgColor = ThymeColor.surface;
    Color borderColor = ThymeColor.border;
    String text = "";
    Color textColor = ThymeColor.text;

    // 입력 화면 규칙: 가능 = 약한 선택(라벤더 틴트 + 딥 나이트 테두리), 선호 = 선택(딥 나이트 면)
    if (state == 1) { // 가능
      bgColor = ThymeColor.selectedSoft;
      borderColor = ThymeColor.primary;
      text = "가능";
    } else if (state == 2) { // 선호
      bgColor = ThymeColor.primary;
      borderColor = ThymeColor.primary;
      text = "선호";
      textColor = ThymeColor.onPrimary;
    } else if (state == 3) { // 고정 일정(잠김)
      bgColor = ThymeColor.surfaceSub;
      borderColor = Colors.transparent;
      text = _locks[(date, shiftId)] ?? "고정";
      textColor = ThymeColor.textSub;
    }

    return GestureDetector(
      onTap: () => _toggleShiftState(date, shiftId),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
      ),
    );
  }

  // [위젯: 범례 아이콘]
  Widget _buildLegendItem(int state, String label) {
    return Row(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
            color: state == 2 ? ThymeColor.primary : state == 3 ? ThymeColor.surfaceSub : (state == 1 ? ThymeColor.selectedSoft : ThymeColor.surface),
            border: Border.all(color: state == 1 ? ThymeColor.primary : state == 0 ? ThymeColor.border : Colors.transparent),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: ThymeColor.textSub)),
      ],
    );
  }

  // [위젯: 플러스 마이너스 버튼]
  Widget _buildCounterButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(8), border: Border.all(color: ThymeColor.border)),
        child: Icon(icon, size: 16, color: ThymeColor.text),
      ),
    );
  }
}