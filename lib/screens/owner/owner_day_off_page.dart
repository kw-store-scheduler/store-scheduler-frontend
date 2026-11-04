import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/day_off_api.dart';
import '../../core/theme.dart';
import '../../models/owner.dart' show mdw;
import '../../widgets/thyme_owner_header.dart';

/// 점주 휴무 신청 보기 (시안 없음, P08 사람 › 휴무 신청). GET /day-offs?from=&to=
/// 직원들이 W03·E01 에서 낸 필수·희망 휴무를 달마다 날짜별로 본다. 근무표 엔진이 그대로 반영하니 승인할 것은 없다
class OwnerDayOffPage extends StatefulWidget {
  const OwnerDayOffPage({super.key});

  @override
  State<OwnerDayOffPage> createState() => _OwnerDayOffPageState();
}

class _OwnerDayOffPageState extends State<OwnerDayOffPage> {
  /// 희망은 다음 달 것을 내므로 다음 달부터
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month + 1);
  List<DayOff>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final items = await DayOffApi().store(_month, DateTime(_month.year, _month.month + 1, 0));
      if (mounted) setState(() => _items = items..sort((a, b) => a.date.compareTo(b.date)));
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _moveMonth(int d) {
    setState(() {
      _month = DateTime(_month.year, _month.month + d);
      _items = null;
    });
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final byDate = <DateTime, List<DayOff>>{};
    for (final d in items ?? const <DayOff>[]) {
      byDate.putIfAbsent(d.date, () => []).add(d);
    }
    final must = items?.where((d) => d.type == DayOffType.must).length ?? 0;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: EdgeInsets.zero, children: [
          const ThymeOwnerHeader(title: "휴무 신청", showBack: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                IconButton(tooltip: "전달", onPressed: () => _moveMonth(-1), icon: const Icon(Icons.chevron_left)),
                Expanded(
                  child: Text("${_month.year}년 ${_month.month}월", textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                ),
                IconButton(tooltip: "다음 달", onPressed: () => _moveMonth(1), icon: const Icon(Icons.chevron_right)),
              ]),
              const SizedBox(height: 8),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                TextButton(onPressed: _load, child: const Text("다시 불러오기")),
              ] else if (items == null)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
              else if (items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(16)),
                  child: const Text("이달 휴무 신청이 없어요.", style: TextStyle(fontSize: 14, color: ThymeColor.textSub)),
                )
              else ...[
                Text("${items.length}건 · 필수 $must · 희망 ${items.length - must}",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                const SizedBox(height: 4),
                const Text("필수는 근무표에서 꼭 지키고, 희망은 안 되면 적어 낸 대안 순서대로 맞춰요.",
                    style: TextStyle(fontSize: 13, color: ThymeColor.textSub, height: 1.5)),
                const SizedBox(height: 12),
                for (final e in byDate.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(left: 6, bottom: 6),
                    child: Text(mdw(e.key), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
                  ),
                  Material(
                    color: ThymeColor.surface,
                    borderRadius: BorderRadius.circular(20),
                    child: Column(children: [
                      for (final (i, d) in e.value.indexed) ...[
                        if (i > 0) const Divider(height: 1, indent: 18, endIndent: 18),
                        _row(d),
                      ],
                    ]),
                  ),
                  const SizedBox(height: 14),
                ],
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _row(DayOff d) {
    final must = d.type == DayOffType.must;
    final sub = [
      if (d.reason != null && d.reason!.isNotEmpty) d.reason!,
      if (d.fallbacks.isNotEmpty) "안 되면 ${d.fallbacks.map((f) => f.label).join(' → ')}",
    ].join(" · ");
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      title: Text(d.employeeName ?? "", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
      subtitle: sub.isEmpty ? null : Text(sub, style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
      trailing: Text(
        must ? "필수" : (d.downgraded ? "희망 (필수 한도 넘음)" : "희망"),
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: must ? ThymeColor.dangerText : ThymeColor.infoText),
      ),
    );
  }
}
