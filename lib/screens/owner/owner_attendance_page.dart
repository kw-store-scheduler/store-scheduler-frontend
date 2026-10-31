import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/owner_api.dart';
import '../../core/theme.dart';
import '../../models/owner.dart';
import '../../models/store.dart' show hhmm;
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_owner_header.dart';

/// 점주 출퇴근 기록 (시안 없음, P08 사람 › 출퇴근 기록). GET /attendance?date= 날짜별 기록,
/// 줄을 누르면 출근·퇴근 시각 고치기 (퇴근 누락·잘못 찍은 기록, PATCH /attendance/{id})
/// 서버는 출근을 찍은 기록만 준다 → 아예 안 찍은 사람은 여기서 만들 수 없다
class OwnerAttendancePage extends StatefulWidget {
  const OwnerAttendancePage({super.key});

  @override
  State<OwnerAttendancePage> createState() => _OwnerAttendancePageState();
}

class _OwnerAttendancePageState extends State<OwnerAttendancePage> {
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  List<AttendanceRecord>? _records;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final r = await OwnerApi().attendance(_date);
      if (mounted) setState(() => _records = r..sort((a, b) => a.clockIn.compareTo(b.clockIn)));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _moveDay(int d) {
    setState(() {
      _date = _date.add(Duration(days: d));
      _records = null;
    });
    _load();
  }

  Future<void> _correct(AttendanceRecord r) async {
    final result = await showModalBottomSheet<({DateTime clockIn, DateTime? clockOut})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThymeColor.surface,
      builder: (_) => _CorrectSheet(record: r),
    );
    if (result == null || !mounted) return;
    try {
      await OwnerApi().correctAttendance(r.id, clockIn: result.clockIn, clockOut: result.clockOut);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("${r.employeeName}님 기록을 고쳤어요")));
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final records = _records;
    final today = DateUtils.dateOnly(DateTime.now());
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: EdgeInsets.zero, children: [
          const ThymeOwnerHeader(title: "출퇴근 기록", showBack: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                IconButton(tooltip: "전날", onPressed: () => _moveDay(-1), icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: Text("${mdw(_date)}${_date == today ? ' · 오늘' : ''}",
                      textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                ),
                IconButton(tooltip: "다음 날", onPressed: _date == today ? null : () => _moveDay(1), icon: const Icon(Icons.chevron_right)),
              ]),
              const SizedBox(height: 8),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                TextButton(onPressed: _load, child: const Text("다시 불러오기")),
              ] else if (records == null)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
              else if (records.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(16)),
                  child: const Text("이날 출근을 찍은 사람이 없어요.", style: TextStyle(fontSize: 14, color: ThymeColor.textSub)),
                )
              else ...[
                Material(
                  color: ThymeColor.surface,
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: Column(children: [
                    for (final (i, r) in records.indexed) ...[
                      if (i > 0) const Divider(height: 1, indent: 18, endIndent: 18),
                      AttendanceTile(record: r, showName: true, onTap: () => _correct(r)),
                    ],
                  ]),
                ),
                const SizedBox(height: 8),
                const Text("줄을 누르면 출근·퇴근 시각을 고쳐요. 고친 시간으로 급여가 다시 계산돼요.",
                    style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
              ],
            ]),
          ),
        ]),
      ),
    );
  }
}

/// 출퇴근 한 줄 (점주 기록 화면 · 근로자 근무 기록 화면 같이 씀)
class AttendanceTile extends StatelessWidget {
  const AttendanceTile({super.key, required this.record, this.showName = false, this.onTap});

  final AttendanceRecord record;
  final bool showName;
  final VoidCallback? onTap;

  static String _hm(DateTime t) => "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    final r = record;
    final missing = r.missingClockOut(DateTime.now());
    final out = r.clockOut == null
        ? (missing ? "퇴근 안 찍음" : "근무 중")
        : "${_hm(r.clockOut!)}${DateUtils.isSameDay(r.clockOut, r.clockIn) ? '' : ' (다음 날)'}";
    final plan = r.scheduledStart == null ? "근무표에 없는 출근" : "근무 ${hhmm(r.scheduledStart!)}–${hhmm(r.scheduledEnd!)}";
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      onTap: onTap,
      title: Text(showName ? r.employeeName : mdw(r.workDate), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
      subtitle: Text(plan, style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
      trailing: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text("${_hm(r.clockIn)} – $out",
            style: ThymeTheme.mono(context, size: 14, color: missing ? ThymeColor.dangerText : ThymeColor.text)),
        if (r.late) const Text("지각", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ThymeColor.dangerText)),
      ]),
    );
  }
}

/// 출근·퇴근 시각 고치기. 퇴근이 출근보다 이르면 다음 날로 본다 (자정 넘는 근무)
class _CorrectSheet extends StatefulWidget {
  const _CorrectSheet({required this.record});

  final AttendanceRecord record;

  @override
  State<_CorrectSheet> createState() => _CorrectSheetState();
}

class _CorrectSheetState extends State<_CorrectSheet> {
  late TimeOfDay _in = TimeOfDay.fromDateTime(widget.record.clockIn);
  late TimeOfDay? _out = widget.record.clockOut == null ? _planned(widget.record.scheduledEnd) : TimeOfDay.fromDateTime(widget.record.clockOut!);

  static TimeOfDay? _planned(String? t) => t == null ? null : TimeOfDay(hour: int.parse(t.substring(0, 2)), minute: int.parse(t.substring(3, 5)));

  static String _fmt(TimeOfDay? t) => t == null ? "--:--" : "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";

  Future<void> _pick(bool clockIn) async {
    final t = await showTimePicker(
      context: context,
      initialTime: (clockIn ? _in : _out) ?? _in,
      helpText: clockIn ? "출근 시각" : "퇴근 시각",
    );
    if (t != null) setState(() => clockIn ? _in = t : _out = t);
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.record;
    final day = DateUtils.dateOnly(r.clockIn);
    DateTime at(TimeOfDay t) => day.add(Duration(hours: t.hour, minutes: t.minute));
    final clockIn = at(_in);
    var clockOut = _out == null ? null : at(_out!);
    if (clockOut != null && !clockOut.isAfter(clockIn)) clockOut = clockOut.add(const Duration(days: 1));
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text("${r.employeeName} · ${mdw(r.workDate)} 기록 고치기", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          if (r.scheduledStart != null) ...[
            const SizedBox(height: 4),
            Text("근무표 ${hhmm(r.scheduledStart!)}–${hhmm(r.scheduledEnd!)}", style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
          ],
          const SizedBox(height: 16),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => _pick(true), child: Text("출근 ${_fmt(_in)}"))),
            const SizedBox(width: 10),
            Expanded(child: OutlinedButton(onPressed: () => _pick(false), child: Text("퇴근 ${_fmt(_out)}"))),
          ]),
          if (clockOut != null && !DateUtils.isSameDay(clockOut, clockIn)) ...[
            const SizedBox(height: 6),
            const Text("퇴근이 출근보다 일러서 다음 날 퇴근으로 저장해요.", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
          ],
          const SizedBox(height: 20),
          FilledButton(onPressed: () => Navigator.pop(context, (clockIn: clockIn, clockOut: clockOut)), child: const Text("저장")),
        ]),
      ),
    );
  }
}
