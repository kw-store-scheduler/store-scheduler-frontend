import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/preference_api.dart';
import '../../core/theme.dart';
import '../../models/preference.dart';
import '../../models/store.dart' show SkillLevel;
import '../../widgets/thyme_step_app_bar.dart';
import 'w14_preference_submit_page.dart';

/// W05 내가 할 수 있는 일 (알바 6/7). 매장 역량마다 내 등급을 '신청'하고, 매니저가 확인하면 배치에 쓰인다
///
/// - 서버: GET /my-skills (확정 등급 · 신청 중 등급 · 혼자 맡길 수 있는 일 · 수습) · PUT /my-skills (바꾼 역량만)
/// - 혼자 맡길 수 있는 일과 수습 기간은 매니저가 정한다 → 읽기만
class SkillsPage extends StatefulWidget {
  const SkillsPage({super.key, required this.draft});

  final PreferenceDraft draft;

  @override
  State<SkillsPage> createState() => _SkillsPageState();
}

class _SkillsPageState extends State<SkillsPage> {
  static const _levels = [SkillLevel.high, SkillLevel.mid, SkillLevel.low, SkillLevel.none];

  MySkills? _data;
  final Map<int, SkillLevel> _picked = {};
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final d = await PreferenceApi().mySkills();
      if (mounted) setState(() => _data = d);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  /// 화면에 보이는 등급: 방금 고른 값 → 신청 중 → 확정 (등급 없이 보유면 null)
  SkillLevel? _shown(MySkill s) => _picked[s.skillId] ?? s.requestedLevel ?? s.level;

  Future<void> _next() async {
    // 지금 서버에 있는 값(신청 중 또는 확정)과 다른 것만 보낸다
    final changed = {
      for (final s in _data?.skills ?? const <MySkill>[])
        if (_picked[s.skillId] != null && _picked[s.skillId] != (s.requestedLevel ?? s.level)) s.skillId: _picked[s.skillId]!,
    };
    setState(() => _saving = true);
    try {
      if (changed.isNotEmpty) await PreferenceApi().requestSkillLevels(changed);
      if (!mounted) return;
      if (changed.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("역량 ${changed.length}개를 신청했어요. 매니저가 확인하면 배치에 쓰여요")));
      }
      Navigator.push(context, MaterialPageRoute(builder: (_) => PreferenceSubmitPage(draft: widget.draft)));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: const ThymeStepAppBar(step: 6, total: 7, title: '나 · 역량'),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
              const Text("내가 할 수 있는 일", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              const SizedBox(height: 8),
              const Text('내가 적은 건 "신청"이에요. 매니저가 확인하면 배치에 쓰여요.', style: TextStyle(fontSize: 15, color: ThymeColor.textSub, height: 1.5)),
              const SizedBox(height: 20),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                TextButton(onPressed: _load, child: const Text("다시 불러오기")),
              ] else if (d == null)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
              else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(22)),
                  child: d.skills.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 14),
                          child: Text("매장에 등록된 역량이 없어요. 그냥 다음으로 가도 돼요.", style: TextStyle(fontSize: 14, color: ThymeColor.textSub)),
                        )
                      : Column(children: [
                          for (final (i, s) in d.skills.indexed) ...[
                            if (i > 0) const Divider(height: 1),
                            _skillRow(s),
                          ],
                        ]),
                ),
                const SizedBox(height: 20),
                const Row(children: [
                  Icon(Icons.lock_outline, size: 18, color: ThymeColor.textSub),
                  SizedBox(width: 6),
                  Text("혼자 맡길 수 있는 일 · 매니저가 정해요", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
                ]),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                  decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(22)),
                  child: Column(children: [
                    for (final (i, p) in d.permissions.indexed) ...[
                      if (i > 0) const Divider(height: 1),
                      _readRow(p.$1, p.$2 ? "가능" : "아직", p.$2 ? ThymeColor.accent : ThymeColor.disabled),
                    ],
                    if (d.permissions.isNotEmpty) const Divider(height: 1),
                    _readRow(
                      "수습 기간",
                      d.probationUntil == null ? "없음" : "~ ${d.probationUntil!.month}/${d.probationUntil!.day}",
                      d.probationUntil == null ? ThymeColor.disabled : ThymeColor.info,
                    ),
                  ]),
                ),
                const SizedBox(height: 10),
                const Text("수습 기간에는 선임 1명과 같은 교대에 배치돼요. 바꿔야 하면 매니저에게 요청하세요.",
                    style: TextStyle(fontSize: 13, color: ThymeColor.textSub, height: 1.5)),
              ],
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: d == null || _saving ? null : _next, child: Text(_saving ? "신청하는 중…" : "다음")),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _skillRow(MySkill s) {
    final shown = _shown(s);
    final changed = _picked[s.skillId] != null && _picked[s.skillId] != (s.requestedLevel ?? s.level);
    final (statusText, statusColor) = changed
        ? ("신청할 값", ThymeColor.info)
        : s.pending
            ? ("확인 대기", ThymeColor.info)
            : ("확정", ThymeColor.accent);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(s.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text))),
          Icon(Icons.circle, size: 8, color: statusColor),
          const SizedBox(width: 4),
          Text(statusText, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: statusColor == ThymeColor.accent ? ThymeColor.successText : ThymeColor.infoText)),
        ]),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(14)),
          child: Row(children: [
            for (final l in _levels)
              Expanded(
                child: Material(
                  color: shown == l ? ThymeColor.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => setState(() => _picked[s.skillId] = l),
                    child: SizedBox(
                      height: 40,
                      child: Center(
                        child: Text(l.label,
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: shown == l ? ThymeColor.onPrimary : ThymeColor.textSub)),
                      ),
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ]),
    );
  }

  Widget _readRow(String title, String value, Color dot) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text))),
          Icon(Icons.circle, size: 8, color: dot),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(fontSize: 14, color: ThymeColor.textSub)),
        ]),
      );
}
