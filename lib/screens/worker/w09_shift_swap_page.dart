import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'h01_part_timer_home_page.dart'; // 처리 후 얄짤없이 홈으로!

class ShiftSwapPage extends StatefulWidget {
  const ShiftSwapPage({super.key});

  @override
  State<ShiftSwapPage> createState() => _ShiftSwapPageState();
}

class _ShiftSwapPageState extends State<ShiftSwapPage> {
  bool _isSwap = true; // true: 맞교환, false: 넘기기
  String? _selectedCoworker = "하준"; 
  bool _applyEveryWeek = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: AppBar(
        backgroundColor: ThymeColor.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: ThymeColor.text),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("근무 바꾸기", style: TextStyle(color: ThymeColor.text, fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // 상단 탭 (넘기기 / 맞교환)
                    Container(
                      color: ThymeColor.surface,
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                      child: Column(
                        children: [
                          Container(
                            decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                Expanded(child: _buildTopTab("넘기기", "내 근무를 동료에게", !_isSwap, () => setState(() => _isSwap = false))),
                                Expanded(child: _buildTopTab("맞교환", "서로의 근무를 바꾸기", _isSwap, () => setState(() => _isSwap = true))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          
                          // 내 근무 정보
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text("내 근무", style: TextStyle(fontSize: 13, color: ThymeColor.textSub, fontWeight: FontWeight.bold)),
                                  SizedBox(height: 4),
                                  Text("11/18(수) · 마감", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                                  SizedBox(height: 4),
                                  Text("17:00~22:00", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                                ],
                              ),
                              TextButton(onPressed: () {}, child: const Text("변경", style: TextStyle(color: ThymeColor.textSub, fontWeight: FontWeight.bold))),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 8), // 배경색 차이로 섹션 분리

                    // 바꿀 수 있는 동료 리스트
                    Ink( // ListTile 물결이 보이도록 Container 대신 Ink
                      color: ThymeColor.surface,
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("바꿀 수 있는 동료의 근무", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                          const SizedBox(height: 16),
                          
                          _buildSwapTargetCard("하", "하준", "11/21(토) 오픈 09~14 ➔ 내 마감", true, isSelected: _selectedCoworker == "하준"),
                          const SizedBox(height: 12),
                          _buildSwapTargetCard("서", "서연", "11/19(목) 오픈 09~14 · 목요일 오전은 내 수업", false), // 선택 불가
                          const SizedBox(height: 12),
                          _buildSwapTargetCard("도", "도윤", "11/22(일) 오픈 09~14 ➔ 내 마감", true, isSelected: _selectedCoworker == "도윤"),
                          
                          const SizedBox(height: 32),
                          const Divider(),
                          const SizedBox(height: 16),
                          
                          // 매주 바꾸기 토글
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            activeTrackColor: ThymeColor.primary, // 스위치 켜짐 = 딥 나이트
                            activeThumbColor: ThymeColor.onPrimary,
                            title: const Text("매주 이렇게 바꾸기", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                            subtitle: const Text("요일 교환 · 다음 달 고정 일정에도 반영", style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
                            value: _applyEveryWeek,
                            onChanged: (val) => setState(() => _applyEveryWeek = val),
                          ),
                          const SizedBox(height: 16),
                          Text("동료가 수락 ➔ 점주 승인 ➔ 근무표·수당이 함께 바뀌어요.\n근무 48시간 전까지 요청할 수 있어요.", style: TextStyle(fontSize: 12, color: ThymeColor.textSub, height: 1.4)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // 하단 버튼
            Container(
              color: ThymeColor.surface,
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThymeColor.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // 요청 완료 후 홈 화면으로 이동
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const PartTimerHomePage()),
                      (route) => false,
                    );
                  },
                  child: Text(
                    _selectedCoworker != null ? "$_selectedCoworker님에게 맞교환 요청" : "대상을 선택해주세요",
                    style: const TextStyle(color: ThymeColor.onPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopTab(String title, String subtitle, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? ThymeColor.text : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isSelected ? ThymeColor.onPrimary : ThymeColor.textSub)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(fontSize: 11, color: isSelected ? ThymeColor.onPrimarySub : ThymeColor.textSub)),
          ],
        ),
      ),
    );
  }

  Widget _buildSwapTargetCard(String initial, String name, String desc, bool isAvailable, {bool isSelected = false}) {
    return GestureDetector(
      onTap: isAvailable ? () => setState(() => _selectedCoworker = name) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isAvailable ? ThymeColor.surface : ThymeColor.surfaceSub,
          border: Border.all(color: isSelected ? ThymeColor.text : ThymeColor.border, width: isSelected ? 1.5 : 1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 20, backgroundColor: ThymeColor.border, child: Text(initial, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isAvailable ? ThymeColor.textSub : ThymeColor.disabled))),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isAvailable ? ThymeColor.text : ThymeColor.disabled)),
                  const SizedBox(height: 4),
                  Text(desc, style: TextStyle(fontSize: 12, color: isAvailable ? ThymeColor.textSub : ThymeColor.disabled)),
                ],
              ),
            ),
            if (isAvailable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? ThymeColor.text : ThymeColor.surface,
                  border: Border.all(color: isSelected ? ThymeColor.text : ThymeColor.border),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text("선택", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSelected ? ThymeColor.onPrimary : ThymeColor.textSub)),
              ),
          ],
        ),
      ),
    );
  }
}