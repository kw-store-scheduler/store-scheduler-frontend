import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/owner_api.dart';
import '../../core/theme.dart';
import '../../models/owner.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_leaf.dart';
import '../../widgets/thyme_owner_header.dart';
import 'o04_curation_page.dart';
import 'p06_substitute_manage_page.dart';

/// M03 역량 매칭. 그날 시간대별 필요 역량(O04)을 채운 사람과 결원 (GET /skill-coverage)
class SkillMatchingPage extends StatefulWidget {
  const SkillMatchingPage({super.key});

  @override
  State<SkillMatchingPage> createState() => _SkillMatchingPageState();
}

class _SkillMatchingPageState extends State<SkillMatchingPage> {
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  List<SkillCoverage>? _rows;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _error = null;
      _rows = null;
    });
    try {
      final rows = await OwnerApi().skillCoverage(_date);
      if (mounted) setState(() => _rows = rows);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _move(int days) {
    _date = _date.add(Duration(days: days));
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    final ok = rows?.where((r) => r.satisfied).length ?? 0;
    final short = (rows?.length ?? 0) - ok;
    final vacancy = rows?.expand((r) => r.vacancies).firstOrNull;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: Column(children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(padding: EdgeInsets.zero, children: [
              const ThymeOwnerHeader(title: "역량 매칭", showBack: true),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  Row(children: [
                    IconButton(tooltip: "전날", onPressed: () => _move(-1), icon: const Icon(Icons.chevron_left)),
                    Expanded(
                      child: Text("${_date.month}월 ${_date.day}일 ${["월", "화", "수", "목", "금", "토", "일"][_date.weekday - 1]}요일",
                          textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, color: ThymeColor.textSub)),
                    ),
                    IconButton(tooltip: "다음 날", onPressed: () => _move(1), icon: const Icon(Icons.chevron_right)),
                  ]),
                  if (rows != null && rows.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(children: [
                        const ThymeLeaf(size: 18),
                        const SizedBox(width: 8),
                        Text("역량 충족 $ok", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                        if (short > 0) ...[
                          const SizedBox(width: 12),
                          const Icon(Icons.circle, size: 10, color: ThymeColor.danger),
                          const SizedBox(width: 6),
                          Text("부족 $short", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.dangerText)),
                        ],
                      ]),
                    ),
                  if (_error != null) ...[
                    Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                    TextButton(onPressed: _load, child: const Text("다시 불러오기")),
                  ] else if (rows == null)
                    const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                  else if (rows.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(16)),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        const Text("이 날 필요한 역량 조건이 없어요.", style: TextStyle(fontSize: 14, color: ThymeColor.textSub)),
                        TextButton(
                          onPressed: () async {
                            await Navigator.push(context, MaterialPageRoute(builder: (_) => const CurationPage(editing: true)));
                            if (mounted) _load();
                          },
                          child: const Text("필요한 역량 정하기 →"),
                        ),
                      ]),
                    )
                  else
                    for (final r in rows) _card(r),
                ]),
              ),
            ]),
          ),
        ),
        if (vacancy != null)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SubstituteManagePage(requestId: vacancy.$1))),
                  child: Text("${vacancy.$2} 결원 · 대타 요청 현황 보기"),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _card(SkillCoverage r) {
    final w = r.window;
    final bad = !r.satisfied;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ThymeColor.surface,
        borderRadius: BorderRadius.circular(20),
        border: bad ? Border.all(color: ThymeColor.danger.withValues(alpha: 0.6), width: 2) : null,
      ),
      child: IntrinsicHeight(
        child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Container(width: 5, decoration: BoxDecoration(color: bad ? ThymeColor.danger : ThymeColor.accent, borderRadius: BorderRadius.circular(99))),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text.rich(TextSpan(children: [
                TextSpan(text: "${hourRange(w.startTime, w.endTime)}  ", style: ThymeTheme.mono(context, size: 16)),
                TextSpan(text: w.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              ])),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(99)),
                child: Text(w.tag, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              ),
              const SizedBox(height: 8),
              Text(
                bad
                    ? [
                        if (r.matchedNames.isNotEmpty) r.matchedNames.join(" · "),
                        "${w.requiredCount - r.matchedNames.length > 0 ? w.requiredCount - r.matchedNames.length : 1}명 부족",
                        for (final v in r.vacancies) "${v.$2} 결원",
                      ].join(" · ")
                    : r.matchedNames.join(" · "),
                style: TextStyle(fontSize: 15, color: bad ? ThymeColor.dangerText : ThymeColor.textSub),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
