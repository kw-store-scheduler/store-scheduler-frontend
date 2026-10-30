import 'package:flutter/material.dart';
import '../../core/home_router.dart';
import '../../core/api_service.dart';
import '../../core/preference_api.dart';
import '../../core/theme.dart';
import '../../models/preference.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'h01_part_timer_home_page.dart';
import 'h02_employee_home_page.dart';

class PreferenceSubmitPage extends StatefulWidget {
  const PreferenceSubmitPage({super.key, required this.draft});

  final PreferenceDraft draft;

  @override
  State<PreferenceSubmitPage> createState() => _PreferenceSubmitPageState();
}

class _PreferenceSubmitPageState extends State<PreferenceSubmitPage> {
  // 사용자가 우선순위를 바꿀 수 있는 리스트 (초안의 순서 그대로 시작)
  late final List<PreferencePriority> _preferences = List.of(widget.draft.priorities);
  bool _submitting = false;

  /// 앞 단계에서 고른 값으로 항목 설명을 만든다
  String _describe(PreferencePriority p) {
    final d = widget.draft;
    final preferred = d.slots.values.where((l) => l == PreferenceLevel.preferred).length;
    return switch (p) {
      PreferencePriority.dayOff => "휴무 요청에서 고른 날",
      PreferencePriority.shift => d.fullTime
          ? "선호 ${d.shiftAttitudes.values.where((a) => a == ShiftAttitude.prefer).length}개"
              " · 피하고 싶음 ${d.shiftAttitudes.values.where((a) => a == ShiftAttitude.avoid).length}개"
          : "가능 ${d.slots.length - preferred}칸 · 선호 $preferred칸",
      PreferencePriority.weekend => d.maxWeekendShifts == null ? "제한 없음" : "한 달 ${d.maxWeekendShifts}회까지",
      PreferencePriority.hours =>
        d.minMonthlyHours == null ? "계약 범위대로" : "${d.minMonthlyHours}~${d.maxMonthlyHours}시간",
      PreferencePriority.rhythm => [
          if (d.noOpenAfterClose) "마감 다음 날 오픈 X",
          if (d.maxConsecutiveDays != null) "최대 연속 ${d.maxConsecutiveDays}일",
        ].join(" · "),
    };
  }

  Future<void> _submit() async {
    widget.draft.priorities = List.of(_preferences);
    setState(() => _submitting = true);
    try {
      await PreferenceApi().submit(widget.draft);
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
      return;
    }
    if (!mounted) return;
    // 플로우맵 갈림길 ②: 알바 W14 → H01 알바 홈, 직원 W14 → H02 직원 홈
    resetTo(context, widget.draft.fullTime ? const EmployeeHomePage() : const PartTimerHomePage());
  }

  // 드래그 앤 드롭으로 순서 변경될 때 실행되는 함수
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _preferences.removeAt(oldIndex);
      _preferences.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      // 알바 7단계의 마지막, 직원은 3단계의 마지막
      appBar: widget.draft.fullTime
          ? ThymeStepAppBar(step: 3, total: 3, group: '직원', title: '우선순위 · 마지막')
          : ThymeStepAppBar(step: 7, total: 7, title: '우선순위 · 마지막'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "무엇을 가장 지키고 싶어요?",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ThymeColor.text),
                ),
                const SizedBox(height: 12),
                Text(
                  "내 선호끼리 부딪히면 위에 있는 것부터 지켜요.\n화살표로 순서를 바꿔요.",
                  style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.5),
                ),
              ],
            ),
          ),
          
          // 우선순위 리스트 (드래그 앤 드롭 가능)
          Expanded(
            child: Theme(
              // 드래그할 때 생기는 기본 그림자/배경색 제거
              data: Theme.of(context).copyWith(
                canvasColor: Colors.transparent,
              ),
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                itemCount: _preferences.length,
                onReorderItem: _onReorder, // 플러터 최신 문법 반영! (onReorder -> onReorderItem)
                buildDefaultDragHandles: true, // 화살표 아이콘 잡고 끌기 허용
                proxyDecorator: (Widget child, int index, Animation<double> animation) {
                  // 드래그 중인 아이템 예쁘게 띄워주기
                  return Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [BoxShadow(color: ThymeColor.text.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: child,
                    ),
                  );
                },
                itemBuilder: (context, index) {
                  return Container(
                    key: ValueKey(_preferences[index]),
                    margin: const EdgeInsets.only(bottom: 12.0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: ThymeColor.surface,
                      border: Border.all(color: ThymeColor.border),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // 순위 숫자 뱃지
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: ThymeColor.text,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(color: ThymeColor.onPrimary, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // 내용
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _preferences[index].label,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _describe(_preferences[index]),
                                style: TextStyle(fontSize: 12, color: ThymeColor.textSub),
                              ),
                            ],
                          ),
                        ),
                        
                        // 우측 상하 화살표 (드래그 핸들)
                        Column(
                          children: [
                            Icon(Icons.keyboard_arrow_up, size: 20, color: ThymeColor.disabled),
                            Icon(Icons.keyboard_arrow_down, size: 20, color: ThymeColor.disabled),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // 하단 안내 문구
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Container(width: 4, height: 4, decoration: const BoxDecoration(color: ThymeColor.text, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "고정 일정과 필수 휴무는 순위와 상관없이 항상 지켜져요.",
                    style: TextStyle(fontSize: 12, color: ThymeColor.text, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          // 하단 제출 버튼
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ThymeFinalButton(label: _submitting ? "제출하는 중…" : "신청 제출", onPressed: _submitting ? null : _submit),
              ),
            ),
          ),
        ],
      ),
    );
  }
}