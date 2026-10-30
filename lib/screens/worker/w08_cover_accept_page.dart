import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../core/worker_api.dart';
import '../../models/owner.dart';
import '../../models/worker.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_back_button.dart';
import '../../widgets/thyme_leaf.dart';
import '../../widgets/thyme_worker_tab_bar.dart';

/// W08 대타 요청 받기. GET /swap-offers/my → 수락(accept) · 어려워요(decline)
/// 홈 배너에서 [offerId]를 넘기면 그 요청을, 아니면 가장 가까운 요청을 연다
class CoverAcceptPage extends StatefulWidget {
  const CoverAcceptPage({super.key, this.offerId});

  final int? offerId;

  @override
  State<CoverAcceptPage> createState() => _CoverAcceptPageState();
}

class _CoverAcceptPageState extends State<CoverAcceptPage> {
  List<SwapOffer>? _offers;
  SwapOffer? _offer;
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
      final offers = await WorkerApi().myOffers()
        ..sort((a, b) => a.workDate.compareTo(b.workDate));
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _offer = offers.where((o) => o.offerId == widget.offerId).firstOrNull ?? offers.firstOrNull;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _respond(bool accept) async {
    final o = _offer!;
    setState(() => _busy = true);
    try {
      final api = WorkerApi();
      accept ? await api.acceptOffer(o.offerId) : await api.declineOffer(o.offerId);
      if (!mounted) return;
      final done = !accept
          ? "거절했어요"
          : o.needsOwnerApproval
              ? "수락했어요. 사장님이 승인하면 근무표에 들어가요"
              : "수락했어요. 근무표에 들어갔어요";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
      ThymeWorkerTabBar.go(context, WorkerTab.home);
    } on ApiException catch (e) {
      if (!mounted) return;
      // 다른 사람이 먼저 수락했거나 마감된 요청 → 목록을 다시 받는다
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      await _load();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final o = _offer;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: AppBar(
        backgroundColor: ThymeColor.bg,
        elevation: 0,
        leading: const ThymeBackButton(icon: Icons.close),
        title: const Text("대타 요청", style: TextStyle(color: ThymeColor.text, fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                  TextButton(onPressed: _load, child: const Text("다시 불러오기")),
                ]),
              )
            : _offers == null
                ? const Center(child: CircularProgressIndicator())
                : o == null
                    ? const Padding(
                        padding: EdgeInsets.all(24),
                        child: Text("지금 나에게 온 대타 요청이 없어요.", style: TextStyle(fontSize: 15, color: ThymeColor.textSub)),
                      )
                    : Column(children: [
                        Expanded(child: _body(o)),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          child: Row(children: [
                            Expanded(child: OutlinedButton(onPressed: _busy ? null : () => _respond(false), child: const Text("어려워요"))),
                            const SizedBox(width: 12),
                            Expanded(flex: 2, child: ThymeFinalButton(label: "수락하기", onPressed: _busy ? null : () => _respond(true))),
                          ]),
                        ),
                      ]),
      ),
    );
  }

  Widget _body(SwapOffer o) {
    final name = WorkerApi().myDisplayName ?? '';
    return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
      if (_offers!.length > 1) ...[
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final x in _offers!)
            ChoiceChip(
              label: Text("${mdw(x.workDate)} ${hourRange(x.startTime, x.endTime)}"),
              selected: x.offerId == o.offerId,
              onSelected: (_) => setState(() => _offer = x),
              selectedColor: ThymeColor.primary,
              labelStyle: TextStyle(color: x.offerId == o.offerId ? ThymeColor.onPrimary : ThymeColor.text, fontWeight: FontWeight.bold),
              showCheckmark: false,
            ),
        ]),
        const SizedBox(height: 16),
      ],
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(color: ThymeColor.dangerBg, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          const Icon(Icons.circle, size: 8, color: ThymeColor.danger),
          const SizedBox(width: 10),
          Expanded(
            child: Text("${o.workDate.month}/${o.workDate.day} ${o.requesterName}님 근무에 결원이 생겼어요",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.dangerText)),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const ThymeLeaf(size: 44, color: ThymeColor.danger, dashed: true),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(mdw(o.workDate), style: const TextStyle(fontSize: 14, color: ThymeColor.textSub)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(timeRange(o.startTime, o.endTime), style: ThymeTheme.mono(context, size: 28)),
                ),
              ]),
            ),
          ]),
          const SizedBox(height: 18),
          Text("${name.isEmpty ? '' : '$name님, '}이날 가능하세요?",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ThymeColor.text)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: ThymeColor.primary, borderRadius: BorderRadius.circular(18)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("이 근무 예상 급여", style: TextStyle(fontSize: 13, color: ThymeColor.onPrimarySub)),
                  const SizedBox(height: 4),
                  FittedBox(child: Text(won(o.expectedPay), style: ThymeTheme.mono(context, size: 22, color: ThymeColor.accent))),
                ]),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(18)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text("이번 주 근무", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                  const SizedBox(height: 4),
                  FittedBox(
                    child: Text(
                      o.weekDaysBefore == null ? "-" : "${o.weekDaysBefore}일 → ${o.weekDaysAfter}일",
                      style: ThymeTheme.mono(context, size: 22),
                    ),
                  ),
                ]),
              ),
            ),
          ]),
          if (o.reasons.isNotEmpty) ...[
            const SizedBox(height: 18),
            const Text("왜 나에게 왔나요?", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
            const SizedBox(height: 8),
            for (final reason in o.reasons)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.check, size: 18, color: ThymeColor.successText),
                  const SizedBox(width: 10),
                  Expanded(child: Text(reason, style: const TextStyle(fontSize: 15, color: ThymeColor.text))),
                ]),
              ),
          ],
        ]),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: ThymeColor.infoBg, borderRadius: BorderRadius.circular(16)),
        child: Text(
          [
            if (o.sentCount > 1) "${o.sentCount}명에게 보냈어요 · 먼저 수락한 1명으로 정해져요",
            if (o.needsOwnerApproval) "동료가 보낸 요청이라 사장님이 승인하면 확정돼요",
            if (o.sentCount <= 1 && !o.needsOwnerApproval) "사장님이 보낸 요청이라 수락하면 바로 확정돼요",
          ].join("\n"),
          style: const TextStyle(fontSize: 14, color: ThymeColor.infoText, height: 1.5),
        ),
      ),
    ]);
  }
}

