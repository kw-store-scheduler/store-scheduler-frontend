import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/day_off_api.dart';
import '../../core/preference_api.dart';
import '../../core/theme.dart';
import '../../models/preference.dart';
import '../../models/store.dart' show weekdayLabels;
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'w04_shift_attitude_page.dart';

/// 화면에서 고치는 휴무 한 건
class _Item {
  _Item({this.serverId, required this.date, this.reason = '', List<DayOffFallback>? order}) : order = order ?? [];

  final int? serverId; // 이미 서버에 있는 신청이면 id
  final DateTime date;
  String reason;
  final List<DayOffFallback> order; // 휴무 요청(1순위) 다음에 누른 순서대로
  bool dirty = false;

  double get leaveUse => DayOff(date: date, type: DayOffType.prefer, fallbacks: order).leaveUse;
}

/// E01 직원 연차·휴무 (직원 1/3). 날짜마다 "휴무 요청 → 대안" 순서를 정한다
///
/// - 서버: 날짜별 희망 휴무(POST /day-offs, type PREFER) + fallbacks(누른 순서) / 남은 연차(GET leave-plan)
/// - 다음: 바뀐 신청만 저장(바꾼 건 취소 후 다시 신청) → 직원 희망 초안을 만들어 W04로
class EmployeeLeavePage extends StatefulWidget {
  const EmployeeLeavePage({super.key, this.month});

  /// 신청 대상 달. 생략하면 다음 달
  final DateTime? month;

  @override
  State<EmployeeLeavePage> createState() => _EmployeeLeavePageState();
}

class _EmployeeLeavePageState extends State<EmployeeLeavePage> {
  // 직원 대안: 연차 · 반차 · 다른 날과 교환 · 그냥 출근 (시안 E01)
  static const _choices = [DayOffFallback.annualLeave, DayOffFallback.halfDay, DayOffFallback.swapDay, DayOffFallback.workAnyway];

  late final DateTime _month = widget.month ?? DateTime(DateTime.now().year, DateTime.now().month + 1);
  final List<_Item> _items = [];
  final List<int> _removed = []; // 지운 서버 신청 id
  int? _remaining;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final api = DayOffApi();
      final mine = await api.mine(_month);
      final plan = await api.leavePlan(_month);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll([for (final d in mine) _Item(serverId: d.id, date: d.date, reason: d.reason ?? '', order: List.of(d.fallbacks))]);
        _items.sort((a, b) => a.date.compareTo(b.date));
        _remaining = plan.remaining;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  double get _maxUse => _items.fold(0.0, (s, i) => s + i.leaveUse);

  static String _num(double v) => v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  Future<void> _addDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final first = _month.isBefore(today) ? today : _month;
    final last = DateTime(_month.year, _month.month + 1, 0);
    if (first.isAfter(last)) return;
    final taken = {for (final i in _items) i.date};
    final picked = await showDatePicker(
      context: context,
      initialDate: [for (var d = first; !d.isAfter(last); d = d.add(const Duration(days: 1))) d].firstWhere((d) => !taken.contains(d), orElse: () => first),
      firstDate: first,
      lastDate: last,
      selectableDayPredicate: (d) => !taken.contains(DateUtils.dateOnly(d)),
      helpText: "쉬고 싶은 날",
    );
    if (picked == null) return;
    setState(() {
      _items.add(_Item(date: DateUtils.dateOnly(picked))..dirty = true);
      _items.sort((a, b) => a.date.compareTo(b.date));
    });
  }

  void _toggle(_Item item, DayOffFallback f) => setState(() {
        item.order.contains(f) ? item.order.remove(f) : item.order.add(f);
        item.dirty = true;
      });

  void _remove(_Item item) => setState(() {
        if (item.serverId != null) _removed.add(item.serverId!);
        _items.remove(item);
      });

  Future<void> _next() async {
    setState(() => _saving = true);
    try {
      final api = DayOffApi();
      for (final id in _removed) {
        await api.cancel(id);
      }
      _removed.clear();
      for (final item in _items.where((i) => i.dirty).toList()) {
        if (item.serverId != null) await api.cancel(item.serverId!); // 같은 날짜는 한 건만 → 취소 후 다시
        final saved = await api.request(DayOff(date: item.date, type: DayOffType.prefer, reason: item.reason.trim(), fallbacks: item.order));
        final i = _items.indexOf(item);
        _items[i] = _Item(serverId: saved.id, date: saved.date, reason: saved.reason ?? '', order: List.of(saved.fallbacks));
      }
      // 직원은 지난달 교대 선호를 그대로 불러와 시작한다
      final PreferenceDraft draft = await PreferenceApi().startDraft(_month, fromLastMonth: true, fullTime: true);
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(builder: (_) => ShiftAttitudePage(draft: draft)));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: ThymeStepAppBar(step: 1, total: 3, group: '직원', title: '연차·휴무'),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? _buildError()
                    : SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("쉬는 방법을 순서대로 골라요",
                                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                            const SizedBox(height: 10),
                            Text("${_month.month}월에 쉬고 싶은 날을 넣고, 휴무가 안 되면 쓸 대안을 누른 순서대로 정해요. 연차를 아끼고 싶으면 연차를 뒤에 두세요.",
                                style: const TextStyle(fontSize: 15, color: ThymeColor.textSub, height: 1.5)),
                            const SizedBox(height: 20),
                            _buildSummary(context),
                            const SizedBox(height: 10),
                            if (_items.isEmpty)
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text("아직 쉬고 싶은 날이 없어요. 없으면 그냥 다음으로 가도 돼요.",
                                    style: TextStyle(fontSize: 14, color: ThymeColor.textSub)),
                              ),
                            for (final item in _items) ...[
                              _buildCard(context, item),
                              const SizedBox(height: 10),
                            ],
                            // + 날짜 추가 (점선 = 아직 안 정함, 가이드 4-5)
                            InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: _addDate,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 18),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: ThymeColor.icon, width: 1.2),
                                ),
                                alignment: Alignment.center,
                                child: const Text("+ 날짜 추가", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                              ),
                            ),
                          ],
                        ),
                      ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _loading || _error != null || _saving ? null : _next,
                  child: Text(_saving ? "저장하는 중…" : "다음 · 선호 시간대"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: ThymeColor.textSub)),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: _load, child: const Text("다시 불러오기")),
          ]),
        ),
      );

  // 남은 연차 · 최대 사용 · 최소 남음
  Widget _buildSummary(BuildContext context) {
    final remaining = _remaining;
    Widget cell(String label, String value) => Expanded(
          child: Column(children: [
            Text(label, style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
            const SizedBox(height: 4),
            Text.rich(TextSpan(children: [
              TextSpan(text: value, style: ThymeTheme.mono(context, size: 22)),
              if (value != "-") const TextSpan(text: "일", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
            ])),
          ]),
        );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(18)),
      child: IntrinsicHeight(
        child: Row(children: [
          cell("남은 연차", remaining == null ? "-" : "$remaining"),
          const VerticalDivider(color: ThymeColor.border),
          cell("최대 사용", _num(_maxUse)),
          const VerticalDivider(color: ThymeColor.border),
          cell("최소 남음", remaining == null ? "-" : _num(remaining - _maxUse)),
        ]),
      ),
    );
  }

  Widget _buildCard(BuildContext context, _Item item) {
    final weekday = weekdayLabels[item.date.weekday - 1];
    final summary = ["1순위 휴무 요청", for (var i = 0; i < item.order.length; i++) "${i + 2}순위 ${item.order[i].label}"].join(" → ");
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
      decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(18)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text("${item.date.month}/${item.date.day} ($weekday)",
                  style: ThymeTheme.mono(context, size: 17, color: ThymeColor.forWeekday(weekday))),
              const Spacer(),
              const Text("누른 순서 = 순위", style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
              IconButton(
                tooltip: "이 날 빼기",
                onPressed: () => _remove(item),
                icon: const Icon(Icons.close, size: 18, color: ThymeColor.textSub),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: TextFormField(
              initialValue: item.reason,
              onChanged: (v) {
                item.reason = v;
                item.dirty = true;
              },
              decoration: const InputDecoration(hintText: "사유 (선택) · 예: 가족 여행", isDense: true),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(1, "휴무 요청", locked: true),
              for (final f in _choices)
                GestureDetector(
                  onTap: () => _toggle(item, f),
                  child: _chip(item.order.contains(f) ? item.order.indexOf(f) + 2 : null, f.label),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(summary, style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
        ],
      ),
    );
  }

  // 순위가 있으면 딥 나이트 테두리 + 번호 (약한 선택, 가이드 4-3)
  Widget _chip(int? rank, String label, {bool locked = false}) {
    final on = rank != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      decoration: BoxDecoration(
        color: on ? ThymeColor.surface : ThymeColor.surfaceSub,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: on ? ThymeColor.primary : Colors.transparent, width: 1.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: on ? ThymeColor.primary : ThymeColor.surface,
            shape: BoxShape.circle,
            border: on ? null : Border.all(color: ThymeColor.disabled, width: 1.5),
          ),
          child: on ? Text("$rank", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.onPrimary)) : null,
        ),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: locked ? ThymeColor.text : (on ? ThymeColor.text : ThymeColor.charcoal))),
      ]),
    );
  }
}
