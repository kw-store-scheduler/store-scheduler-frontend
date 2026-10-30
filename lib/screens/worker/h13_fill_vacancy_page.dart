import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../core/worker_api.dart';
import '../../models/owner.dart';
import '../../models/worker.dart';
import '../../widgets/thyme_leaf.dart';
import '../../widgets/thyme_step_app_bar.dart';
import '../../widgets/thyme_worker_tab_bar.dart';

/// H13 빈자리 채우기 (결원 신고 2/2). 신고한 결원을
/// - 대타 직접 구하기: 엔진이 고른 가능한 동료에게 동시에 요청 (POST swap-requests/{id}/offers, 먼저 수락한 1명 → 사장님 승인)
/// - 게시판에 올리기: 빈 근무 게시판에 올려 지원을 받는다 (POST swap-requests/{id}/board)
class FillVacancyPage extends StatefulWidget {
  const FillVacancyPage({super.key, required this.request});

  final SwapRequestInfo request;

  @override
  State<FillVacancyPage> createState() => _FillVacancyPageState();
}

class _FillVacancyPageState extends State<FillVacancyPage> {
  bool _board = false;
  List<SwapCandidate>? _candidates;
  final Set<int> _picked = {};
  String? _error;
  bool _busy = false;

  SwapRequestInfo get r => widget.request;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final c = await WorkerApi().candidates(r.id);
      if (!mounted) return;
      setState(() {
        _candidates = c;
        // 엔진이 이번 주 근무가 적은 순으로 준다 → 가능한 앞의 2명을 미리 골라 둔다 (시안)
        _picked
          ..clear()
          ..addAll(c.where((x) => x.eligible && x.contactStatus == null).take(2).map((x) => x.employeeId));
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _run(Future<String> Function(WorkerApi api) action) async {
    setState(() => _busy = true);
    try {
      final done = await action(WorkerApi());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
      ThymeWorkerTabBar.go(context, WorkerTab.swap);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("결원 신고를 취소할까요?"),
        content: const Text("근무에 그대로 나가는 걸로 돌아가요."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("아니요")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("신고 취소")),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _run((api) async {
      await api.cancelAbsence(r.id);
      return "결원 신고를 취소했어요";
    });
  }

  @override
  Widget build(BuildContext context) {
    final from = r.partialFrom ?? r.startTime;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: ThymeStepAppBar(step: 2, total: 2, group: '결원 신고', actions: [
        TextButton(onPressed: _busy ? null : _cancel, child: const Text("신고 취소")),
      ]),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: ThymeColor.dangerBg, borderRadius: BorderRadius.circular(20)),
                child: Row(children: [
                  const ThymeLeaf(size: 36, color: ThymeColor.danger, dashed: true),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      const Text("사장님께 결원을 알렸어요", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.dangerText)),
                      const SizedBox(height: 2),
                      Text([mdw(r.workDate), timeRange(from, r.endTime), ?r.reasonCategory?.label].join(" · "),
                          style: const TextStyle(fontSize: 14, color: ThymeColor.dangerText)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 24),
              const Text("빈자리는 어떻게 채울까요?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: ThymeColor.selectedSoft, borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  Expanded(child: _segment("대타 직접 구하기", !_board, () => setState(() => _board = false))),
                  Expanded(child: _segment("게시판에 올리기", _board, () => setState(() => _board = true))),
                ]),
              ),
              const SizedBox(height: 20),
              if (_board) ..._boardSection() else ..._directSection(),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: _board
                  ? FilledButton(
                      onPressed: _busy
                          ? null
                          : () => _run((api) async {
                                final n = await api.postToBoard(r.id);
                                return n > 0 ? "게시판에 올리고 $n명에게 알렸어요" : "게시판에 올렸어요";
                              }),
                      child: const Text("게시판에 올리기"),
                    )
                  : FilledButton(
                      onPressed: _busy || _picked.isEmpty
                          ? null
                          : () => _run((api) async {
                                await api.sendOffers(r.id, _picked.toList());
                                return "${_picked.length}명에게 대타를 요청했어요";
                              }),
                      child: Text(_picked.isEmpty ? "보낼 동료를 골라 주세요" : "${_picked.length}명에게 대타 요청 보내기"),
                    ),
            ),
          ),
        ]),
      ),
    );
  }

  List<Widget> _directSection() {
    final cands = _candidates;
    return [
      const Row(children: [
        Expanded(child: Text("보낼 동료 고르기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text))),
        Text("이번 주 근무가 적은 순 · 규칙 통과", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
      ]),
      const SizedBox(height: 10),
      if (_error != null) ...[
        Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
        TextButton(onPressed: _load, child: const Text("다시 불러오기")),
      ] else if (cands == null)
        const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()))
      else if (cands.every((c) => !c.eligible))
        _note("대신 나갈 수 있는 동료가 없어요. 게시판에 올려 지원을 받아 보세요.")
      else
        for (final c in cands) _candidateRow(c),
      const SizedBox(height: 6),
      _note("한 명이 수락하면 나머지 요청은 자동으로 닫히고, 사장님이 승인하면 확정돼요. 30분 안에 아무도 안 받으면 게시판으로 넘어가요."),
    ];
  }

  List<Widget> _boardSection() => [
        _note("빈 근무 게시판에 올리면 이 근무를 할 수 있는 동료 모두에게 알림이 가요. 지원한 사람 중에서 사장님이 골라요."),
      ];

  Widget _note(String text) => Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: ThymeColor.infoBg, borderRadius: BorderRadius.circular(16)),
        child: Text(text, style: const TextStyle(fontSize: 14, color: ThymeColor.infoText, height: 1.5)),
      );

  Widget _segment(String label, bool selected, VoidCallback onTap) => Material(
        color: selected ? ThymeColor.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: selected ? ThymeColor.text : ThymeColor.textSub)),
            ),
          ),
        ),
      );

  Widget _candidateRow(SwapCandidate c) {
    final picked = _picked.contains(c.employeeId);
    final selectable = c.eligible && c.contactStatus == null;
    final sub = c.eligible
        ? ["이번 주 ${c.weeklyHours}시간", if (c.coveredSkills.isNotEmpty) "${c.coveredSkills.join('·')} 가능"].join(" · ")
        : c.reasons.join(" · ");
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: c.eligible ? ThymeColor.surface : ThymeColor.surfaceSub,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: selectable ? () => setState(() => picked ? _picked.remove(c.employeeId) : _picked.add(c.employeeId)) : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: picked ? ThymeColor.primary : Colors.transparent, width: 2),
            ),
            child: Row(children: [
              Icon(
                picked ? Icons.check_box : Icons.check_box_outline_blank,
                color: selectable ? (picked ? ThymeColor.primary : ThymeColor.border) : ThymeColor.disabled,
                size: 28,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: c.eligible ? ThymeColor.text : ThymeColor.textSub)),
                  const SizedBox(height: 2),
                  Text(sub, style: TextStyle(fontSize: 13, color: c.eligible ? ThymeColor.textSub : ThymeColor.dangerText)),
                ]),
              ),
              if (c.contactStatus != null)
                Text(c.contactStatus == 'SENT' ? "요청함" : "연락함", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
            ]),
          ),
        ),
      ),
    );
  }
}
