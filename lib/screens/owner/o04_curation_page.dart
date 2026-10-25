import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/session.dart';
import '../../core/store_api.dart';
import '../../core/theme.dart';
import '../../models/store.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'o05_labor_law_page.dart'; // 다음 화면 임포트!

/// O04 리테일 큐레이션 (매장 등록 5/6). 시간대마다 꼭 있어야 하는 역량을 정한다
///
/// 로그인했으면 매장 역량(GET /skills)과 시간대별 필요 역량(GET·POST /skill-windows)을 쓴다.
/// 여기서 정한 시간대가 M03 역량 매칭과 근무표 엔진의 필수/우선 조건이 된다.
class CurationPage extends StatefulWidget {
  const CurationPage({super.key});

  @override
  State<CurationPage> createState() => _CurationPageState();
}

class _CurationPageState extends State<CurationPage> {
  bool get _live => Session.instance.isLoggedIn;

  // 시연용 (시안 값)
  List<String> _skillNames = const ["음료 제조", "응대 속도", "오픈·마감", "외국어", "정산"];
  List<(String time, List<String> tags)> _demoRows = const [
    ("피크 12~14", ["응대 상 · 필수", "중국어 · 필수"]),
    ("저녁 18~20", ["영어 · 우선"]),
    ("마감 20~22", ["정산 · 필수"]),
    ("화·금 10~12", ["발주·입고 가능자 1 · 필수"]),
    ("수습 기간", ["선임 1명과 같이 · 필수"]),
  ];

  List<SkillInfo> _skills = [];
  List<SkillWindow> _windows = [];

  @override
  void initState() {
    super.initState();
    if (_live) _load();
  }

  Future<void> _load() async {
    try {
      final api = StoreApi();
      final skills = await api.skills();
      final windows = await api.skillWindows();
      if (!mounted) return;
      setState(() {
        _skills = skills;
        _skillNames = [for (final s in skills) s.name];
        _windows = windows;
        _demoRows = const [];
      });
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _add() async {
    if (_skills.isEmpty) return;
    final window = await showModalBottomSheet<SkillWindow>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThymeColor.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _AddWindowSheet(skills: _skills),
    );
    if (window == null) return;
    try {
      await StoreApi().addSkillWindow(window);
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _next() => Navigator.push(context, MaterialPageRoute(builder: (context) => const LaborLawPage()));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: ThymeStepAppBar(step: 5, total: 6, group: '매장 등록', owner: true, actions: [TextButton(
            onPressed: _next,
            child: const Text("건너뛰기", style: TextStyle(color: ThymeColor.textSub, fontWeight: FontWeight.bold)),
          )]),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Text("'필요한 사람' 정하기", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text, height: 1.3)),
                        const SizedBox(width: 8),
                        Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), decoration: BoxDecoration(color: ThymeColor.selectedSoft, borderRadius: BorderRadius.circular(99)), child: const Text("선택 · NEW", style: TextStyle(color: ThymeColor.charcoal, fontSize: 10, fontWeight: FontWeight.bold))),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text("인원 수만이 아니라, 그 시간에 꼭 있어야 하는 능력을 정해요.", style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.4)),
                    const SizedBox(height: 32),

                    // 섹션 1: 매장 역량 (업종에 맞춰 미리 만들어짐)
                    const Text("01 · 누가 무엇을 할 수 있나", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [for (final name in _skillNames) _buildChip(name, required: false)],
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            "직원이 합류해서 역량을 신청하면, 근무자 프로필에서 상·중·하를 확정해요.",
                            style: TextStyle(fontSize: 12, color: ThymeColor.textSub, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 섹션 2: 시간대별 필요 역량
                    const Text("02 · 언제 무엇이 필요한가", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
                    const SizedBox(height: 16),
                    for (final (time, tags) in _demoRows) _buildRequirementRow(time, tags),
                    for (final w in _windows) _buildRequirementRow(_windowTime(w), [w.tag]),
                    if (_live) ...[
                      if (_windows.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 12),
                          child: Text("아직 없어요. 피크·마감처럼 꼭 필요한 시간대가 있으면 추가해요.",
                              style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                        ),
                      TextButton(
                        onPressed: _skills.isEmpty ? null : _add,
                        child: const Text("+ 필요한 역량 추가", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                      ),
                    ],
                    const SizedBox(height: 32),

                    // 섹션 3: 입객 데이터 (M04 수요 예측은 부수 서비스 X 범위 밖이라 아직 동작하지 않는다)
                    const Text("03 · 언제 누가 오나", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeTrackColor: ThymeColor.primary, // 스위치 켜짐 = 딥 나이트
                      activeThumbColor: ThymeColor.onPrimary,
                      title: const Text("입객 예측 데이터 연동", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                      subtitle: const Text("시간 · 고객 · 인원이 쌓이면 배치에 반영", style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
                      value: true,
                      onChanged: (val) {},
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _next, child: Text("다음")),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _windowTime(SkillWindow w) {
    final label = w.label.isEmpty ? "" : "${w.label} ";
    return "$label${hhmm(w.startTime).substring(0, 2)}~${hhmm(w.endTime).substring(0, 2)}";
  }

  Widget _buildRequirementRow(String time, List<String> tags) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 80, child: Text(time, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.text))),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final tag in tags) _buildChip(tag, required: tag.contains("필수"))],
            ),
          ),
        ],
      ),
    );
  }

  // 필수 = 딥 나이트, 우선·분류 = 라벤더 (가이드 5장 O04)
  Widget _buildChip(String tag, {required bool required}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: required ? ThymeColor.text : ThymeColor.surfaceSub,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(tag, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: required ? ThymeColor.onPrimary : ThymeColor.charcoal)),
    );
  }
}

/// 시간대별 필요 역량 추가: 이름 · 시간 · 역량 · 최소 등급 · 필수/우선
class _AddWindowSheet extends StatefulWidget {
  const _AddWindowSheet({required this.skills});

  final List<SkillInfo> skills;

  @override
  State<_AddWindowSheet> createState() => _AddWindowSheetState();
}

class _AddWindowSheetState extends State<_AddWindowSheet> {
  final _label = TextEditingController(text: "피크");
  TimeOfDay _start = const TimeOfDay(hour: 12, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 14, minute: 0);
  late SkillInfo _skill = widget.skills.first;
  SkillLevel _level = SkillLevel.mid;
  bool _mandatory = true;

  @override
  void dispose() {
    _label.dispose();
    super.dispose();
  }

  static String _hms(TimeOfDay t) => "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}:00";

  Future<void> _pick(bool start) async {
    final t = await showTimePicker(context: context, initialTime: start ? _start : _end);
    if (t != null) setState(() => start ? _start = t : _end = t);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("필요한 역량 추가", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThymeColor.text)),
          const SizedBox(height: 16),
          TextField(controller: _label, decoration: const InputDecoration(hintText: "시간대 이름 · 예: 피크")),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => _pick(true), child: Text("시작 ${_start.format(context)}"))),
            const SizedBox(width: 8),
            Expanded(child: OutlinedButton(onPressed: () => _pick(false), child: Text("끝 ${_end.format(context)}"))),
          ]),
          const SizedBox(height: 12),
          DropdownButtonFormField<SkillInfo>(
            initialValue: _skill,
            items: [for (final s in widget.skills) DropdownMenuItem(value: s, child: Text(s.name))],
            onChanged: (s) => setState(() => _skill = s ?? _skill),
            decoration: const InputDecoration(labelText: "역량"),
          ),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: [
            for (final l in const [SkillLevel.low, SkillLevel.mid, SkillLevel.high])
              ChoiceChip(
                label: Text("${l.label} 이상"),
                selected: _level == l,
                onSelected: (_) => setState(() => _level = l),
                selectedColor: ThymeColor.primary,
                labelStyle: TextStyle(color: _level == l ? ThymeColor.onPrimary : ThymeColor.text, fontWeight: FontWeight.bold),
                showCheckmark: false,
              ),
          ]),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeTrackColor: ThymeColor.primary,
            activeThumbColor: ThymeColor.onPrimary,
            title: const Text("필수 (끄면 '우선')", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            value: _mandatory,
            onChanged: (v) => setState(() => _mandatory = v),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.pop(
                context,
                SkillWindow(
                  label: _label.text.trim(),
                  startTime: _hms(_start),
                  endTime: _hms(_end),
                  skillId: _skill.id,
                  minLevel: _level,
                  mandatory: _mandatory,
                ),
              ),
              child: const Text("추가"),
            ),
          ),
        ],
      ),
    );
  }
}
