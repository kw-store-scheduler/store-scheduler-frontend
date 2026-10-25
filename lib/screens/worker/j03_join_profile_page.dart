import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/home_router.dart';
import '../../core/join_api.dart';
import '../../core/theme.dart';
import '../../models/user.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'j04_approval_waiting_page.dart';

/// J03 프로필 (가입 3/3). 이름·부르는 이름·근무 시작일·만 18세 미만 → POST /api/stores/join/{storeCode} → J04
class JoinProfilePage extends StatefulWidget {
  const JoinProfilePage({super.key, required this.fullTime, required this.storeCode, required this.storeName});

  /// J02에서 직원을 골랐으면 true
  final bool fullTime;

  /// J01에서 찾은 매장
  final String storeCode;
  final String storeName;

  @override
  State<JoinProfilePage> createState() => _JoinProfilePageState();
}

class _JoinProfilePageState extends State<JoinProfilePage> {
  final _name = TextEditingController();
  final _nickname = TextEditingController();
  DateTime _startDate = DateUtils.dateOnly(DateTime.now());
  bool _minor = false;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {})); // 첫 글자 동그라미·버튼 상태
  }

  @override
  void dispose() {
    _name.dispose();
    _nickname.dispose();
    super.dispose();
  }

  static String _format(DateTime d) => "${d.year}. ${d.month.toString().padLeft(2, '0')}. ${d.day.toString().padLeft(2, '0')}";

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime(DateTime.now().year + 1, 12, 31),
      helpText: "근무 시작일",
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final nickname = _nickname.text.trim();
    setState(() => _sending = true);
    try {
      final m = await JoinApi().join(
        storeCode: widget.storeCode,
        name: name,
        nickname: nickname,
        startDate: _startDate,
        minor: _minor,
        employmentType: widget.fullTime ? EmploymentType.fullTime : EmploymentType.partTime,
      );
      if (!mounted) return;
      resetTo(
        context,
        ApprovalWaitingPage(
          fullTime: widget.fullTime,
          name: nickname.isNotEmpty ? nickname : name,
          storeName: m.storeName,
          requestedAt: DateTime.now(),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = _name.text.trim();
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: ThymeStepAppBar(step: 3, total: 3, group: '가입'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("동료들에게 보일 정보", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                  const SizedBox(height: 10),
                  Text("${widget.storeName} 근무표와 대타 요청에 이 이름이 나와요.",
                      style: const TextStyle(fontSize: 15, color: ThymeColor.textSub, height: 1.5)),
                  const SizedBox(height: 24),

                  // 이름 첫 글자 (프로필 사진은 백엔드에 아직 없음)
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: ThymeColor.selectedSoft,
                    child: Text(name.isEmpty ? "?" : name.characters.first,
                        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                  ),
                  const SizedBox(height: 24),

                  _label("이름"),
                  TextField(controller: _name, textInputAction: TextInputAction.next, decoration: const InputDecoration(hintText: "실명")),
                  const SizedBox(height: 20),
                  _label("매장에서 부르는 이름 (선택)"),
                  TextField(controller: _nickname, textInputAction: TextInputAction.done, decoration: const InputDecoration(hintText: "예: 유나")),
                  const SizedBox(height: 20),
                  _label("근무 시작일"),
                  // 누르면 달력 (예전엔 readOnly 만 있고 달력을 여는 처리가 없었다)
                  Material(
                    color: ThymeColor.surface,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: ThymeColor.border),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Text(_format(_startDate), style: ThymeTheme.mono(context, size: 17))),
                            const Icon(Icons.calendar_today, size: 20, color: ThymeColor.text),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 만 18세 미만 (엔진 하드 제약: 22~06시, 하루 7시간 초과 금지)
                  Material(
                    color: ThymeColor.surface,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => setState(() => _minor = !_minor),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: _minor ? ThymeColor.primary : ThymeColor.surface,
                                border: Border.all(color: _minor ? ThymeColor.primary : ThymeColor.disabled, width: 1.5),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: _minor ? const Icon(Icons.check, size: 18, color: ThymeColor.onPrimary) : null,
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("만 18세 미만이에요", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                                  SizedBox(height: 4),
                                  Text("22시~06시·하루 7시간 넘는 근무는 자동으로 빠지고, 친권자 동의서를 올리게 돼요.",
                                      style: TextStyle(fontSize: 13, color: ThymeColor.textSub, height: 1.4)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(14)),
                    child: const Text("시급은 사장님이 승인하면서 정해요. 내 정보에서 언제든 확인할 수 있어요.",
                        style: TextStyle(fontSize: 13, color: ThymeColor.charcoal, height: 1.5)),
                  ),
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
                  // 이름은 서버 필수값
                  onPressed: name.isEmpty || _sending ? null : _submit,
                  child: Text(_sending ? "보내는 중…" : (name.isEmpty ? "이름을 입력해 주세요" : "가입 요청 보내기")),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
      );
}
