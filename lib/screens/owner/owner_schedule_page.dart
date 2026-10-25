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
/// 다음 주기 일정(GET /schedules/plan)과 '근무표 만들기'(P03)로 간다
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
                            child: const Text("아직 확정된 근무표가 없어요. '근무표 만들기'로 3안을 받아 하나를 확정해 주세요.",
                                style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.5)),
                          )
                        else
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
      ]),
    );
  }
}
