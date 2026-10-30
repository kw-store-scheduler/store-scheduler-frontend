import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/day_off_api.dart';
import '../../core/theme.dart';
import '../../models/preference.dart';
import '../../models/store.dart' show weekdayLabels;
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'w06_work_hours_page.dart';

/// 화면에서 고치는 휴무 한 건
class _Item {
  _Item({this.serverId, required this.date, this.must = false, this.reason = '', List<DayOffFallback>? order, this.downgraded = false})
      : order = order ?? [];

  final int? serverId; // 이미 서버에 있는 신청이면 id
  final DateTime date;
  bool must;
  String reason;
  final List<DayOffFallback> order; // 희망 휴무가 안 될 때 대안, 누른 순서대로
  final bool downgraded; // 필수로 냈지만 월 한도를 넘어 희망으로 저장됨
  bool dirty = false;
}

/// W03 쉬고 싶은 날 (알바 4/7). 필수 휴무는 반드시 지키고, 희망 휴무는 안 될 때의 대안 순서를 정한다
///
/// - 서버: GET /day-offs/my · POST /day-offs (type MUST/PREFER, fallbacks = 누른 순서) · DELETE /day-offs/{id}
/// - 같은 날짜는 한 건만 → 바꾼 건 취소 후 다시 신청. 필수는 한 달 2일까지, 넘으면 서버가 희망으로 바꾼다
/// - 휴무는 희망 제출(W14)과 따로 저장된다 → '다음'에서 바로 저장
class RestDayPreferencePage extends StatefulWidget {
  const RestDayPreferencePage({super.key, required this.draft});

  final PreferenceDraft draft;

  @override
  State<RestDayPreferencePage> createState() => _RestDayPreferencePageState();
}

class _RestDayPreferencePageState extends State<RestDayPreferencePage> {
  // 알바 대안: 오후만 쉬기 · 다른 날과 바꾸기 · 대타 직접 구하기 · 그냥 출근 (시안 W03)
  static const _choices = [DayOffFallback.afternoonOff, DayOffFallback.swapDay, DayOffFallback.findSubstitute, DayOffFallback.workAnyway];
  static const _mustLimit = 2;

  DateTime get _month => widget.draft.month;
  final List<_Item> _items = [];
  final List<int> _removed = [];
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
      final mine = await DayOffApi().mine(_month);
      if (!mounted) return;
      setState(() {
        _items
          ..clear()
          ..addAll([
            for (final d in mine)
              _Item(serverId: d.id, date: d.date, must: d.type == DayOffType.must, reason: d.reason ?? '', order: List.of(d.fallbacks), downgraded: d.downgraded),
          ])
          ..sort((a, b) => a.date.compareTo(b.date));
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  int get _mustCount => _items.where((i) => i.must).length;

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
      var downgraded = 0;
      for (final item in _items.where((i) => i.dirty).toList()) {
        if (item.serverId != null) await api.cancel(item.serverId!); // 같은 날짜는 한 건만 → 취소 후 다시
        final saved = await api.request(DayOff(
          date: item.date,
          type: item.must ? DayOffType.must : DayOffType.prefer,
          reason: item.reason.trim(),
          // 필수는 순위 없이 항상 지켜진다 → 대안은 희망일 때만
          fallbacks: item.must ? const [] : item.order,
        ));
        if (saved.downgraded) downgraded++;
        final i = _items.indexOf(item);
        _items[i] = _Item(
          serverId: saved.id,
          date: saved.date,
          must: saved.type == DayOffType.must,
          reason: saved.reason ?? '',
          order: List.of(saved.fallbacks),
          downgraded: saved.downgraded,
        );
      }
      if (!mounted) return;
      if (downgraded > 0) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("필수 휴무는 한 달 $_mustLimit일까지라 $downgraded일은 희망 휴무로 저장했어요")));
      }
      Navigator.push(context, MaterialPageRoute(builder: (_) => WorkHoursPage(draft: widget.draft)));
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
      appBar: const ThymeStepAppBar(step: 4, total: 7, title: '언제 · 휴무'),
      body: Column(children: [
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_error!, style: const TextStyle(color: ThymeColor.textSub)),
                        OutlinedButton(onPressed: _load, child: const Text("다시 불러오기")),
                      ]),
                    )
                  : ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
                      const Text("쉬고 싶은 날이 있나요?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                      const SizedBox(height: 8),
                      const Text("필수는 반드시 지켜져요. 희망은 안 될 때 어떻게 할지 순서를 정해 두면 그대로 처리돼요.",
                          style: TextStyle(fontSize: 15, color: ThymeColor.textSub, height: 1.5)),
                      const SizedBox(height: 20),
                      if (_items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text("아직 쉬고 싶은 날이 없어요. 없으면 그냥 다음으로 가도 돼요.", style: TextStyle(fontSize: 14, color: ThymeColor.textSub)),
                        ),
                      for (final item in _items) ...[
                        _card(item),
                        const SizedBox(height: 12),
                      ],
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: _addDate,
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: ThymeColor.icon, width: 1.2)),
                          alignment: Alignment.center,
                          child: const Text("+ 휴무 추가", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: ThymeColor.warnBg, borderRadius: BorderRadius.circular(16)),
                        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const Padding(padding: EdgeInsets.only(top: 5), child: Icon(Icons.circle, size: 8, color: ThymeColor.warn)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text("필수 휴무는 한 달에 최대 $_mustLimit일까지예요. 넘으면 희망 휴무로 바뀌어요.",
                                style: const TextStyle(fontSize: 14, color: ThymeColor.warnText, height: 1.5)),
                          ),
                        ]),
                      ),
                    ]),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _loading || _error != null || _saving ? null : _next, child: Text(_saving ? "저장하는 중…" : "다음")),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _card(_Item item) {
    final weekday = weekdayLabels[item.date.weekday - 1];
    final summary = item.order.isEmpty
        ? "대안을 고르지 않으면 안 될 때 그냥 출근으로 봐요."
        : "안 되면 ${[for (var i = 0; i < item.order.length; i++) "${i + 1}순위 ${item.order[i].label}"].join(" → ")} 순서로 처리해요.";
    final overLimit = item.must && _mustCount > _mustLimit && _items.where((i) => i.must).toList().indexOf(item) >= _mustLimit;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(22)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(color: item.must ? ThymeColor.selectedSoft : ThymeColor.dangerBg, borderRadius: BorderRadius.circular(14)),
            child: Column(children: [
              Text(weekday, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.forWeekday(weekday))),
              Text("${item.date.month}/${item.date.day}", style: ThymeTheme.mono(context, size: 16, color: ThymeColor.forWeekday(weekday))),
            ]),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              initialValue: item.reason,
              onChanged: (v) {
                item.reason = v;
                item.dirty = true;
              },
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(hintText: "사유 (선택) · 예: 가족 행사", isDense: true),
            ),
          ),
          IconButton(
            tooltip: "이 날 빼기",
            visualDensity: VisualDensity.compact,
            onPressed: () => _remove(item),
            icon: const Icon(Icons.close, size: 18, color: ThymeColor.textSub),
          ),
        ]),
        const SizedBox(height: 10),
        // 필수 ↔ 희망
        SegmentedButton<bool>(
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
          segments: const [ButtonSegment(value: true, label: Text("필수")), ButtonSegment(value: false, label: Text("희망"))],
          selected: {item.must},
          onSelectionChanged: (v) => setState(() {
            item.must = v.first;
            item.dirty = true;
          }),
        ),
        if (item.downgraded || overLimit)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text("필수 한도를 넘어 희망 휴무로 저장돼요", style: TextStyle(fontSize: 13, color: ThymeColor.warnText)),
          ),
        if (item.must)
          const Padding(
            padding: EdgeInsets.only(top: 8, left: 2),
            child: Text("필수 · 순위 없이 항상 지켜져요", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
          )
        else ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Row(children: [
                Expanded(child: Text("이 날이 안 되면?", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text))),
                Text("누른 순서대로 1·2·3", style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
              ]),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final f in _choices)
                  GestureDetector(onTap: () => _toggle(item, f), child: _chip(item.order.contains(f) ? item.order.indexOf(f) + 1 : null, f.label)),
              ]),
              const SizedBox(height: 10),
              Text(summary, style: const TextStyle(fontSize: 13, color: ThymeColor.textSub, height: 1.4)),
            ]),
          ),
        ],
      ]),
    );
  }

  // 순위가 있으면 딥 나이트 테두리 + 번호 (약한 선택, 가이드 4-3)
  Widget _chip(int? rank, String label) {
    final on = rank != null;
    return Container(
      padding: const EdgeInsets.fromLTRB(6, 6, 14, 6),
      decoration: BoxDecoration(
        color: ThymeColor.surface,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: on ? ThymeColor.primary : ThymeColor.border, width: 1.5),
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
        Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: on ? ThymeColor.text : ThymeColor.charcoal)),
      ]),
    );
  }
}
