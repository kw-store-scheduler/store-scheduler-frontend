import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/store_api.dart';
import '../../core/theme.dart';
import '../../core/worker_api.dart';
import '../../models/owner.dart';
import '../../models/store.dart';
import '../../models/worker.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_back_button.dart';
import '../../widgets/thyme_leaf.dart';
import '../../widgets/thyme_worker_tab_bar.dart';
import 'w10_preference_report_page.dart';

/// W07 나의 근무표 (근로자 하단 탭 '근무표'). GET /schedules/my (확정 근무) + 교대 이름(GET /shifts)
/// 날짜를 누르면 그날 배정 사유(reasons)를 보여 준다. 열면 서버가 확정 근무표를 확인한 것으로 기록한다
class MySchedulePage extends StatefulWidget {
  const MySchedulePage({super.key});

  @override
  State<MySchedulePage> createState() => _MySchedulePageState();
}

class _MySchedulePageState extends State<MySchedulePage> {
  List<MyShift>? _shifts;
  List<ShiftInfo> _storeShifts = const [];
  late DateTime _month;
  DateTime? _selected;
  String? _error;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month);
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final mine = await WorkerApi().mySchedules();
      // 교대 이름은 꾸밈이라 못 받아도 시간만 보여 준다
      final storeShifts = await StoreApi().shifts().catchError((_) => <ShiftInfo>[]);
      if (!mounted) return;
      setState(() {
        _shifts = mine;
        _storeShifts = storeShifts;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  String? _shiftName(MyShift s) =>
      _storeShifts.where((x) => hm(x.startTime) == hm(s.startTime) && hm(x.endTime) == hm(s.endTime)).firstOrNull?.name;

  List<MyShift> get _monthShifts => [
        for (final s in _shifts ?? const <MyShift>[])
          if (s.workDate.year == _month.year && s.workDate.month == _month.month) s,
      ];

  double _hoursOf(MyShift s) {
    int mins(String t) => int.parse(t.substring(0, 2)) * 60 + int.parse(t.substring(3, 5));
    var d = mins(s.endTime) - mins(s.startTime);
    if (d <= 0) d += 24 * 60;
    return d / 60;
  }

  void _moveMonth(int delta) => setState(() {
        _month = DateTime(_month.year, _month.month + delta);
        _selected = null;
      });

  @override
  Widget build(BuildContext context) {
    final monthShifts = _monthShifts;
    final byDay = {for (final s in monthShifts) s.workDate.day: s};
    final selected = _selected == null ? null : byDay[_selected!.day];
    final storeName = WorkerApi().myStoreName;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: EdgeInsets.zero, children: [
          // 민트 머리 (결과 화면: 확정 = 민트)
          Container(
            padding: EdgeInsets.fromLTRB(12, MediaQuery.paddingOf(context).top + 12, 20, 22),
            decoration: const BoxDecoration(color: ThymeColor.accent, borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))),
            child: Row(children: [
              if (Navigator.canPop(context)) const ThymeBackButton(size: 20) else const SizedBox(width: 8),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  if (storeName != null) Text(storeName, style: const TextStyle(fontSize: 13, color: ThymeColor.onAccent)),
                  const SizedBox(height: 2),
                  Row(children: [
                    GestureDetector(onTap: () => _moveMonth(-1), child: const Icon(Icons.chevron_left, color: ThymeColor.onAccent)),
                    Text("나의 ${_month.month}월 근무표", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ThymeColor.onAccent)),
                    GestureDetector(onTap: () => _moveMonth(1), child: const Icon(Icons.chevron_right, color: ThymeColor.onAccent)),
                  ]),
                ]),
              ),
              if (monthShifts.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(16)),
                  child: const Row(children: [
                    ThymeLeaf(size: 14),
                    SizedBox(width: 4),
                    Text("확정", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.successText)),
                  ]),
                ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: _error != null
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                    TextButton(onPressed: _load, child: const Text("다시 불러오기")),
                  ])
                : _shifts == null
                    ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                    : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        _calendar(byDay),
                        const SizedBox(height: 12),
                        _reasonCard(selected, monthShifts),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PreferenceReportPage(month: _month))),
                          child: const Text("내 희망이 얼마나 반영됐는지 보기"),
                        ),
                      ]),
          ),
        ]),
      ),
      bottomNavigationBar: const ThymeWorkerTabBar(current: WorkerTab.schedule),
    );
  }

  Widget _calendar(Map<int, MyShift> byDay) {
    final first = DateTime(_month.year, _month.month);
    final days = DateTime(_month.year, _month.month + 1, 0).day;
    final lead = first.weekday % 7; // 일요일 시작
    final total = byDay.values.fold<double>(0, (a, s) => a + _hoursOf(s));
    const heads = ['일', '월', '화', '수', '목', '금', '토'];
    Color dayColor(int col) => col == 0 ? ThymeColor.dangerText : (col == 6 ? ThymeColor.infoText : ThymeColor.text);
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 16),
      decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(24)),
      child: Column(children: [
        Row(children: [
          for (var c = 0; c < 7; c++)
            Expanded(child: Center(child: Text(heads[c], style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: dayColor(c))))),
        ]),
        const SizedBox(height: 8),
        for (var row = 0; row * 7 < lead + days; row++)
          Row(children: [
            for (var c = 0; c < 7; c++)
              Expanded(
                child: Builder(builder: (context) {
                  final day = row * 7 + c - lead + 1;
                  if (day < 1 || day > days) return const SizedBox(height: 58);
                  final s = byDay[day];
                  final sel = _selected?.day == day;
                  return GestureDetector(
                    onTap: s == null ? null : () => setState(() => _selected = DateTime(_month.year, _month.month, day)),
                    child: Container(
                      height: 58,
                      margin: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: s == null ? null : ThymeColor.successBg,
                        borderRadius: BorderRadius.circular(12),
                        border: sel ? Border.all(color: ThymeColor.primary, width: 2) : null,
                      ),
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text("$day", style: ThymeTheme.mono(context, size: 14, color: dayColor(c))),
                        if (s != null)
                          Text(_shiftName(s) ?? hourRange(s.startTime, s.endTime),
                              maxLines: 1, overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: ThymeColor.successText)),
                      ]),
                    ),
                  );
                }),
              ),
          ]),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(children: [
            Container(width: 14, height: 14, decoration: BoxDecoration(color: ThymeColor.successBg, borderRadius: BorderRadius.circular(4))),
            const SizedBox(width: 6),
            const Text("근무", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
            const Spacer(),
            Text("${byDay.length}일 · ${hours(total)}h", style: ThymeTheme.mono(context, size: 14)),
          ]),
        ),
      ]),
    );
  }

  Widget _reasonCard(MyShift? s, List<MyShift> monthShifts) {
    final String title;
    final List<String> reasons;
    if (monthShifts.isEmpty) {
      title = "배정 사유";
      reasons = const ["이달 확정된 근무가 없어요. 근무표가 확정되면 알림으로 알려 드려요."];
    } else if (s == null) {
      title = "배정 사유";
      reasons = const ["날짜를 누르면 그날 왜 이렇게 배정됐는지 보여 드려요."];
    } else {
      title = "${mdw(s.workDate)} ${_shiftName(s) ?? ''} ${timeRange(s.startTime, s.endTime)}";
      reasons = s.reasons.isEmpty ? const ["사장님이 직접 넣거나 바꾼 근무예요."] : s.reasons;
    }
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.info_outline, size: 20, color: ThymeColor.text),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text))),
        ]),
        const SizedBox(height: 10),
        for (final r in reasons)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text("· $r", style: const TextStyle(fontSize: 14, color: ThymeColor.charcoal, height: 1.5)),
          ),
      ]),
    );
  }
}
