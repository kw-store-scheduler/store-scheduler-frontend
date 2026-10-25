import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/home_router.dart';
import '../../core/store_api.dart';
import '../../core/theme.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'p02_registration_complete_page.dart';

/// O05 근무 규칙과 수당 (매장 등록 6/6). 법정 한도는 잠금, 연속 근무 한도·5인 이상만 PATCH /settings → P02
class LaborLawPage extends StatefulWidget {
  const LaborLawPage({super.key});

  @override
  State<LaborLawPage> createState() => _LaborLawPageState();
}

class _LaborLawPageState extends State<LaborLawPage> {
  // 서버 규칙: 연속 근무 한도 1~6일 (StoreController.StoreSettingsRequest)
  static const _minDays = 1;
  static const _maxDays = 6;
  int? _days;
  bool _fivePlus = false;
  bool _fivePlusTouched = false; // 서버 값이 null(직원 수로 자동 판단)이면 건드렸을 때만 보낸다
  bool _fivePlusAuto = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final store = await StoreApi().current();
      if (!mounted) return;
      setState(() {
        _days = store.maxConsecutiveDays.clamp(_minDays, _maxDays);
        _fivePlusAuto = store.fivePlusBusiness == null;
        _fivePlus = store.fivePlusBusiness ?? false;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    try {
      await StoreApi().updateSettings(
        maxConsecutiveDays: _days,
        fivePlusBusiness: _fivePlusAuto && !_fivePlusTouched ? null : _fivePlus,
      );
      if (!mounted) return;
      // 등록이 끝나면 뒤로가기로 등록 단계에 돌아가지 않게 스택을 비운다
      resetTo(context, const RegistrationCompletePage());
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = _days;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: const ThymeStepAppBar(step: 6, total: 6, group: '매장 등록', owner: true),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("근무 규칙과 수당", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                  const SizedBox(height: 10),
                  const Text("법정 한도는 잠겨 있어요. 매장 규칙만 고르면 수당까지 자동으로 계산돼요.",
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
                  else if (days == null)
                    const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                  else ...[
                    _card(Column(children: [
                      _locked("주 최대 근무", Text("52h", style: ThymeTheme.mono(context, size: 18))),
                      const Divider(height: 1),
                      _locked("휴게시간", const Text("4시간마다 30분", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text))),
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(children: [
                          const Expanded(child: Text("연속 근무 최대", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text))),
                          _stepButton(Icons.remove, "하루 줄이기", days > _minDays ? () => setState(() => _days = days - 1) : null, dark: false),
                          SizedBox(width: 64, child: Center(child: Text("$days일", style: ThymeTheme.mono(context, size: 18)))),
                          _stepButton(Icons.add, "하루 늘리기", days < _maxDays ? () => setState(() => _days = days + 1) : null, dark: true),
                        ]),
                      ),
                    ])),
                    const SizedBox(height: 12),
                    _card(Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Row(children: [
                          const Expanded(child: Text("상시 5인 이상 사업장", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text))),
                          Switch(
                            value: _fivePlus,
                            onChanged: (v) => setState(() {
                              _fivePlus = v;
                              _fivePlusTouched = true;
                            }),
                          ),
                        ]),
                        const SizedBox(height: 8),
                        Text(
                          _fivePlusAuto && !_fivePlusTouched
                              ? "지금은 승인된 직원 수로 자동 판단해요. 5인 미만이면 연장·야간 가산(+50%)은 빠지고 주휴수당은 그대로 계산돼요."
                              : "5인 미만이면 연장·야간 가산(+50%)은 빠지고 주휴수당은 그대로 계산돼요.",
                          style: const TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.5),
                        ),
                        const SizedBox(height: 12),
                        Wrap(spacing: 8, runSpacing: 8, children: [
                          _badge("주휴 · 주 15시간 이상", on: true),
                          _badge("야간 22–06 +50%", on: _fivePlus),
                          _badge("연장 +50%", on: _fivePlus),
                        ]),
                      ]),
                    )),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: ThymeColor.primary, borderRadius: BorderRadius.circular(20)),
                      child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Padding(padding: EdgeInsets.only(top: 2), child: Icon(Icons.shield_outlined, color: ThymeColor.accent, size: 20)),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text.rich(TextSpan(children: [
                            TextSpan(text: "위반 근무표는 아예 만들어지지 않아요. ", style: TextStyle(fontWeight: FontWeight.bold, color: ThymeColor.onPrimary)),
                            TextSpan(text: "한도는 엔진의 하드 제약으로 들어가요.", style: TextStyle(color: ThymeColor.onPrimarySub)),
                          ]), style: TextStyle(fontSize: 15, height: 1.5)),
                        ),
                      ]),
                    ),
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
                // 흐름의 마지막 확정 = 민트 CTA (가이드 4-0)
                child: ThymeFinalButton(label: _saving ? "저장 중…" : "매장 등록 완료", onPressed: days == null || _saving ? null : _finish),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(Widget child) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
        child: child,
      );

  Widget _locked(String title, Widget value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text))),
          value,
          const SizedBox(width: 10),
          const Icon(Icons.lock_outline, size: 20, color: ThymeColor.icon),
        ]),
      );

  Widget _stepButton(IconData icon, String tooltip, VoidCallback? onTap, {required bool dark}) => Tooltip(
        message: tooltip,
        child: Material(
          color: onTap == null ? ThymeColor.surfaceSub : (dark ? ThymeColor.primary : ThymeColor.surfaceSub),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              width: 48,
              height: 48,
              decoration: dark ? null : BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: ThymeColor.border)),
              child: Icon(icon, color: onTap == null ? ThymeColor.disabled : (dark ? ThymeColor.onPrimary : ThymeColor.text)),
            ),
          ),
        ),
      );

  // 켜진 가산 = 라벤더 배지, 5인 미만이라 빠진 가산 = 취소선 (가이드 O05 '가산수당 배지 on/off')
  Widget _badge(String text, {required bool on}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: on ? ThymeColor.selectedSoft : ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(99)),
        child: Text(text,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: on ? ThymeColor.text : ThymeColor.disabled,
              decoration: on ? null : TextDecoration.lineThrough,
            )),
      );
}
