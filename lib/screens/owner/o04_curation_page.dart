import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/store_api.dart';
import '../../core/theme.dart';
import '../../models/store.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'o05_labor_law_page.dart';

/// O04 리테일 큐레이션 (매장 등록 5/6, 선택). 그 시간에 꼭 있어야 하는 능력을 정한다
///
/// Q1 직원 × 역량 등급 = GET /skill-matrix (합류 전이면 비어 있음)
/// Q2 시간대별 필요 역량 = GET·POST·DELETE /skill-windows → M03 역량 매칭과 근무표 엔진의 필수/우선 조건
/// Q3 입객 데이터 = 마감 보고 객수 → 다음 달 인원 제안 (설정할 것이 없어 안내만)
class CurationPage extends StatefulWidget {
  const CurationPage({super.key, this.editing = false});

  /// 매장 설정(P08)에서 고칠 때: 진행바 대신 제목, '다음' 대신 저장 후 돌아가기
  final bool editing;

  @override
  State<CurationPage> createState() => _CurationPageState();
}

class _CurationPageState extends State<CurationPage> {
  List<SkillInfo>? _skills;
  List<SkillWindow> _windows = [];
  List<SkillMatrixRow> _matrix = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final api = StoreApi();
      final skills = await api.skills();
      final windows = await api.skillWindows();
      final matrix = await api.skillMatrix();
      if (!mounted) return;
      setState(() {
        _skills = skills;
        _windows = windows;
        _matrix = matrix;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _add() async {
    final window = await showModalBottomSheet<SkillWindow>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThymeColor.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddWindowSheet(skills: _skills!),
    );
    if (window == null || !mounted) return;
    try {
      await StoreApi().addSkillWindow(window);
      await _load();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    }
  }

  Future<void> _remove(SkillWindow w) async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: ThymeColor.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(w.when, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            const SizedBox(height: 6),
            Text(w.tag, style: const TextStyle(fontSize: 15, color: ThymeColor.textSub)),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(backgroundColor: ThymeColor.danger),
                onPressed: () => Navigator.pop(context, true),
                child: const Text("이 조건 삭제"),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(width: double.infinity, child: TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("닫기"))),
          ]),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await StoreApi().deleteSkillWindow(w.id!);
      await _load();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    }
  }

  // 조건은 추가·삭제할 때마다 바로 저장된다
  void _next() => widget.editing ? Navigator.pop(context) : Navigator.push(context, MaterialPageRoute(builder: (_) => const LaborLawPage()));

  @override
  Widget build(BuildContext context) {
    final skills = _skills;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: widget.editing ? thymeEditAppBar('리테일 큐레이션') : ThymeStepAppBar(step: 5, total: 6, group: '매장 등록', owner: true, actions: [
        TextButton(onPressed: _next, child: const Text("건너뛰기", style: TextStyle(color: ThymeColor.textSub, fontWeight: FontWeight.bold))),
      ]),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(crossAxisAlignment: WrapCrossAlignment.center, spacing: 10, runSpacing: 6, children: [
                    const Text("'필요한 사람' 정하기", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: ThymeColor.selectedSoft, borderRadius: BorderRadius.circular(99)),
                      child: const Text("선택 · NEW", style: TextStyle(color: ThymeColor.charcoal, fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  const Text("인원 수만이 아니라, 그 시간에 꼭 있어야 하는 능력을 정해요.",
                      style: TextStyle(fontSize: 15, color: ThymeColor.textSub, height: 1.5)),
                  const SizedBox(height: 20),
                  if (_error != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: ThymeColor.dangerBg, borderRadius: BorderRadius.circular(16)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                        TextButton(onPressed: _load, child: const Text("다시 불러오기")),
                      ]),
                    )
                  else if (skills == null)
                    const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                  else ...[
                    _q1(skills),
                    const SizedBox(height: 12),
                    _q2(skills),
                    const SizedBox(height: 12),
                    _q3(),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(width: double.infinity, child: FilledButton(onPressed: _next, child: Text(widget.editing ? "완료" : "다음"))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(String q, String title, List<Widget> children) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text.rich(TextSpan(children: [
            TextSpan(text: "$q · ", style: ThymeTheme.mono(context, size: 14, color: ThymeColor.textSub)),
            TextSpan(text: title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
          ])),
          const SizedBox(height: 14),
          ...children,
        ]),
      );

  /// Q1 직원 × 역량. 아직 직원이 없으면 업종 역량 목록과 안내
  Widget _q1(List<SkillInfo> skills) {
    if (_matrix.isEmpty) {
      return _card("Q1", "누가 무엇을 할 수 있나", [
        Wrap(spacing: 8, runSpacing: 8, children: [for (final s in skills) _chip(s.name, strong: false)]),
        const SizedBox(height: 12),
        const Text("직원이 합류해 역량을 신청하면, 근무자 프로필에서 상·중·하를 확정해요. 그러면 여기에 표로 보여요.",
            style: TextStyle(fontSize: 13, color: ThymeColor.textSub, height: 1.5)),
      ]);
    }
    return _card("Q1", "누가 무엇을 할 수 있나", [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const SizedBox(width: 88),
            for (final s in skills)
              SizedBox(width: 76, child: Center(child: Text(s.name, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)))),
          ]),
          const SizedBox(height: 6),
          for (final r in _matrix)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(children: [
                SizedBox(
                  width: 88,
                  child: Text.rich(TextSpan(children: [
                    TextSpan(text: r.name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                    if (r.onProbation) const TextSpan(text: " 수습", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                  ]), overflow: TextOverflow.ellipsis),
                ),
                for (final s in skills) _levelCell(r.levels[s.id]),
              ]),
            ),
        ]),
      ),
    ]);
  }

  Widget _levelCell(SkillLevel? level) {
    final (bg, fg) = switch (level) {
      SkillLevel.high => (ThymeColor.primary, ThymeColor.onPrimary),
      SkillLevel.mid => (ThymeColor.selectedSoft, ThymeColor.text),
      _ => (ThymeColor.surfaceSub, ThymeColor.textSub),
    };
    return Container(
      width: 72,
      height: 38,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(level == null || level == SkillLevel.none ? "–" : level.label,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: fg)),
    );
  }

  /// Q2 시간대별 필요 역량. 칩을 누르면 삭제
  Widget _q2(List<SkillInfo> skills) => _card("Q2", "언제 무엇이 필요한가", [
        if (_windows.isEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text("아직 없어요. 피크·마감·입고일처럼 꼭 필요한 시간대가 있으면 추가해요.",
                style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.5)),
          ),
        for (final w in _windows)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              SizedBox(width: 120, child: Text(w.when, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text))),
              Expanded(
                child: Wrap(children: [
                  InkWell(borderRadius: BorderRadius.circular(99), onTap: () => _remove(w), child: _chip(w.tag, strong: w.mandatory)),
                ]),
              ),
            ]),
          ),
        InkWell(
          onTap: _add,
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text("+ 필요한 역량 추가", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
          ),
        ),
      ]);

  Widget _q3() => _card("Q3", "언제 누가 오나", const [
        Text("마감 보고에 객수를 적으면", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text)),
        SizedBox(height: 4),
        Text("직전 4주 객수로 다음 달 교대별 필요 인원을 제안해요. 매장 홈의 '+ 기록'에서 적어요.",
            style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.5)),
      ]);

  // 필수 = 딥 나이트, 우선·분류 = 라벤더 (가이드 5장 O04)
  Widget _chip(String text, {required bool strong}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: strong ? ThymeColor.primary : ThymeColor.selectedSoft, borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: strong ? ThymeColor.onPrimary : ThymeColor.text)),
      );
}

/// 시간대별 필요 역량 추가: 이름 · 요일 · 시간(30분 단위) · 역량+등급 또는 권한 · 인원 · 필수/우선
class _AddWindowSheet extends StatefulWidget {
  const _AddWindowSheet({required this.skills});

  final List<SkillInfo> skills;

  @override
  State<_AddWindowSheet> createState() => _AddWindowSheetState();
}

class _AddWindowSheetState extends State<_AddWindowSheet> {
  final _label = TextEditingController(text: "피크");
  int _start = 12 * 60;
  int _end = 14 * 60;
  final Set<int> _days = {}; // 비면 매일
  late SkillInfo? _skill = widget.skills.isEmpty ? null : widget.skills.first;
  EmployeePermission? _permission; // 고르면 역량 대신 권한 조건
  SkillLevel _level = SkillLevel.mid;
  int _count = 1;
  bool _mandatory = true;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  static String _fmt(int m) => "${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}";

  Future<void> _pickTime(bool start) async {
    var value = start ? _start : _end;
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: ThymeColor.surface,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            height: 200,
            child: CupertinoPicker(
              itemExtent: 36,
              scrollController: FixedExtentScrollController(initialItem: value ~/ 30),
              onSelectedItemChanged: (i) => value = i * 30,
              children: [for (var i = 0; i < 48; i++) Center(child: Text(_fmt(i * 30), style: ThymeTheme.mono(context, size: 18)))],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context, value), child: const Text("확인"))),
          ),
        ]),
      ),
    );
    if (picked != null) setState(() => start ? _start = picked : _end = picked);
  }

  Widget _choice(String label, bool on, VoidCallback onTap) => ChoiceChip(
        label: Text(label),
        selected: on,
        onSelected: (_) => onTap(),
        selectedColor: ThymeColor.primary,
        labelStyle: TextStyle(color: on ? ThymeColor.onPrimary : ThymeColor.text, fontWeight: FontWeight.bold),
        showCheckmark: false,
      );

  Widget _title(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
      );

  @override
  Widget build(BuildContext context) {
    final valid = _start < _end && (_skill != null || _permission != null);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("필요한 역량 추가", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              const SizedBox(height: 16),
              TextField(controller: _label, decoration: const InputDecoration(hintText: "시간대 이름 · 예: 피크, 마감, 입고")),
              _title("요일 (안 고르면 매일)"),
              Wrap(spacing: 6, runSpacing: 6, children: [
                for (var d = 0; d < 7; d++)
                  _choice(weekdayLabels[d], _days.contains(d), () => setState(() => _days.contains(d) ? _days.remove(d) : _days.add(d))),
              ]),
              _title("시간"),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => _pickTime(true), child: Text("시작 ${_fmt(_start)}"))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton(onPressed: () => _pickTime(false), child: Text("끝 ${_fmt(_end)}"))),
              ]),
              if (_start >= _end)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text("끝 시간이 시작보다 늦어야 해요.", style: TextStyle(fontSize: 13, color: ThymeColor.dangerText)),
                ),
              _title("누가 있어야 하나요"),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in widget.skills)
                  _choice(s.name, _permission == null && _skill?.id == s.id, () => setState(() {
                        _skill = s;
                        _permission = null;
                      })),
                for (final p in EmployeePermission.values)
                  _choice(p.label, _permission == p, () => setState(() => _permission = p)),
              ]),
              if (_permission == null) ...[
                _title("최소 등급"),
                Wrap(spacing: 8, children: [
                  for (final l in const [SkillLevel.low, SkillLevel.mid, SkillLevel.high])
                    _choice("${l.label} 이상", _level == l, () => setState(() => _level = l)),
                ]),
              ],
              _title("인원"),
              Row(children: [
                IconButton(tooltip: "1명 줄이기", onPressed: _count > 1 ? () => setState(() => _count--) : null, icon: const Icon(Icons.remove_circle_outline)),
                SizedBox(width: 40, child: Center(child: Text("$_count", style: ThymeTheme.mono(context, size: 18)))),
                IconButton(tooltip: "1명 늘리기", onPressed: _count < 10 ? () => setState(() => _count++) : null, icon: const Icon(Icons.add_circle_outline)),
                const Text("명", style: TextStyle(fontSize: 15, color: ThymeColor.text)),
              ]),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("필수 (끄면 '우선')", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                subtitle: const Text("필수는 꼭 맞추고, 우선은 되도록 맞춰요", style: TextStyle(fontSize: 12)),
                value: _mandatory,
                onChanged: (v) => setState(() => _mandatory = v),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: !valid
                      ? null
                      : () => Navigator.pop(
                            context,
                            SkillWindow(
                              label: _label.text.trim(),
                              startTime: "${_fmt(_start)}:00",
                              endTime: "${_fmt(_end)}:00",
                              skillId: _permission == null ? _skill?.id : null,
                              minLevel: _permission == null ? _level : null,
                              permission: _permission,
                              requiredCount: _count,
                              mandatory: _mandatory,
                              days: _days.toList()..sort(),
                            ),
                          ),
                  child: const Text("추가"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
