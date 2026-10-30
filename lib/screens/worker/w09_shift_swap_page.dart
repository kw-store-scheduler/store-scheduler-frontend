import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../core/worker_api.dart';
import '../../models/owner.dart';
import '../../models/worker.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_back_button.dart';

/// W09 근무 바꾸기. 내 근무를 동료에게 넘기기(HANDOVER) 또는 동료 근무와 맞교환(EXCHANGE)
/// GET schedules/{id}/trade-options → POST schedules/{id}/trades. 동료 수락 → 사장님 승인 → 근무표 반영
/// 위에는 나에게 온 요청(수락·거절)과 내가 보낸 진행 중 요청(취소)을 보여 준다 (GET trades/my)
class ShiftSwapPage extends StatefulWidget {
  const ShiftSwapPage({super.key, this.scheduleId});

  /// 바꿀 내 근무 (없으면 앞으로의 근무 중 가장 가까운 것)
  final int? scheduleId;

  @override
  State<ShiftSwapPage> createState() => _ShiftSwapPageState();
}

class _ShiftSwapPageState extends State<ShiftSwapPage> {
  bool _exchange = true;
  List<MyShift>? _upcoming;
  MyShift? _shift;
  List<TradeOption>? _handover;
  List<TradeOption>? _exchangeOptions;
  List<Trade> _trades = const [];
  TradeOption? _picked;
  bool _recurring = false;
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
      final api = WorkerApi();
      final now = DateTime.now();
      final mine = await api.mySchedules();
      // 서버는 근무 48시간 전까지만 바꾸기를 받는다 (더 급하면 결원 신고)
      final limit = now.add(const Duration(hours: 48));
      final upcoming = [for (final s in mine) if (_startOf(s).isAfter(limit)) s]..sort((a, b) => _startOf(a).compareTo(_startOf(b)));
      final trades = await api.myTrades();
      if (!mounted) return;
      setState(() {
        _upcoming = upcoming;
        _trades = trades;
        _shift = upcoming.where((s) => s.id == (_shift?.id ?? widget.scheduleId)).firstOrNull ?? upcoming.firstOrNull;
      });
      await _loadOptions();
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  static DateTime _startOf(MyShift s) =>
      DateTime(s.workDate.year, s.workDate.month, s.workDate.day, int.parse(s.startTime.substring(0, 2)), int.parse(s.startTime.substring(3, 5)));

  Future<void> _loadOptions() async {
    final s = _shift;
    setState(() {
      _handover = null;
      _exchangeOptions = null;
      _picked = null;
    });
    if (s == null) return;
    try {
      final (h, x) = await WorkerApi().tradeOptions(s.id);
      if (mounted && _shift?.id == s.id) {
        setState(() {
          _handover = h;
          _exchangeOptions = x;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _run(Future<void> Function(WorkerApi api) action, String done) async {
    setState(() => _busy = true);
    try {
      await action(WorkerApi());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickShift() async {
    final picked = await showModalBottomSheet<MyShift>(
      context: context,
      builder: (context) => SafeArea(
        child: ListView(shrinkWrap: true, padding: const EdgeInsets.symmetric(vertical: 12), children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text("바꿀 내 근무", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
          ),
          for (final s in _upcoming!)
            ListTile(
              title: Text("${mdw(s.workDate)} ${timeRange(s.startTime, s.endTime)}"),
              trailing: s.id == _shift?.id ? const Icon(Icons.check, color: ThymeColor.primary) : null,
              onTap: () => Navigator.pop(context, s),
            ),
        ]),
      ),
    );
    if (picked == null || picked.id == _shift?.id) return;
    setState(() => _shift = picked);
    await _loadOptions();
  }

  @override
  Widget build(BuildContext context) {
    final me = WorkerApi().myEmployeeId;
    final received = [for (final t in _trades) if (t.targetId == me && t.status == 'REQUESTED') t];
    final sent = [for (final t in _trades) if (t.requesterId == me && t.open) t];
    final options = _exchange ? _exchangeOptions : _handover;
    final p = _picked;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: AppBar(
        backgroundColor: ThymeColor.bg,
        elevation: 0,
        leading: const ThymeBackButton(),
        title: const Text("근무 바꾸기", style: TextStyle(color: ThymeColor.text, fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
                if (_error != null) ...[
                  Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                  TextButton(onPressed: _load, child: const Text("다시 불러오기")),
                ],
                for (final t in received) _receivedCard(t),
                for (final t in sent) _sentCard(t),
                if (received.isNotEmpty || sent.isNotEmpty) const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(18)),
                  child: Row(children: [
                    Expanded(child: _segment("넘기기", "내 근무를 동료에게", !_exchange, () => setState(() {
                          _exchange = false;
                          _picked = null;
                        }))),
                    Expanded(child: _segment("맞교환", "서로의 근무를 바꾸기", _exchange, () => setState(() {
                          _exchange = true;
                          _picked = null;
                        }))),
                  ]),
                ),
                const SizedBox(height: 12),
                if (_upcoming == null && _error == null)
                  const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                else if (_shift == null)
                  _note("48시간 뒤에 잡힌 근무가 없어요. 더 가까운 근무는 '내 근무 내놓기'(결원 신고)로 알려 주세요.")
                else ...[
                  _myShiftCard(_shift!),
                  const SizedBox(height: 20),
                  Text(_exchange ? "바꿀 수 있는 동료의 근무" : "넘겨받을 수 있는 동료",
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
                  const SizedBox(height: 10),
                  if (options == null)
                    const Padding(padding: EdgeInsets.all(30), child: Center(child: CircularProgressIndicator()))
                  else if (options.isEmpty)
                    _note(_exchange ? "앞뒤 7일 안에 바꿀 수 있는 동료 근무가 없어요." : "이 근무를 넘겨받을 수 있는 동료가 없어요.")
                  else
                    for (final o in options) _optionRow(o),
                  if (_exchange) ...[
                    const SizedBox(height: 4),
                    // 스위치 줄의 물결이 보이도록 Container 대신 Material
                    Material(
                      color: ThymeColor.surface,
                      borderRadius: BorderRadius.circular(18),
                      child: SwitchListTile(
                        contentPadding: const EdgeInsets.fromLTRB(18, 8, 8, 8),
                        value: _recurring,
                        onChanged: (v) => setState(() => _recurring = v),
                        title: const Text("매주 이렇게 바꾸기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        subtitle: const Text("그달 남은 같은 요일·시간 근무도 함께"),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  _note("동료가 수락 → 사장님 승인 → 근무표·수당이 함께 바뀌어요. 근무 48시간 전까지 요청할 수 있어요."),
                ],
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: p == null || _busy
                    ? null
                    : () => _run(
                          (api) => api.requestTrade(
                            _shift!.id,
                            exchange: _exchange,
                            targetEmployeeId: _exchange ? null : p.employeeId,
                            targetScheduleId: _exchange ? p.scheduleId : null,
                            recurring: _exchange && _recurring,
                          ),
                          "${p.employeeName}님에게 ${_exchange ? '맞교환' : '넘기기'}을 요청했어요",
                        ),
                child: Text(p == null ? "바꿀 동료를 골라 주세요" : "${p.employeeName}님에게 ${_exchange ? '맞교환' : '넘기기'} 요청"),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _note(String text) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: ThymeColor.infoBg, borderRadius: BorderRadius.circular(16)),
        child: Text(text, style: const TextStyle(fontSize: 14, color: ThymeColor.infoText, height: 1.5)),
      );

  Widget _segment(String title, String sub, bool selected, VoidCallback onTap) => Material(
        color: selected ? ThymeColor.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(children: [
              Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: selected ? ThymeColor.onPrimary : ThymeColor.textSub)),
              Text(sub, style: TextStyle(fontSize: 12, color: selected ? ThymeColor.onPrimarySub : ThymeColor.disabled)),
            ]),
          ),
        ),
      );

  Widget _myShiftCard(MyShift s) => Container(
        padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
        decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          const Text("내\n근무", style: TextStyle(fontSize: 14, color: ThymeColor.textSub)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(mdw(s.workDate), style: const TextStyle(fontSize: 14, color: ThymeColor.textSub)),
              Text(timeRange(s.startTime, s.endTime), style: ThymeTheme.mono(context, size: 22)),
            ]),
          ),
          if (_upcoming!.length > 1) TextButton(onPressed: _pickShift, child: const Text("변경")),
        ]),
      );

  Widget _optionRow(TradeOption o) {
    final picked = _picked == o;
    final detail = o.workDate == null ? null : "${mdw(o.workDate!)} ${hourRange(o.startTime!, o.endTime!)}";
    final sub = o.available ? (detail == null ? "넘겨받을 수 있어요" : "$detail ↔ 내 근무") : [?detail, o.blocker ?? "바꿀 수 없어요"].join(" · ");
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: o.available ? ThymeColor.surface : ThymeColor.surfaceSub,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: o.available ? () => setState(() => _picked = picked ? null : o) : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: picked ? ThymeColor.primary : Colors.transparent, width: 2),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: ThymeColor.selectedSoft,
                child: Text(o.employeeName.isEmpty ? "?" : o.employeeName.characters.first,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: o.available ? ThymeColor.text : ThymeColor.textSub)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(o.employeeName, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: o.available ? ThymeColor.text : ThymeColor.textSub)),
                  const SizedBox(height: 2),
                  Text(sub, style: TextStyle(fontSize: 13, color: o.available ? ThymeColor.textSub : ThymeColor.dangerText)),
                ]),
              ),
              if (picked)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: ThymeColor.primary, borderRadius: BorderRadius.circular(14)),
                  child: const Text("선택", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.onPrimary)),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  String _tradeText(Trade t, {required bool incoming}) {
    final mine = "${mdw(t.requesterDate)} ${hourRange(t.requesterStart, t.requesterEnd)}";
    if (!t.exchange) return incoming ? "${t.requesterName}님 근무 $mine 을 넘겨받기" : "$mine → ${t.targetName}님에게 넘기기";
    final theirs = t.targetDate == null ? "" : "${mdw(t.targetDate!)} ${hourRange(t.targetStart!, t.targetEnd!)}";
    return incoming ? "${t.requesterName}님 $mine ↔ 내 $theirs" : "내 $mine ↔ ${t.targetName}님 $theirs";
  }

  Widget _receivedCard(Trade t) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: ThymeColor.dangerBg, borderRadius: BorderRadius.circular(18)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text("${t.requesterName}님이 ${t.exchange ? '맞교환' : '넘기기'}을 요청했어요",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.dangerText)),
          const SizedBox(height: 4),
          Text(_tradeText(t, incoming: true) + (t.recurring ? " · 매주" : ""), style: const TextStyle(fontSize: 14, color: ThymeColor.text)),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: _busy ? null : () => _run((api) => api.declineTrade(t.id), "거절했어요"), child: const Text("거절"))),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _busy ? null : () => _run((api) => api.acceptTrade(t.id), "수락했어요. 사장님이 승인하면 근무표가 바뀌어요"),
                child: const Text("수락"),
              ),
            ),
          ]),
        ]),
      );

  Widget _sentCard(Trade t) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
        decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(t.statusLabel, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.infoText)),
              const SizedBox(height: 2),
              Text(_tradeText(t, incoming: false), style: const TextStyle(fontSize: 14, color: ThymeColor.text)),
            ]),
          ),
          TextButton(onPressed: _busy ? null : () => _run((api) => api.cancelTrade(t.id), "요청을 취소했어요"), child: const Text("취소")),
        ]),
      );
}
