import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/session.dart';
import '../../core/store_api.dart';
import '../../core/theme.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'p02_registration_complete_page.dart'; // 마지막 완료 화면으로 임포트!

class LaborLawPage extends StatefulWidget {
  const LaborLawPage({super.key});

  @override
  State<LaborLawPage> createState() => _LaborLawPageState();
}

class _LaborLawPageState extends State<LaborLawPage> {
  final int _maxHours = 52; // 법정 주 최대 근무 (잠금)
  // 서버 규칙: 연속 근무 한도 1~6일, 기본 4일 (StoreController.StoreSettingsRequest)
  static const _minDays = 1;
  static const _maxDays = 6;
  int _maxConsecutiveDays = 4;
  bool _isOver5Employees = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (Session.instance.isLoggedIn) _load();
  }

  Future<void> _load() async {
    try {
      final store = await StoreApi().current();
      if (!mounted) return;
      setState(() {
        _maxConsecutiveDays = store.maxConsecutiveDays.clamp(_minDays, _maxDays);
        // null = 아직 안 정함 (서버는 승인된 직원 수로 판단) → 시안처럼 켜 둔다
        _isOver5Employees = store.fivePlusBusiness ?? true;
      });
    } on ApiException {
      // 기본값으로 진행
    }
  }

  /// 노동법 설정을 저장하고 P02 등록 완료로
  Future<void> _finish() async {
    if (Session.instance.isLoggedIn) {
      setState(() => _saving = true);
      try {
        await StoreApi().updateSettings(maxConsecutiveDays: _maxConsecutiveDays, fivePlusBusiness: _isOver5Employees);
      } on ApiException catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        return;
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (context) => const RegistrationCompletePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: ThymeStepAppBar(step: 6, total: 6, group: '매장 등록', owner: true),
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
                    const Text("근무 규칙과 수당", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text, height: 1.3)),
                    const SizedBox(height: 12),
                    Text("법정 한도는 잠겨 있어요. 매장 규칙만 고르면 수당까지 자동으로 계산돼요.", style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.4)),
                    const SizedBox(height: 32),

                    // 하드 제약 조건들
                    _buildLockedRow("주 최대 근무", "${_maxHours}h", Icons.lock_outline),
                    const SizedBox(height: 24),
                    _buildLockedRow("휴게시간", "4시간마다 30분", Icons.lock_outline),
                    const SizedBox(height: 24),
                    
                    // Stepper
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("연속 근무 최대", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                        Row(
                          children: [
                            InkWell(onTap: () => setState(() => _maxConsecutiveDays = (_maxConsecutiveDays - 1).clamp(_minDays, _maxDays)), child: Container(width: 32, height: 32, decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.remove, size: 16, color: ThymeColor.text))),
                            Container(width: 48, alignment: Alignment.center, child: Text("$_maxConsecutiveDays일", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text))),
                            InkWell(onTap: () => setState(() => _maxConsecutiveDays = (_maxConsecutiveDays + 1).clamp(_minDays, _maxDays)), child: Container(width: 32, height: 32, decoration: BoxDecoration(color: ThymeColor.text, borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.add, size: 16, color: ThymeColor.onPrimary))),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    const Divider(),
                    const SizedBox(height: 16),

                    // 5인 이상 사업장 토글
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      activeTrackColor: ThymeColor.primary, // 스위치 켜짐 = 딥 나이트
                      activeThumbColor: ThymeColor.onPrimary,
                      title: const Text("상시 5인 이상 사업장", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                      subtitle: const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text("5인 미만이면 연장·야간 가산(+50%)은 빠지고 주휴수당은 그대로 계산돼요.", style: TextStyle(fontSize: 12, color: ThymeColor.textSub, height: 1.4)),
                      ),
                      value: _isOver5Employees,
                      onChanged: (val) => setState(() => _isOver5Employees = val),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildBadge("주휴 · 주 15시간 이상"),
                        _buildBadge("야간 22~06 +50%"),
                        _buildBadge("연장 +50%"),
                      ],
                    ),
                    const SizedBox(height: 32),

                    // 안내 박스
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: ThymeColor.text, borderRadius: BorderRadius.circular(16)),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: ThymeColor.onPrimarySub, size: 20),
                          const SizedBox(width: 12),
                          Expanded(child: Text("위반 근무표는 아예 만들어지지 않아요. 한도는 엔진의 하드 제약으로 들어가요.", style: TextStyle(color: ThymeColor.onPrimary.withValues(alpha: 0.9), fontSize: 13, height: 1.4))),
                        ],
                      ),
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
                child: ThymeFinalButton(label: _saving ? "저장 중…" : "매장 등록 완료", onPressed: _saving ? null : _finish),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLockedRow(String title, String value, IconData icon) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
        Row(
          children: [
            Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            const SizedBox(width: 8),
            Icon(icon, size: 16, color: ThymeColor.disabled),
          ],
        ),
      ],
    );
  }

  Widget _buildBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(16)),
      child: Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ThymeColor.charcoal)),
    );
  }
}