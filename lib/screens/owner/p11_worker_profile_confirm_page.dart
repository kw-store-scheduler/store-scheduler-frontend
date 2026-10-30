import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api_service.dart';
import '../../core/owner_api.dart';
import '../../core/theme.dart';
import '../../models/owner.dart';
import '../../models/store.dart';
import '../../models/user.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_owner_header.dart';
import 'm01_worker_approval_page.dart' show minimumWage2026;

/// P11 근무자 프로필 관리. GET·PATCH /employees/{id}/profile
/// 역량 신청 확정/유지 · 혼자 맡길 수 있는 일 · 수습 기간 · 계약 시간·직책(직원) · 시급 · 변경 이력 (바꾸면 근로자에게 알림)
/// 급여 설정(공제·수습 시급, PUT /pay-settings) · 퇴사(예정) 처리·취소 (POST·DELETE /resign)
class WorkerProfileConfirmPage extends StatefulWidget {
  const WorkerProfileConfirmPage({super.key, required this.employeeId});

  final int employeeId;

  @override
  State<WorkerProfileConfirmPage> createState() => _WorkerProfileConfirmPageState();
}

class _WorkerProfileConfirmPageState extends State<WorkerProfileConfirmPage> {
  EmployeeProfile? _p;

  /// 수습 시급·공제·퇴사 예정일 (프로필 응답에 없어서 직원 목록에서 받는다). 못 받으면 그 카드만 숨긴다
  EmployeeInfo? _info;
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
      final p = await OwnerApi().profile(widget.employeeId);
      final info = await OwnerApi().employee(widget.employeeId).catchError((_) => null);
      if (mounted) {
        setState(() {
          _p = p;
          _info = info;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  /// 서버가 새 프로필을 돌려주는 변경
  Future<void> _apply(Future<EmployeeProfile> Function(OwnerApi api) change, [String? done]) async {
    setState(() => _busy = true);
    try {
      final p = await change(OwnerApi());
      if (!mounted) return;
      setState(() => _p = p);
      if (done != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _togglePermission(EmployeePermission perm, bool on) {
    final now = {for (final e in _p!.permissions.entries) if (e.value) e.key};
    on ? now.add(perm) : now.remove(perm);
    return _apply((api) => api.updateProfile(widget.employeeId, permissions: now.toList()));
  }

  Future<void> _editProbation() async {
    final p = _p!;
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: ThymeColor.surface,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.event), title: const Text("수습 끝나는 날 정하기"), onTap: () => Navigator.pop(context, 'pick')),
          if (p.probationUntil != null)
            ListTile(leading: const Icon(Icons.check_circle_outline), title: const Text("수습 끝내기"), onTap: () => Navigator.pop(context, 'clear')),
        ]),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'clear') return _apply((api) => api.updateProfile(widget.employeeId, clearProbation: true), "수습을 끝냈어요");
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: p.probationUntil ?? DateTime(now.year, now.month + 3, now.day),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 2),
      helpText: "수습 끝나는 날",
    );
    if (picked != null) await _apply((api) => api.updateProfile(widget.employeeId, probationUntil: picked));
  }

  Future<void> _editWage() async {
    final wage = await _askNumber("시급 (원)", _p!.hourlyWage);
    if (wage == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await OwnerApi().updateWage(widget.employeeId, wage);
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editContract() async {
    final p = _p!;
    final min = await _askNumber("계약 주 최소 시간", p.contractMinWeeklyHours);
    if (min == null || !mounted) return;
    final max = await _askNumber("계약 주 최대 시간", p.contractMaxWeeklyHours ?? min);
    if (max == null || !mounted) return;
    await _apply((api) => api.updateProfile(widget.employeeId, contractMinWeeklyHours: min, contractMaxWeeklyHours: max));
  }

  /// 수습 감액 하한: 최저임금의 90% (백엔드 LaborPolicy.probationWageFloor)
  static final _probationFloor = (minimumWage2026 * 0.9).ceil();

  /// 급여 설정은 보낸 값으로 통째로 바뀐다 → 안 바꾸는 쪽은 지금 값을 다시 보낸다.
  /// 이미 수습 시급이 있으면 요건(1년 이상 계약·단순노무 아님)은 정할 때 확인했으니 그대로 true 로 보낸다
  Future<void> _savePay({required PayDeduction deduction, required int? probationWage, String? done}) async {
    setState(() => _busy = true);
    try {
      final info = await OwnerApi().updatePaySettings(widget.employeeId,
          deduction: deduction, probationWage: probationWage, contractOneYearOrMore: probationWage != null);
      if (!mounted) return;
      setState(() => _info = info);
      if (done != null) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
      await _load(); // 변경 이력
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  static const _deductionText = {
    PayDeduction.none: "공제 없음",
    PayDeduction.freelance: "3.3% · 사업소득",
    PayDeduction.fourInsurance: "4대 보험 · 근로자 부담분",
  };

  Future<void> _editDeduction() async {
    final info = _info!;
    final d = await showModalBottomSheet<PayDeduction>(
      context: context,
      backgroundColor: ThymeColor.surface,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
            child: Text("급여에서 떼는 것", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Text("근무자 홈과 인건비에 예상 실수령액으로 보여요. 근로소득세는 빠진 예상치예요.",
                style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
          ),
          for (final v in PayDeduction.values)
            ListTile(
              title: Text(_deductionText[v]!),
              trailing: info.deduction == v ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, v),
            ),
        ]),
      ),
    );
    if (d == null || d == info.deduction || !mounted) return;
    await _savePay(deduction: d, probationWage: info.probationWage, done: "공제를 바꿨어요 · ${_deductionText[d]}");
  }

  Future<void> _editProbationWage() async {
    final info = _info!;
    if (_p!.probationUntil == null || _p!.startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("수습 시급은 입사일과 수습 기간이 있어야 정할 수 있어요. 위의 '수습'부터 정해 주세요.")));
      return;
    }
    final c = TextEditingController(text: info.probationWage?.toString() ?? "$_probationFloor");
    var longContract = info.probationWage != null;
    var notSimpleLabor = info.probationWage != null;
    // null = 닫음, (wage: null) = 해제, (wage: n) = 저장
    final result = await showModalBottomSheet<({int? wage})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThymeColor.surface,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) {
          final wage = int.tryParse(c.text);
          final ok = longContract && notSimpleLabor && wage != null && wage >= _probationFloor;
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
            child: SafeArea(
              top: false,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Text("수습 시급", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text("수습 시작 3개월까지만, 최저임금의 90%(${won(_probationFloor)}) 이상으로 줄일 수 있어요. 아래 두 가지를 모두 확인해야 해요.",
                    style: const TextStyle(fontSize: 13, color: ThymeColor.textSub, height: 1.5)),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: longContract,
                  onChanged: (v) => setSheet(() => longContract = v ?? false),
                  title: const Text("근로계약 기간이 1년 이상이에요"),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: notSimpleLabor,
                  onChanged: (v) => setSheet(() => notSimpleLabor = v ?? false),
                  title: const Text("단순노무 직종이 아니에요"),
                ),
                const SizedBox(height: 4),
                TextField(
                  controller: c,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  onChanged: (_) => setSheet(() {}),
                  decoration: InputDecoration(labelText: "수습 시급 (원)", helperText: "${won(_probationFloor)} 이상"),
                ),
                const SizedBox(height: 16),
                FilledButton(onPressed: ok ? () => Navigator.pop(context, (wage: wage)) : null, child: const Text("저장")),
                if (info.probationWage != null)
                  TextButton(onPressed: () => Navigator.pop(context, (wage: null)), child: const Text("수습 감액 없애기 (시급 그대로)")),
              ]),
            ),
          );
        },
      ),
    );
    c.dispose();
    if (result == null || !mounted) return;
    await _savePay(
      deduction: info.deduction,
      probationWage: result.wage,
      done: result.wage == null ? "수습 감액을 없앴어요" : "수습 시급을 ${won(result.wage!)}으로 정했어요",
    );
  }

  Future<void> _resign() async {
    final p = _p!;
    final today = DateUtils.dateOnly(DateTime.now());
    final last = await showDatePicker(
      context: context,
      initialDate: today,
      firstDate: today.subtract(const Duration(days: 90)),
      lastDate: today.add(const Duration(days: 365)),
      helpText: "마지막 근무일",
    );
    if (last == null || !mounted) return;
    final future = last.isAfter(today);
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${p.displayName}님 ${future ? '퇴사 예정' : '퇴사'} 처리"),
        content: Text([
          "마지막 근무일: ${last.month}/${last.day}",
          "그 뒤에 잡힌 근무는 지금 바로 지워지고, 걸려 있던 대타·근무 바꾸기도 닫혀요.",
          if (future) "그날까지는 앱을 그대로 쓰고, 지나면 자동으로 퇴사돼요. 예정을 취소해도 지운 근무는 돌아오지 않아요.",
          "지난 근무와 급여 기록은 남아요.",
        ].join("\n\n")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("취소")),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("퇴사 처리", style: TextStyle(color: ThymeColor.dangerText)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      final removed = await OwnerApi().resign(widget.employeeId, last);
      if (!mounted) return;
      final shifts = removed > 0 ? " 근무 $removed개를 지웠어요." : "";
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(future ? "${last.month}/${last.day}까지 근무하고 퇴사해요.$shifts" : "${p.displayName}님을 퇴사 처리했어요.$shifts")));
      // 오늘까지면 바로 퇴사 → 직원 목록에서 빠지므로 이 화면을 닫는다
      if (future) {
        await _load();
      } else {
        Navigator.pop(context);
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancelResignation() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("퇴사 예정 취소"),
        content: const Text("계속 근무하는 걸로 돌려요. 퇴사 예정 때 지운 근무는 돌아오지 않으니 근무표에 다시 넣어 주세요."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("닫기")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("예정 취소")),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await OwnerApi().cancelResignation(widget.employeeId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("퇴사 예정을 취소했어요")));
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _setLevel(SkillRequest s) async {
    final level = await showModalBottomSheet<SkillLevel>(
      context: context,
      backgroundColor: ThymeColor.surface,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text("${s.skillName} 등급", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          for (final l in SkillLevel.values.reversed)
            ListTile(
              title: Text(l == SkillLevel.none ? "없음 (역량에서 빼기)" : l.label),
              trailing: s.level == l ? const Icon(Icons.check) : null,
              onTap: () => Navigator.pop(context, l),
            ),
        ]),
      ),
    );
    if (level != null) await _apply((api) => api.setSkillLevel(widget.employeeId, s.skillId, level));
  }

  Future<int?> _askNumber(String label, int? initial) async {
    final c = TextEditingController(text: initial?.toString() ?? "");
    final v = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThymeColor.surface,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(
              controller: c,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(labelText: label),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: () => Navigator.pop(context, int.tryParse(c.text)), child: const Text("저장")),
            ),
          ]),
        ),
      ),
    );
    c.dispose();
    return v;
  }

  @override
  Widget build(BuildContext context) {
    final p = _p;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: EdgeInsets.zero, children: [
          ThymeOwnerHeader(
            label: "OWNER · 근무자",
            title: p?.displayName ?? " ",
            subtitle: p == null
                ? null
                : [
                    employmentLabel(p.employmentType),
                    ?p.position?.label,
                    if (p.startDate != null) "${p.startDate!.month}/${p.startDate!.day} 입사",
                  ].join(" · "),
            showBack: true,
            child: p == null ? null : _stats(p),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: _error != null
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                    TextButton(onPressed: _load, child: const Text("다시 불러오기")),
                  ])
                : p == null
                    ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                    : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        for (final s in p.skills.where((s) => s.requestedLevel != null)) ...[_requestCard(s), const SizedBox(height: 12)],
                        _skillsCard(p),
                        const SizedBox(height: 12),
                        _permissionsCard(p),
                        if (p.employmentType == EmploymentType.fullTime) ...[const SizedBox(height: 12), _positionCard(p)],
                        if (_info != null) ...[const SizedBox(height: 12), _payCard(_info!)],
                        const SizedBox(height: 20),
                        Text("변경 이력 · 바꾸면 ${p.displayName}님에게 알림이 가요",
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
                        const SizedBox(height: 8),
                        if (p.history.isEmpty) const Text("아직 없어요.", style: TextStyle(color: ThymeColor.textSub)),
                        for (final (at, text) in p.history)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              SizedBox(
                                width: 60,
                                child: Text("${at.month.toString().padLeft(2, '0')}/${at.day.toString().padLeft(2, '0')}",
                                    style: ThymeTheme.mono(context, size: 13, color: ThymeColor.textSub)),
                              ),
                              Expanded(child: Text(text, style: const TextStyle(fontSize: 14, color: ThymeColor.charcoal))),
                            ]),
                          ),
                        if (_info != null) ...[const SizedBox(height: 20), _resignCard(_info!)],
                      ]),
          ),
        ]),
      ),
    );
  }

  Widget _stats(EmployeeProfile p) {
    Widget card(String label, String value, VoidCallback onTap) => Expanded(
          child: Material(
            color: ThymeColor.indigoSurface,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: _busy ? null : onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(label, style: const TextStyle(color: ThymeColor.onPrimarySub, fontSize: 13))),
                    const Icon(Icons.edit, size: 14, color: ThymeColor.onPrimarySub),
                  ]),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value, style: ThymeTheme.mono(context, size: 17, color: ThymeColor.onPrimary)),
                  ),
                ]),
              ),
            ),
          ),
        );
    final contract = p.contractMinWeeklyHours == null ? "미정" : "주 ${p.contractMinWeeklyHours}–${p.contractMaxWeeklyHours}h";
    final probation = p.probationUntil == null ? "없음" : "~ ${p.probationUntil!.month}/${p.probationUntil!.day}";
    return Row(children: [
      card("계약", contract, _editContract),
      const SizedBox(width: 8),
      card("시급", p.hourlyWage == null ? "미정" : won(p.hourlyWage!), _editWage),
      const SizedBox(width: 8),
      card("수습", probation, _editProbation),
    ]);
  }

  Widget _card(Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
        child: child,
      );

  /// 받침이 있으면 '으로' (상으로·중으로·하로)
  static String _ro(String w) {
    final c = w.codeUnitAt(w.length - 1) - 0xAC00;
    return c >= 0 && c < 11172 && c % 28 != 0 && c % 28 != 8 ? "$w으로" : "$w로";
  }

  Widget _requestCard(SkillRequest s) {
    final from = s.level?.label ?? "없음";
    final to = s.requestedLevel!.label;
    return _card(Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 8, children: [
          const Icon(Icons.circle, size: 10, color: ThymeColor.info),
          const Text("확인 대기", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.infoText)),
          Text("${s.skillName} $from → $to 신청", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text)),
        ]),
        const SizedBox(height: 6),
        const Text("확정하면 이 역량이 필요한 시간대에 배치될 수 있어요.", style: TextStyle(fontSize: 14, color: ThymeColor.textSub)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _busy ? null : () => _apply((api) => api.keepSkillLevel(widget.employeeId, s.skillId), "${_ro(from)} 유지했어요"),
              child: Text("${_ro(from)} 유지"),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: FilledButton(
              onPressed: _busy ? null : () => _apply((api) => api.setSkillLevel(widget.employeeId, s.skillId, s.requestedLevel!), "${_ro(to)} 확정했어요"),
              child: Text("${_ro(to)} 확정"),
            ),
          ),
        ]),
      ]),
    ));
  }

  Widget _skillsCard(EmployeeProfile p) => _card(Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("역량 · 누르면 등급을 바꿔요", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
          const SizedBox(height: 10),
          if (p.skills.isEmpty) const Text("매장 역량이 없어요.", style: TextStyle(color: ThymeColor.textSub)),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final s in p.skills)
              ActionChip(
                onPressed: _busy ? null : () => _setLevel(s),
                label: Text("${s.skillName} ${s.level == null || s.level == SkillLevel.none ? '–' : s.level!.label}"),
                backgroundColor: s.level == SkillLevel.high ? ThymeColor.primary : ThymeColor.surfaceSub,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: s.level == SkillLevel.high ? ThymeColor.onPrimary : ThymeColor.text,
                ),
              ),
          ]),
        ]),
      ));

  // 스위치 줄의 물결 효과가 보이도록 색 있는 상자 대신 Material 로 감싼다
  Widget _permissionsCard(EmployeeProfile p) => Material(
      color: ThymeColor.surface,
      borderRadius: BorderRadius.circular(20),
      child: Padding(padding: const EdgeInsets.symmetric(horizontal: 18), child: Column(children: [
        for (final perm in EmployeePermission.values) ...[
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(perm == EmployeePermission.ordering ? "발주 시스템" : perm.label,
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            value: p.permissions[perm] ?? false,
            onChanged: _busy ? null : (v) => _togglePermission(perm, v),
          ),
          if (perm != EmployeePermission.values.last) const Divider(height: 1),
        ],
      ])));

  Widget _payCard(EmployeeInfo info) => Material(
        color: ThymeColor.surface,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18),
            enabled: !_busy,
            title: const Text("급여 공제", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            subtitle: const Text("예상 실수령액 계산용", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
            trailing: Text(info.deduction.label, style: const TextStyle(color: ThymeColor.textSub)),
            onTap: _editDeduction,
          ),
          const Divider(height: 1, indent: 18, endIndent: 18),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 18),
            enabled: !_busy,
            title: const Text("수습 시급", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            subtitle: const Text("수습 3개월까지 최저임금 90% 이상", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
            trailing: Text(info.probationWage == null ? "감액 없음" : won(info.probationWage!), style: const TextStyle(color: ThymeColor.textSub)),
            onTap: _editProbationWage,
          ),
        ]),
      );

  Widget _resignCard(EmployeeInfo info) {
    final on = info.resignedOn;
    if (on == null) {
      return OutlinedButton(
        onPressed: _busy ? null : _resign,
        style: OutlinedButton.styleFrom(foregroundColor: ThymeColor.dangerText),
        child: const Text("퇴사 처리"),
      );
    }
    return _card(Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.circle, size: 10, color: ThymeColor.danger),
          const SizedBox(width: 8),
          Text("${on.month}/${on.day}까지 근무 · 퇴사 예정", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text)),
        ]),
        const SizedBox(height: 6),
        const Text("그날이 지나면 자동으로 퇴사 처리돼요.", style: TextStyle(fontSize: 14, color: ThymeColor.textSub)),
        const SizedBox(height: 12),
        OutlinedButton(onPressed: _busy ? null : _cancelResignation, child: const Text("퇴사 예정 취소")),
      ]),
    ));
  }

  Widget _positionCard(EmployeeProfile p) => _card(Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("직책", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, children: [
            for (final pos in StaffPosition.values)
              ChoiceChip(
                label: Text(pos.label),
                selected: p.position == pos,
                onSelected: _busy ? null : (_) => _apply((api) => api.updateProfile(widget.employeeId, position: pos)),
                selectedColor: ThymeColor.primary,
                labelStyle: TextStyle(color: p.position == pos ? ThymeColor.onPrimary : ThymeColor.text, fontWeight: FontWeight.bold),
                showCheckmark: false,
              ),
          ]),
        ]),
      ));
}
