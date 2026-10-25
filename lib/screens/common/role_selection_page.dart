import 'package:flutter/material.dart';
import '../../core/theme.dart';

class RoleSelectionPage extends StatefulWidget {
  const RoleSelectionPage({super.key});

  @override
  State<RoleSelectionPage> createState() => _RoleSelectionPageState();
}

class _RoleSelectionPageState extends State<RoleSelectionPage> {
  // 0: 점주/매니저, 1: 근로자 (디자인 시안에 맞춰 근로자 기본 선택)
  int _selectedRoleIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: ThymeColor.deepNight, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "반가워요, 김남용님",
                style: TextStyle(fontSize: 14, color: ThymeColor.textGrey),
              ),
              const SizedBox(height: 8),
              const Text(
                "어떻게 쓰실 건가요?",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ThymeColor.deepNight),
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
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.5),
              ),

              const Spacer(),

              // 하단 버튼 (선택된 역할에 따라 텍스트 변경)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThymeColor.deepNight,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // 점주면 매장 등록(O01), 근로자면 매장 코드 입력(J01)으로 이동
                  },
                  child: Text(
                    _selectedRoleIndex == 0 ? "매장 등록하기" : "매장 코드 입력하기",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
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
          color: isSelected ? ThymeColor.deepNight : Colors.white,
          border: Border.all(
            color: isSelected ? ThymeColor.deepNight : Colors.grey.shade300,
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
                    color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : ThymeColor.deepNight,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? Colors.white : ThymeColor.deepNight,
                  ),
                ),
                const Spacer(),
                Icon(
                  isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                  color: isSelected ? Colors.white : Colors.grey.shade300,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: TextStyle(
                fontSize: 14,
                color: isSelected ? Colors.white70 : ThymeColor.textGrey,
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
        color: isSelected ? Colors.white.withValues(alpha: 0.1) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : ThymeColor.textGrey,
        ),
      ),
    );
  }
}