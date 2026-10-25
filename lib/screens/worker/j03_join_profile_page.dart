import 'package:flutter/material.dart';
import '../../core/home_router.dart';
import '../../core/api_service.dart';
import '../../core/join_api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../models/user.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'j04_approval_waiting_page.dart';

class JoinProfilePage extends StatefulWidget {
  const JoinProfilePage({super.key, this.fullTime = false, this.storeCode, this.storeName});

  /// J02에서 직원을 골랐으면 true
  final bool fullTime;

  /// J01에서 찾은 매장 (시연 중이면 null)
  final String? storeCode;
  final String? storeName;

  @override
  State<JoinProfilePage> createState() => _JoinProfilePageState();
}

class _JoinProfilePageState extends State<JoinProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(text: _format(DateTime.now())); // 오늘 날짜 기본 세팅
  bool _isUnderage = false;
  bool _sending = false;

  static String _format(DateTime d) => "${d.year}. ${d.month.toString().padLeft(2, '0')}. ${d.day.toString().padLeft(2, '0')}";

  /// "2026. 11. 20" → 날짜 (형식이 틀리면 null → 서버에 보내지 않음)
  static DateTime? _parse(String text) {
    final m = RegExp(r'^\s*(\d{4})\D+(\d{1,2})\D+(\d{1,2})').firstMatch(text);
    if (m == null) return null;
    return DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
  }

  /// 로그인했으면 합류 신청(POST /api/stores/join/{code}) 후 J04, 시연 중이면 바로 J04
  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final nickname = _nicknameController.text.trim();
    var storeName = widget.storeName;
    if (Session.instance.isLoggedIn) {
      final code = widget.storeCode;
      if (code == null) {
        _show("매장 코드를 먼저 확인해 주세요.");
        return;
      }
      if (name.isEmpty) {
        _show("이름을 입력해 주세요.");
        return;
      }
      setState(() => _sending = true);
      try {
        final m = await JoinApi().join(
          storeCode: code,
          name: name,
          nickname: nickname,
          startDate: _parse(_dateController.text),
          minor: _isUnderage,
          employmentType: widget.fullTime ? EmploymentType.fullTime : EmploymentType.partTime,
        );
        storeName = m.storeName;
      } on ApiException catch (e) {
        _show(e.message);
        return;
      } finally {
        if (mounted) setState(() => _sending = false);
      }
    }
    if (!mounted) return;
    final shown = nickname.isNotEmpty ? nickname : name;
    resetTo(context, ApprovalWaitingPage(
          fullTime: widget.fullTime,
          name: shown.isEmpty ? "김유나" : shown,
          storeName: storeName ?? "구시대 커피 광운대점",
          requestedAt: DateTime.now(),
        ));
  }

  void _show(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: ThymeStepAppBar(step: 3, total: 3, group: '가입'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "동료들에게 보일 정보",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ThymeColor.text),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "근무표와 대타 요청에 이 이름이 나와요.",
                    style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  // 프로필 사진 등록 (선택)
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: ThymeColor.surfaceSub,
                            shape: BoxShape.circle,
                            border: Border.all(color: ThymeColor.border),
                          ),
                          child: const Icon(Icons.person, size: 40, color: ThymeColor.textSub),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: ThymeColor.surfaceSub,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: ThymeColor.border),
                          ),
                          child: const Text("사진 바꾸기 (선택)", style: TextStyle(fontSize: 12, color: ThymeColor.text, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 이름 입력
                  const Text("이름", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                  const SizedBox(height: 12),
                  _buildTextField(_nameController, "김남용"),
                  const SizedBox(height: 24),

                  // 닉네임 입력 (선택)
                  const Text("매장에서 부르는 이름 (선택)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                  const SizedBox(height: 12),
                  _buildTextField(_nicknameController, "남용"),
                  const SizedBox(height: 24),

                  // 근무 시작일
                  const Text("근무 시작일", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _dateController,
                    readOnly: true,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: ThymeColor.text),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: ThymeColor.surface,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: ThymeColor.text, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: ThymeColor.text, width: 2.0),
                      ),
                      suffixIcon: const Icon(Icons.calendar_today, color: ThymeColor.text, size: 20),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 미성년자 체크박스
                  GestureDetector(
                    onTap: () => setState(() => _isUnderage = !_isUnderage),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isUnderage ? ThymeColor.danger.withValues(alpha: 0.05) : ThymeColor.surface,
                        border: Border.all(color: _isUnderage ? ThymeColor.danger : ThymeColor.border, width: _isUnderage ? 1.5 : 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _isUnderage ? Icons.check_box : Icons.check_box_outline_blank,
                            color: _isUnderage ? ThymeColor.danger : ThymeColor.disabled,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "만 18세 미만이에요",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _isUnderage ? ThymeColor.danger : ThymeColor.text,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "22시~06시·하루 7시간 넘는 근무는 자동으로 빠지고, 친권자 동의서를 올리게 돼요.",
                                  style: TextStyle(fontSize: 12, color: ThymeColor.textSub, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 하단 안내 문구
                  Center(
                    child: Text(
                      "시급은 사장님이 승인하면서 정해요.\n내 정보에서 언제든 확인할 수 있어요.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: ThymeColor.textSub, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 하단 버튼
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _sending ? null : _submit, child: Text(_sending ? "보내는 중…" : "가입 요청 보내기")),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 텍스트 필드 공통 위젯
  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: ThymeColor.border),
        filled: true,
        fillColor: ThymeColor.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: ThymeColor.border, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ThymeColor.text, width: 2.0),
        ),
      ),
    );
  }
}