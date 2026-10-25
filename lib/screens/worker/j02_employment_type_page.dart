import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'j03_join_profile_page.dart';

/// J02 직원 / 알바 (가입 2/3). 형태에 따라 희망 신청 단계와 홈이 달라진다
class EmploymentTypePage extends StatefulWidget {
  const EmploymentTypePage({super.key, required this.storeCode, required this.storeName});

  /// J01에서 찾은 매장
  final String storeCode;
  final String storeName;

  @override
  State<EmploymentTypePage> createState() => _EmploymentTypePageState();
}

class _EmploymentTypePageState extends State<EmploymentTypePage> {
  // 0: 직원(월급제), 1: 알바(시급제)
  int _selectedType = 1; // 시안에 맞춰 알바 기본 선택

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: ThymeStepAppBar(step: 2, total: 3, group: '가입'),
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
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ThymeColor.text),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "형태에 따라 신청하는 내용과 홈 화면이 달라져요.",
                    style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.5),
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
                      color: ThymeColor.surfaceSub,
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
                      style: TextStyle(fontSize: 12, color: ThymeColor.textSub),
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
                    backgroundColor: ThymeColor.primary,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => JoinProfilePage(
                          fullTime: _selectedType == 0,
                          storeCode: widget.storeCode,
                          storeName: widget.storeName,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    _selectedType == 0 ? "직원으로 계속" : "알바로 계속",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.onPrimary),
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
          color: isSelected ? ThymeColor.text : ThymeColor.surface,
          border: Border.all(color: isSelected ? ThymeColor.text : ThymeColor.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isSelected ? ThymeColor.onPrimary : ThymeColor.text),
            ),
            const SizedBox(height: 12),
            Text(
              desc,
              style: TextStyle(fontSize: 12, color: isSelected ? ThymeColor.onPrimary.withValues(alpha: 0.8) : ThymeColor.textSub, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? ThymeColor.surface.withValues(alpha: 0.2) : ThymeColor.surfaceSub,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                badge,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isSelected ? ThymeColor.onPrimary : ThymeColor.textSub),
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
        Expanded(child: Text("직원", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _selectedType == 0 ? ThymeColor.text : ThymeColor.textSub))),
        Expanded(child: Text("알바", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: _selectedType == 1 ? ThymeColor.text : ThymeColor.textSub))),
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
            child: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ThymeColor.text)),
          ),
          Expanded(
            child: Text(
              staffText,
              style: TextStyle(fontSize: 12, color: _selectedType == 0 ? ThymeColor.text : ThymeColor.textSub, height: 1.4),
            ),
          ),
          Expanded(
            child: Text(
              partTimeText,
              style: TextStyle(fontSize: 12, color: _selectedType == 1 ? ThymeColor.text : ThymeColor.textSub, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}