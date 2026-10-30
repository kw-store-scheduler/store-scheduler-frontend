import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/preference_api.dart';
import '../../core/theme.dart';
import '../../models/preference.dart';
import '../../models/store.dart' show weekdayLabels;
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'w02_date_shift_page.dart';

/// 화면에서 고치는 고정 일정 묶음 (이름·시간·기간이 같은 요일들을 한 카드로)
class _Group {
  _Group({required this.label, required this.category, required this.start, required this.end, Set<int>? days, this.validFrom, this.validUntil})
      : days = days ?? {};

  String label;
  final FixedScheduleCategory category;
  TimeOfDay start;
  TimeOfDay end;
  final Set<int> days;
  DateTime? validFrom;
  DateTime? validUntil;

  double get weeklyHours {
    var m = (end.hour * 60 + end.minute) - (start.hour * 60 + start.minute);
    if (m <= 0) m += 24 * 60;
    return m / 60 * days.length;
  }
}

/// W11 고정 일정 (알바 2/7, 내 정보에서도 연다). 매주 같은 시간에 못 나오는 일정
///
/// - 서버: GET/PUT /fixed-schedules/my (요일마다 한 건, 통째로 교체) · GET/PUT /unavailable-periods/my (이번 달만 예외 기간)
/// - 고정 일정과 겹치는 W02 칸은 서버가 잠근다 → 저장한 뒤 그달 칸을 다시 받아 초안에 반영한다
/// - [draft]가 없으면 내 정보에서 온 것 → '저장' 후 돌아간다
class FixedSchedulePage extends StatefulWidget {
  const FixedSchedulePage({super.key, this.draft});

  final PreferenceDraft? draft;

  @override
  State<FixedSchedulePage> createState() => _FixedSchedulePageState();
}

class _FixedSchedulePageState extends State<FixedSchedulePage> {
  List<_Group>? _groups;
  List<UnavailablePeriod> _periods = [];
  String? _error;
  bool _saving = false;

  static TimeOfDay _tod(String t) => TimeOfDay(hour: int.parse(t.substring(0, 2)), minute: int.parse(t.substring(3, 5)));
  static String _hm(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
  static String _md(DateTime d) => '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final api = PreferenceApi();
      final list = await api.fixedSchedules();
      final periods = await api.unavailablePeriods();
      final groups = <String, _Group>{};
      for (final f in list) {
        final key = [f.label, f.category.name, f.startTime, f.endTime, f.validFrom, f.validUntil].join('|');
        groups.putIfAbsent(
          key,
          () => _Group(label: f.label, category: f.category, start: _tod(f.startTime), end: _tod(f.endTime), validFrom: f.validFrom, validUntil: f.validUntil),
        ).days.add(f.weekday);
      }
      if (!mounted) return;
      setState(() {
        _groups = groups.values.toList();
        _periods = periods;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _add(FixedScheduleCategory c) => setState(() => _groups!.add(_Group(
        label: c.label,
        category: c,
        start: const TimeOfDay(hour: 9, minute: 0),
        end: const TimeOfDay(hour: 13, minute: 0),
      )));

  Future<void> _editTime(_Group g) async {
    final start = await showTimePicker(context: context, initialTime: g.start, helpText: "시작 시간");
    if (start == null || !mounted) return;
    final end = await showTimePicker(context: context, initialTime: g.end, helpText: "끝 시간");
    if (end == null) return;
    setState(() {
      g.start = start;
      g.end = end;
    });
  }

  Future<void> _editLabel(_Group g) async {
    final c = TextEditingController(text: g.label);
    final v = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("일정 이름"),
        content: TextField(controller: c, autofocus: true, maxLength: 20, decoration: const InputDecoration(hintText: "예: 전공 수업")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text("확인")),
        ],
      ),
    );
    if (v != null && v.isNotEmpty) setState(() => g.label = v);
  }

  Future<void> _editPeriod(_Group g) async {
    final now = DateTime.now();
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      initialDateRange: g.validFrom == null || g.validUntil == null ? null : DateTimeRange(start: g.validFrom!, end: g.validUntil!),
      helpText: "이 일정이 있는 기간",
      saveText: "확인",
    );
    if (r != null) {
      setState(() {
        g.validFrom = r.start;
        g.validUntil = r.end;
      });
    }
  }

  Future<void> _addPeriod() async {
    final month = widget.draft?.month ?? DateTime(DateTime.now().year, DateTime.now().month + 1);
    final r = await showDateRangePicker(
      context: context,
      firstDate: DateTime(month.year, month.month - 1),
      lastDate: DateTime(month.year, month.month + 2, 0),
      initialDateRange: DateTimeRange(start: month, end: month.add(const Duration(days: 4))),
      helpText: "못 나오는 기간 (시험 기간 등)",
      saveText: "확인",
    );
    if (r == null || !mounted) return;
    final weekdaysOnly = await showDialog<bool>(
      context: context,
      builder: (context) => SimpleDialog(title: const Text("이 기간에 못 나오는 날"), children: [
        SimpleDialogOption(onPressed: () => Navigator.pop(context, true), child: const Text("평일만")),
        SimpleDialogOption(onPressed: () => Navigator.pop(context, false), child: const Text("주말 포함 전부")),
      ]),
    );
    if (weekdaysOnly == null) return;
    setState(() => _periods.add(UnavailablePeriod(startDate: r.start, endDate: r.end, weekdaysOnly: weekdaysOnly)));
  }

  Future<void> _save() async {
    final groups = [for (final g in _groups!) if (g.days.isNotEmpty) g];
    setState(() => _saving = true);
    try {
      final api = PreferenceApi();
      await api.replaceFixedSchedules([
        for (final g in groups)
          for (final d in g.days.toList()..sort())
            FixedSchedule(
              weekday: d,
              startTime: _hm(g.start),
              endTime: _hm(g.end),
              label: g.label,
              category: g.category,
              validFrom: g.validFrom,
              validUntil: g.validUntil,
            ),
      ]);
      await api.replaceUnavailablePeriods(_periods);
      final draft = widget.draft;
      if (draft == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("고정 일정을 저장했어요")));
        Navigator.maybePop(context);
        return;
      }
      // 잠긴 칸이 바뀌었을 수 있으니 그달 칸을 다시 받는다
      draft.replaceView(await api.getMine(draft.month));
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => DateShiftPage(draft: draft)));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: widget.draft == null
          ? AppBar(backgroundColor: ThymeColor.bg, title: const Text("고정 일정", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)), centerTitle: true)
          : const ThymeStepAppBar(step: 2, total: 7, title: '언제 · 고정 일정'),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
              const Text("매주 반복되는 일정이 있나요?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              const SizedBox(height: 8),
              const Text("학교, 다른 직장, 돌봄처럼 매주 같은 시간에 못 나오는 일정이에요. 기간이 끝나면 자동으로 풀려요.",
                  style: TextStyle(fontSize: 15, color: ThymeColor.textSub, height: 1.5)),
              const SizedBox(height: 20),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                TextButton(onPressed: _load, child: const Text("다시 불러오기")),
              ] else if (groups == null)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
              else ...[
                for (final g in groups) _card(g),
                const Padding(
                  padding: EdgeInsets.only(top: 4, bottom: 10),
                  child: Text("일정 추가", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
                ),
                Row(children: [
                  for (final (i, c) in FixedScheduleCategory.values.indexed) ...[
                    if (i > 0) const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(minimumSize: const Size(0, 52), padding: EdgeInsets.zero),
                        onPressed: () => _add(c),
                        child: Text(c.label, style: const TextStyle(fontSize: 14)),
                      ),
                    ),
                  ],
                ]),
                const SizedBox(height: 16),
                _periodCard(),
              ],
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: groups == null || _saving ? null : _save,
                child: Text(_saving ? "저장하는 중…" : (widget.draft == null ? "저장" : "다음")),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _card(_Group g) {
    final period = g.validFrom == null && g.validUntil == null ? "계속" : "${g.validFrom == null ? '' : _md(g.validFrom!)} – ${g.validUntil == null ? '' : _md(g.validUntil!)}";
    final h = g.weeklyHours;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
      decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: ThymeColor.selectedSoft, borderRadius: BorderRadius.circular(12)),
            child: Text(g.category.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.text)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _editLabel(g),
              child: Text(g.label, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            ),
          ),
          TextButton(onPressed: () => _editTime(g), child: Text("${_hm(g.start)}–${_hm(g.end)}", style: ThymeTheme.mono(context, size: 15))),
          IconButton(
            tooltip: "삭제",
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => _groups!.remove(g)),
            icon: const Icon(Icons.close, size: 20, color: ThymeColor.textSub),
          ),
        ]),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Row(children: [
            for (var d = 0; d < 7; d++) ...[
              if (d > 0) const SizedBox(width: 6),
              Expanded(
                child: Material(
                  color: g.days.contains(d) ? ThymeColor.primary : ThymeColor.surfaceSub,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => setState(() => g.days.contains(d) ? g.days.remove(d) : g.days.add(d)),
                    child: SizedBox(
                      height: 44,
                      child: Center(
                        child: Text(weekdayLabels[d],
                            style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: g.days.contains(d)
                                    ? ThymeColor.onPrimary
                                    : (d == 6 ? ThymeColor.dangerText : (d == 5 ? ThymeColor.infoText : ThymeColor.textSub)))),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ]),
        ),
        const SizedBox(height: 6),
        Row(children: [
          TextButton(
            style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 36)),
            onPressed: () => _editPeriod(g),
            child: Text(period, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text)),
          ),
          if (g.validFrom != null)
            IconButton(
              tooltip: "기간 없이 계속",
              visualDensity: VisualDensity.compact,
              onPressed: () => setState(() {
                g.validFrom = null;
                g.validUntil = null;
              }),
              icon: const Icon(Icons.all_inclusive, size: 18, color: ThymeColor.textSub),
            ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              [
                if (h > 0) "주 ${h == h.roundToDouble() ? h.toInt() : h.toStringAsFixed(1)}시간",
                if (g.category == FixedScheduleCategory.otherJob) "주당 총 근로시간에 합산해요",
                if (g.days.isEmpty) "요일을 골라 주세요",
              ].join(" · "),
              style: TextStyle(fontSize: 13, color: g.days.isEmpty ? ThymeColor.dangerText : ThymeColor.textSub),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _periodCard() => Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 8, 10),
        decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("이번 달만 예외", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text)),
          const SizedBox(height: 2),
          const Text("시험 기간처럼 잠깐 못 나오는 날", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
          for (final p in _periods)
            Row(children: [
              Expanded(
                child: Text("${_md(p.startDate)}–${_md(p.endDate)} · ${p.weekdaysOnly ? '평일 전부 불가' : '전부 불가'}",
                    style: const TextStyle(fontSize: 15, color: ThymeColor.text)),
              ),
              IconButton(
                tooltip: "삭제",
                onPressed: () => setState(() => _periods.remove(p)),
                icon: const Icon(Icons.close, size: 20, color: ThymeColor.textSub),
              ),
            ]),
          TextButton.icon(onPressed: _addPeriod, icon: const Icon(Icons.add), label: const Text("기간 추가")),
        ]),
      );
}
