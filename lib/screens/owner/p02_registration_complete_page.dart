import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/api_service.dart';
import '../../core/home_router.dart';
import '../../core/join_api.dart';
import '../../core/store_api.dart';
import '../../core/theme.dart';
import '../../models/store.dart';
import '../../theme/thyme_colors.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_leaf.dart';
import 'p01_owner_home_page.dart';

/// P02 매장 등록 완료. 매장 코드(직원이 J01에 넣는 8자리)와 등록한 설정 요약 → P01 매장 홈
class RegistrationCompletePage extends StatefulWidget {
  const RegistrationCompletePage({super.key});

  @override
  State<RegistrationCompletePage> createState() => _RegistrationCompletePageState();
}

class _RegistrationCompletePageState extends State<RegistrationCompletePage> {
  StoreInfo? _store;
  List<ShiftInfo> _shifts = [];
  int _windows = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final api = StoreApi();
      final store = await api.current();
      final shifts = await api.shifts();
      final windows = await api.skillWindows();
      if (!mounted) return;
      setState(() {
        _store = store;
        _shifts = shifts;
        _windows = windows.length;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _copy(String text, String done) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
  }

  String _message(StoreInfo s) =>
      "[thyme] ${s.name} 근무표에 초대해요.\n아래 링크를 열거나, 앱에서 매장 코드 ${s.storeCode} 를 입력해 주세요.\n${JoinApi.inviteLink(s.storeCode)}";

  void _showQr(StoreInfo s) => showModalBottomSheet(
        context: context,
        backgroundColor: ThymeColor.surface,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(s.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              const SizedBox(height: 4),
              const Text("직원이 휴대폰 카메라로 찍으면 가입 화면이 열려요", style: TextStyle(fontSize: 14, color: ThymeColor.textSub)),
              const SizedBox(height: 20),
              QrImageView(
                data: JoinApi.inviteLink(s.storeCode),
                size: 220,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: ThymeColor.text),
                dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: ThymeColor.text),
              ),
              const SizedBox(height: 12),
              Text(s.storeCode, style: ThymeTheme.mono(context, size: 22, color: ThymeColor.text)),
              const SizedBox(height: 16),
              SizedBox(width: double.infinity, child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text("닫기"))),
            ]),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = _store;
    return Scaffold(
      backgroundColor: ThymePalette.mint50,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      ThymeLeaf(size: 46, color: ThymeColor.accent),
                      SizedBox(width: 8),
                      ThymeLeaf(size: 34, color: ThymePalette.mint300, flip: true),
                      SizedBox(width: 8),
                      ThymeLeaf(size: 22, color: ThymePalette.mint100),
                    ]),
                    const SizedBox(height: 20),
                    Text("OWNER · 매장 등록 완료", style: ThymeTheme.mono(context, size: 13, color: ThymeColor.successText)),
                    const SizedBox(height: 10),
                    if (_error != null) ...[
                      Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                      TextButton(onPressed: _load, child: const Text("다시 불러오기")),
                    ] else if (s == null)
                      const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                    else ...[
                      Text("${s.name}이\n준비됐어요", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ThymeColor.text, height: 1.35)),
                      const SizedBox(height: 10),
                      const Text("이제 직원들을 초대하면 희망 제출이 시작돼요.", style: TextStyle(fontSize: 15, color: ThymeColor.charcoal)),
                      const SizedBox(height: 24),
                      _codeCard(s),
                      const SizedBox(height: 16),
                      _summary(s),
                    ],
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: () => resetTo(context, const OwnerHomePage()), child: const Text("매장 홈으로")),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _codeCard(StoreInfo s) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: ThymeColor.primary, borderRadius: BorderRadius.circular(24)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text("매장 코드", style: TextStyle(color: ThymeColor.onPrimarySub, fontSize: 14)),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(s.storeCode, style: ThymeTheme.mono(context, size: 36, color: ThymeColor.accent).copyWith(letterSpacing: 6)),
          ),
          const SizedBox(height: 18),
          Row(children: [
            _action("링크 복사", () => _copy(JoinApi.inviteLink(s.storeCode), "초대 링크를 복사했어요")),
            const SizedBox(width: 8),
            _action("메시지 공유", () => _copy(_message(s), "초대 메시지를 복사했어요. 카톡·문자에 붙여 넣어 보내세요")),
            const SizedBox(width: 8),
            _action("QR 보기", () => _showQr(s)),
          ]),
        ]),
      );

  Widget _action(String label, VoidCallback onTap) => Expanded(
        child: Material(
          color: ThymeColor.indigoSurface,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              height: 50,
              alignment: Alignment.center,
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: ThymeColor.onPrimary.withValues(alpha: 0.12))),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: const TextStyle(color: ThymeColor.onPrimary, fontSize: 15, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ),
      );

  Widget _summary(StoreInfo s) {
    final fivePlus = switch (s.fivePlusBusiness) {
      true => "5인 이상",
      false => "5인 미만",
      null => "직원 수로 자동",
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(children: [
        _row(const ThymeLeaf(size: 18), "교대 시간대 ${_shifts.length}개", Text(_shifts.map((e) => e.name).join("·"), style: const TextStyle(fontSize: 14, color: ThymeColor.textSub))),
        const Divider(height: 1),
        _row(const ThymeLeaf(size: 18), "노동법 한도 · 수당 자동", Text(fivePlus, style: const TextStyle(fontSize: 14, color: ThymeColor.textSub))),
        const Divider(height: 1),
        _windows == 0
            ? _row(const ThymeLeaf(size: 18, color: ThymeColor.warn, dashed: true), "리테일 큐레이션",
                const Text("나중에 해도 돼요", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.warnText)))
            : _row(const ThymeLeaf(size: 18), "리테일 큐레이션", Text("조건 $_windows개", style: const TextStyle(fontSize: 14, color: ThymeColor.textSub))),
      ]),
    );
  }

  Widget _row(Widget leaf, String title, Widget trailing) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(children: [
          leaf,
          const SizedBox(width: 14),
          Expanded(child: Text(title, style: const TextStyle(fontSize: 16, color: ThymeColor.text))),
          Flexible(child: trailing),
        ]),
      );
}
