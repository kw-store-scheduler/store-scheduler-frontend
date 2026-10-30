import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../core/worker_api.dart';
import '../../models/owner.dart';
import '../../models/worker.dart';
import '../../widgets/thyme_worker_home_parts.dart';
import '../../widgets/thyme_worker_tab_bar.dart';
import 'h04_notification_page.dart';
import 'h12_absence_report_page.dart';
import 'w00_load_last_month_page.dart';
import 'w08_cover_accept_page.dart';

/// H01 알바 홈. GET /home/worker
/// 오늘 근무(출근·퇴근, 오늘 못 나가요) → 나에게 온 대타 요청 → 희망 제출·새 공지 → 이번 주 → 이번 달 예상 급여
class PartTimerHomePage extends StatefulWidget {
  const PartTimerHomePage({super.key});

  @override
  State<PartTimerHomePage> createState() => _PartTimerHomePageState();
}

class _PartTimerHomePageState extends State<PartTimerHomePage> {
  WorkerHome? _home;
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
      if (mounted) setState(() => _home = h);
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
                  Text("${h?.storeName ?? WorkerApi().myStoreName ?? ''} · 알바", style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
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
              if (h.swapOffers.isNotEmpty) ...[
                const SizedBox(height: 12),
                WorkerOfferBanner(
                  offer: h.swapOffers.first,
                  more: h.swapOffers.length - 1,
                  onTap: () => _open(CoverAcceptPage(offerId: h.swapOffers.first.offerId)),
                ),
              ],
              ..._notices(h),
              const SizedBox(height: 12),
              WorkerWeekStrip(week: h.week, today: h.date, onAll: () => ThymeWorkerTabBar.go(context, WorkerTab.schedule)),
              const SizedBox(height: 12),
              _payCard(h),
            ],
          ]),
        ),
      ),
      bottomNavigationBar: const ThymeWorkerTabBar(current: WorkerTab.home),
    );
  }

  /// 희망 제출 · 새 공지 (구분선 리스트의 옐로·페리 점)
  List<Widget> _notices(WorkerHome h) {
    final p = h.nextMonthPreferences;
    final rows = <Widget>[
      // 마감이 지나도 서버는 받는다 (사장님 화면에 '늦게 냄'으로 보임). 낸 뒤에도 다시 고칠 수 있다
      if (!p.submittedByMe)
        _row(p.daysUntilDeadline >= 0 ? ThymeColor.warn : ThymeColor.danger, "${p.monthNumber}월 희망 제출 · 아직 안 냈어요",
            p.daysUntilDeadline >= 0 ? "D-${p.daysUntilDeadline}" : "마감 지남", () => _open(LoadLastMonthPage(month: _monthOf(p.month))))
      else
        _row(ThymeColor.accent, "${p.monthNumber}월 희망 제출 완료", "고치기", () => _open(LoadLastMonthPage(month: _monthOf(p.month)))),
      if (h.latestNoticeTitle != null)
        _row(ThymeColor.info, "새 공지 · ${h.latestNoticeTitle}", h.latestNoticeAt == null ? null : "${h.latestNoticeAt!.month}/${h.latestNoticeAt!.day}",
            () => ThymeWorkerTabBar.go(context, WorkerTab.notice)),
    ];
    if (rows.isEmpty) return const [];
    return [
      const SizedBox(height: 12),
      Material(
        color: ThymeColor.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 20, endIndent: 20),
            rows[i],
          ],
        ]),
      ),
    ];
  }

  /// "2026-11" → 2026년 11월 1일
  static DateTime _monthOf(String ym) => DateTime(int.parse(ym.substring(0, 4)), int.parse(ym.substring(5, 7)));

  Widget _row(Color dot, String title, String? trailing, VoidCallback? onTap) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Icon(Icons.circle, size: 10, color: dot),
        minLeadingWidth: 10,
        title: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
        trailing: trailing == null ? null : Text(trailing, style: const TextStyle(fontSize: 14, color: ThymeColor.textSub)),
        onTap: onTap,
      );

  Widget _payCard(WorkerHome h) => Material(
        color: ThymeColor.primary,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => ThymeWorkerTabBar.go(context, WorkerTab.me),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    "${h.date.month}월 예상 급여 · ${hours(h.monthHours)}시간${h.weeklyHolidayPay > 0 ? ' · 주휴 포함' : ''}",
                    style: const TextStyle(fontSize: 13, color: ThymeColor.onPrimarySub),
                  ),
                  const SizedBox(height: 4),
                  Text(won(h.monthPay), style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.accent)),
                ]),
              ),
              const Text("내 정보 →", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.onPrimary)),
            ]),
          ),
        ),
      );
}
