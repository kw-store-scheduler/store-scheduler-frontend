import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/theme.dart';
import '../theme/thyme_theme.dart';

/// 앱 공통 입력 시트 (2026-11 UI 점검: 시계 다이얼·전체 화면 달력 대신)
/// - 시간: 아이폰 알람처럼 위아래로 굴리는 휠, '직접 입력'으로 키보드
/// - 숫자: 키보드로 바로 입력
/// - 날짜·기간: 숙소 예약 앱처럼 아래 시트 달력, 시작 → 끝 두 번 누르면 사이가 띠로 칠해진다
/// - 먼 날짜(근무 시작일): 연·월·일 휠

const _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

/// 11/20(목)
String thymeMdw(DateTime d) => '${d.month}/${d.day}(${_weekdays[d.weekday - 1]})';

String _hm(TimeOfDay t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

String _ymdKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// 테스트에서 날짜 칸을 찾을 때
Key thymeDayKey(DateTime d) => Key('thyme-day-${_ymdKey(d)}');

Future<T?> _showSheet<T>(BuildContext context, Widget child) => showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: ThymeColor.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => child,
    );

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, this.action});

  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
        child: Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThymeColor.text))),
          ?action,
          IconButton(tooltip: '닫기', icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
        ]),
      );
}

Widget _confirmBar({required String label, VoidCallback? onPressed, Widget? summary}) => SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: ThymeColor.border))),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (summary != null) ...[summary, const SizedBox(height: 10)],
          FilledButton(onPressed: onPressed, child: Text(label)),
        ]),
      ),
    );

// ───────────────────────── 시간 ─────────────────────────

/// 시간 하나. [minuteStep] 분 단위로 휠이 돌고, '직접 입력'은 아무 분이나 된다
Future<TimeOfDay?> showThymeTimePicker(BuildContext context, {required TimeOfDay initial, String title = '시간', int minuteStep = 5}) async {
  final r = await _showSheet<List<TimeOfDay>>(context, _TimeSheet(title: title, initial: [initial], labels: const ['시간'], minuteStep: minuteStep));
  return r?.first;
}

/// 시작·끝을 한 시트에서
Future<(TimeOfDay, TimeOfDay)?> showThymeTimeRangePicker(BuildContext context,
    {required TimeOfDay start, required TimeOfDay end, String title = '시간', int minuteStep = 5}) async {
  final r = await _showSheet<List<TimeOfDay>>(
      context, _TimeSheet(title: title, initial: [start, end], labels: const ['시작', '끝'], minuteStep: minuteStep));
  return r == null ? null : (r[0], r[1]);
}

class _TimeSheet extends StatefulWidget {
  const _TimeSheet({required this.title, required this.initial, required this.labels, required this.minuteStep});

  final String title;
  final List<TimeOfDay> initial;
  final List<String> labels;
  final int minuteStep;

  @override
  State<_TimeSheet> createState() => _TimeSheetState();
}

class _TimeSheetState extends State<_TimeSheet> {
  late final List<TimeOfDay> _values = [...widget.initial];
  int _active = 0;
  bool _typing = false;
  late final List<TextEditingController> _fields = [for (final v in widget.initial) TextEditingController(text: _hm(v))];
  String? _error;

  int get _minuteCount => 60 ~/ widget.minuteStep;

  // 휠 위치는 시트가 다시 그려져도 유지 (만들 때마다 새로 만들면 굴리는 도중 튄다). 탭을 바꿀 때만 새로
  late FixedExtentScrollController _hourCtrl;
  late FixedExtentScrollController _minCtrl;

  void _makeWheelControllers() {
    final v = _values[_active];
    _hourCtrl = FixedExtentScrollController(initialItem: v.hour);
    _minCtrl = FixedExtentScrollController(initialItem: (v.minute / widget.minuteStep).round() % _minuteCount);
  }

  @override
  void initState() {
    super.initState();
    _makeWheelControllers();
  }

  void _switchTo(int i) {
    if (i == _active) return;
    final oldH = _hourCtrl, oldM = _minCtrl;
    setState(() {
      _active = i;
      _makeWheelControllers();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      oldH.dispose();
      oldM.dispose();
    });
  }

  @override
  void dispose() {
    for (final c in _fields) {
      c.dispose();
    }
    _hourCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  /// "930" "0930" "9:30" "21" → TimeOfDay
  static TimeOfDay? _parse(String s) {
    final t = s.trim();
    int h, m;
    if (t.contains(':')) {
      final p = t.split(':');
      if (p.length != 2) return null;
      h = int.tryParse(p[0]) ?? -1;
      m = int.tryParse(p[1].isEmpty ? '0' : p[1]) ?? -1;
    } else {
      final d = t.replaceAll(RegExp(r'\D'), '');
      if (d.isEmpty || d.length > 4) return null;
      if (d.length <= 2) {
        h = int.parse(d);
        m = 0;
      } else {
        h = int.parse(d.substring(0, d.length - 2));
        m = int.parse(d.substring(d.length - 2));
      }
    }
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return TimeOfDay(hour: h, minute: m);
  }

  void _confirm() {
    if (_typing) {
      final parsed = [for (final c in _fields) _parse(c.text)];
      if (parsed.contains(null)) {
        setState(() => _error = '시간을 09:30 처럼 적어 주세요');
        return;
      }
      Navigator.pop(context, parsed.cast<TimeOfDay>());
    } else {
      Navigator.pop(context, _values);
    }
  }

  Widget _tabs() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(children: [
          for (var i = 0; i < _values.length; i++) ...[
            if (i > 0) const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('~', style: TextStyle(fontSize: 20, color: ThymeColor.textSub))),
            Expanded(
              child: Material(
                color: i == _active ? ThymeColor.primary : ThymeColor.surfaceSub,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => _switchTo(i),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(children: [
                      Text(widget.labels[i], style: TextStyle(fontSize: 12, color: i == _active ? ThymeColor.onPrimarySub : ThymeColor.textSub)),
                      Text(_hm(_values[i]), style: ThymeTheme.mono(context, size: 22, color: i == _active ? ThymeColor.onPrimary : ThymeColor.text)),
                    ]),
                  ),
                ),
              ),
            ),
          ],
        ]),
      );

  Widget _wheel() {
    final style = ThymeTheme.mono(context, size: 24, color: ThymeColor.text);
    void setH(int h) => setState(() => _values[_active] = TimeOfDay(hour: h, minute: _values[_active].minute));
    void setM(int m) => setState(() => _values[_active] = TimeOfDay(hour: _values[_active].hour, minute: m));
    return SizedBox(
      height: 200,
      child: Row(key: ValueKey(_active), mainAxisAlignment: MainAxisAlignment.center, children: [
        SizedBox(
          width: 90,
          child: CupertinoPicker(
            itemExtent: 44,
            looping: true,
            scrollController: _hourCtrl,
            onSelectedItemChanged: (i) => setH(i % 24),
            children: [for (var h = 0; h < 24; h++) Center(child: Text(h.toString().padLeft(2, '0'), style: style))],
          ),
        ),
        Text(':', style: style),
        SizedBox(
          width: 90,
          child: CupertinoPicker(
            itemExtent: 44,
            looping: true,
            scrollController: _minCtrl,
            onSelectedItemChanged: (i) => setM((i % _minuteCount) * widget.minuteStep),
            children: [
              for (var i = 0; i < _minuteCount; i++) Center(child: Text((i * widget.minuteStep).toString().padLeft(2, '0'), style: style)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _keyboard() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            for (var i = 0; i < _fields.length; i++) ...[
              if (i > 0) const Padding(padding: EdgeInsets.symmetric(horizontal: 8), child: Text('~', style: TextStyle(fontSize: 20, color: ThymeColor.textSub))),
              Expanded(
                child: TextField(
                  controller: _fields[i],
                  autofocus: i == 0,
                  keyboardType: TextInputType.datetime,
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9:]')), LengthLimitingTextInputFormatter(5)],
                  textAlign: TextAlign.center,
                  style: ThymeTheme.mono(context, size: 22, color: ThymeColor.text),
                  decoration: InputDecoration(labelText: widget.labels[i], hintText: '09:30'),
                  onChanged: (_) => setState(() => _error = null),
                  onSubmitted: (_) => _confirm(),
                ),
              ),
            ],
          ]),
          const SizedBox(height: 8),
          Text(_error ?? '숫자만 쳐도 돼요. 930 → 09:30', style: TextStyle(fontSize: 13, color: _error == null ? ThymeColor.textSub : ThymeColor.dangerText)),
        ]),
      );

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _SheetHeader(
            title: widget.title,
            action: TextButton(
              onPressed: () => setState(() {
                _typing = !_typing;
                _error = null;
                if (_typing) {
                  for (var i = 0; i < _values.length; i++) {
                    _fields[i].text = _hm(_values[i]);
                  }
                }
              }),
              child: Text(_typing ? '휠로 고르기' : '직접 입력'),
            ),
          ),
          if (_typing) _keyboard() else ...[if (_values.length > 1) _tabs(), _wheel()],
          _confirmBar(label: '확인', onPressed: _confirm),
        ]),
      );
}

// ───────────────────────── 숫자 ─────────────────────────

/// 숫자 하나를 키보드로. [min]~[max] 밖이면 알려 준다
Future<int?> showThymeNumberInput(BuildContext context,
        {required String title, int? initial, required int min, required int max, String unit = ''}) =>
    _showSheet<int>(context, _NumberSheet(title: title, initial: initial, min: min, max: max, unit: unit));

class _NumberSheet extends StatefulWidget {
  const _NumberSheet({required this.title, this.initial, required this.min, required this.max, required this.unit});

  final String title;
  final int? initial;
  final int min;
  final int max;
  final String unit;

  @override
  State<_NumberSheet> createState() => _NumberSheetState();
}

class _NumberSheetState extends State<_NumberSheet> {
  late final _c = TextEditingController(text: widget.initial?.toString() ?? '');
  String? _error;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  void _confirm() {
    final v = int.tryParse(_c.text.trim());
    if (v == null || v < widget.min || v > widget.max) {
      setState(() => _error = '${widget.min}~${widget.max}${widget.unit} 사이로 적어 주세요');
      return;
    }
    Navigator.pop(context, v);
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _SheetHeader(title: widget.title),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: TextField(
              controller: _c,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(4)],
              textAlign: TextAlign.center,
              style: ThymeTheme.mono(context, size: 26, color: ThymeColor.text),
              decoration: InputDecoration(
                suffixText: widget.unit,
                helperText: _error == null ? '${widget.min}~${widget.max}${widget.unit}' : null,
                errorText: _error,
              ),
              onChanged: (_) => setState(() => _error = null),
              onSubmitted: (_) => _confirm(),
            ),
          ),
          _confirmBar(label: '확인', onPressed: _confirm),
        ]),
      );
}

/// 누르면 한 번, 길게 누르고 있으면 계속 (− / + 버튼)
class ThymeRepeatButton extends StatefulWidget {
  const ThymeRepeatButton({super.key, required this.icon, required this.tooltip, this.onPressed, this.size, this.style = ThymeRepeatStyle.plain});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final double? size;
  final ThymeRepeatStyle style;

  @override
  State<ThymeRepeatButton> createState() => _ThymeRepeatButtonState();
}

class _ThymeRepeatButtonState extends State<ThymeRepeatButton> {
  Timer? _timer;

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => GestureDetector(
        onLongPressStart: widget.onPressed == null
            ? null
            : (_) {
                _stop();
                _timer = Timer.periodic(const Duration(milliseconds: 90), (_) {
                  if (!mounted || widget.onPressed == null) return _stop();
                  widget.onPressed!();
                });
              },
        onLongPressEnd: (_) => _stop(),
        onLongPressCancel: _stop,
        child: switch (widget.style) {
          ThymeRepeatStyle.plain => IconButton(tooltip: widget.tooltip, iconSize: widget.size, icon: Icon(widget.icon), onPressed: widget.onPressed),
          ThymeRepeatStyle.outlined => IconButton.outlined(tooltip: widget.tooltip, iconSize: widget.size, icon: Icon(widget.icon), onPressed: widget.onPressed),
          ThymeRepeatStyle.filled => IconButton.filled(tooltip: widget.tooltip, iconSize: widget.size, icon: Icon(widget.icon), onPressed: widget.onPressed),
        },
      );
}

enum ThymeRepeatStyle { plain, outlined, filled }

// ───────────────────────── 날짜·기간 (달력 시트) ─────────────────────────

typedef HolidayLoader = Future<Map<DateTime, String>> Function(int year);

/// 날짜 하나
Future<DateTime?> showThymeDatePicker(
  BuildContext context, {
  DateTime? initial,
  required DateTime first,
  required DateTime last,
  String title = '날짜',
  bool Function(DateTime day)? selectable,
  HolidayLoader? holidays,
}) async {
  final r = await _showSheet<DateTimeRange>(
    context,
    _CalendarSheet(
      title: title,
      range: false,
      first: DateUtils.dateOnly(first),
      last: DateUtils.dateOnly(last),
      initialStart: initial == null ? null : DateUtils.dateOnly(initial),
      selectable: selectable,
      holidays: holidays,
    ),
  );
  return r?.start;
}

/// 기간 (시작 → 끝). 같은 날을 두 번 누르거나 끝을 안 고르면 하루
Future<DateTimeRange?> showThymeDateRangePicker(
  BuildContext context, {
  DateTimeRange? initial,
  required DateTime first,
  required DateTime last,
  String title = '기간',
  HolidayLoader? holidays,
}) =>
    _showSheet<DateTimeRange>(
      context,
      _CalendarSheet(
        title: title,
        range: true,
        first: DateUtils.dateOnly(first),
        last: DateUtils.dateOnly(last),
        initialStart: initial == null ? null : DateUtils.dateOnly(initial.start),
        initialEnd: initial == null ? null : DateUtils.dateOnly(initial.end),
        holidays: holidays,
      ),
    );

class _CalendarSheet extends StatefulWidget {
  const _CalendarSheet({
    required this.title,
    required this.range,
    required this.first,
    required this.last,
    this.initialStart,
    this.initialEnd,
    this.selectable,
    this.holidays,
  });

  final String title;
  final bool range;
  final DateTime first;
  final DateTime last;
  final DateTime? initialStart;
  final DateTime? initialEnd;
  final bool Function(DateTime day)? selectable;
  final HolidayLoader? holidays;

  @override
  State<_CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends State<_CalendarSheet> {
  static const _cell = 46.0;
  static const _monthTitle = 48.0;
  static const _monthGap = 12.0;

  late DateTime? _start = widget.initialStart;
  late DateTime? _end = widget.initialEnd;
  final Map<DateTime, String> _holidays = {};
  late final List<DateTime> _months = [
    for (var m = DateTime(widget.first.year, widget.first.month);
        !m.isAfter(DateTime(widget.last.year, widget.last.month));
        m = DateTime(m.year, m.month + 1))
      m,
  ];
  late final ScrollController _scroll;

  /// 일요일 시작 달력에서 그 달의 줄 수
  static int _rows(DateTime month) {
    final lead = DateTime(month.year, month.month, 1).weekday % 7;
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    return ((lead + days) / 7).ceil();
  }

  static double _height(DateTime month) => _monthTitle + _rows(month) * _cell + _monthGap;

  @override
  void initState() {
    super.initState();
    // 고른 날(없으면 오늘, 범위 밖이면 첫 달)이 있는 달에서 연다
    final focus = _start ?? DateUtils.dateOnly(DateTime.now());
    var offset = 0.0;
    for (final m in _months) {
      if (m.year == focus.year && m.month == focus.month) break;
      if (m.isAfter(focus)) {
        offset = 0;
        break;
      }
      offset += _height(m);
    }
    if (offset >= _months.fold<double>(0, (s, m) => s + _height(m))) offset = 0;
    _scroll = ScrollController(initialScrollOffset: offset);
    _loadHolidays();
  }

  Future<void> _loadHolidays() async {
    final loader = widget.holidays;
    if (loader == null) return;
    for (var y = widget.first.year; y <= widget.last.year; y++) {
      try {
        final h = await loader(y);
        if (!mounted) return;
        setState(() => _holidays.addAll({for (final e in h.entries) DateUtils.dateOnly(e.key): e.value}));
      } catch (_) {
        // 공휴일을 못 불러와도 날짜는 고를 수 있다
      }
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  bool _enabled(DateTime d) => !d.isBefore(widget.first) && !d.isAfter(widget.last) && (widget.selectable?.call(d) ?? true);

  void _tap(DateTime d) => setState(() {
        if (!widget.range) {
          _start = d;
          _end = null;
        } else if (_start == null || _end != null) {
          _start = d;
          _end = null;
        } else if (d.isBefore(_start!)) {
          _start = d;
        } else {
          _end = d;
        }
      });

  DateTime? get _rangeEnd => _end ?? _start;

  String _summary() {
    if (!widget.range) return _start == null ? '날짜를 골라 주세요' : thymeMdw(_start!);
    if (_start == null) return '시작일을 골라 주세요';
    if (_end == null) return '${thymeMdw(_start!)} ~ 끝나는 날을 골라 주세요 (하루면 그대로 확인)';
    final days = _end!.difference(_start!).inDays + 1;
    return _end == _start ? '${thymeMdw(_start!)} · 하루' : '${thymeMdw(_start!)} ~ ${thymeMdw(_end!)} · $days일';
  }

  Widget _day(DateTime d) {
    final enabled = _enabled(d);
    final isStart = _start != null && d == _start;
    final isEnd = widget.range && _start != null && d == _rangeEnd;
    final selected = isStart || isEnd;
    final inBand = widget.range && _start != null && _end != null && !d.isBefore(_start!) && !d.isAfter(_end!) && _start != _end;
    final holiday = _holidays[d];
    final today = d == DateUtils.dateOnly(DateTime.now());
    final Color fg = !enabled
        ? ThymeColor.disabled
        : selected
            ? ThymeColor.onPrimary
            : (d.weekday == DateTime.sunday || holiday != null)
                ? ThymeColor.danger
                : d.weekday == DateTime.saturday
                    ? ThymeColor.info
                    : ThymeColor.text;
    return Semantics(
      button: enabled,
      selected: selected,
      label: '${d.month}월 ${d.day}일${holiday == null ? '' : ' $holiday'}',
      child: InkWell(
        key: thymeDayKey(d),
        onTap: enabled ? () => _tap(d) : null,
        child: Stack(alignment: Alignment.center, children: [
          if (inBand)
            Positioned.fill(
              top: 4,
              bottom: 4,
              child: Row(children: [
                Expanded(child: Container(color: d == _start ? Colors.transparent : ThymeColor.selectedSoft)),
                Expanded(child: Container(color: d == _end ? Colors.transparent : ThymeColor.selectedSoft)),
              ]),
            ),
          Container(
            width: 38,
            height: 38,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? ThymeColor.primary : null,
              shape: BoxShape.circle,
              border: today && !selected ? Border.all(color: ThymeColor.border, width: 1.5) : null,
            ),
            child: Text('${d.day}', style: TextStyle(fontSize: 15, fontWeight: selected ? FontWeight.bold : FontWeight.w500, color: fg)),
          ),
        ]),
      ),
    );
  }

  Widget _month(DateTime month) {
    final lead = DateTime(month.year, month.month, 1).weekday % 7;
    final days = DateUtils.getDaysInMonth(month.year, month.month);
    final rows = _rows(month);
    return SizedBox(
      height: _height(month),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
          height: _monthTitle,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 16, 8, 0),
            child: Text('${month.year}년 ${month.month}월', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
          ),
        ),
        for (var r = 0; r < rows; r++)
          SizedBox(
            height: _cell,
            child: Row(children: [
              for (var c = 0; c < 7; c++)
                Expanded(
                  child: Builder(builder: (_) {
                    final n = r * 7 + c - lead + 1;
                    return n < 1 || n > days ? const SizedBox() : _day(DateTime(month.year, month.month, n));
                  }),
                ),
            ]),
          ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ready = _start != null;
    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.86,
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        _SheetHeader(
          title: widget.title,
          action: widget.range && _start != null
              ? TextButton(onPressed: () => setState(() => _start = _end = null), child: const Text('다시 고르기'))
              : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(children: [
            for (final (i, w) in const ['일', '월', '화', '수', '목', '금', '토'].indexed)
              Expanded(
                child: Center(
                  child: Text(w,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: i == 0 ? ThymeColor.danger : (i == 6 ? ThymeColor.info : ThymeColor.textSub))),
                ),
              ),
          ]),
        ),
        const Divider(height: 12),
        Expanded(
          child: ListView.builder(
            controller: _scroll,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _months.length,
            itemBuilder: (_, i) => _month(_months[i]),
          ),
        ),
        _confirmBar(
          label: '확인',
          onPressed: ready ? () => Navigator.pop(context, DateTimeRange(start: _start!, end: _rangeEnd!)) : null,
          summary: Text(_summary(),
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ready ? ThymeColor.text : ThymeColor.textSub)),
        ),
      ]),
    );
  }
}

// ───────────────────────── 먼 날짜 (연·월·일 휠) ─────────────────────────

/// 몇 년 전일 수도 있는 날짜 (근무 시작일 등): 달력을 넘기지 않고 연·월·일을 굴린다
Future<DateTime?> showThymeDateWheel(BuildContext context,
        {required DateTime initial, required DateTime first, required DateTime last, String title = '날짜'}) =>
    _showSheet<DateTime>(context, _DateWheelSheet(title: title, initial: initial, first: first, last: last));

class _DateWheelSheet extends StatefulWidget {
  const _DateWheelSheet({required this.title, required this.initial, required this.first, required this.last});

  final String title;
  final DateTime initial;
  final DateTime first;
  final DateTime last;

  @override
  State<_DateWheelSheet> createState() => _DateWheelSheetState();
}

class _DateWheelSheetState extends State<_DateWheelSheet> {
  late int _y = widget.initial.year;
  late int _m = widget.initial.month;
  late int _d = widget.initial.day;
  late final _yearCtrl = FixedExtentScrollController(initialItem: _y - widget.first.year);
  late final _monthCtrl = FixedExtentScrollController(initialItem: _m - 1);
  late final _dayCtrl = FixedExtentScrollController(initialItem: _d - 1);

  @override
  void dispose() {
    _yearCtrl.dispose();
    _monthCtrl.dispose();
    _dayCtrl.dispose();
    super.dispose();
  }

  DateTime get _value {
    final days = DateUtils.getDaysInMonth(_y, _m);
    final v = DateTime(_y, _m, _d.clamp(1, days));
    if (v.isBefore(widget.first)) return DateUtils.dateOnly(widget.first);
    if (v.isAfter(widget.last)) return DateUtils.dateOnly(widget.last);
    return v;
  }

  Widget _picker({required int count, required String Function(int) label, required ValueChanged<int> onChanged, required FixedExtentScrollController controller, double width = 90}) =>
      SizedBox(
        width: width,
        child: CupertinoPicker(
          itemExtent: 44,
          scrollController: controller,
          onSelectedItemChanged: onChanged,
          children: [for (var i = 0; i < count; i++) Center(child: Text(label(i), style: const TextStyle(fontSize: 20, color: ThymeColor.text)))],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final years = widget.last.year - widget.first.year + 1;
    final days = DateUtils.getDaysInMonth(_y, _m);
    final v = _value;
    return Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _SheetHeader(title: widget.title),
      SizedBox(
        height: 200,
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _picker(count: years, controller: _yearCtrl, label: (i) => '${widget.first.year + i}년', width: 110, onChanged: (i) => setState(() => _y = widget.first.year + i)),
          _picker(count: 12, controller: _monthCtrl, label: (i) => '${i + 1}월', onChanged: (i) => setState(() => _m = i + 1)),
          _picker(count: days, controller: _dayCtrl, label: (i) => '${i + 1}일', onChanged: (i) => setState(() => _d = i + 1)),
        ]),
      ),
      _confirmBar(
        label: '확인',
        onPressed: () => Navigator.pop(context, v),
        summary: Text('${v.year}. ${v.month}. ${v.day} (${_weekdays[v.weekday - 1]})',
            textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
      ),
    ]);
  }
}
