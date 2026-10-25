import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/store_api.dart';
import '../../core/theme.dart';
import '../../models/store.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'o04_curation_page.dart';

IconData _iconOf(ExceptionCategory c) => switch (c) {
      ExceptionCategory.delivery => Icons.inventory_2_outlined,
      ExceptionCategory.sale => Icons.sell_outlined,
      ExceptionCategory.season => Icons.star_outline,
      ExceptionCategory.holidayEve => Icons.calendar_today_outlined,
      ExceptionCategory.other => Icons.label_outline,
    };

String _md(DateTime d) => "${d.month}/${d.day}";

String _when(StaffingException e) {
  final end = e.endDate;
  if (end == null || end == e.date) return _md(e.date);
  return end.month == e.date.month ? "${_md(e.date)}–${end.day}" : "${_md(e.date)}–${_md(end)}";
}

/// 오른쪽 요약: +1 · 휴점 · 2명 · 시간
String _change(StaffingException e) {
  if (e.deltaStaff != null) return e.deltaStaff! > 0 ? "+${e.deltaStaff}" : "${e.deltaStaff}";
  if (e.minStaff != null) return e.minStaff == 0 ? "휴점" : "${e.minStaff}명";
  return "시간";
}

String _detail(StaffingException e) {
  final target = e.shiftName ?? "모든 교대";
  return [
    if (e.deltaStaff != null) "$target ${_change(e)}명",
    if (e.deltaStaff == null && e.minStaff != null) e.minStaff == 0 ? "$target 쉬어요" : "$target ${e.minStaff}명",
    if (e.deltaStaff == null && e.minStaff == null) target,
    if (e.startTimeOverride != null) "${hhmm(e.startTimeOverride!)} 시작",
    if (e.endTimeOverride != null) "${hhmm(e.endTimeOverride!)}까지",
    if (e.note != null && e.note!.isNotEmpty) e.note!,
  ].join(" · ");
}

/// O06 평소와 다른 날 (매장 등록 4/6). 입고일·행사·명절처럼 인원이 달라지는 날만 적는다.
/// 달력의 날짜를 누르면 그날 예외일을 보거나 추가한다. GET·POST·DELETE /staffing-exceptions, GET /holidays
class ExceptionDaysPage extends StatefulWidget {
  const ExceptionDaysPage({super.key});

  @override
  State<ExceptionDaysPage> createState() => _ExceptionDaysPageState();
}

class _ExceptionDaysPageState extends State<ExceptionDaysPage> {
  // 근무표는 다음 달부터라 다음 달을 먼저 보여 준다
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month + 1);
  List<StaffingException>? _items;
  Map<DateTime, String> _holidays = {};
  List<ShiftInfo> _shifts = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    final api = StoreApi();
    try {
      final exceptions = await api.exceptions(_month, DateTime(_month.year, _month.month + 1, 0));
      if (_shifts.isEmpty) _shifts = await api.shifts();
      if (!mounted) return;
      setState(() => _items = exceptions);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
    try {
      final holidays = await api.holidays(_month.year);
      if (mounted) setState(() => _holidays = holidays);
    } on ApiException {
      // 서버에 없는 해(2026·2027 외)는 공휴일 표시만 빠진다
      if (mounted) setState(() => _holidays = {});
    }
  }

  void _moveMonth(int delta) {
    setState(() {
      _month = DateTime(_month.year, _month.month + delta);
      _items = null;
    });
    _load();
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _add([DateTime? day]) async {
    final added = await showModalBottomSheet<StaffingException>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThymeColor.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddExceptionSheet(day: day ?? _month, shifts: _shifts, holiday: day == null ? null : _holidays[day]),
    );
    if (added == null || !mounted) return;
    try {
      await StoreApi().addException(added);
      await _load();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    }
  }

  Future<void> _delete(StaffingException e) async {
    try {
      await StoreApi().deleteException(e.id!);
      await _load();
    } on ApiException catch (err) {
      if (mounted) _toast(err.message);
    }
  }

  /// 날짜를 누르면: 예외일이 있으면 그날 목록(삭제·추가), 없으면 바로 추가
  Future<void> _tapDay(DateTime d) async {
    final onDay = [for (final e in _items ?? <StaffingException>[]) if (e.covers(d)) e];
    if (onDay.isEmpty) return _add(d);
    final action = await showModalBottomSheet<Object>(
      context: context,
      backgroundColor: ThymeColor.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("${d.month}월 ${d.day}일 (${weekdayLabels[d.weekday - 1]})${_holidays[d] == null ? "" : " · ${_holidays[d]}"}",
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              const SizedBox(height: 8),
              for (final e in onDay)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(_iconOf(e.category), color: ThymeColor.charcoal),
                  title: Text("${_when(e)} · ${e.category.label}", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(_detail(e)),
                  trailing: TextButton(
                    style: TextButton.styleFrom(foregroundColor: ThymeColor.dangerText),
                    onPressed: () => Navigator.pop(context, e),
                    child: const Text("삭제"),
                  ),
                ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(onPressed: () => Navigator.pop(context, 'add'), child: const Text("이 날 예외일 더 추가")),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted) return;
    if (action == 'add') return _add(d);
    if (action is StaffingException) return _delete(action);
  }

  void _next() => Navigator.push(context, MaterialPageRoute(builder: (_) => const CurationPage()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: ThymeStepAppBar(
        step: 4,
        total: 6,
        group: '매장 등록',
        owner: true,
        actions: [
          TextButton(onPressed: _next, child: const Text("건너뛰기", style: TextStyle(color: ThymeColor.textSub, fontWeight: FontWeight.bold))),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("평소와 다른 날", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                  const SizedBox(height: 10),
                  const Text("입고일·행사·명절처럼 인원이 달라지는 날만 적어요.\n나머지는 요일 템플릿대로예요.",
                      style: TextStyle(fontSize: 15, color: ThymeColor.textSub, height: 1.5)),
                  const SizedBox(height: 20),
                  _calendar(),
                  const SizedBox(height: 12),
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: ThymeColor.dangerBg, borderRadius: BorderRadius.circular(16)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                        TextButton(onPressed: _load, child: const Text("다시 불러오기")),
                      ]),
                    )
                  else
                    _list(),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: ThymeColor.infoBg, borderRadius: BorderRadius.circular(16)),
                    child: const Text("매주 반복되는 일(입고일 발주 등)은 다음 단계 '필요한 역량'에서 시간대로 정해요.",
                        style: TextStyle(fontSize: 13, color: ThymeColor.infoText, height: 1.5)),
                  ),
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(width: double.infinity, child: FilledButton(onPressed: _next, child: const Text("다음 · 필요한 역량"))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _calendar() {
    const weekdays = ["일", "월", "화", "수", "목", "금", "토"];
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = DateTime(_month.year, _month.month, 1).weekday % 7; // 일요일 시작
    final now = DateTime.now();
    final canBack = _month.isAfter(DateTime(now.year, now.month));
    final canForward = _month.isBefore(DateTime(now.year + 1, now.month));
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          Row(children: [
            IconButton(visualDensity: VisualDensity.compact, tooltip: "이전 달", onPressed: canBack ? () => _moveMonth(-1) : null, icon: const Icon(Icons.chevron_left)),
            Text("${_month.year}. ${_month.month}", style: ThymeTheme.mono(context, size: 17)),
            IconButton(visualDensity: VisualDensity.compact, tooltip: "다음 달", onPressed: canForward ? () => _moveMonth(1) : null, icon: const Icon(Icons.chevron_right)),
            const Expanded(
              child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
                Icon(Icons.circle, size: 6, color: ThymeColor.textSub),
                SizedBox(width: 4),
                Flexible(child: Text("예외일 · 공휴일 자동", overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: ThymeColor.textSub))),
              ]),
            ),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            for (final w in weekdays)
              Expanded(child: Center(child: Text(w, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.forWeekday(w))))),
          ]),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            childAspectRatio: 1.1,
            children: [
              for (var i = 0; i < lead; i++) const SizedBox(),
              for (var d = 1; d <= days; d++) _day(DateTime(_month.year, _month.month, d)),
            ],
          ),
          const SizedBox(height: 4),
          const Text("날짜를 누르면 그날 예외일을 추가해요", style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
        ],
      ),
    );
  }

  Widget _day(DateTime d) {
    final marked = (_items ?? const []).any((e) => e.covers(d));
    final holiday = _holidays[d];
    // 공휴일은 일요일처럼 dangerText (가이드 2장 Do 6)
    final weekday = holiday != null ? "일" : weekdayLabels[d.weekday - 1];
    return Material(
      color: marked ? ThymeColor.selectedSoft : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _items == null ? null : () => _tapDay(d),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("${d.day}", style: ThymeTheme.mono(context, size: 15, color: ThymeColor.forWeekday(weekday))),
            const SizedBox(height: 3),
            Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(color: marked || holiday != null ? ThymeColor.text : Colors.transparent, shape: BoxShape.circle),
            ),
          ],
        ),
      ),
    );
  }

  Widget _list() {
    final items = _items;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          if (items == null)
            const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator())
          else if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Text("이 달엔 예외일이 없어요. 평소와 같으면 그냥 넘어가도 돼요.", style: TextStyle(fontSize: 14, color: ThymeColor.textSub)),
            ),
          for (final e in items ?? const <StaffingException>[]) ...[
            InkWell(
              onTap: () => _tapDay(e.date),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                          Text(_when(e), style: ThymeTheme.mono(context, size: 16)),
                          _kindChip(e.category),
                        ]),
                        const SizedBox(height: 6),
                        Text(_detail(e), style: const TextStyle(fontSize: 14, color: ThymeColor.textSub)),
                      ],
                    ),
                  ),
                  Text(_change(e), style: ThymeTheme.mono(context, size: 17)),
                ]),
              ),
            ),
            const Divider(height: 1),
          ],
          InkWell(
            onTap: items == null ? null : () => _add(),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Row(children: [
                Text("+ 예외일 추가", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// 분류 칩 = 라벤더 틴트 + 차콜 글자 + 선 아이콘 (가이드 1-1)
Widget _kindChip(ExceptionCategory c) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: ThymeColor.selectedSoft, borderRadius: BorderRadius.circular(99)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(_iconOf(c), size: 14, color: ThymeColor.charcoal),
        const SizedBox(width: 4),
        Text(c.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.charcoal)),
      ]),
    );

enum _Kind { delta, closed, time }

/// 예외일 추가: 분류 · 날짜(기간) · 교대 · 인원 ± / 휴점 / 시간 변경 · 메모
class _AddExceptionSheet extends StatefulWidget {
  const _AddExceptionSheet({required this.day, required this.shifts, this.holiday});

  final DateTime day;
  final List<ShiftInfo> shifts;
  final String? holiday;

  @override
  State<_AddExceptionSheet> createState() => _AddExceptionSheetState();
}

class _AddExceptionSheetState extends State<_AddExceptionSheet> {
  late ExceptionCategory _category = widget.holiday != null ? ExceptionCategory.holidayEve : ExceptionCategory.sale;
  late DateTime _start = widget.day;
  late DateTime _end = widget.day;
  ShiftInfo? _shift; // null = 모든 교대
  _Kind _kind = _Kind.delta;
  int _delta = 1;
  int? _startOverride; // 분
  int? _endOverride;
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  static int _min(String t) => int.parse(t.substring(0, 2)) * 60 + int.parse(t.substring(3, 5));
  static String _fmt(int m) => "${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}";

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year, now.month),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: DateTimeRange(start: _start, end: _end),
    );
    if (range != null) {
      setState(() {
        _start = range.start;
        _end = range.end;
      });
    }
  }

  /// 30분 단위 시각 고르기
  Future<void> _pickTime(bool start) async {
    final shift = _shift!;
    var value = (start ? _startOverride : _endOverride) ?? _min(start ? shift.startTime : shift.endTime);
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: ThymeColor.surface,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            height: 200,
            child: CupertinoPicker(
              itemExtent: 36,
              scrollController: FixedExtentScrollController(initialItem: value ~/ 30),
              onSelectedItemChanged: (i) => value = i * 30,
              children: [for (var i = 0; i < 48; i++) Center(child: Text(_fmt(i * 30), style: ThymeTheme.mono(context, size: 18)))],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context, value), child: const Text("확인"))),
          ),
        ]),
      ),
    );
    if (picked != null) setState(() => start ? _startOverride = picked : _endOverride = picked);
  }

  bool get _valid => _kind != _Kind.time || (_shift != null && (_startOverride != null || _endOverride != null));

  StaffingException _result() => StaffingException(
        date: _start,
        endDate: _start == _end ? null : _end,
        shiftId: _shift?.id,
        category: _category,
        deltaStaff: _kind == _Kind.delta ? _delta : null,
        minStaff: _kind == _Kind.closed ? 0 : null,
        startTimeOverride: _kind == _Kind.time && _startOverride != null ? _fmt(_startOverride!) : null,
        endTimeOverride: _kind == _Kind.time && _endOverride != null ? _fmt(_endOverride!) : null,
        note: _note.text.trim(),
      );

  Widget _choice<T>(T value, T group, String label, ValueChanged<T> onTap) => ChoiceChip(
        label: Text(label),
        selected: value == group,
        onSelected: (_) => onTap(value),
        // 선택 = 딥 나이트 (가이드 4-3)
        selectedColor: ThymeColor.primary,
        labelStyle: TextStyle(color: value == group ? ThymeColor.onPrimary : ThymeColor.text, fontWeight: FontWeight.bold),
        showCheckmark: false,
      );

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
      );

  @override
  Widget build(BuildContext context) {
    final sameDay = _start == _end;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("예외일 추가", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              _label("날짜"),
              OutlinedButton.icon(
                onPressed: _pickRange,
                icon: const Icon(Icons.date_range, size: 18),
                label: Text(sameDay ? "${_md(_start)} (${weekdayLabels[_start.weekday - 1]}) · 기간으로 바꾸기" : "${_md(_start)} – ${_md(_end)}"),
              ),
              _label("분류"),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final c in ExceptionCategory.values) _choice(c, _category, c.label, (v) => setState(() => _category = v)),
              ]),
              _label("교대"),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _choice<int?>(null, _shift?.id, "모든 교대", (_) => setState(() => _shift = null)),
                for (final s in widget.shifts)
                  _choice<int?>(s.id, _shift?.id, s.name, (_) => setState(() {
                        _shift = s;
                        _startOverride = _endOverride = null;
                      })),
              ]),
              _label("무엇이 달라지나요"),
              Wrap(spacing: 8, runSpacing: 8, children: [
                _choice(_Kind.delta, _kind, "인원 ±", (v) => setState(() => _kind = v)),
                _choice(_Kind.closed, _kind, "휴무 (0명)", (v) => setState(() => _kind = v)),
                _choice(_Kind.time, _kind, "시간 변경", (v) => setState(() => _kind = v)),
              ]),
              const SizedBox(height: 12),
              if (_kind == _Kind.delta)
                Row(children: [
                  const Expanded(child: Text("평소 대비 인원", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text))),
                  IconButton(
                    tooltip: "1명 줄이기",
                    onPressed: _delta > -5 ? () => setState(() => _delta = _delta - 1 == 0 ? -1 : _delta - 1) : null,
                    icon: const Icon(Icons.remove_circle_outline),
                  ),
                  SizedBox(width: 44, child: Center(child: Text(_delta > 0 ? "+$_delta" : "$_delta", style: ThymeTheme.mono(context, size: 18)))),
                  IconButton(
                    tooltip: "1명 늘리기",
                    onPressed: _delta < 5 ? () => setState(() => _delta = _delta + 1 == 0 ? 1 : _delta + 1) : null,
                    icon: const Icon(Icons.add_circle_outline),
                  ),
                ]),
              if (_kind == _Kind.time)
                _shift == null
                    ? const Text("시간을 바꿀 교대를 위에서 골라 주세요.", style: TextStyle(fontSize: 14, color: ThymeColor.dangerText))
                    : Row(children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _pickTime(true),
                            child: Text("시작 ${_fmt(_startOverride ?? _min(_shift!.startTime))}${_startOverride == null ? " (평소)" : ""}"),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _pickTime(false),
                            child: Text("끝 ${_fmt(_endOverride ?? _min(_shift!.endTime))}${_endOverride == null ? " (평소)" : ""}"),
                          ),
                        ),
                      ]),
              const SizedBox(height: 12),
              TextField(controller: _note, decoration: const InputDecoration(hintText: "메모 (선택) · 예: 겨울 세일")),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _valid ? () => Navigator.pop(context, _result()) : null, child: const Text("추가")),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
