import 'package:flutter/material.dart';
import '../../core/theme.dart';

class ShiftApplicationPage extends StatefulWidget {
  const ShiftApplicationPage({super.key});

  @override
  State<ShiftApplicationPage> createState() => _ShiftApplicationPageState();
}

class _ShiftApplicationPageState extends State<ShiftApplicationPage> {
  // [UI 상태용 변수]
  int _selectedWeek = 2; // 15~21일 주차 선택 (시안 기준)
  int _maxWeekendWork = 2;
  
  // 0: 불가(빈칸), 1: 가능, 2: 선호, 3: 고정일정(잠김)
  final Map<String, int> _shiftState = {}; 
  final Map<String, String> _fixedSchedules = {}; // 잠긴 사유 (수업 등)

  final List<String> _dates = [
    "11/15 일", "11/16 월", "11/17 화", "11/18 수", "11/19 목", "11/20 금", "11/21 토"
  ];
  final List<String> _shifts = ["오픈 09-14", "미들 12-18", "마감 17-22"];

  @override
  void initState() {
    super.initState();
    // 시안과 동일하게 고정 일정(수업, 면접) 임시 세팅
    _fixedSchedules["11/16 월_오픈 09-14"] = "수업";
    _fixedSchedules["11/16 월_미들 12-18"] = "수업";
    _fixedSchedules["11/19 목_오픈 09-14"] = "수업";
    _fixedSchedules["11/19 목_미들 12-18"] = "수업";
    _fixedSchedules["11/20 금_마감 17-22"] = "면접";

    // 맵 초기화 (고정 일정은 3, 나머지는 0으로 세팅)
    for (var date in _dates) {
      for (var shift in _shifts) {
        String key = "${date}_$shift";
        if (_fixedSchedules.containsKey(key)) {
          _shiftState[key] = 3;
        } else {
          _shiftState[key] = 0;
        }
      }
    }

    // 시안처럼 '선호', '가능' 임시 세팅
    _shiftState["11/17 화_오픈 09-14"] = 2; // 선호
    _shiftState["11/17 화_미들 12-18"] = 1; // 가능
    _shiftState["11/18 수_오픈 09-14"] = 2; // 선호
    _shiftState["11/18 수_미들 12-18"] = 1; // 가능
    _shiftState["11/18 수_마감 17-22"] = 1; // 가능
    _shiftState["11/20 금_오픈 09-14"] = 2; // 선호
    _shiftState["11/20 금_미들 12-18"] = 1; // 가능
  }

  void _toggleShiftState(String key) {
    if (_shiftState[key] == 3) return; // 잠긴 칸은 터치 무시
    setState(() {
      _shiftState[key] = (_shiftState[key]! + 1) % 3; // 0 -> 1 -> 2 -> 0 순환
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
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 24, top: 20),
            child: Text("3 / 7", style: TextStyle(color: ThymeColor.textGrey, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("언제, 어느 교대에\n나올 수 있어요?", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.deepNight, height: 1.3)),
                  const SizedBox(height: 12),
                  const Text("한 번 누르면 가능, 두 번 누르면 선호예요. 고정 일정과 겹치는 칸은 미리 잠겼어요.", style: TextStyle(fontSize: 13, color: ThymeColor.textGrey, height: 1.4)),
                  const SizedBox(height: 24),

                  // [상단 주차 탭]
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildWeekTab(0, "1~7"),
                      _buildWeekTab(1, "8~14"),
                      _buildWeekTab(2, "15~21"),
                      _buildWeekTab(3, "22~28"),
                      _buildWeekTab(4, "29~30"),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // [매트릭스 달력 헤더]
                  Row(
                    children: [
                      const SizedBox(width: 50), // 날짜 열 여백
                      ..._shifts.map((shift) => Expanded(
                        child: Center(child: Text(shift, style: const TextStyle(fontSize: 11, color: ThymeColor.textGrey, fontWeight: FontWeight.bold))),
                      )),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // [매트릭스 달력 바디]
                  ..._dates.map((date) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 50,
                          child: Text(date, style: TextStyle(fontSize: 13, fontWeight: date.contains("일") || date.contains("토") ? FontWeight.bold : FontWeight.normal, color: date.contains("일") ? ThymeColor.rose : ThymeColor.deepNight)),
                        ),
                        ..._shifts.map((shift) => Expanded(
                          child: _buildShiftCell("${date}_$shift"),
                        )),
                      ],
                    ),
                  )),

                  const SizedBox(height: 16),
                  
                  // [범례 아이콘]
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(0, "불가"),
                      const SizedBox(width: 12),
                      _buildLegendItem(1, "가능"),
                      const SizedBox(width: 12),
                      _buildLegendItem(2, "선호"),
                      const SizedBox(width: 12),
                      _buildLegendItem(3, "고정 일정"),
                    ],
                  ),
                  const SizedBox(height: 40),

                  // [주말 근무 한도 설정 박스]
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: ThymeColor.neutralBase, borderRadius: BorderRadius.circular(16)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("주말 근무, 한 달 최대", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                            SizedBox(height: 4),
                            Text("팀 평균 2회 · 4주 누적으로 공평하게", style: TextStyle(fontSize: 12, color: ThymeColor.textGrey)),
                          ],
                        ),
                        Row(
                          children: [
                            _buildCounterButton(Icons.remove, () {
                              if (_maxWeekendWork > 0) setState(() => _maxWeekendWork--);
                            }),
                            Container(
                              width: 40,
                              alignment: Alignment.center,
                              child: Text("$_maxWeekendWork회", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                            ),
                            _buildCounterButton(Icons.add, () => setState(() => _maxWeekendWork++)),
                          ],
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text("11월 전체 · 가능 28칸 · 선호 9칸", style: TextStyle(fontSize: 12, color: ThymeColor.textGrey)),
                  const SizedBox(height: 32), // 하단 여백
                ],
              ),
            ),
          ),
          
          // [하단 고정 버튼]
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
                  ),
                  onPressed: () {
                    // 다음 단계(휴무 요청 W03)로 이동
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

  // [위젯: 주차 탭]
  Widget _buildWeekTab(int index, String label) {
    bool isSelected = _selectedWeek == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedWeek = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? ThymeColor.deepNight : ThymeColor.neutralBase,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isSelected ? Colors.white : ThymeColor.textGrey)),
      ),
    );
  }

  // [위젯: 매트릭스 달력 셀]
  Widget _buildShiftCell(String key) {
    int state = _shiftState[key] ?? 0;
    
    Color bgColor = Colors.white;
    Color borderColor = Colors.grey.shade300;
    String text = "";
    Color textColor = ThymeColor.deepNight;

    if (state == 1) { // 가능
      borderColor = ThymeColor.deepNight;
      text = "가능";
    } else if (state == 2) { // 선호
      bgColor = ThymeColor.deepNight;
      borderColor = ThymeColor.deepNight;
      text = "선호";
      textColor = Colors.white;
    } else if (state == 3) { // 고정 일정(잠김)
      bgColor = ThymeColor.neutralBase;
      borderColor = Colors.transparent;
      text = _fixedSchedules[key] ?? "고정";
      textColor = ThymeColor.textGrey;
    }

    return GestureDetector(
      onTap: () => _toggleShiftState(key),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        height: 44,
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(color: borderColor, width: 1.5),
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.center,
        child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: textColor)),
      ),
    );
  }

  // [위젯: 범례 아이콘]
  Widget _buildLegendItem(int state, String label) {
    return Row(
      children: [
        Container(
          width: 12, height: 12,
          decoration: BoxDecoration(
            color: state == 2 ? ThymeColor.deepNight : state == 3 ? ThymeColor.neutralBase : Colors.white,
            border: Border.all(color: state == 1 ? ThymeColor.deepNight : state == 0 ? Colors.grey.shade300 : Colors.transparent),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: ThymeColor.textGrey)),
      ],
    );
  }

  // [위젯: 플러스 마이너스 버튼]
  Widget _buildCounterButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.grey.shade300)),
        child: Icon(icon, size: 16, color: ThymeColor.deepNight),
      ),
    );
  }
}