import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/owner_api.dart';
import '../../core/store_api.dart';
import '../../core/theme.dart';
import '../../models/owner.dart';
import '../../models/store.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_owner_header.dart';
import '../../widgets/thyme_owner_tab_bar.dart';
import 'p03_generating_schedule_page.dart';

/// 점주 하단 탭 '근무표' (시안 없음: P01 탭 구성에만 있음). 확정 근무표(GET /schedules)를 주 단위로 보고,
/// 다음 주기 일정(GET /schedules/plan)과 '근무표 만들기'(P03)로 간다.
/// 날짜의 + 로 근무 직접 추가, 근무를 누르면 배정 사유 · 고치기(담당자·날짜·시간) · 지우기.
/// 규칙(휴무·가용 시간·주 52시간 등)에 걸리면 서버 사유를 보여 주고, 점주가 그래도 하면 force 로 다시 보낸다
class OwnerSchedulePage extends StatefulWidget {
  const OwnerSchedulePage({super.key});

  @override
  State<OwnerSchedulePage> createState() => _OwnerSchedulePageState();
}

class _OwnerSchedulePageState extends State<OwnerSchedulePage> {
  List<ScheduleEntry>? _entries;
  SchedulePlan? _plan;
  String? _error;
  late DateTime _week = _monday(DateTime.now());

  static DateTime _monday(DateTime d) => DateUtils.dateOnly(d).subtract(Duration(days: d.weekday - 1));

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final entries = await OwnerApi().schedules();
      final plan = await StoreApi().plan();
      if (!mounted) return;
      setState(() {
        _entries = entries;
        _plan = plan;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  /// 추가·고치기 공통: 먼저 규칙대로 보내고, 400(규칙 위반 등)이면 사유를 보여 준 뒤 원하면 force 로 다시
  Future<void> _save(Future<void> Function(bool force) send, String done) async {
    try {
      await send(false);
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode != 400) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        return;
      }
      final force = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("근무 규칙에 걸려요"),
          content: Text("${e.message}\n\n사장님 판단으로 그래도 배정할까요?"),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("취소")),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("그래도 배정")),
          ],
        ),
      );
      if (force != true || !mounted) return;
      try {
        await send(true);
      } on ApiException catch (e2) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e2.message)));
        return;
      }
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
    await _load();
  }

  /// 근무 추가·고치기 시트 (직원 목록·교대 시간은 열 때 받는다)
  Future<void> _edit({DateTime? day, ScheduleEntry? entry}) async {
    final people = await OwnerApi().roster().then((r) => r.employees).catchError((_) => <RosterRow>[]);
    final shifts = await StoreApi().shifts().catchError((_) => <ShiftInfo>[]);
    if (!mounted) return;
    if (people.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("근무를 넣을 직원이 없어요. 먼저 직원을 승인해 주세요.")));
      return;
    }
    final r = await showModalBottomSheet<_Edit>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThymeColor.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ScheduleEditSheet(people: people, shifts: shifts, day: day ?? entry!.workDate, entry: entry),
    );
    if (r == null || !mounted) return;
    final api = OwnerApi();
    if (entry == null) {
      await _save((force) => api.addSchedule(employeeId: r.employeeId, date: r.date, start: r.start, end: r.end, force: force), "근무를 넣었어요");
    } else {
      await _save((force) => api.updateSchedule(entry.id, employeeId: r.employeeId, date: r.date, start: r.start, end: r.end, force: force),
          "근무를 고쳤어요");
    }
  }

  Future<void> _delete(ScheduleEntry e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("근무 지우기"),
        content: Text("${e.employeeName} · ${mdw(e.workDate)} ${hourRange(e.startTime, e.endTime)}시 근무를 지워요."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("취소")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("지우기", style: TextStyle(color: ThymeColor.dangerText))),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await OwnerApi().deleteSchedule(e.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("근무를 지웠어요")));
      await _load();
    } on ApiException catch (err) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err.message)));
    }
  }

  Future<void> _make() async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => const GeneratingSchedulePage()));
    if (mounted) _load();
  }

  void _showEntry(ScheduleEntry e) => showModalBottomSheet(
        context: context,
        backgroundColor: ThymeColor.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("${e.employeeName} · ${mdw(e.workDate)} ${hourRange(e.startTime, e.endTime)}",
                  style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              const SizedBox(height: 12),
              const Text("배정 사유", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
              const SizedBox(height: 6),
              if (e.reasons.isEmpty) const Text("직접 넣은 근무예요.", style: TextStyle(color: ThymeColor.textSub)),
              for (final r in e.reasons) Text("· $r", style: const TextStyle(fontSize: 14, color: ThymeColor.charcoal, height: 1.5)),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(foregroundColor: ThymeColor.dangerText),
                    onPressed: () {
                      Navigator.pop(context);
                      _delete(e);
                    },
                    child: const Text("지우기"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _edit(entry: e);
                    },
                    child: const Text("고치기"),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final entries = _entries;
    final plan = _plan;
    final days = [for (var i = 0; i < 7; i++) _week.add(Duration(days: i))];
    final hasAny = entries != null && entries.isNotEmpty;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: EdgeInsets.zero, children: [
          ThymeOwnerHeader(
            title: "근무표",
            child: plan == null
                ? null
                : Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: ThymeColor.indigoSurface, borderRadius: BorderRadius.circular(18)),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text("다음 근무표 · ${periodLabel(plan.periodStart, plan.periodEnd, monthly: plan.cycle == ScheduleCycle.monthly)}",
                              style: const TextStyle(color: ThymeColor.onPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(
                            "희망 마감 ${mdw(plan.preferenceDeadline)}${plan.autoGenerate ? " · 자동 생성 ${mdw(plan.generateAt)}" : ""}",
                            style: const TextStyle(color: ThymeColor.onPrimarySub, fontSize: 13),
                          ),
                        ]),
                      ),
                      FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: ThymeColor.accent,
                          foregroundColor: ThymeColor.onAccent,
                          minimumSize: const Size(0, 44),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        onPressed: _make,
                        child: const Text("근무표 만들기"),
                      ),
                    ]),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: _error != null
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                    TextButton(onPressed: _load, child: const Text("다시 불러오기")),
                  ])
                : entries == null
                    ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                    : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        Row(children: [
                          IconButton(
                            tooltip: "지난주",
                            onPressed: () => setState(() => _week = _week.subtract(const Duration(days: 7))),
                            icon: const Icon(Icons.chevron_left),
                          ),
                          Expanded(
                            child: Text("${_week.month}/${_week.day} – ${days.last.month}/${days.last.day}",
                                textAlign: TextAlign.center, style: ThymeTheme.mono(context, size: 16)),
                          ),
                          IconButton(
                            tooltip: "다음 주",
                            onPressed: () => setState(() => _week = _week.add(const Duration(days: 7))),
                            icon: const Icon(Icons.chevron_right),
                          ),
                        ]),
                        if (!hasAny)
                          Container(
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(16)),
                            child: const Text("아직 확정된 근무표가 없어요. '근무표 만들기'로 3안을 받아 하나를 확정하거나, 날짜의 + 로 직접 넣어 주세요.",
                                style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.5)),
                          ),
                        for (final d in days) _day(d, [for (final e in entries) if (DateUtils.isSameDay(e.workDate, d)) e]),
                      ]),
          ),
        ]),
      ),
      bottomNavigationBar: const ThymeOwnerTabBar(current: OwnerTab.schedule),
    );
  }

  Widget _day(DateTime d, List<ScheduleEntry> list) {
    list.sort((a, b) => a.startTime.compareTo(b.startTime));
    final today = DateUtils.isSameDay(d, DateTime.now());
    final w = weekdayLabels[d.weekday - 1];
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ThymeColor.surface,
        borderRadius: BorderRadius.circular(16),
        border: today ? Border.all(color: ThymeColor.primary, width: 2) : null,
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          width: 56,
          child: Text("${d.month}/${d.day}\n$w", style: ThymeTheme.mono(context, size: 14, color: ThymeColor.forWeekday(w))),
        ),
        Expanded(
          child: list.isEmpty
              ? const Text("근무 없음", style: TextStyle(fontSize: 14, color: ThymeColor.textSub))
              : Wrap(spacing: 6, runSpacing: 6, children: [
                  for (final e in list)
                    ActionChip(
                      onPressed: () => _showEntry(e),
                      backgroundColor: ThymeColor.successBg,
                      side: BorderSide.none,
                      label: Text("${e.employeeName} ${hourRange(e.startTime, e.endTime)}",
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                    ),
                ]),
        ),
        IconButton(
          tooltip: "${d.month}/${d.day} 근무 추가",
          visualDensity: VisualDensity.compact,
          onPressed: () => _edit(day: d),
          icon: const Icon(Icons.add_circle_outline, color: ThymeColor.textSub),
        ),
      ]),
    );
  }
}

/// 근무 추가·고치기 결과
typedef _Edit = ({int employeeId, DateTime date, String start, String end});

/// 근무 추가·고치기 시트: 직원 · 날짜 · 시간 (교대를 누르면 그 시간으로)
class _ScheduleEditSheet extends StatefulWidget {
  const _ScheduleEditSheet({required this.people, required this.shifts, required this.day, this.entry});

  final List<RosterRow> people;
  final List<ShiftInfo> shifts;
  final DateTime day;
  final ScheduleEntry? entry;

  @override
  State<_ScheduleEditSheet> createState() => _ScheduleEditSheetState();
}

class _ScheduleEditSheetState extends State<_ScheduleEditSheet> {
  late int? _employeeId = widget.entry?.employeeId;
  late DateTime _date = widget.day;
  late String? _start = widget.entry == null ? null : hhmm(widget.entry!.startTime);
  late String? _end = widget.entry == null ? null : hhmm(widget.entry!.endTime);

  Future<void> _pickTime(bool start) async {
    final cur = start ? _start : _end;
    final t = await showTimePicker(
      context: context,
      initialTime: cur == null ? TimeOfDay(hour: start ? 9 : 18, minute: 0) : TimeOfDay(hour: int.parse(cur.substring(0, 2)), minute: int.parse(cur.substring(3, 5))),
      helpText: start ? "시작 시간" : "끝나는 시간",
    );
    if (t == null) return;
    final v = "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
    setState(() => start ? _start = v : _end = v);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 60)),
      lastDate: DateTime.now().add(const Duration(days: 120)),
      helpText: "근무 날짜",
    );
    if (d != null) setState(() => _date = d);
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) => ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        selectedColor: ThymeColor.primary,
        labelStyle: TextStyle(color: selected ? ThymeColor.onPrimary : ThymeColor.text, fontWeight: FontWeight.bold),
        showCheckmark: false,
      );

  @override
  Widget build(BuildContext context) {
    final ok = _employeeId != null && _start != null && _end != null;
    TextStyle label() => const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text(widget.entry == null ? "근무 추가" : "근무 고치기", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text("누가", style: label()),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final p in widget.people) _chip(p.name, _employeeId == p.employeeId, () => setState(() => _employeeId = p.employeeId)),
            ]),
            const SizedBox(height: 16),
            Text("언제", style: label()),
            const SizedBox(height: 8),
            OutlinedButton.icon(onPressed: _pickDate, icon: const Icon(Icons.event), label: Text(mdw(_date))),
            if (widget.shifts.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in widget.shifts)
                  _chip("${s.name} ${hourRange(s.startTime, s.endTime)}", _start == hhmm(s.startTime) && _end == hhmm(s.endTime),
                      () => setState(() {
                            _start = hhmm(s.startTime);
                            _end = hhmm(s.endTime);
                          })),
              ]),
            ],
            const SizedBox(height: 10),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => _pickTime(true), child: Text("시작 ${_start ?? '--:--'}"))),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text("–")),
              Expanded(child: OutlinedButton(onPressed: () => _pickTime(false), child: Text("끝 ${_end ?? '--:--'}"))),
            ]),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: ok ? () => Navigator.pop<_Edit>(context, (employeeId: _employeeId!, date: _date, start: _start!, end: _end!)) : null,
              child: Text(widget.entry == null ? "넣기" : "고치기"),
            ),
          ]),
        ),
      ),
    );
  }
}
