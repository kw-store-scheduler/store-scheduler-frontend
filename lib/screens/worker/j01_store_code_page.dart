import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/join_api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../models/store.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'j02_employment_type_page.dart';

class StoreCodePage extends StatefulWidget {
  const StoreCodePage({super.key});

  @override
  State<StoreCodePage> createState() => _StoreCodePageState();
}

class _StoreCodePageState extends State<StoreCodePage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isCodeValid = false;
  StorePreview? _preview; // 서버에서 찾은 매장 (시연 중이면 null)
  String? _error;
  String _lookedUp = "";

  // 서버 매장 코드는 8자리 (시안 예시 NLXAYE는 6자리라 시연 중에는 6자리부터 받는다)
  static int get _codeLength => Session.instance.isLoggedIn ? JoinApi.codeLength : 6;

  @override
  void initState() {
    super.initState();
    // 글자가 다 차면 자동으로 매장 검색 결과 카드 띄우기
    _codeController.addListener(_onCodeChanged);
  }

  Future<void> _onCodeChanged() async {
    final code = _codeController.text.trim().toUpperCase();
    if (code == _lookedUp) return;
    _lookedUp = code;
    setState(() {
      _isCodeValid = false;
      _preview = null;
      _error = null;
    });
    if (code.length < _codeLength) return;
    if (!Session.instance.isLoggedIn) {
      setState(() => _isCodeValid = true);
      return;
    }
    try {
      final preview = await JoinApi().preview(code);
      if (!mounted || _lookedUp != code) return; // 그사이 코드를 또 바꿨으면 버린다
      setState(() {
        _preview = preview;
        _isCodeValid = true;
      });
    } on ApiException catch (e) {
      if (mounted && _lookedUp == code) setState(() => _error = e.message);
    }
  }

  String get _storeName => _preview?.name ?? "구시대 커피 광운대점";

  String get _storeDetail {
    final p = _preview;
    if (p == null) return "카페 · 서울 노원구 · 근무자 7명";
    return [p.industryLabel, if (p.address != null && p.address!.isNotEmpty) p.address!, "근무자 ${p.employeeCount}명"].join(" · ");
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: ThymeStepAppBar(step: 1, total: 3, group: '가입'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "어느 매장에서\n일하세요?",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ThymeColor.text, height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "사장님에게 받은 6자리 코드를 넣거나, 받은 링크를\n누르면 바로 채워져요.",
                    style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.5),
                  ),
                  const SizedBox(height: 40),

                  // 매장 코드 입력 필드
                  const Text("매장 코드", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _codeController,
                    maxLength: JoinApi.codeLength,
                    textCapitalization: TextCapitalization.characters,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8, color: ThymeColor.text),
                    decoration: InputDecoration(
                      hintText: Session.instance.isLoggedIn ? "9E3A4FC9" : "NLXAYE",
                      hintStyle: TextStyle(color: ThymeColor.border, letterSpacing: 8),
                      counterText: "", // 하단 글자 수 카운트 숨기기
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
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 틀린 코드 (서버 메시지 그대로)
                  if (_error != null)
                    Text(_error!, style: const TextStyle(fontSize: 13, color: ThymeColor.dangerText)),

                  // 코드를 다 넣고 매장을 찾았을 때만 보여주는 매장 정보 카드
                  if (_isCodeValid)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: ThymeColor.surfaceSub,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: ThymeColor.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: ThymeColor.surface,
                              shape: BoxShape.circle,
                              border: Border.all(color: ThymeColor.border),
                            ),
                            child: const Icon(Icons.storefront_outlined, color: ThymeColor.text),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_storeName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                                const SizedBox(height: 6),
                                Text(_storeDetail, style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Row(
                            children: [
                              Icon(Icons.check_circle, size: 14, color: ThymeColor.successText),
                              SizedBox(width: 4),
                              Text("찾았어요", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ThymeColor.successText)),
                            ],
                          )
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      "코드가 없어요 · 사장님에게 요청 보내기",
                      style: TextStyle(fontSize: 13, color: ThymeColor.textSub, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 하단 계속하기 버튼
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _isCodeValid ? () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EmploymentTypePage(storeCode: _codeController.text.trim().toUpperCase(), storeName: _storeName),
                    ),
                  );
                } : null, child: Text("이 매장으로 계속")),
              ),
            ),
          ),
        ],
      ),
    );
  }
}