import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../models/user.dart';
import '../owner/o01_store_registration_page.dart';
import '../worker/j01_store_code_page.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  // 0: 점주/매니저, 1: 근로자 (디자인 시안에 맞춰 근로자 기본 선택)
  int _selectedRoleIndex = 1;
  bool _saving = false;

  /// 로그인했으면 서버에 역할을 확정하고(새 토큰), 점주면 O01 · 근로자면 J01로
  Future<void> _next() async {
    final owner = _selectedRoleIndex == 0;
    if (Session.instance.isLoggedIn) {
      setState(() => _saving = true);
      try {
        await Session.instance.changeRole(owner ? Role.manager : Role.employee);
      } on ApiException catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        return;
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => owner ? const StoreRegistrationPage() : const StoreCodePage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: AppBar(
        backgroundColor: ThymeColor.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: ThymeColor.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                // 로그인했으면 아이디, 시연 중이면 시안 이름
                "반가워요, ${Session.instance.me?.username ?? "김남용"}님",
                style: const TextStyle(fontSize: 14, color: ThymeColor.textSub),
              ),
              const SizedBox(height: 8),
              const Text(
                "어떻게 쓰실 건가요?",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ThymeColor.text),
              ),
              const SizedBox(height: 32),

              // 점주 · 매니저 선택 카드
              _buildRoleCard(
                index: 0,
                icon: Icons.storefront_outlined,
                title: "점주 · 매니저",
                description: "매장을 운영하고 근무표를 만들어요",
                tags: ["근무표 자동 생성", "인건비", "대타 관리"],
              ),
              const SizedBox(height: 16),

              // 근로자 선택 카드
              _buildRoleCard(
                index: 1,
                icon: Icons.person_outline,
                title: "근로자",
                description: "매장에서 일하고 희망 근무를 제출해요",
                tags: ["희망 제출", "내 근무표", "대타 수락"],
              ),
              
              const SizedBox(height: 24),
              Text(
                "점주이면서 직접 근무도 한다면, 나중에 내 정보에서 근로자 역할을 추가할 수 있어요.",
                style: TextStyle(fontSize: 12, color: ThymeColor.textSub, height: 1.5),
              ),

              const Spacer(),

              // 하단 버튼 (선택된 역할에 따라 텍스트 변경)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThymeColor.primary,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  // 점주면 매장 등록(O01), 근로자면 매장 코드 입력(J01)으로 이동
                  onPressed: _saving ? null : _next,
                  child: Text(
                    _selectedRoleIndex == 0 ? "매장 등록하기" : "매장 코드 입력하기",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.onPrimary),
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard({
    required int index,
    required IconData icon,
    required String title,
    required String description,
    required List<String> tags,
  }) {
    bool isSelected = _selectedRoleIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _selectedRoleIndex = index),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected ? ThymeColor.text : ThymeColor.surface,
          border: Border.all(
            color: isSelected ? ThymeColor.text : ThymeColor.border,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? ThymeColor.surface.withValues(alpha: 0.2) : ThymeColor.surfaceSub,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? ThymeColor.surface : ThymeColor.text,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? ThymeColor.surface : ThymeColor.text,
                  ),
                ),
                const Spacer(),
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? ThymeColor.surface : ThymeColor.border,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? ThymeColor.onPrimarySub : ThymeColor.textSub,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              children: tags.map((tag) => _buildTag(tag, isSelected)).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTag(String text, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isSelected ? ThymeColor.surface.withValues(alpha: 0.1) : ThymeColor.surfaceSub,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? ThymeColor.surface : ThymeColor.textSub,
        ),
      ),
    );
  }
}