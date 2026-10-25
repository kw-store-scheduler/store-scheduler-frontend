import 'package:flutter/material.dart';
import '../../core/theme.dart';

class PreferenceSubmitPage extends StatefulWidget {
  const PreferenceSubmitPage({super.key});

  @override
  State<PreferenceSubmitPage> createState() => _PreferenceSubmitPageState();
}

class _PreferenceSubmitPageState extends State<PreferenceSubmitPage> {
  // 사용자가 우선순위를 바꿀 수 있는 리스트 데이터
  final List<Map<String, String>> _preferences = [
    {"title": "희망 휴무", "desc": "11/15(일) 시험 공부"},
    {"title": "선호 교대", "desc": "평일 오픈 선호 · 미들 가능"},
    {"title": "주말 횟수", "desc": "한 달 2회까지"},
    {"title": "이번 달 근무량", "desc": "64~86시간 (계약 주 15~20h)"},
    {"title": "근무 리듬", "desc": "마감 다음 날 오픈 X · 최대 연속 3일"},
  ];

  // 드래그 앤 드롭으로 순서 변경될 때 실행되는 함수
  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = _preferences.removeAt(oldIndex);
      _preferences.insert(newIndex, item);
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
          "우선순위 · 마지막",
          style: TextStyle(color: ThymeColor.textGrey, fontSize: 14),
        ),
        centerTitle: true,
        actions: [
          const Center(
            child: Padding(
              padding: EdgeInsets.only(right: 24.0),
              child: Text("7 / 7", style: TextStyle(color: ThymeColor.textGrey, fontSize: 14, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "무엇을 가장 지키고 싶어요?",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ThymeColor.deepNight),
                ),
                const SizedBox(height: 12),
                Text(
                  "내 선호끼리 부딪히면 위에 있는 것부터 지켜요.\n화살표로 순서를 바꿔요.",
                  style: TextStyle(fontSize: 14, color: ThymeColor.textGrey, height: 1.5),
                ),
              ],
            ),
          ),
          
          // 우선순위 리스트 (드래그 앤 드롭 가능)
          Expanded(
            child: Theme(
              // 드래그할 때 생기는 기본 그림자/배경색 제거
              data: Theme.of(context).copyWith(
                canvasColor: Colors.transparent,
              ),
              child: ReorderableListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                itemCount: _preferences.length,
                onReorderItem: _onReorder, // 플러터 최신 문법 반영! (onReorder -> onReorderItem)
                buildDefaultDragHandles: true, // 화살표 아이콘 잡고 끌기 허용
                proxyDecorator: (Widget child, int index, Animation<double> animation) {
                  // 드래그 중인 아이템 예쁘게 띄워주기
                  return Material(
                    color: Colors.transparent,
                    child: Container(
                      decoration: BoxDecoration(
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 5))],
                      ),
                      child: child,
                    ),
                  );
                },
                itemBuilder: (context, index) {
                  return Container(
                    key: ValueKey(_preferences[index]["title"]),
                    margin: const EdgeInsets.only(bottom: 12.0),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        // 순위 숫자 뱃지
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: ThymeColor.deepNight,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            "${index + 1}",
                            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 16),
                        
                        // 내용
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _preferences[index]["title"]!,
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.deepNight),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _preferences[index]["desc"]!,
                                style: TextStyle(fontSize: 12, color: ThymeColor.textGrey),
                              ),
                            ],
                          ),
                        ),
                        
                        // 우측 상하 화살표 (드래그 핸들)
                        Column(
                          children: [
                            Icon(Icons.keyboard_arrow_up, size: 20, color: Colors.grey.shade400),
                            Icon(Icons.keyboard_arrow_down, size: 20, color: Colors.grey.shade400),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // 하단 안내 문구
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              children: [
                Container(width: 4, height: 4, decoration: const BoxDecoration(color: ThymeColor.deepNight, shape: BoxShape.circle)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    "고정 일정과 필수 휴무는 순위와 상관없이 항상 지켜져요.",
                    style: TextStyle(fontSize: 12, color: ThymeColor.deepNight, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          
          // 하단 제출 버튼
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThymeColor.mint, // 시안의 마지막 제출 버튼은 민트색!
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    // 서버로 최종 희망 데이터 쏘고 W04 승인 대기 화면 등으로 이동
                  },
                  child: const Text("신청 제출", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}