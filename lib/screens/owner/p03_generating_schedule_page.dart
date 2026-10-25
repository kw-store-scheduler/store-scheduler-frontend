import 'dart:async';

import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/owner_api.dart';
import '../../core/store_api.dart';
import '../../core/theme.dart';
import '../../models/owner.dart';
import '../../models/store.dart';
import '../../theme/thyme_colors.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_back_button.dart';
import '../../widgets/thyme_leaf.dart';
import 'm05_proposal_compare_page.dart';

/// 근무표 기간 이름: 월간이면 "12월", 주간·2주면 "11/30–12/6"
String periodLabel(DateTime start, DateTime? end, {bool monthly = false}) =>
    monthly || (end != null && start.day == 1 && end.month == start.month && end.day >= 28)
        ? "${start.month}월"
        : "${start.month}/${start.day}${end == null ? '' : '–${end.month}/${end.day}'}";

/// P03 근무표 생성 중. 다음 주기(GET /schedules/plan)의 3안을 POST /schedules/automate 로 만들고 M05로 넘어간다
class GeneratingSchedulePage extends StatefulWidget {
  const GeneratingSchedulePage({super.key});

  @override
  State<GeneratingSchedulePage> createState() => _GeneratingSchedulePageState();
}

class _GeneratingSchedulePageState extends State<GeneratingSchedulePage> {
  SchedulePlan? _plan;
  PreferenceStatus? _prefs;
  int _step = 0; // 0~3 진행 중인 단계, 4 = 끝
  String? _error;
  Timer? _timer;

  static const _steps = [
    ("희망 불러오기", "고정 일정 · 휴무 · 선호 · 우선순위"),
    ("규칙을 제약으로 바꾸기", "주 52시간 · 최소 인원 · 필수 휴무"),
    ("가장 공정한 조합 찾기", "CP-SAT · 주말·마감 4주 누적 균등"),
    ("3안으로 정리", "공정 · 인건비 · 희망 우선"),
  ];

  @override
  void initState() {
    super.initState();
    _run();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _run() async {
    setState(() {
      _error = null;
      _step = 0;
    });
    // 서버 계산이 끝날 때까지 앞의 세 단계를 차례로 보여 준다 (마지막 단계는 응답이 와야 끝난다)
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 700), (t) {
      if (_step < 2) {
        setState(() => _step++);
      } else {
        t.cancel();
      }
    });
    try {
      final plan = await StoreApi().plan();
      final home = await OwnerApi().home();
      if (mounted) {
        setState(() {
          _plan = plan;
          _prefs = home.preferences;
        });
      }
      final proposal = await OwnerApi().automate(plan);
      _timer?.cancel();
      if (!mounted) return;
      if (!proposal.success || proposal.candidates.isEmpty) {
        setState(() => _error = proposal.message ?? "근무표를 만들지 못했어요.");
        return;
      }
      setState(() => _step = 4);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ProposalComparePage(proposal: proposal, monthly: plan.cycle == ScheduleCycle.monthly)),
      );
    } on ApiException catch (e) {
      _timer?.cancel();
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    final prefs = _prefs;
    final missing = prefs == null ? 0 : prefs.employeeCount - prefs.submittedCount;
    return Scaffold(
      backgroundColor: ThymeColor.primary,
      appBar: AppBar(
        backgroundColor: ThymeColor.primary,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const ThymeBackButton(color: ThymeColor.onPrimary),
      ),
      body: SafeArea(
        top: false,
        child: ListView(padding: const EdgeInsets.fromLTRB(24, 8, 24, 24), children: [
          const Row(children: [
            ThymeLeaf(size: 40),
            SizedBox(width: 10),
            ThymeLeaf(size: 40, color: ThymePalette.mint300, flip: true),
            SizedBox(width: 10),
            ThymeLeaf(size: 40, color: ThymePalette.mint800),
          ]),
          const SizedBox(height: 20),
          Text("OWNER · ${plan == null ? '' : "${periodLabel(plan.periodStart, plan.periodEnd, monthly: plan.cycle == ScheduleCycle.monthly)} "}근무표",
              style: ThymeTheme.mono(context, size: 13, color: ThymeColor.onPrimarySub)),
          const SizedBox(height: 10),
          const Text("모두가 납득할 수 있는\n조합을 찾고 있어요",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ThymeColor.onPrimary, height: 1.35)),
          const SizedBox(height: 8),
          const Text("보통 몇 초 안에 끝나요", style: TextStyle(fontSize: 15, color: ThymeColor.onPrimarySub)),
          const SizedBox(height: 24),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: _error != null ? null : (_step.clamp(0, 4) + (_step >= 4 ? 0 : 0.5)) / 4,
              minHeight: 10,
              color: ThymePalette.peri300,
              backgroundColor: ThymeColor.indigoSurface,
            ),
          ),
          const SizedBox(height: 16),
          for (var i = 0; i < _steps.length; i++) _stepRow(i, i == 0 && prefs != null ? "희망 ${prefs.submittedCount}명 불러오기" : _steps[i].$1, _steps[i].$2),
          const SizedBox(height: 20),
          if (_error != null)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: ThymeColor.indigoSurface, borderRadius: BorderRadius.circular(18)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(_error!, style: const TextStyle(color: ThymePalette.rose300, fontSize: 15, height: 1.5)),
                const SizedBox(height: 8),
                FilledButton(
                  style: FilledButton.styleFrom(backgroundColor: ThymeColor.onPrimary, foregroundColor: ThymeColor.text),
                  onPressed: _run,
                  child: const Text("다시 만들기"),
                ),
              ]),
            )
          else if (missing > 0)
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: ThymeColor.indigoSurface, borderRadius: BorderRadius.circular(18)),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(padding: EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 10, color: ThymeColor.warn)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text("아직 희망을 안 낸 사람이 $missing명 있어요. 확정 전에 다시 만들 수 있어요.",
                      style: const TextStyle(color: ThymePalette.yellow300, fontSize: 15, height: 1.5)),
                ),
              ]),
            ),
        ]),
      ),
    );
  }

  Widget _stepRow(int i, String title, String sub) {
    final done = _step > i;
    final running = _step == i && _error == null;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: ThymeColor.indigoSurface))),
      child: Row(children: [
        ThymeLeaf(size: 30, color: done ? ThymeColor.accent : (running ? ThymePalette.peri300 : ThymeColor.onPrimarySub), dashed: !done),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: done || running ? ThymeColor.onPrimary : ThymeColor.onPrimarySub)),
            const SizedBox(height: 4),
            Text(sub, style: const TextStyle(fontSize: 14, color: ThymeColor.onPrimarySub)),
          ]),
        ),
        Text(done ? "완료" : (running ? "계산 중" : "대기"),
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: done ? ThymeColor.accent : (running ? ThymeColor.onPrimary : ThymeColor.onPrimarySub))),
      ]),
    );
  }
}
