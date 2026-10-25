import 'package:flutter/material.dart';
import '../../core/theme.dart';

class StoreShiftSetupPage extends StatefulWidget {
  const StoreShiftSetupPage({super.key});

  @override
  State<StoreShiftSetupPage> createState() => _StoreShiftSetupPageState();
}

class _StoreShiftSetupPageState extends State<StoreShiftSetupPage> {
  bool _isSplitShiftEnabled = false;
  bool _isOwnerWorking = true;

  // 요일별 필요 인원 데이터 (오픈, 미들, 마감)
  final List<List<int>> _minStaff = [
    [1, 1, 1, 1, 1, 2, 2], // 오픈 (월~일)
    [2, 2, 2, 2, 2, 3, 3], // 미들
    [1, 1, 1, 1, 2, 2, 2], // 마감
  ];

  final List<String> _days = ["월", "화", "수", "목", "금", "토", "일"];
  final List<String> _shifts = ["오픈", "미들", "마감"];

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
              child: Text("매장 등록 3 / 6", style: TextStyle(color: ThymeColor.textGrey, fontSize: 13, fontWeight: FontWeight.bold)),
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
                    "교대와 요일별 인원",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ThymeColor.deepNight),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "여기서 정한 교대가 근로자 신청 화면의 칸이 돼요.",
                    style: TextStyle(fontSize: 14, color: ThymeColor.textGrey, height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  // 상단 탭 (정해진 교대 / 시간 자유)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
                            ),
                            alignment: Alignment.center,
                            child: const Text("정해진 교대", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            alignment: Alignment.center,
                            child: Text("시간 자유 (30분 단위)", style: TextStyle(fontSize: 14, color: Colors.grey.shade500)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 교대 리스트
                  _buildShiftRow("오픈", "09:00~14:00", "5시간"),
                  const SizedBox(height: 16),
                  _buildShiftRow("미들", "12:00~18:00", "6시간"),
                  const SizedBox(height: 16),
                  _buildShiftRow("마감", "17:00~22:00", "5시간"),
                  const SizedBox(height: 24),

                  // 쪼개기 교대 토글 (에러 수정된 부분)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("쪼개기 교대 (하루 2번 근무)", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                          SizedBox(height: 4),
                          Text("끄면 근로자에게 묻지 않아요", style: TextStyle(fontSize: 12, color: ThymeColor.textGrey)),
                        ],
                      ),
                      Switch(
                        value: _isSplitShiftEnabled,
                        onChanged: (val) => setState(() => _isSplitShiftEnabled = val),
                        activeTrackColor: ThymeColor.deepNight, // activeColor 대신 activeTrackColor 사용
                      ),
                    ],
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Divider(),
                  ),

                  // 요일별 최소 인원 표
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("요일별 최소 인원", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                      Text("칸을 누르면 +1", style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 인원 설정 그리드 (가로: 요일, 세로: 교대)
                  Row(
                    children: [
                      const SizedBox(width: 40), // 교대명 라벨 공간
                      ..._days.map((day) => Expanded(
                            child: Center(
                              child: Text(
                                day,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: (day == "토" || day == "일") ? ThymeColor.rose : ThymeColor.textGrey,
                                ),
                              ),
                            ),
                          )),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  ...List.generate(3, (shiftIndex) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Text(_shifts[shiftIndex], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                          ),
                          ...List.generate(7, (dayIndex) {
                            int count = _minStaff[shiftIndex][dayIndex];
                            bool isWeekend = dayIndex >= 5;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _minStaff[shiftIndex][dayIndex] = count >= 5 ? 1 : count + 1; // 1~5 순환
                                  });
                                },
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: isWeekend ? ThymeColor.deepNight : Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    "$count",
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isWeekend ? Colors.white : ThymeColor.deepNight,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                  
                  const SizedBox(height: 12),
                  Text("목표 인원 중 최소 +1명 시작해요 · 하루 평균 5명", style: TextStyle(fontSize: 11, color: Colors.grey.shade400)),
                  const SizedBox(height: 24),

                  // 점주 근무 포함 여부 토글 (에러 수정된 부분)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("점주·매니저도 근무에 넣기 · 주 3일 오픈", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                      Switch(
                        value: _isOwnerWorking,
                        onChanged: (val) => setState(() => _isOwnerWorking = val),
                        activeTrackColor: ThymeColor.deepNight, // activeColor 대신 activeTrackColor 사용
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
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
                    // O06 예외일 설정 화면으로 이동할 자리
                  },
                  child: const Text("다음 · 예외일", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 교대 정보 한 줄 위젯
  Widget _buildShiftRow(String name, String time, String duration) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
            const SizedBox(width: 16),
            Text(time, style: const TextStyle(fontSize: 15, color: ThymeColor.deepNight)),
          ],
        ),
        Text(duration, style: TextStyle(fontSize: 14, color: ThymeColor.textGrey)),
      ],
    );
  }
}