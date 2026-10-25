import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/home_router.dart';
import '../../core/owner_api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../models/owner.dart';
import '../../theme/thyme_theme.dart';
import 'p03_generating_schedule_page.dart' show periodLabel;
import 'p04_share_complete_page.dart';

/// M05 3안 비교. 공정 우선 · 인건비 우선 · 희망 우선 후보를 비교하고 하나를 확정한다 (POST /proposals/{id}/confirm)
class ProposalComparePage extends StatefulWidget {
  const ProposalComparePage({super.key, required this.proposal, this.monthly = false});

  final Proposal proposal;
  final bool monthly;

  @override
  State<ProposalComparePage> createState() => _ProposalComparePageState();
}

class _ProposalComparePageState extends State<ProposalComparePage> {
  late ProposalCandidate _selected = widget.proposal.candidates.first;
  bool _saving = false;

  static const _letters = ["A", "B", "C", "D", "E"];

  String _letter(ProposalCandidate c) => c.index < _letters.length ? _letters[c.index] : "${c.index + 1}";

  String get _period => periodLabel(widget.proposal.periodStart, widget.proposal.periodEnd, monthly: widget.monthly);

  Future<void> _confirm() async {
    final p = widget.proposal;
    setState(() => _saving = true);
    try {
      await OwnerApi().confirm(p.proposalId!, _selected.index);
      if (!mounted) return;
      resetTo(context, ShareCompletePage(proposalId: p.proposalId!, letter: _letter(_selected), period: _period, candidate: _selected));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showReasons() => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: ThymeColor.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          builder: (context, scroll) {
            final rows = [..._selected.assignments]..sort((a, b) => a.workDate.compareTo(b.workDate) != 0 ? a.workDate.compareTo(b.workDate) : a.startTime.compareTo(b.startTime));
            return ListView(controller: scroll, padding: const EdgeInsets.fromLTRB(20, 20, 20, 24), children: [
              Text("${_letter(_selected)}안 배정 사유", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              const SizedBox(height: 12),
              if (rows.isEmpty) const Text("배정이 없어요.", style: TextStyle(color: ThymeColor.textSub)),
              for (final a in rows)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("${mdw(a.workDate)} ${a.shiftName ?? ''} ${hourRange(a.startTime, a.endTime)} · ${a.employeeName}",
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                    for (final r in a.reasons)
                      Text("· $r", style: const TextStyle(fontSize: 13, color: ThymeColor.textSub, height: 1.5)),
                  ]),
                ),
            ]);
          },
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = widget.proposal;
    final c = _selected;
    final store = Session.instance.currentOwnedStore?.name;
    final notices = [...c.warnings, if (p.needsAttention && p.noticeSummary != null) p.noticeSummary!];
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: Column(children: [
        Expanded(
          child: ListView(padding: EdgeInsets.zero, children: [
            Container(
              padding: EdgeInsets.fromLTRB(20, MediaQuery.paddingOf(context).top + 16, 20, 24),
              decoration: const BoxDecoration(color: ThymeColor.primary, borderRadius: BorderRadius.vertical(bottom: Radius.circular(24))),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  if (Navigator.canPop(context))
                    IconButton(
                      padding: EdgeInsets.zero,
                      alignment: Alignment.centerLeft,
                      icon: const Icon(Icons.arrow_back_ios, color: ThymeColor.onPrimary, size: 20),
                      onPressed: () => Navigator.maybePop(context),
                    ),
                  const Text("OWNER", style: TextStyle(color: ThymeColor.onPrimarySub, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1)),
                ]),
                const SizedBox(height: 4),
                Text(
                  [?store, if (p.solveMs != null) "${(p.solveMs! / 1000).toStringAsFixed(1)}초 만에 계산"].join(" · "),
                  style: const TextStyle(color: ThymeColor.onPrimarySub, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text("$_period 근무표 ${p.candidates.length}안이 준비됐어요",
                    style: const TextStyle(color: ThymeColor.onPrimary, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Row(children: [
                  _stat("노동법 위반", "${c.laborLawViolations}건", c.laborLawViolations == 0),
                  const SizedBox(width: 10),
                  _stat("최소 인원 충족", "${_pct(c.minStaffCoverage)}%", c.minStaffCoverage >= 100),
                ]),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                for (final cand in p.candidates) _candidateCard(cand),
                for (final n in notices)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: ThymeColor.warnBg, borderRadius: BorderRadius.circular(16)),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Padding(padding: EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 10, color: ThymeColor.warn)),
                      const SizedBox(width: 12),
                      Expanded(child: Text(n, style: const TextStyle(fontSize: 14, color: ThymeColor.warnText, height: 1.5))),
                    ]),
                  ),
              ]),
            ),
          ]),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(children: [
              Expanded(flex: 2, child: OutlinedButton(onPressed: _showReasons, child: const Text("배정 사유"))),
              const SizedBox(width: 10),
              Expanded(
                flex: 4,
                child: ThymeFinalButton(label: _saving ? "확정 중…" : "${_letter(c)}안으로 확정", onPressed: _saving || p.proposalId == null ? null : _confirm),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  static String _pct(double v) => v == v.roundToDouble() ? "${v.toInt()}" : v.toStringAsFixed(1);

  Widget _stat(String label, String value, bool good) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: ThymeColor.indigoSurface, borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: ThymeColor.onPrimarySub, fontSize: 14)),
            const SizedBox(height: 6),
            Text(value, style: ThymeTheme.mono(context, size: 26, color: good ? ThymeColor.accent : ThymeColor.danger)),
          ]),
        ),
      );

  Widget _candidateCard(ProposalCandidate cand) {
    final on = cand.index == _selected.index;
    Widget metric(String label, String value) => Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(14)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
              const SizedBox(height: 4),
              Text(value, style: ThymeTheme.mono(context, size: 17)),
            ]),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: ThymeColor.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _selected = cand),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: on ? ThymeColor.primary : Colors.transparent, width: 2),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    Text("${_letter(cand)}안 · ${cand.label}", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                    if (cand.index == 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: ThymeColor.selectedSoft, borderRadius: BorderRadius.circular(99)),
                        child: const Text("추천", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.charcoal)),
                      ),
                  ]),
                ),
                Text(won(cand.estimatedCost), style: ThymeTheme.mono(context, size: 16)),
              ]),
              if (cand.description != null && cand.description!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(cand.description!, style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
              ],
              const SizedBox(height: 12),
              Row(children: [
                metric("희망 반영", cand.preferenceRate == null ? "희망 없음" : "${_pct(cand.preferenceRate!)}%"),
                const SizedBox(width: 10),
                metric("주말 근무 최대 차이", "${cand.weekendGap}회"),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
