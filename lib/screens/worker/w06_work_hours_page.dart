import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../models/preference.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'w05_skills_page.dart'; // 방금 이름 변경한 역량 화면으로 임포트!

class WorkHoursPage extends StatefulWidget {
  const WorkHoursPage({super.key, required this.draft});

  final PreferenceDraft draft;

  @override
  State<WorkHoursPage> createState() => _WorkHoursPageState();
}

class _WorkHoursPageState extends State<WorkHoursPage> {
  // 지난달 답을 불러왔으면 그 값, 아니면 시안 기본값
  late int _minHours = widget.draft.minMonthlyHours ?? 64;
  late int _maxHours = widget.draft.maxMonthlyHours ?? 86;
  late int _maxConsecutiveDays = widget.draft.maxConsecutiveDays ?? 3;
  late bool _avoidNextDayOpen = widget.draft.noOpenAfterClose;

  void _next() {
    widget.draft
      ..minMonthlyHours = _minHours
      ..maxMonthlyHours = _maxHours
      ..maxConsecutiveDays = _maxConsecutiveDays
      ..noOpenAfterClose = _avoidNextDayOpen;
    Navigator.push(context, MaterialPageRoute(builder: (context) => SkillsPage(draft: widget.draft)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: ThymeStepAppBar(step: 5, total: 7, title: '어떻게 · 근무량'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    const Text("이번 달은 얼마나 일할까요?", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text, height: 1.3)),
                    const SizedBox(height: 12),
                    Text("계약 범위 안에서 이번 달 최소~최대한 정해요. 엔진이 그 사이로 맞출게요.", style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.4)),
                    const SizedBox(height: 32),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          Icon(Icons.lock_outline, size: 20, color: ThymeColor.textSub),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("근로계약서 · 2026.09.01부터", style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
                                const SizedBox(height: 4),
                                const Text("주 15~20시간 · 시급 ₩10,320", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                              ],
                            ),
                          ),
                          Text("보기", style: TextStyle(fontSize: 13, color: ThymeColor.textSub, fontWeight: FontWeight.bold)),
                          Icon(Icons.chevron_right, size: 16, color: ThymeColor.textSub),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildStepper("이번 달 최소", "주 14.9시간", _minHours, "h", (val) => setState(() => _minHours = val)),
                    const SizedBox(height: 24),
                    _buildStepper("이번 달 최대", "주 20.0시간", _maxHours, "h", (val) => setState(() => _maxHours = val)),
                    const SizedBox(height: 24),
                    _buildStepper("최대 연속 근무", "파견 한도 5일", _maxConsecutiveDays, "일", (val) => setState(() => _maxConsecutiveDays = val)),
                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 12),

                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeTrackColor: ThymeColor.primary, // 스위치 켜짐 = 딥 나이트
                      activeThumbColor: ThymeColor.onPrimary,
                      title: const Text("마감 다음 날 오픈 피하기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                      subtitle: const Text("22시 퇴근 → 다음 날 9시 출근 방지", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                      value: _avoidNextDayOpen,
                      onChanged: (val) => setState(() => _avoidNextDayOpen = val),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(color: ThymeColor.warnBg, borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(padding: EdgeInsets.only(top: 4.0), child: Icon(Icons.circle, size: 6, color: ThymeColor.warn)),
                          const SizedBox(width: 8),
                          Expanded(child: Text("최소가 주 15시간 이하라, 주휴수당이 빠지는 주가 생길 수 있어요", style: TextStyle(fontSize: 13, color: ThymeColor.charcoal, height: 1.4))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(color: ThymeColor.surface, boxShadow: [BoxShadow(color: ThymeColor.text.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5))]),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(color: ThymeColor.text, borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("이번 달 예상 급여 · 주휴 포함", style: TextStyle(color: ThymeColor.onPrimarySub, fontSize: 13)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: const [
                            Text("₩660,480 ~", style: TextStyle(color: ThymeColor.onPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
                            Text("₩1,065,024", style: TextStyle(color: ThymeColor.onPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(onPressed: _next, child: Text("다음")),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepper(String title, String subtitle, int value, String unit, Function(int) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
          ],
        ),
        Row(
          children: [
            InkWell(
              onTap: () => onChanged(value > 0 ? value - 1 : 0),
              child: Container(width: 40, height: 40, decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.remove, color: ThymeColor.text)),
            ),
            Container(
              width: 60,
              alignment: Alignment.center,
              child: Text("$value$unit", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            ),
            InkWell(
              onTap: () => onChanged(value + 1),
              child: Container(width: 40, height: 40, decoration: BoxDecoration(color: ThymeColor.text, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.add, color: ThymeColor.onPrimary)),
            ),
          ],
        ),
      ],
    );
  }
}