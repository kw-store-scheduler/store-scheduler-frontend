import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/notice_api.dart';
import '../../core/theme.dart';
import '../../core/worker_api.dart';
import '../../models/worker.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_worker_home_parts.dart';
import '../../widgets/thyme_worker_tab_bar.dart';
import 'e01_employee_leave_page.dart';
import 'h04_notification_page.dart';
import 'h12_absence_report_page.dart';
import 'w08_cover_accept_page.dart';

/// H02 직원 홈. GET /home/worker + 오늘 내 업무(GET /tasks/my) (가이드 4-0 직원 vs 알바)
/// 오늘 근무(출근·퇴근) → 이번 주 근무 시간 · 남은 연차 → 나에게 온 대타 요청 → 오늘 업무 체크리스트
class EmployeeHomePage extends StatefulWidget {
  const EmployeeHomePage({super.key});

  @override
  State<EmployeeHomePage> createState() => _EmployeeHomePageState();
}

class _EmployeeHomePageState extends State<EmployeeHomePage> {
  /// 직원 주 소정근로시간 (진행바 기준)
  static const _weekLimit = 40;

  WorkerHome? _home;
  List<StoreTask> _tasks = const [];
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final h = await WorkerApi().home();
      // 업무는 덤이라 못 받아도 홈은 보여 준다
      final tasks = await NoticeApi().myTasks().catchError((_) => <StoreTask>[]);
      if (mounted) {
        setState(() {
          _home = h;
          _tasks = tasks;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _load();
  }

  Future<void> _clock() async {
    final h = _home!;
    setState(() => _busy = true);
    try {
      final api = WorkerApi();
      h.clockIn == null ? await api.clockIn() : await api.clockOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(h.clockIn == null ? "출근을 기록했어요" : "퇴근을 기록했어요. 수고했어요")));
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toggle(StoreTask t) async {
    try {
      final updated = await NoticeApi().check(t.id, !t.done);
      if (mounted) setState(() => _tasks = [for (final x in _tasks) x.id == t.id ? updated : x]);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  double _weekHours(WorkerHome h) {
    int mins(String t) => int.parse(t.substring(0, 2)) * 60 + int.parse(t.substring(3, 5));
    var total = 0;
    for (final d in h.week.where((d) => d.working)) {
      var m = mins(d.endTime!) - mins(d.startTime!);
      if (m <= 0) m += 24 * 60;
      total += m;
    }
    return total / 60;
  }

  @override
  Widget build(BuildContext context) {
    final h = _home;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
            Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text("${h?.storeName ?? WorkerApi().myStoreName ?? ''} · 직원", style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                  const SizedBox(height: 4),
                  Text(greeting(h?.employeeName ?? WorkerApi().myDisplayName ?? ''),
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                ]),
              ),
              IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: ThymeColor.surface, fixedSize: const Size(48, 48)),
                icon: const Icon(Icons.notifications_none, color: ThymeColor.text),
                onPressed: () => _open(const NotificationPage()),
              ),
            ]),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
              TextButton(onPressed: _load, child: const Text("다시 불러오기")),
            ] else if (h == null)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
            else ...[
              WorkerTodayCard(home: h, busy: _busy, onClock: _clock, onAbsent: () => _open(AbsenceReportPage(shift: h.today))),
              const SizedBox(height: 12),
              _stats(h),
              if (h.swapOffers.isNotEmpty) ...[
                const SizedBox(height: 12),
                WorkerOfferBanner(
                  offer: h.swapOffers.first,
                  more: h.swapOffers.length - 1,
                  onTap: () => _open(CoverAcceptPage(offerId: h.swapOffers.first.offerId)),
                ),
              ],
              ..._preferenceRow(h),
              const SizedBox(height: 12),
              _taskCard(),
            ],
          ]),
        ),
      ),
      bottomNavigationBar: const ThymeWorkerTabBar(current: WorkerTab.home),
    );
  }

  /// 다음 달 연차·희망 제출 (마감이 지나도 서버는 받는다. 낸 뒤에도 고칠 수 있다)
  List<Widget> _preferenceRow(WorkerHome h) {
    final p = h.nextMonthPreferences;
    final month = DateTime(int.parse(p.month.substring(0, 4)), int.parse(p.month.substring(5, 7)));
    final (dot, title, trailing) = p.submittedByMe
        ? (ThymeColor.accent, "${p.monthNumber}월 연차·희망 제출 완료", "고치기")
        : (p.daysUntilDeadline >= 0 ? ThymeColor.warn : ThymeColor.danger, "${p.monthNumber}월 연차·희망 제출 · 아직 안 냈어요",
            p.daysUntilDeadline >= 0 ? "D-${p.daysUntilDeadline}" : "마감 지남");
    return [
      const SizedBox(height: 12),
      Material(
        color: ThymeColor.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          leading: Icon(Icons.circle, size: 10, color: dot),
          minLeadingWidth: 10,
          title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
          trailing: Text(trailing, style: const TextStyle(color: ThymeColor.textSub)),
          onTap: () => _open(EmployeeLeavePage(month: month)),
        ),
      ),
    ];
  }

  Widget _stats(WorkerHome h) {
    final week = _weekHours(h);
    return Container(
      decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
      child: IntrinsicHeight(
        child: Row(children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("이번 주 근무", style: TextStyle(fontSize: 14, color: ThymeColor.textSub)),
                const SizedBox(height: 8),
                Text.rich(TextSpan(children: [
                  TextSpan(text: hours(week), style: ThymeTheme.mono(context, size: 26)),
                  TextSpan(text: " / ${_weekLimit}h", style: ThymeTheme.mono(context, size: 15, color: ThymeColor.textSub)),
                ])),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (week / _weekLimit).clamp(0, 1),
                    minHeight: 8,
                    color: ThymeColor.info,
                    backgroundColor: ThymeColor.surfaceSub,
                  ),
                ),
              ]),
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text("남은 연차", style: TextStyle(fontSize: 14, color: ThymeColor.textSub)),
                const SizedBox(height: 8),
                Text.rich(TextSpan(children: [
                  TextSpan(text: "${h.leaveRemaining ?? '-'}", style: ThymeTheme.mono(context, size: 26)),
                  const TextSpan(text: "일", style: TextStyle(fontSize: 15, color: ThymeColor.textSub)),
                ])),
                if (h.leaveEntitled != null) ...[
                  const SizedBox(height: 6),
                  Text("올해 ${h.leaveEntitled}일 중", style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                ],
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _taskCard() {
    final done = _tasks.where((t) => t.done).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Expanded(child: Text("오늘 내 업무", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text))),
          if (_tasks.isNotEmpty) Text("$done / ${_tasks.length}", style: ThymeTheme.mono(context, size: 14, color: ThymeColor.successText)),
        ]),
        const SizedBox(height: 4),
        if (_tasks.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Text("오늘 맡은 업무가 없어요.", style: TextStyle(fontSize: 14, color: ThymeColor.textSub)),
          )
        else
          for (final t in _tasks)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: t.done,
              onChanged: (_) => _toggle(t),
              activeColor: ThymeColor.accent,
              checkColor: ThymeColor.onAccent,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(t.title,
                  style: TextStyle(
                      fontSize: 15,
                      color: t.done ? ThymeColor.textSub : ThymeColor.text,
                      decoration: t.done ? TextDecoration.lineThrough : null)),
            ),
      ]),
    );
  }
}
