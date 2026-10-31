import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/owner_api.dart';
import '../../core/theme.dart';
import '../../models/owner.dart';
import '../../models/store.dart' show hhmm;
import '../../models/worker.dart' show Trade;
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_leaf.dart';
import '../../widgets/thyme_owner_header.dart';
import '../../widgets/thyme_owner_tab_bar.dart';
import 'p09_open_shift_post_page.dart';

/// P06 대타 관리 (점주 하단 탭 '대타'). 진행 중인 결원(GET /swap-requests)과 엔진이 고른 후보(GET /candidates)
/// → 고른 동료에게 요청 · 가능한 모두에게 요청 · 직접 배정 · 빈 근무로 올리기 · 직원끼리 구한 대타 승인
/// 아래에 직원끼리 한 근무 바꾸기(넘기기·맞교환, GET /trades) 승인·거절
class SubstituteManagePage extends StatefulWidget {
  const SubstituteManagePage({super.key, this.requestId});

  /// 홈 결원 배너에서 들어오면 그 결원을 먼저 연다
  final int? requestId;

  @override
  State<SubstituteManagePage> createState() => _SubstituteManagePageState();
}

class _SubstituteManagePageState extends State<SubstituteManagePage> {
  List<SwapRequestInfo>? _requests;
  SwapRequestInfo? _current;
  List<SwapCandidate>? _candidates;

  /// 진행 중인 근무 바꾸기. 못 받아도 결원 화면은 보여 준다
  List<Trade> _trades = const [];
  final Set<int> _picked = {};
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<SwapRequestInfo> get _active => [for (final r in _requests ?? const <SwapRequestInfo>[]) if (r.active) r];

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final list = await OwnerApi().swapRequests();
      final trades = await OwnerApi().trades().catchError((_) => <Trade>[]);
      if (!mounted) return;
      // 승인할 수 있는 것(동료 수락)을 위로
      _trades = [...trades.where((t) => t.status == 'PEER_ACCEPTED'), ...trades.where((t) => t.status != 'PEER_ACCEPTED')];
      final active = [for (final r in list) if (r.active) r]..sort((a, b) => a.workDate.compareTo(b.workDate));
      final keep = _current?.id ?? widget.requestId;
      setState(() {
        _requests = list;
        _current = active.where((r) => r.id == keep).firstOrNull ?? active.firstOrNull;
      });
      await _loadCandidates();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _loadCandidates() async {
    final r = _current;
    setState(() {
      _candidates = null;
      _picked.clear();
    });
    if (r == null || r.status == 'PENDING_APPROVAL') return;
    try {
      final c = await OwnerApi().candidates(r.id);
      if (mounted && _current?.id == r.id) setState(() => _candidates = c);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _run(Future<void> Function(OwnerApi api) action, String done) async {
    setState(() => _busy = true);
    try {
      await action(OwnerApi());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _toBoard(SwapRequestInfo r) async {
    setState(() => _busy = true);
    try {
      await OwnerApi().postToBoard(r.id);
      final posts = await OwnerApi().openShifts();
      if (!mounted) return;
      final post = posts.where((p) => p.swapRequestId == r.id).firstOrNull;
      await Navigator.push(context, MaterialPageRoute(builder: (_) => OpenShiftPostPage(openShiftId: post?.id)));
      if (mounted) await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = _current;
    final active = _active;
    final now = DateTime.now();
    final done = [
      for (final x in _requests ?? const <SwapRequestInfo>[])
        if (x.status == 'ACCEPTED' && x.workDate.year == now.year && x.workDate.month == now.month) x,
    ];
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: EdgeInsets.zero, children: [
          ThymeOwnerHeader(title: "대타 관리", showBack: true, child: r == null ? null : _vacancyCard(r)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: _error != null
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                    TextButton(onPressed: _load, child: const Text("다시 불러오기")),
                  ])
                : _requests == null
                    ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                    : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        if (active.length > 1) ...[
                          Wrap(spacing: 8, runSpacing: 8, children: [
                            for (final a in active)
                              ChoiceChip(
                                label: Text("${mdw(a.workDate)} ${hourRange(a.startTime, a.endTime)} ${a.requesterName}"),
                                selected: a.id == r?.id,
                                onSelected: (_) {
                                  setState(() => _current = a);
                                  _loadCandidates();
                                },
                                selectedColor: ThymeColor.primary,
                                labelStyle: TextStyle(color: a.id == r?.id ? ThymeColor.onPrimary : ThymeColor.text, fontWeight: FontWeight.bold),
                                showCheckmark: false,
                              ),
                          ]),
                          const SizedBox(height: 16),
                        ],
                        if (r == null)
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(16)),
                            child: const Text("진행 중인 결원이 없어요. 직원이 '오늘 못 나가요'를 보내면 여기에 떠요.",
                                style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.5)),
                          )
                        else if (r.status == 'PENDING_APPROVAL')
                          _approvalCard(r)
                        else
                          ..._candidateSection(r),
                        if (_trades.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Row(children: [
                            const Expanded(child: Text("근무 바꾸기 요청", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text))),
                            Text("승인 대기 ${_trades.where((t) => t.status == 'PEER_ACCEPTED').length}건",
                                style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                          ]),
                          const SizedBox(height: 10),
                          for (final t in _trades) _tradeCard(t),
                        ],
                        if (done.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          const Text("이번 달 처리한 결원", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
                            child: Column(children: [
                              for (final x in done)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                  child: Row(children: [
                                    const ThymeLeaf(size: 20),
                                    const SizedBox(width: 12),
                                    SizedBox(width: 60, child: Text("${x.workDate.month}/${x.workDate.day}", style: ThymeTheme.mono(context, size: 14))),
                                    Expanded(
                                      child: Text("${x.requesterName} 결원 → ${x.substituteName ?? '배정'} 수락",
                                          style: const TextStyle(fontSize: 15, color: ThymeColor.text)),
                                    ),
                                  ]),
                                ),
                            ]),
                          ),
                        ],
                      ]),
          ),
        ]),
      ),
      bottomNavigationBar: Navigator.canPop(context) ? null : const ThymeOwnerTabBar(current: OwnerTab.substitute),
    );
  }

  Widget _vacancyCard(SwapRequestInfo r) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: ThymeColor.indigoSurface, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          const ThymeLeaf(size: 44, color: ThymeColor.danger, dashed: true),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                [mdw(r.workDate), r.requesterName, ?r.reasonCategory?.label].join(" · "),
                style: const TextStyle(color: ThymeColor.onPrimarySub, fontSize: 14),
              ),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text("${hhmm(r.partialFrom ?? r.startTime)}–${hhmm(r.endTime)}", style: ThymeTheme.mono(context, size: 26, color: ThymeColor.onPrimary)),
              ),
              if (r.reason != null && r.reason!.isNotEmpty)
                Text(r.reason!, style: const TextStyle(color: ThymeColor.onPrimarySub, fontSize: 13)),
            ]),
          ),
          const Icon(Icons.circle, size: 8, color: ThymeColor.danger),
          const SizedBox(width: 6),
          const Text("결원", style: TextStyle(color: ThymeColor.danger, fontWeight: FontWeight.bold)),
        ]),
      );

  Widget _approvalCard(SwapRequestInfo r) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text("${r.substituteName ?? '동료'}님이 대신 나가기로 했어요", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text)),
          const SizedBox(height: 4),
          const Text("직원끼리 구한 대타는 사장님이 승인해야 확정돼요.", style: TextStyle(fontSize: 14, color: ThymeColor.textSub)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => _run((api) => api.rejectSubstitute(r.id), "대타를 거절했어요. 다시 구해요."),
                child: const Text("거절"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : () => _run((api) => api.approveSwap(r.id), "대타를 승인했어요"),
                child: const Text("승인"),
              ),
            ),
          ]),
        ]),
      );

  /// 직원끼리 근무 바꾸기 한 건. 동료가 수락했으면 승인·거절, 동료 응답 전이면 거절만
  Widget _tradeCard(Trade t) {
    final peerAccepted = t.status == 'PEER_ACCEPTED';
    String shift(DateTime? d, String? s, String? e) => d == null || s == null || e == null ? "" : "${mdw(d)} ${hourRange(s, e)}시";
    final what = t.exchange
        ? "${t.requesterName} ${shift(t.requesterDate, t.requesterStart, t.requesterEnd)} ↔ ${t.targetName} ${shift(t.targetDate, t.targetStart, t.targetEnd)}"
        : "${t.requesterName} → ${t.targetName} · ${shift(t.requesterDate, t.requesterStart, t.requesterEnd)}";
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Text(t.exchange ? "맞교환" : "넘기기", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
          if (t.recurring) const Text(" · 매주 반복", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
          const Spacer(),
          Icon(Icons.circle, size: 8, color: peerAccepted ? ThymeColor.warn : ThymeColor.info),
          const SizedBox(width: 4),
          Text(t.statusLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.text)),
        ]),
        const SizedBox(height: 6),
        Text(what, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
        if (t.recurring) ...[
          const SizedBox(height: 4),
          const Text("승인하면 그달 남은 같은 요일·시간 근무도 함께 바뀌어요.", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
        ],
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _busy ? null : () => _run((api) => api.rejectTrade(t.id), "근무 바꾸기를 거절했어요"),
              child: const Text("거절"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: _busy || !peerAccepted ? null : () => _run((api) => api.approveTrade(t.id), "승인했어요. 근무표가 바뀌었어요"),
              child: Text(peerAccepted ? "승인" : "동료 응답 대기"),
            ),
          ),
        ]),
      ]),
    );
  }

  List<Widget> _candidateSection(SwapRequestInfo r) {
    final cands = _candidates;
    final eligible = [for (final c in cands ?? const <SwapCandidate>[]) if (c.eligible) c];
    final one = _picked.length == 1 ? _picked.first : null;
    return [
      const Row(children: [
        Expanded(child: Text("엔진이 고른 후보", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text))),
        Text("이번 주 근무가 적은 순 · 규칙 통과", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
      ]),
      const SizedBox(height: 10),
      if (cands == null) const Padding(padding: EdgeInsets.all(20), child: Center(child: CircularProgressIndicator())),
      if (cands != null && cands.isEmpty)
        const Text("대신할 수 있는 사람이 없어요. 빈 근무로 올려 지원을 받아 보세요.", style: TextStyle(color: ThymeColor.textSub)),
      for (final c in cands ?? const <SwapCandidate>[]) _candidateRow(c),
      const SizedBox(height: 8),
      if (cands != null) ...[
        FilledButton(
          onPressed: _busy || (eligible.isEmpty && _picked.isEmpty)
              ? null
              : _picked.isEmpty
                  ? () => _run((api) async => await api.broadcast(r.id), "가능한 모두에게 대타를 요청했어요")
                  : () => _run((api) => api.sendOffers(r.id, _picked.toList()), "${_picked.length}명에게 대타를 요청했어요"),
          child: Text(_picked.isEmpty ? "가능한 ${eligible.length}명 모두에게 요청" : "고른 ${_picked.length}명에게 요청"),
        ),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _busy || one == null ? null : () => _run((api) => api.assign(r.id, one), "직접 배정했어요"),
              child: Text(one == null ? "직접 배정 (1명 고르기)" : "직접 배정"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(child: OutlinedButton(onPressed: _busy ? null : () => _toBoard(r), child: const Text("빈 근무로 올리기"))),
        ]),
      ],
    ];
  }

  Widget _candidateRow(SwapCandidate c) {
    final (color, label) = switch (c.contactStatus) {
      'SENT' => (ThymeColor.info, c.waitingMinutes == null ? "확인 중" : "확인 중 ${c.waitingMinutes}분"),
      'ACCEPTED' => (ThymeColor.accent, "수락"),
      'DECLINED' => (ThymeColor.disabled, "거절"),
      'EXPIRED' => (ThymeColor.danger, "응답 없음"),
      'CLOSED' => (ThymeColor.disabled, "마감"),
      'PENDING_APPROVAL' => (ThymeColor.warn, "승인 대기"),
      'APPLIED' => (ThymeColor.info, "게시판 지원"),
      null => (Colors.transparent, ""),
      _ => (ThymeColor.disabled, c.contactStatus!),
    };
    final picked = _picked.contains(c.employeeId);
    final sub = c.eligible
        ? ["이번 주 ${c.weeklyHours}시간", if (c.coveredSkills.isNotEmpty) "${c.coveredSkills.join('·')} 가능"].join(" · ")
        : c.reasons.join(" · ");
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: ThymeColor.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: !c.eligible || c.contactStatus != null
              ? null
              : () => setState(() => picked ? _picked.remove(c.employeeId) : _picked.add(c.employeeId)),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: picked ? ThymeColor.primary : Colors.transparent, width: 2),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: picked ? ThymeColor.primary : ThymeColor.selectedSoft,
                child: Text(c.name.isEmpty ? "?" : c.name.characters.first,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: picked ? ThymeColor.onPrimary : ThymeColor.text)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(c.name, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: c.eligible ? ThymeColor.text : ThymeColor.textSub)),
                  const SizedBox(height: 2),
                  Text(sub, style: TextStyle(fontSize: 13, color: c.eligible ? ThymeColor.textSub : ThymeColor.dangerText)),
                ]),
              ),
              if (label.isNotEmpty) ...[
                Icon(Icons.circle, size: 8, color: color),
                const SizedBox(width: 4),
                Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color == ThymeColor.danger ? ThymeColor.dangerText : ThymeColor.text)),
              ] else if (c.eligible)
                Icon(picked ? Icons.check_circle : Icons.radio_button_unchecked, color: picked ? ThymeColor.primary : ThymeColor.disabled),
            ]),
          ),
        ),
      ),
    );
  }
}
