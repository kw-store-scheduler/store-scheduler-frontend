import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../core/worker_api.dart';
import '../../models/owner.dart';
import '../../models/worker.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_back_button.dart';
import '../../widgets/thyme_leaf.dart';
import 'w09_shift_swap_page.dart';

/// W10 희망 반영 결과. GET /preference-report/my?month= (확정된 그달 근무표 기준)
/// 선호 반영률, 휴무 수용률, 최근 4주 부담 근무(주말·마감·야간) 나 vs 팀 평균, 반영 못 한 근무와 이유
class PreferenceReportPage extends StatefulWidget {
  const PreferenceReportPage({super.key, this.month});

  /// 없으면 이번 달
  final DateTime? month;

  @override
  State<PreferenceReportPage> createState() => _PreferenceReportPageState();
}

class _PreferenceReportPageState extends State<PreferenceReportPage> {
  late final DateTime _month = widget.month ?? DateTime(DateTime.now().year, DateTime.now().month);
  PreferenceReport? _report;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final r = await WorkerApi().preferenceReport(_month);
      if (mounted) setState(() => _report = r);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _report;
    final first = r?.unfulfilled.firstOrNull;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: AppBar(
        backgroundColor: ThymeColor.bg,
        elevation: 0,
        leading: const ThymeBackButton(size: 20),
        title: Text("${_month.month}월 희망 반영 결과", style: const TextStyle(color: ThymeColor.text, fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                TextButton(onPressed: _load, child: const Text("다시 불러오기")),
              ] else if (r == null)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
              else if (r.assignedCount == 0)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(16)),
                  child: Text("${_month.month}월에 확정된 내 근무가 없어요.", style: const TextStyle(fontSize: 14, color: ThymeColor.textSub)),
                )
              else ...[
                Row(children: [
                  Expanded(
                    child: _rateCard(
                      dark: true,
                      label: "희망 반영",
                      rate: r.preferenceRate,
                      sub: r.preferenceRate == null ? "선호를 낸 근무가 없어요" : "${r.assignedCount}개 중 ${r.honoredCount}개",
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _rateCard(
                      dark: false,
                      label: "휴무 요청 수용",
                      rate: r.dayOffRate,
                      sub: r.dayOffRequested == 0 ? "휴무 요청이 없었어요" : "${r.dayOffRequested}개 중 ${r.dayOffHonored}개",
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                _burdenCard(r.burdens),
                const SizedBox(height: 12),
                _unfulfilledCard(r.unfulfilled),
              ],
            ]),
          ),
          if (first != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ShiftSwapPage(scheduleId: first.scheduleId))),
                  child: const Text("이 근무 교대 요청하기"),
                ),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _rateCard({required bool dark, required String label, required double? rate, required String sub}) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: dark ? ThymeColor.primary : ThymeColor.surface, borderRadius: BorderRadius.circular(22)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 14, color: dark ? ThymeColor.onPrimarySub : ThymeColor.textSub)),
          const SizedBox(height: 6),
          Text(rate == null ? "–" : "${rate.round()}%",
              style: ThymeTheme.mono(context, size: 34, color: dark ? ThymeColor.accent : ThymeColor.text)),
          const SizedBox(height: 4),
          Text(sub, style: TextStyle(fontSize: 13, color: dark ? ThymeColor.onPrimarySub : ThymeColor.textSub)),
        ]),
      );

  Widget _burdenCard(List<Burden> burdens) {
    final maxV = burdens.fold<double>(1, (m, b) => [m, b.mine.toDouble(), b.teamAverage].reduce((a, c) => a > c ? a : c));
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(24)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Row(children: [
          Expanded(child: Text("부담 근무, 나와 팀 평균", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text))),
          Text("최근 4주 누적", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
        ]),
        const SizedBox(height: 14),
        for (final b in burdens) ...[
          Row(children: [
            Expanded(child: Text("${b.label} 근무", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text))),
            Text("나 ${b.mine}회 · 평균 ${b.teamAverage.toStringAsFixed(1)}", style: ThymeTheme.mono(context, size: 13, color: ThymeColor.textSub)),
          ]),
          const SizedBox(height: 8),
          LayoutBuilder(builder: (context, c) {
            final w = c.maxWidth;
            return SizedBox(
              height: 18,
              child: Stack(alignment: Alignment.centerLeft, children: [
                Container(height: 10, decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(5))),
                Container(
                  height: 10,
                  width: w * b.mine / maxV,
                  decoration: BoxDecoration(color: ThymeColor.accent, borderRadius: BorderRadius.circular(5)),
                ),
                Positioned(left: (w * b.teamAverage / maxV - 2).clamp(0, w - 4), child: Container(width: 4, height: 18, color: ThymeColor.primary)),
              ]),
            );
          }),
          const SizedBox(height: 14),
        ],
        const Text("민트 막대가 나, 세로선이 팀 평균이에요.", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
      ]),
    );
  }

  Widget _unfulfilledCard(List<Unfulfilled> items) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(items.isEmpty ? "원하던 교대에 모두 배정됐어요" : "반영되지 못한 ${items.length}건",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
          for (final u in items) ...[
            const SizedBox(height: 12),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Padding(padding: EdgeInsets.only(top: 2), child: ThymeLeaf(size: 20, color: ThymeColor.icon, dashed: true)),
              const SizedBox(width: 12),
              Expanded(
                child: Text.rich(TextSpan(style: const TextStyle(fontSize: 14, color: ThymeColor.charcoal, height: 1.5), children: [
                  TextSpan(
                    text: "${mdw(u.workDate)} ${u.preferredShiftNames.join('·')} 선호 → ${u.assignedShiftName ?? timeRange(u.startTime, u.endTime)} 배정. ",
                    style: const TextStyle(fontWeight: FontWeight.bold, color: ThymeColor.text),
                  ),
                  TextSpan(text: u.reasons.join(" ")),
                ])),
              ),
            ]),
          ],
        ]),
      );
}
