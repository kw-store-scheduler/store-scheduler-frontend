import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../core/worker_api.dart';
import '../../models/owner.dart';
import '../../widgets/thyme_back_button.dart';
import '../owner/owner_attendance_page.dart' show AttendanceTile;

/// 근로자 내 근무 기록 (시안 없음, H06 '근무 기록'). GET /attendance/my 한 달씩.
/// 근로자가 직접 고치는 API 는 없어서 보기만 하고, 잘못 찍혔으면 사장님께 고쳐 달라고 안내한다
class WorkerAttendancePage extends StatefulWidget {
  const WorkerAttendancePage({super.key});

  @override
  State<WorkerAttendancePage> createState() => _WorkerAttendancePageState();
}

class _WorkerAttendancePageState extends State<WorkerAttendancePage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
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
      final r = await WorkerApi().myAttendance(_month, DateTime(_month.year, _month.month + 1, 0));
      if (mounted) setState(() => _records = r..sort((a, b) => b.clockIn.compareTo(a.clockIn)));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _moveMonth(int d) {
    setState(() {
      _month = DateTime(_month.year, _month.month + d);
      _records = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final records = _records;
    final now = DateTime.now();
    final thisMonth = _month.year == now.year && _month.month == now.month;
    final missing = records?.where((r) => r.missingClockOut(now)).length ?? 0;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: AppBar(
        backgroundColor: ThymeColor.bg,
        leading: const ThymeBackButton(),
        title: const Text("근무 기록", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 0, 20, 32), children: [
          Row(children: [
            IconButton(tooltip: "지난달", onPressed: () => _moveMonth(-1), icon: const Icon(Icons.chevron_left)),
            Expanded(
              child: Text("${_month.year}년 ${_month.month}월",
                  textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            ),
            IconButton(tooltip: "다음 달", onPressed: thisMonth ? null : () => _moveMonth(1), icon: const Icon(Icons.chevron_right)),
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
              child: const Text("이달 출퇴근 기록이 없어요.", style: TextStyle(fontSize: 14, color: ThymeColor.textSub)),
            )
          else ...[
            Text("출근 ${records.length}번${missing > 0 ? ' · 퇴근 안 찍음 $missing번' : ''}",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: missing > 0 ? ThymeColor.dangerText : ThymeColor.textSub)),
            const SizedBox(height: 8),
            Material(
              color: ThymeColor.surface,
              borderRadius: BorderRadius.circular(20),
              clipBehavior: Clip.antiAlias,
              child: Column(children: [
                for (final (i, r) in records.indexed) ...[
                  if (i > 0) const Divider(height: 1, indent: 18, endIndent: 18),
                  AttendanceTile(record: r),
                ],
              ]),
            ),
          ],
          const SizedBox(height: 12),
          const Text("기록이 잘못됐거나 퇴근을 못 찍었으면 사장님께 고쳐 달라고 말해 주세요. 사장님이 고치면 급여도 다시 계산돼요.",
              style: TextStyle(fontSize: 13, color: ThymeColor.textSub, height: 1.5)),
        ]),
      ),
    );
  }
}
