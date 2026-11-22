import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/owner_api.dart';
import '../../core/store_api.dart';
import '../../core/theme.dart';
import '../../models/owner.dart';
import '../../models/preference.dart';
import '../../models/store.dart';
import '../../models/user.dart' show EmploymentType;
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_owner_header.dart';

/// 직원 전체의 평소 일할 수 있는 시간 (시안 없음, P07 근무자 목록 위 링크). GET /stores/{id}/availabilities
/// 직원이 W11 아래에서 정한 요일별 시간을 요일마다 모아 본다. 엔진은 희망을 안 낸 달에만 이 시간을 쓴다:
/// 정한 요일·시간 안의 교대만 배정, 안 정한 요일은 배정 안 함 (정규직이 하나도 안 정했으면 매일 가능).
/// 교대가 들어가는지는 백엔드 fitsAvailability 와 같게 본다 (밤샘 교대는 끝이 23:59 이어야 한다)
class OwnerAvailabilityPage extends StatefulWidget {
  const OwnerAvailabilityPage({super.key});

  @override
  State<OwnerAvailabilityPage> createState() => _OwnerAvailabilityPageState();
}

class _OwnerAvailabilityPageState extends State<OwnerAvailabilityPage> {
  List<RosterRow>? _people;
  List<WeeklyAvailability> _avail = const [];
  List<ShiftInfo> _shifts = const [];
  int _day = DateTime.now().weekday - 1; // 0 = 월
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final api = OwnerApi();
      final roster = await api.roster();
      final avail = await api.storeAvailabilities();
      // 교대는 '몇 명 되나' 덤이라 못 받아도 시간표는 보여 준다
      final shifts = await StoreApi().shifts().catchError((_) => <ShiftInfo>[]);
      if (mounted) {
        final ids = {for (final p in roster.employees) p.employeeId};
        setState(() {
          _people = roster.employees;
          _avail = [for (final a in avail) if (ids.contains(a.employeeId)) a];
          _shifts = shifts;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  static int _min(String t) => int.parse(t.substring(0, 2)) * 60 + int.parse(t.substring(3, 5));

  /// 백엔드 fitsAvailability: 교대 시작이 가능 시작 이후, 끝이 가능 끝 이전. 밤을 넘기는 교대는 가능 끝이 23:59 여야 한다
  static bool _fits(ShiftInfo s, WeeklyAvailability a) {
    if (_min(s.startTime) < _min(a.startTime)) return false;
    final overnight = _min(s.endTime) <= _min(s.startTime);
    return overnight ? a.untilMidnight : _min(s.endTime) <= _min(a.endTime);
  }

  bool _openOn(ShiftInfo s, int day) => s.dayOfWeek == null || s.dayOfWeek == const ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'][day];

  List<WeeklyAvailability> _on(int day) => [for (final a in _avail) if (a.weekday == day) a];

  String _name(int? id) => _people?.where((p) => p.employeeId == id).firstOrNull?.name ?? '';

  String _end(WeeklyAvailability a) => a.untilMidnight ? '24:00' : a.endTime;

  @override
  Widget build(BuildContext context) {
    final people = _people;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: EdgeInsets.zero, children: [
          ThymeOwnerHeader(
            title: "평소 일할 수 있는 시간",
            label: "OWNER · 근무자",
            showBack: true,
            child: people == null ? null : _dayTabs(),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: _error != null
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                    TextButton(onPressed: _load, child: const Text("다시 불러오기")),
                  ])
                : people == null
                    ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                    : _body(people),
          ),
        ]),
      ),
    );
  }

  Widget _dayTabs() => Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: ThymeColor.indigoSurface, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          for (var d = 0; d < 7; d++)
            Expanded(
              child: Semantics(
                button: true,
                selected: _day == d,
                label: "${weekdayLabels[d]}요일 ${_on(d).length}명",
                child: GestureDetector(
                  onTap: () => setState(() => _day = d),
                  child: Container(
                    height: 56,
                    decoration: BoxDecoration(color: _day == d ? ThymeColor.surface : Colors.transparent, borderRadius: BorderRadius.circular(14)),
                    child: ExcludeSemantics(
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text(weekdayLabels[d],
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _day == d ? ThymeColor.text : ThymeColor.onPrimarySub)),
                        const SizedBox(height: 2),
                        Text("${_on(d).length}명", style: TextStyle(fontSize: 12, color: _day == d ? ThymeColor.textSub : ThymeColor.onPrimarySub)),
                      ]),
                    ),
                  ),
                ),
              ),
            ),
        ]),
      );

  Widget _body(List<RosterRow> people) {
    if (_avail.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(16)),
        child: const Text("아직 평소 일할 수 있는 시간을 정한 직원이 없어요. 직원은 '내 정보 › 고정 일정' 아래에서 요일마다 정할 수 있어요.",
            style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.5)),
      );
    }
    final today = _on(_day)..sort((a, b) => a.startTime != b.startTime ? a.startTime.compareTo(b.startTime) : _end(b).compareTo(_end(a)));
    final withAny = {for (final a in _avail) a.employeeId};
    // 아무 요일도 안 정한 사람: 정규직은 엔진이 매일 가능으로 보고, 알바는 희망이 없으면 배정되지 않는다
    final noneFull = [for (final p in people) if (!withAny.contains(p.employeeId) && p.employmentType == EmploymentType.fullTime) p];
    final nonePart = [for (final p in people) if (!withAny.contains(p.employeeId) && p.employmentType != EmploymentType.fullTime) p];
    final otherDays = [for (final p in people) if (withAny.contains(p.employeeId) && !today.any((a) => a.employeeId == p.employeeId)) p];
    final shifts = [for (final s in _shifts) if (_openOn(s, _day)) s]..sort((a, b) => a.startTime.compareTo(b.startTime));
    String names(List<RosterRow> ps) => ps.map((p) => p.name).join(', ');
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: ThymeColor.infoBg, borderRadius: BorderRadius.circular(16)),
        child: const Text("희망 근무를 안 낸 달에는 이 시간으로 근무표를 짜요. 시간 안에 다 들어가는 교대만 배정하고, 시간을 안 정한 요일은 배정하지 않아요.",
            style: TextStyle(fontSize: 14, color: ThymeColor.infoText, height: 1.5)),
      ),
      if (shifts.isNotEmpty) ...[
        const SizedBox(height: 16),
        Text("${weekdayLabels[_day]}요일 교대별로 들어갈 수 있는 사람", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
        const SizedBox(height: 10),
        Material(
          color: ThymeColor.surface,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(children: [
              for (final s in shifts) _shiftRow(s, today, noneFull.length),
              if (noneFull.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 10),
                  child: Text("시간을 안 정한 정규직 ${noneFull.length}명(매일 가능으로 봄)을 포함한 수예요.",
                      style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                ),
            ]),
          ),
        ),
      ],
      const SizedBox(height: 20),
      Text("${weekdayLabels[_day]}요일 ${today.length}명", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
      const SizedBox(height: 10),
      if (today.isEmpty)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(16)),
          child: Text("${weekdayLabels[_day]}요일에 시간을 정한 직원이 없어요.", style: const TextStyle(fontSize: 14, color: ThymeColor.textSub)),
        )
      else
        Material(
          color: ThymeColor.surface,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Column(children: [
              _axis(),
              for (final a in today) _barRow(a, shifts),
            ]),
          ),
        ),
      if (otherDays.isNotEmpty || noneFull.isNotEmpty || nonePart.isNotEmpty) ...[
        const SizedBox(height: 20),
        Material(
          color: ThymeColor.surface,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (otherDays.isNotEmpty) _group("${weekdayLabels[_day]}요일은 안 돼요 ${otherDays.length}", names(otherDays), "다른 요일만 정했어요"),
              if (noneFull.isNotEmpty) _group("시간을 안 정한 정규직 ${noneFull.length}", names(noneFull), "매일 가능으로 보고 배정해요"),
              if (nonePart.isNotEmpty) _group("시간을 안 정한 알바 ${nonePart.length}", names(nonePart), "희망 근무도 안 내면 그 달은 배정되지 않아요"),
            ]),
          ),
        ),
      ],
    ]);
  }

  Widget _group(String title, String names, String note) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
          const SizedBox(height: 4),
          Text(names, style: const TextStyle(fontSize: 14, color: ThymeColor.charcoal, height: 1.5)),
          const SizedBox(height: 2),
          Text(note, style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
        ]),
      );

  Widget _shiftRow(ShiftInfo s, List<WeeklyAvailability> today, int everyDay) {
    final n = today.where((a) => _fits(s, a)).length + everyDay;
    final need = s.minStaffOn(_day);
    final short = n < need;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(children: [
        Expanded(
          child: Text.rich(TextSpan(children: [
            TextSpan(text: s.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            TextSpan(text: "  ${s.startTime.substring(0, 5)}–${s.endTime.substring(0, 5)}", style: const TextStyle(fontSize: 14, color: ThymeColor.textSub)),
          ])),
        ),
        Text("$n명", style: ThymeTheme.mono(context, size: 16).copyWith(color: short ? ThymeColor.dangerText : ThymeColor.successText)),
        const SizedBox(width: 6),
        Text("/ 최소 $need", style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
      ]),
    );
  }

  static const _nameW = 64.0;

  Widget _axis() => Padding(
        padding: const EdgeInsets.only(left: _nameW, bottom: 6),
        child: LayoutBuilder(
          builder: (context, c) => SizedBox(
            height: 16,
            child: Stack(clipBehavior: Clip.none, children: [
              for (final h in const [0, 6, 12, 18, 24])
                Positioned(
                  left: c.maxWidth * h / 24 - (h == 24 ? 16 : h == 0 ? 0 : 8),
                  child: Text("$h", style: const TextStyle(fontSize: 12, color: ThymeColor.textSub)),
                ),
            ]),
          ),
        ),
      );

  Widget _barRow(WeeklyAvailability a, List<ShiftInfo> shifts) {
    final start = _min(a.startTime) / 1440;
    final end = (a.untilMidnight ? 1440 : _min(a.endTime)) / 1440;
    final range = "${a.startTime}–${_end(a)}";
    return Semantics(
      label: "${_name(a.employeeId)} $range",
      child: ExcludeSemantics(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(children: [
            SizedBox(
              width: _nameW,
              child: Text(_name(a.employeeId), maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            ),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                LayoutBuilder(
                  builder: (context, c) => SizedBox(
                    height: 22,
                    child: Stack(children: [
                      Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(6)))),
                      // 교대 경계 (흐린 세로선)
                      for (final s in shifts)
                        Positioned(left: c.maxWidth * _min(s.startTime) / 1440, top: 0, bottom: 0, child: Container(width: 1, color: ThymeColor.border)),
                      Positioned(
                        left: c.maxWidth * start,
                        width: c.maxWidth * (end - start),
                        top: 0,
                        bottom: 0,
                        child: DecoratedBox(decoration: BoxDecoration(color: ThymeColor.accent, borderRadius: BorderRadius.circular(6))),
                      ),
                    ]),
                  ),
                ),
                const SizedBox(height: 3),
                Text(a.untilMidnight ? "$range (밤샘 가능)" : range, style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
              ]),
            ),
          ]),
        ),
      ),
    );
  }
}
