import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../models/user.dart';
import '../../widgets/thyme_back_button.dart';
import '../owner/o01_store_registration_page.dart';
import '../worker/j01_store_code_page.dart';

/// A06 점주 / 근로자 선택. 서버에 역할을 확정하고(PATCH /api/users/me/role → 새 토큰) 점주는 O01, 근로자는 J01로
class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  // 0: 점주/매니저, 1: 근로자 (시안: 근로자 기본 선택)
  int _selected = 1;
  bool _saving = false;

  Future<void> _next() async {
    final owner = _selected == 0;
    setState(() => _saving = true);
    try {
      await Session.instance.changeRole(owner ? Role.manager : Role.employee);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      return;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => owner ? const StoreRegistrationPage() : const StoreCodePage()));
  }

  @override
  Widget build(BuildContext context) {
    final name = Session.instance.me?.username;
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
                  if (name != null) Text("반가워요, $name님", style: const TextStyle(fontSize: 15, color: ThymeColor.textSub)),
                  const SizedBox(height: 8),
                  const Text("어떻게 쓰실 건가요?", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                  const SizedBox(height: 28),
                  _buildCard(0, Icons.home_outlined, "점주 · 매니저", "매장을 운영하고 근무표를 만들어요", const ["근무표 자동 생성", "인건비", "대타 관리"]),
                  const SizedBox(height: 12),
                  _buildCard(1, Icons.person_outline, "근로자", "매장에서 일하고 희망 근무를 제출해요", const ["희망 제출", "내 근무표", "대타 수락"]),
                  const SizedBox(height: 20),
                  // 백엔드 규칙: 매장을 등록하거나 합류 신청한 뒤에는 역할을 바꿀 수 없다 (AuthService.changeRole)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: Text("매장을 등록하거나 합류 신청한 뒤에는 역할을 바꿀 수 없어요. 둘 다 쓰려면 계정을 하나 더 만들어 주세요.",
                        style: TextStyle(fontSize: 13, color: ThymeColor.textSub, height: 1.5)),
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
                  onPressed: _saving ? null : _next,
                  child: Text(_saving ? "잠시만요…" : (_selected == 0 ? "매장 등록하기" : "매장 코드 입력하기")),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 선택된 카드 = 딥 나이트 면 + 흰 글자 (가이드 4-3)
  Widget _buildCard(int index, IconData icon, String title, String desc, List<String> tags) {
    final on = _selected == index;
    return Material(
      color: on ? ThymeColor.primary : ThymeColor.surface,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => setState(() => _selected = index),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: on ? ThymeColor.indigoSurface : ThymeColor.surfaceSub,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: on ? ThymeColor.onPrimary : ThymeColor.text),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: on ? ThymeColor.onPrimary : ThymeColor.text)),
                        const SizedBox(height: 4),
                        Text(desc, style: TextStyle(fontSize: 14, color: on ? ThymeColor.onPrimarySub : ThymeColor.textSub)),
                      ],
                    ),
                  ),
                  Icon(on ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                      color: on ? ThymeColor.onPrimary : ThymeColor.disabled),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in tags)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: on ? ThymeColor.indigoSurface : ThymeColor.surfaceSub,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: on ? ThymeColor.onPrimary : ThymeColor.text)),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
