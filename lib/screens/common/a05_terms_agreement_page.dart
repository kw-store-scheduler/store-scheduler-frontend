import 'package:flutter/material.dart';
import '../../core/push_service.dart';
import '../../core/theme.dart';
import '../../widgets/thyme_back_button.dart';
import 'a06_role_selection_page.dart';

/// 약관 한 줄
class _Term {
  const _Term(this.label, {required this.required});

  final String label;
  final bool required;
}

/// A05 약관 · 알림 권한. 필수 2개에 동의하면 알림 권한을 묻고 A06 역할 선택으로
class TermsAgreementPage extends StatefulWidget {
  const TermsAgreementPage({super.key});

  @override
  State<TermsAgreementPage> createState() => _TermsAgreementPageState();
}

class _TermsAgreementPageState extends State<TermsAgreementPage> {
  static const _terms = [
    _Term("이용약관", required: true),
    _Term("개인정보 수집·이용", required: true),
    _Term("위치 기반 출근 체크", required: false),
    _Term("이벤트·혜택 알림", required: false),
  ];

  final _checked = List<bool>.filled(_terms.length, false);
  bool _going = false;

  bool get _all => _checked.every((c) => c);
  bool get _requiredOk => [for (var i = 0; i < _terms.length; i++) if (_terms[i].required) _checked[i]].every((c) => c);

  Future<void> _next() async {
    setState(() => _going = true);
    // "다음 화면에서 권한을 물어봐요" — 브라우저·기기 알림 권한을 묻고 이 기기를 서버에 등록 (실패해도 진행)
    await PushService.registerDevice();
    if (!mounted) return;
    setState(() => _going = false);
    Navigator.push(context, MaterialPageRoute(builder: (_) => const RoleSelectionPage()));
  }

  void _showTerm(_Term t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: ThymeColor.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("${t.required ? "(필수)" : "(선택)"} ${t.label}",
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            const SizedBox(height: 12),
            const Text("약관 전문은 서비스 정식 출시 전에 이곳에 공개돼요.",
                style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.5)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: AppBar(
        backgroundColor: ThymeColor.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const ThymeBackButton(size: 20),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("서비스 이용에\n동의해 주세요",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text, height: 1.3)),
                  const SizedBox(height: 24),

                  // 전체 동의
                  Material(
                    color: ThymeColor.surface,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => setState(() => _checked.fillRange(0, _checked.length, !_all)),
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(children: [
                          _Box(checked: _all),
                          const SizedBox(width: 14),
                          const Text("전체 동의", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                        ]),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 항목별
                  Material(
                    color: ThymeColor.surface,
                    borderRadius: BorderRadius.circular(18),
                    child: Column(
                      children: [
                        for (var i = 0; i < _terms.length; i++) ...[
                          if (i > 0) const Divider(indent: 18, endIndent: 18),
                          InkWell(
                            onTap: () => setState(() => _checked[i] = !_checked[i]),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              child: Row(
                                children: [
                                  _Box(checked: _checked[i]),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Text.rich(TextSpan(children: [
                                      TextSpan(
                                        text: _terms[i].required ? "(필수) " : "(선택) ",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: _terms[i].required ? ThymeColor.text : ThymeColor.textSub),
                                      ),
                                      TextSpan(text: _terms[i].label, style: const TextStyle(color: ThymeColor.text)),
                                    ]), style: const TextStyle(fontSize: 15)),
                                  ),
                                  TextButton(
                                    onPressed: () => _showTerm(_terms[i]),
                                    child: const Text("보기",
                                        style: TextStyle(fontSize: 14, color: ThymeColor.textSub, decoration: TextDecoration.underline)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  // 알림 안내 = 페리윙클 배너
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(color: ThymeColor.infoBg, borderRadius: BorderRadius.circular(18)),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notifications_none, color: ThymeColor.info),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("알림을 꼭 켜 주세요", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.infoText)),
                              SizedBox(height: 6),
                              Text("근무표 확정, 대타 요청, 희망 제출 마감을 놓치지 않게 알려드려요. 다음 화면에서 권한을 물어봐요.",
                                  style: TextStyle(fontSize: 13, color: ThymeColor.infoText, height: 1.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
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
                  onPressed: _requiredOk && !_going ? _next : null,
                  child: Text(_requiredOk ? "동의하고 계속하기" : "필수 항목에 동의해 주세요"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 체크 상자: 켜짐 = 딥 나이트 면 + 흰 체크 (가이드: 선택 = 딥 나이트)
class _Box extends StatelessWidget {
  const _Box({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: checked ? ThymeColor.primary : ThymeColor.surface,
        border: Border.all(color: checked ? ThymeColor.primary : ThymeColor.disabled, width: 1.5),
        borderRadius: BorderRadius.circular(7),
      ),
      child: checked ? const Icon(Icons.check, size: 18, color: ThymeColor.onPrimary) : null,
    );
  }
}
