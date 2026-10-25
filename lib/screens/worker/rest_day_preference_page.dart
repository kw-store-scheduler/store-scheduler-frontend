import 'package:flutter/material.dart';
import '../../core/theme.dart';

class RestDayPreferencePage extends StatefulWidget {
  const RestDayPreferencePage({super.key});

  @override
  State<RestDayPreferencePage> createState() => _RestDayPreferencePageState();
}

class _RestDayPreferencePageState extends State<RestDayPreferencePage> {
  // 샘플로 1순위, 2순위 선택 상태를 관리하는 변수
  int _firstChoice = 1; // 1: 오후만 쉬기
  int _secondChoice = 2; // 2: 다른 날과 바꾸기

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: ThymeColor.deepNight, size: 20),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          "인재 · 휴무",
          style: TextStyle(color: ThymeColor.textGrey, fontSize: 14),
        ),
        centerTitle: true,
        actions: [
          const Center(
            child: Padding(
              padding: EdgeInsets.only(right: 24.0),
              child: Text("4 / 7", style: TextStyle(color: ThymeColor.textGrey, fontSize: 14, fontWeight: FontWeight.bold)),
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
                    "쉬고 싶은 날이 있나요?",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ThymeColor.deepNight, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "필수는 반드시 지켜져요. 희망은 안 될 때 어떻게 할지 순서를 정해 두면 그대로 처리해요.",
                    style: TextStyle(fontSize: 14, color: ThymeColor.textGrey, height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  // 첫 번째 휴무 카드 (필수)
                  _buildMandatoryRestCard(),
                  const SizedBox(height: 16),

                  // 두 번째 휴무 카드 (희망 + 대안 선택)
                  _buildPreferredRestCard(),
                  const SizedBox(height: 16),

                  // 휴무 추가 버튼
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        // 날짜 및 사유 입력 바텀시트 띄우기
                      },
                      icon: const Icon(Icons.add, color: ThymeColor.deepNight, size: 18),
                      label: const Text("휴무 추가", style: TextStyle(color: ThymeColor.deepNight, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // 하단 안내 문구
                  Row(
                    children: [
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: ThymeColor.mint, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "필수 휴무는 한 달에 최대 2일까지예요. 넘으면 희망 휴무로 바뀌어요.",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                        ),
                      ),
                    ],
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
                    // W06 계약·근무량 혹은 다음 스텝으로 이동
                  },
                  child: const Text("다음", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 필수 휴무 카드 위젯
  Widget _buildMandatoryRestCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text("토", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                  const SizedBox(width: 8),
                  const Text("11/07", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                  const SizedBox(width: 12),
                  Text("가족 행사 · 하루 종일", style: TextStyle(fontSize: 14, color: ThymeColor.textGrey)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: ThymeColor.deepNight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text("필수", style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const SizedBox(height: 12),
          const Text("필수는 반드시 지켜져요. 순위 없이 항상 지켜져요.", style: TextStyle(fontSize: 12, color: ThymeColor.textGrey)),
        ],
      ),
    );
  }

  // 희망 휴무 및 대안 선택 카드 위젯
  Widget _buildPreferredRestCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThymeColor.deepNight.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text("일", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.rose)),
                  const SizedBox(width: 8),
                  const Text("11/15", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                  const SizedBox(width: 12),
                  Text("시험 공부 · 하루 종일", style: TextStyle(fontSize: 14, color: ThymeColor.textGrey)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text("희망", style: TextStyle(fontSize: 12, color: ThymeColor.deepNight, fontWeight: FontWeight.bold)),
              )
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("이 날이 안 되면?", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
              Text("누른 순서대로 1-2-3", style: TextStyle(fontSize: 12, color: Colors.grey.shade400)),
            ],
          ),
          const SizedBox(height: 16),
          
          // 대안 버튼들
          Row(
            children: [
              Expanded(child: _buildAlternativeButton(1, "오후만 쉬기", _firstChoice == 1 || _secondChoice == 1)),
              const SizedBox(width: 8),
              Expanded(child: _buildAlternativeButton(2, "다른 날과 바꾸기", _firstChoice == 2 || _secondChoice == 2)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildAlternativeButton(3, "대타 직접 구하기", _firstChoice == 3 || _secondChoice == 3)),
              const SizedBox(width: 8),
              Expanded(child: _buildAlternativeButton(4, "그냥 출근할게요", _firstChoice == 4 || _secondChoice == 4)),
            ],
          ),
          const SizedBox(height: 16),
          
          // 선택된 순위 설명
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
            child: const Text(
              "안 되면 1순위 오후만 쉬기 → 2순위 다른 날과 바꾸기\n순서로 처리해요.",
              style: TextStyle(fontSize: 12, color: ThymeColor.textGrey, height: 1.4),
            ),
          )
        ],
      ),
    );
  }

  // 대안 선택 버튼 컴포넌트 (선택 시 상태가 변하도록 에러 수정)
  Widget _buildAlternativeButton(int id, String text, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          // 플러터 잔소리(prefer_final_fields) 방지 겸 임시 선택 로직 추가!
          if (_firstChoice == id) {
            _firstChoice = 0; // 선택 해제
          } else {
            _secondChoice = _firstChoice; // 기존 1순위를 2순위로 밀어냄
            _firstChoice = id; // 누른 걸 1순위로
          }
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.grey.shade50,
          border: Border.all(color: isSelected ? ThymeColor.deepNight : Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isSelected) ...[
              Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(color: ThymeColor.deepNight, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  id == _firstChoice ? "1" : "2",
                  style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? ThymeColor.deepNight : ThymeColor.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}