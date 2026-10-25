import 'package:flutter/material.dart';
import '../../core/theme.dart';

class ShiftPreferencePage extends StatefulWidget {
  const ShiftPreferencePage({super.key});

  @override
  State<ShiftPreferencePage> createState() => _ShiftPreferencePageState();
}

class _ShiftPreferencePageState extends State<ShiftPreferencePage> {
  // 상태: 0 = 불가(빈칸), 1 = 가능(민트), 2 = 선호(진남색), 3 = 고정일정(회색/잠김)
  // 시안에 맞춰 초기 데이터 세팅 (11/15 ~ 11/21)
  final List<Map<String, dynamic>> _scheduleData = [
    {"date": "11/15", "day": "일", "shifts": [0, 0, 0]},
    {"date": "11/16", "day": "월", "shifts": [3, 3, 0]}, // 수업으로 잠김
    {"date": "11/17", "day": "화", "shifts": [2, 1, 0]}, // 선호, 가능, 불가
    {"date": "11/18", "day": "수", "shifts": [2, 1, 0]},
    {"date": "11/19", "day": "목", "shifts": [3, 3, 1]}, // 수업 2개, 마감 가능
    {"date": "11/20", "day": "금", "shifts": [2, 1, 3]}, // 선호, 가능, 편의점 알바로 잠김
    {"date": "11/21", "day": "토", "shifts": [0, 1, 0]},
  ];

  int _maxWeekendShifts = 2; // 주말 근무 최대 횟수

  void _toggleShift(int rowIndex, int shiftIndex) {
    setState(() {
      int currentState = _scheduleData[rowIndex]["shifts"][shiftIndex];
      if (currentState == 3) return; // 고정 일정은 터치 무시
      // 0(불가) -> 1(가능) -> 2(선호) -> 0(불가) 순환
      _scheduleData[rowIndex]["shifts"][shiftIndex] = (currentState + 1) % 3;
    });
  }

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
        title: const Text(
          "인재 · 날짜와 교대",
          style: TextStyle(color: ThymeColor.textGrey, fontSize: 14),
        ),
        centerTitle: true,
        actions: [
          const Center(
            child: Padding(
              padding: EdgeInsets.only(right: 24.0),
              child: Text("3 / 7", style: TextStyle(color: ThymeColor.textGrey, fontSize: 14, fontWeight: FontWeight.bold)),
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
                    "언제, 어느 교대에\n나올 수 있어요?",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ThymeColor.deepNight, height: 1.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "한 번 누르면 가능, 두 번 누르면 선호예요.\n고정 일정과 겹치는 칸은 미리 잠갔어요.",
                    style: TextStyle(fontSize: 14, color: ThymeColor.textGrey, height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  // 시간표 헤더
                  Row(
                    children: [
                      const SizedBox(width: 50), // 날짜 열 여백
                      _buildShiftHeader("오픈", "09~14"),
                      _buildShiftHeader("미들", "12~18"),
                      _buildShiftHeader("마감", "17~22"),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // 시간표 그리드
                  ...List.generate(_scheduleData.length, (rowIndex) {
                    var rowData = _scheduleData[rowIndex];
                    bool isWeekend = rowData["day"] == "토" || rowData["day"] == "일";
                    
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          // 날짜 라벨
                          SizedBox(
                            width: 50,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(rowData["date"], style: const TextStyle(fontSize: 12, color: ThymeColor.textGrey)),
                                Text(
                                  rowData["day"],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: isWeekend ? ThymeColor.rose : ThymeColor.deepNight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // 3개 교대 버튼
                          ...List.generate(3, (shiftIndex) {
                            return _buildShiftCell(
                              state: rowData["shifts"][shiftIndex],
                              onTap: () => _toggleShift(rowIndex, shiftIndex),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 16),

                  // 범례 (불가, 가능, 선호, 고정일정)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegend(0, "불가"),
                      const SizedBox(width: 12),
                      _buildLegend(1, "가능"),
                      const SizedBox(width: 12),
                      _buildLegend(2, "선호"),
                      const SizedBox(width: 12),
                      _buildLegend(3, "고정 일정"),
                    ],
                  ),
                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 24),

                  // 주말 근무 최대 횟수 설정
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("주말 근무, 한 달 최대", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                          SizedBox(height: 4),
                          Text("팀 평균 2회 · 4주 누적으로 공평하게", style: TextStyle(fontSize: 12, color: ThymeColor.textGrey)),
                        ],
                      ),
                      Row(
                        children: [
                          _buildCountButton(Icons.remove, () {
                            if (_maxWeekendShifts > 0) setState(() => _maxWeekendShifts--);
                          }),
                          Container(
                            width: 40,
                            alignment: Alignment.center,
                            child: Text("$_maxWeekendShifts회", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                          ),
                          _buildCountButton(Icons.add, () {
                            setState(() => _maxWeekendShifts++);
                          }),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      "11월 전체 · 가능 28칸 · 선호 9칸",
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
                    // W03 휴무 지정 화면 또는 다음 단계로 이동할 자리
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

  // 교대 헤더 컴포넌트
  Widget _buildShiftHeader(String title, String time) {
    return Expanded(
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
          const SizedBox(height: 2),
          Text(time, style: const TextStyle(fontSize: 11, color: ThymeColor.textGrey)),
        ],
      ),
    );
  }

  // 시간표 칸(셀) 컴포넌트
  Widget _buildShiftCell({required int state, required VoidCallback onTap}) {
    Color bgColor;
    Color borderColor;
    String label = "";
    Color textColor = ThymeColor.deepNight;

    if (state == 1) { // 가능
      bgColor = ThymeColor.mint;
      borderColor = ThymeColor.mint;
      label = "가능";
    } else if (state == 2) { // 선호
      bgColor = ThymeColor.deepNight;
      borderColor = ThymeColor.deepNight;
      label = "선호";
      textColor = Colors.white;
    } else if (state == 3) { // 고정 일정(잠김)
      bgColor = Colors.grey.shade100;
      borderColor = Colors.grey.shade200;
      label = "수업"; // 시안 상단 예시 텍스트
      textColor = Colors.grey.shade500;
    } else { // 0: 불가 (기본)
      bgColor = Colors.white;
      borderColor = Colors.grey.shade300;
    }

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          height: 44,
          decoration: BoxDecoration(
            color: bgColor,
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(fontSize: 12, fontWeight: state > 0 ? FontWeight.bold : FontWeight.normal, color: textColor),
          ),
        ),
      ),
    );
  }

 // 하단 범례 컴포넌트
  Widget _buildLegend(int state, String text) {
    Color color;
    if (state == 1) {
      color = ThymeColor.mint;
    } else if (state == 2) {
      color = ThymeColor.deepNight;
    } else if (state == 3) {
      color = Colors.grey.shade300;
    } else {
      color = Colors.white;
    }

    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            border: Border.all(color: state == 0 ? Colors.grey.shade400 : color),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(text, style: const TextStyle(fontSize: 12, color: ThymeColor.textGrey)),
      ],
    );
  }

  // -, + 카운트 버튼
  Widget _buildCountButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: ThymeColor.deepNight,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}