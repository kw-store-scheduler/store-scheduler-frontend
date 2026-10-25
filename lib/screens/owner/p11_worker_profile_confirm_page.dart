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

/// P11 근무자 프로필 관리. GET·PATCH /employees/{id}/profile
/// 역량 신청 확정/유지 · 혼자 맡길 수 있는 일 · 수습 기간 · 계약 시간·직책(직원) · 시급 · 변경 이력 (바꾸면 근로자에게 알림)
class WorkerProfileConfirmPage extends StatefulWidget {
  const WorkerProfileConfirmPage({super.key, required this.employeeId});

  final int employeeId;

  @override
  State<WorkerProfileConfirmPage> createState() => _WorkerProfileConfirmPageState();
}

class _WorkerProfileConfirmPageState extends State<WorkerProfileConfirmPage> {
  EmployeeProfile? _p;
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
      if (mounted) setState(() => _p = p);
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

  Widget _permissionsCard(EmployeeProfile p) => _card(Column(children: [
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
      ]));

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
