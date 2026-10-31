import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/preference_api.dart';
import '../../core/theme.dart';
import '../../models/owner.dart' show won;
import '../../models/preference.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'w05_skills_page.dart';

/// W06 이번 달 근무량 (알바 5/7). 계약 범위 안에서 이번 달 최소~최대 시간과 근무 리듬을 정한다
///
/// - 서버: GET /preferences/my/workload (계약 주 시간 → 그달 시간, 예상 급여 범위, 주휴 기준 미달·계약 초과 경고)
/// - 값은 초안에 담았다가 W14 제출 때 함께 보낸다 (minMonthlyHours·maxMonthlyHours·maxConsecutiveDays·noOpenAfterClose)
class WorkHoursPage extends StatefulWidget {
  const WorkHoursPage({super.key, required this.draft});

  final PreferenceDraft draft;

  @override
  State<WorkHoursPage> createState() => _WorkHoursPageState();
}

class _WorkHoursPageState extends State<WorkHoursPage> {
  /// 매장 연속 근무 한도 범위 (서버 1~6일)
  static const _maxStreak = 6;

  Workload? _w;
  String? _error;
  int? _min;
  int? _max;
  late int? _streak = widget.draft.maxConsecutiveDays;
  late bool _noOpenAfterClose = widget.draft.noOpenAfterClose;
  Timer? _debounce;

  double get _weeks => DateUtils.getDaysInMonth(widget.draft.month.year, widget.draft.month.month) / 7;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      // 지난달 답이 있으면 그 값으로, 없으면 서버가 계약 범위로 채워 준다
      final w = await PreferenceApi().workload(widget.draft.month, min: widget.draft.minMonthlyHours, max: widget.draft.maxMonthlyHours);
      if (!mounted) return;
      setState(() {
        _w = w;
        _min = w.minMonthly;
        _max = w.maxMonthly;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  /// 값을 바꾸면 잠깐 기다렸다가 예상 급여·경고를 다시 받는다
  void _changed() {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () async {
      try {
        final w = await PreferenceApi().workload(widget.draft.month, min: _min, max: _max);
        if (mounted) setState(() => _w = w);
      } on ApiException catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    });
  }

  void _set({int? min, int? max}) {
    if (min != null) {
      _min = min;
      if (_max != null && _max! < min) _max = min;
    }
    if (max != null) _max = max;
    _changed();
  }

  void _next() {
    widget.draft
      ..minMonthlyHours = _min
      ..maxMonthlyHours = _max
      ..maxConsecutiveDays = _streak
      ..noOpenAfterClose = _noOpenAfterClose;
    Navigator.push(context, MaterialPageRoute(builder: (_) => SkillsPage(draft: widget.draft)));
  }

  String _perWeek(int? monthly) => monthly == null ? "정하지 않음" : "주 ${(monthly / _weeks).toStringAsFixed(1)}시간";

  @override
  Widget build(BuildContext context) {
    final w = _w;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: const ThymeStepAppBar(step: 5, total: 7, title: '어떻게 · 근무량'),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
              const Text("이번 달은 얼마나 일할까요?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              const SizedBox(height: 8),
              const Text("계약 범위 안에서 이번 달 최소~최대만 정해요. 엔진이 그 사이로 맞춰요.",
                  style: TextStyle(fontSize: 15, color: ThymeColor.textSub, height: 1.5)),
              const SizedBox(height: 20),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                TextButton(onPressed: _load, child: const Text("다시 불러오기")),
              ] else if (w == null)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
              else ...[
                _contract(w),
                const SizedBox(height: 12),
                // 스위치 줄의 물결이 보이도록 Container 대신 Material
                Material(
                  color: ThymeColor.surface,
                  borderRadius: BorderRadius.circular(22),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
                    child: Column(children: [
                      _stepper("이번 달 최소", _perWeek(_min), _min == null ? "–" : "${_min}h",
                          dec: _min == null || _min! <= 0 ? null : () => _set(min: _min! - 2),
                          inc: () => _set(min: (_min ?? w.contractMinMonthly ?? 40) + (_min == null ? 0 : 2))),
                      const Divider(height: 1),
                      _stepper("이번 달 최대", _perWeek(_max), _max == null ? "–" : "${_max}h",
                          dec: _max == null || _max! <= (_min ?? 0) ? null : () => _set(max: _max! - 2),
                          inc: () => _set(max: (_max ?? w.contractMaxMonthly ?? 80) + (_max == null ? 0 : 2))),
                      const Divider(height: 1),
                      _stepper("최대 연속 근무", "1~$_maxStreak일", _streak == null ? "–" : "$_streak일",
                          dec: _streak == null || _streak! <= 1 ? null : () => setState(() => _streak = _streak! - 1),
                          inc: _streak != null && _streak! >= _maxStreak ? null : () => setState(() => _streak = (_streak ?? 3) + (_streak == null ? 0 : 1))),
                      const Divider(height: 1),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: _noOpenAfterClose,
                        onChanged: (v) => setState(() => _noOpenAfterClose = v),
                        title: const Text("마감 다음 날 오픈 피하기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        subtitle: const Text("늦게 퇴근하고 다음 날 아침 출근 방지"),
                      ),
                    ]),
                  ),
                ),
                if (w.belowWeeklyHolidayThreshold) ...[
                  const SizedBox(height: 12),
                  _banner(ThymeColor.warnBg, ThymeColor.warn, ThymeColor.warnText, "최소가 주 15시간 아래라, 주휴수당이 빠지는 주가 생길 수 있어요."),
                ],
                if (w.exceedsContract) ...[
                  const SizedBox(height: 12),
                  _banner(ThymeColor.infoBg, ThymeColor.info, ThymeColor.infoText, "계약 상한보다 많이 일하려면 사장님 승인이 필요해요. 제출하면 사장님 승인 목록에 올라가고, 승인 전에는 계약 시간까지만 배치돼요."),
                ],
                if (w.expectedPayMin != null || w.expectedPayMax != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: ThymeColor.primary, borderRadius: BorderRadius.circular(22)),
                    child: Row(children: [
                      const Expanded(child: Text("이번 달 예상 급여 · 주휴 포함", style: TextStyle(fontSize: 14, color: ThymeColor.onPrimarySub))),
                      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        if (w.expectedPayMin != null) Text("${won(w.expectedPayMin!)} –", style: ThymeTheme.mono(context, size: 17, color: ThymeColor.accent)),
                        if (w.expectedPayMax != null) Text(won(w.expectedPayMax!), style: ThymeTheme.mono(context, size: 17, color: ThymeColor.accent)),
                      ]),
                    ]),
                  ),
                ],
              ],
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(width: double.infinity, child: FilledButton(onPressed: w == null ? null : _next, child: const Text("다음"))),
          ),
        ]),
      ),
    );
  }

  Widget _contract(Workload w) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          const Icon(Icons.lock_outline, size: 20, color: ThymeColor.textSub),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("근로계약", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
              const SizedBox(height: 2),
              Text(
                [
                  if (w.contractMinWeekly != null || w.contractMaxWeekly != null)
                    "주 ${w.contractMinWeekly ?? 0}–${w.contractMaxWeekly ?? '?'}시간"
                  else
                    "계약 시간 정하지 않음",
                  if (w.hourlyWage > 0) "시급 ${won(w.hourlyWage)}",
                ].join(" · "),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text),
              ),
            ]),
          ),
        ]),
      );

  Widget _stepper(String title, String sub, String value, {VoidCallback? dec, VoidCallback? inc}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              Text(sub, style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
            ]),
          ),
          IconButton.outlined(tooltip: "$title 줄이기", onPressed: dec, icon: const Icon(Icons.remove)),
          SizedBox(width: 64, child: Center(child: Text(value, style: ThymeTheme.mono(context, size: 18)))),
          IconButton.filled(tooltip: "$title 늘리기", onPressed: inc, icon: const Icon(Icons.add)),
        ]),
      );

  Widget _banner(Color bg, Color dot, Color fg, String text) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(16)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.only(top: 5), child: Icon(Icons.circle, size: 8, color: dot)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(fontSize: 14, color: fg, height: 1.5))),
        ]),
      );
}
