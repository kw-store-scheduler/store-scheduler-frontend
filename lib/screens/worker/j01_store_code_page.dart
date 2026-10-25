import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api_service.dart';
import '../../core/join_api.dart';
import '../../core/theme.dart';
import '../../models/store.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'j02_employment_type_page.dart';

/// J01 매장 코드 (가입 1/3). 코드를 다 넣으면 GET /api/stores/code/{code} 로 매장을 찾는다
class StoreCodePage extends StatefulWidget {
  const StoreCodePage({super.key});

  @override
  State<StoreCodePage> createState() => _StoreCodePageState();
}

class _StoreCodePageState extends State<StoreCodePage> {
  final _code = TextEditingController();
  final _focus = FocusNode();
  StorePreview? _preview;
  String? _error;
  bool _searching = false;
  String _lookedUp = "";

  static const _length = JoinApi.codeLength; // 서버 매장 코드 8자리

  @override
  void initState() {
    super.initState();
    _code.addListener(_onChanged);
    // 사장님이 보낸 초대 링크로 들어왔으면 코드를 미리 채운다
    final invited = JoinApi.invitedCode;
    if (invited != null) _code.text = invited;
  }

  @override
  void dispose() {
    _code.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _onChanged() async {
    final code = _code.text.trim().toUpperCase();
    setState(() {}); // 칸 다시 그리기
    if (code == _lookedUp) return;
    _lookedUp = code;
    setState(() {
      _preview = null;
      _error = null;
    });
    if (code.length < _length) return;
    setState(() => _searching = true);
    try {
      final preview = await JoinApi().preview(code);
      if (!mounted || _lookedUp != code) return; // 그사이 코드를 또 바꿨으면 버린다
      setState(() => _preview = preview);
    } on ApiException catch (e) {
      if (mounted && _lookedUp == code) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _showNoCode() {
    showModalBottomSheet(
      context: context,
      backgroundColor: ThymeColor.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const Padding(
        padding: EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("사장님께 매장 코드를 받아 주세요", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            SizedBox(height: 12),
            Text(
              "사장님은 Thyme 앱의 매장 설정 화면이나 매장 등록을 마친 화면에서 8자리 매장 코드를 볼 수 있고, 초대 링크나 QR로 바로 보낼 수 있어요.",
              style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final code = _code.text.toUpperCase();
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: ThymeStepAppBar(step: 1, total: 3, group: '가입'),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("어느 매장에서\n일하세요?",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ThymeColor.text, height: 1.3)),
                  const SizedBox(height: 12),
                  const Text("사장님에게 받은 8자리 매장 코드를 넣어 주세요.",
                      style: TextStyle(fontSize: 15, color: ThymeColor.textSub, height: 1.5)),
                  const SizedBox(height: 28),
                  const Text("매장 코드", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
                  const SizedBox(height: 10),

                  // 칸마다 한 글자 (실제 입력은 뒤의 투명한 입력창이 받는다)
                  GestureDetector(
                    onTap: () => _focus.requestFocus(),
                    child: Stack(
                      children: [
                        Row(
                          children: [
                            for (var i = 0; i < _length; i++) ...[
                              if (i > 0) const SizedBox(width: 6),
                              Expanded(
                                child: AspectRatio(
                                  aspectRatio: 0.8,
                                  child: Container(
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: ThymeColor.surface,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: i < code.length || i == code.length ? ThymeColor.primary : ThymeColor.border,
                                        width: i == code.length && _focus.hasFocus ? 2.5 : 1.5,
                                      ),
                                    ),
                                    child: Text(i < code.length ? code[i] : "", style: ThymeTheme.mono(context, size: 22)),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        Positioned.fill(
                          child: Opacity(
                            opacity: 0,
                            child: TextField(
                              controller: _code,
                              focusNode: _focus,
                              autofocus: true,
                              maxLength: _length,
                              textCapitalization: TextCapitalization.characters,
                              inputFormatters: [FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]'))],
                              decoration: const InputDecoration(counterText: "", border: InputBorder.none),
                              showCursor: false,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (_searching) const Text("매장을 찾는 중…", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                  // 틀린 코드 (서버 메시지 그대로)
                  if (_error != null) Text(_error!, style: const TextStyle(fontSize: 13, color: ThymeColor.dangerText)),
                  if (_preview != null) _buildStoreCard(_preview!),

                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: _showNoCode,
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    child: const Text("코드가 없어요 · 사장님께 받는 방법",
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text, decoration: TextDecoration.underline)),
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
                  onPressed: _preview == null
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => EmploymentTypePage(storeCode: _lookedUp, storeName: _preview!.name)),
                          ),
                  child: const Text("이 매장으로 계속"),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStoreCard(StorePreview p) {
    final detail = [p.industryLabel, if (p.address != null && p.address!.isNotEmpty) p.address!, "근무자 ${p.employeeCount}명"].join(" · ");
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.home_outlined, color: ThymeColor.text),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                const SizedBox(height: 4),
                Text(detail, style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
              ],
            ),
          ),
          // 상태 = 원색 점 + 딥 글자
          const Icon(Icons.circle, size: 8, color: ThymeColor.accent),
          const SizedBox(width: 6),
          const Text("찾았어요", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.successText)),
        ],
      ),
    );
  }
}
