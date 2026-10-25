import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/store_api.dart';
import '../../core/theme.dart';
import '../../models/store.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'o03_store_shift_setup_page.dart';

/// O02 근무표 주기 (매장 등록 2/6). 고르는 즉시 PATCH /settings 로 저장하고
/// GET /schedules/plan 으로 서버가 계산한 적용 시작·희망 마감·자동 생성 시각을 보여 준다
class ScheduleCyclePage extends StatefulWidget {
  const ScheduleCyclePage({super.key});

  @override
  State<ScheduleCyclePage> createState() => _ScheduleCyclePageState();
}

class _ScheduleCyclePageState extends State<ScheduleCyclePage> {
  ScheduleCycle? _cycle;
  SchedulePlan? _plan;
  bool _saving = false;
  String? _error;

  static const _options = [
    (ScheduleCycle.weekly, "주간 (7일)", "매주 근무표가 바뀌는 매장"),
    (ScheduleCycle.biweekly, "2주", "학기·시험 기간에 맞추기 좋아요"),
    (ScheduleCycle.monthly, "월간", "가장 많이 써요 · 주말 부담을 4주 누적으로 배분"),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      var store = await StoreApi().current();
      // 매장 등록에선 정한 주기에 맞춰 자동으로 3안을 만든다 (시안 '자동 생성')
      if (!store.autoGenerate) store = await StoreApi().updateSettings(autoGenerate: true);
      final plan = await StoreApi().plan();
      if (mounted) {
        setState(() {
          _cycle = store.scheduleCycle;
          _plan = plan;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _select(ScheduleCycle c) async {
    if (_saving || c == _cycle) return;
    final before = _cycle;
    setState(() {
      _cycle = c;
      _saving = true;
    });
    try {
      await StoreApi().updateSettings(scheduleCycle: c, autoGenerate: true);
      final plan = await StoreApi().plan();
      if (mounted) setState(() => _plan = plan);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _cycle = before);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static String _md(DateTime d) => "${d.month}/${d.day}(${weekdayLabels[d.weekday - 1]})";

  static String _hour(int h) => h < 12 ? "오전 ${h == 0 ? 12 : h}시" : "오후 ${h == 12 ? 12 : h - 12}시";

  String _startText(SchedulePlan p) => p.cycle == ScheduleCycle.monthly
      ? "${p.periodStart.year}. ${p.periodStart.month}"
      : "${p.periodStart.year}. ${p.periodStart.month}. ${p.periodStart.day}";

  String _deadlineText(SchedulePlan p) {
    final days = DateTime(p.generateAt.year, p.generateAt.month, p.generateAt.day).difference(p.preferenceDeadline).inDays;
    return p.autoGenerate ? "생성 $days일 전 · ${_md(p.preferenceDeadline)}" : _md(p.preferenceDeadline);
  }

  @override
  Widget build(BuildContext context) {
    final plan = _plan;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: const ThymeStepAppBar(step: 2, total: 6, group: '매장 등록', owner: true),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("근무표를 얼마마다 만들까요?", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text, height: 1.3)),
                  const SizedBox(height: 10),
                  const Text("정한 주기에 맞춰 직원들에게 희망 제출 알림이 가요.", style: TextStyle(fontSize: 15, color: ThymeColor.textSub)),
                  const SizedBox(height: 24),
                  if (_error != null)
                    _ErrorBox(message: _error!, onRetry: _load)
                  else if (_cycle == null)
                    const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                  else ...[
                    for (final (c, title, sub) in _options) ...[
                      _option(c, title, sub),
                      const SizedBox(height: 10),
                    ],
                    if (plan != null) ...[
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
                        decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
                        child: Column(children: [
                          _info("적용 시작", _startText(plan), mono: true),
                          _info("희망 마감", _deadlineText(plan)),
                          _info("자동 생성", "${_md(plan.generateAt)} ${_hour(plan.generateAt.hour)}"),
                        ]),
                      ),
                    ],
                    if (_cycle == ScheduleCycle.monthly) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(color: ThymeColor.infoBg, borderRadius: BorderRadius.circular(16)),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(padding: EdgeInsets.only(top: 6), child: Icon(Icons.circle, size: 8, color: ThymeColor.info)),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text("월간을 고르면 직원은 날짜별로 가능 여부를 체크해요. 지난달 패턴이 미리 채워져요.",
                                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.infoText, height: 1.5)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _cycle == null || _saving
                      ? null
                      : () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreShiftSetupPage())),
                  child: Text(_saving ? "저장 중…" : "다음"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _option(ScheduleCycle c, String title, String sub) {
    final on = c == _cycle;
    return Material(
      color: ThymeColor.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _select(c),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: on ? ThymeColor.primary : Colors.transparent, width: 2),
          ),
          child: Row(
            children: [
              Icon(on ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: on ? ThymeColor.primary : ThymeColor.disabled, size: 26),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                    const SizedBox(height: 4),
                    Text(sub, style: const TextStyle(fontSize: 14, color: ThymeColor.textSub)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _info(String label, String value, {bool mono = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          children: [
            SizedBox(width: 96, child: Text(label, style: const TextStyle(color: ThymeColor.textSub, fontSize: 15))),
            Expanded(
              child: Text(value,
                  style: mono
                      ? ThymeTheme.mono(context, size: 16, color: ThymeColor.text)
                      : const TextStyle(color: ThymeColor.text, fontSize: 15, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: ThymeColor.dangerBg, borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(color: ThymeColor.dangerText, fontSize: 14)),
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text("다시 불러오기")),
          ],
        ),
      );
}
