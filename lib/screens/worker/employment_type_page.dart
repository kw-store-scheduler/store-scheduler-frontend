import 'package:flutter/material.dart';
import '../../core/theme.dart';

class EmploymentTypePage extends StatefulWidget {
  const EmploymentTypePage({super.key});

  @override
  State<EmploymentTypePage> createState() => _EmploymentTypePageState();
}

class _EmploymentTypePageState extends State<EmploymentTypePage> {
  // 0: 직원(월급제), 1: 알바(시급제)
  int _selectedType = 1; // 시안에 맞춰 알바 기본 선택

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
        actions: [
          const Center(
            child: Padding(
              padding: EdgeInsets.only(right: 24.0),
              child: Text("가입 2 / 3", style: TextStyle(color: ThymeColor.textGrey, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "어떤 형태로 일하세요?",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ThymeColor.deepNight),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "형태에 따라 신청하는 내용과 홈 화면이 달라져요.",
                    style: TextStyle(fontSize: 14, color: ThymeColor.textGrey, height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  // 선택 카드 2개
                  Row(
                    children: [
                      Expanded(child: _buildTypeCard(0, "직원", "정규 계약직, 정해진 주\n근무시간이 있어요", "월급제")),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTypeCard(1, "알바", "시간제, 가능한 날을 매달\n알려줘요", "시급제")),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // 형태별 비교표
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        _buildComparisonHeader(),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Divider(),
                        ),
                        _buildComparisonRow("기본 근무", "주 5일 · 40시간", "희망 일수만큼"),
                        _buildComparisonRow("매달 신청", "연차·휴무 → 교대\n선호 (3단계)", "날짜×교대부터\n(7단계)"),
                        _buildComparisonRow("홈 화면", "남은 연차 · 오늘\n업무", "예상 급여 · 대타\n요청"),
                        _buildComparisonRow("대타 요청", "매니저 권한으로\n승인", "받고 수락"),
                        _buildComparisonRow("업무", "오픈·마감 책임\n체크리스트", "배정된 업무만"),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 하단 안내 문구
                  Center(
                    child: Text(
                      "사장님이 승인할 때 바로잡을 수 있어요.",
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 하단 다음 버튼
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThymeColor.deepNight,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // J03 프로필 입력 화면으로 이동
                  },
                  child: Text(
                    _selectedType == 0 ? "직원으로 계속" : "알바로 계속",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 상단 선택 카드 위젯
  Widget _buildTypeCard(int index, String title, String desc, String badge) {
    bool isSelected = _selectedType == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedType = index),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? ThymeColor.deepNight : Colors.white,
          border: Border.all(color: isSelected ? ThymeColor.deepNight : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : ThymeColor.deepNight),
            ),
            const SizedBox(height: 12),
            Text(
              desc,
              style: TextStyle(fontSize: 12, color: isSelected ? Colors.white.withValues(alpha: 0.8) : ThymeColor.textGrey, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : ThymeColor.textGrey),
              ),
            )
          ],
        ),
      ),
    );
  }

  // 비교표 헤더
  Widget _buildComparisonHeader() {
    return Row(
      children: [
        const SizedBox(width: 70), // 항목 이름 여백
        Expanded(child: Text("직원", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _selectedType == 0 ? ThymeColor.deepNight : ThymeColor.textGrey))),
        Expanded(child: Text("알바", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _selectedType == 1 ? ThymeColor.deepNight : ThymeColor.textGrey))),
      ],
    );
  }

  // 비교표 내용 줄
  Widget _buildComparisonRow(String label, String staffText, String partTimeText) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
          ),
          Expanded(
            child: Text(
              staffText,
              style: TextStyle(fontSize: 12, color: _selectedType == 0 ? ThymeColor.deepNight : ThymeColor.textGrey, height: 1.4),
            ),
          ),
          Expanded(
            child: Text(
              partTimeText,
              style: TextStyle(fontSize: 12, color: _selectedType == 1 ? ThymeColor.deepNight : ThymeColor.textGrey, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}