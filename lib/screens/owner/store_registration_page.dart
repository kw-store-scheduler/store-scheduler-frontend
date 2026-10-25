import 'package:flutter/material.dart';
import '../../core/theme.dart';

class StoreRegistrationPage extends StatefulWidget {
  const StoreRegistrationPage({super.key});

  @override
  State<StoreRegistrationPage> createState() => _StoreRegistrationPageState();
}

class _StoreRegistrationPageState extends State<StoreRegistrationPage> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedIndustry = "카페"; // 기본 선택값

  final List<String> _industries = ["카페", "의류", "편의점", "향수", "음식점", "기타"];
  
  // 업종별 미리 세팅되는 추천 역량 (시안 기준 카페 데이터)
  final List<String> _cafeSkills = ["음료 제조", "응대 속도", "오픈·마감", "외국어", "정산"];

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
              child: Text("매장 등록 1 / 6", style: TextStyle(color: ThymeColor.textGrey, fontSize: 13, fontWeight: FontWeight.bold)),
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
                    "어떤 매장인가요?",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ThymeColor.deepNight),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "업종을 고르면 그 업종에 맞는 역량 항목과 기본 교대 시간을 미리 채워 드려요.",
                    style: TextStyle(fontSize: 14, color: ThymeColor.textGrey, height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  // 매장 이름 입력
                  const Text("매장 이름", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: "구시대 커피 광운대점",
                      hintStyle: TextStyle(color: Colors.grey.shade400),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: ThymeColor.deepNight, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: ThymeColor.deepNight, width: 2.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 업종 선택 그리드
                  const Text("업종", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: _industries.length,
                    itemBuilder: (context, index) {
                      bool isSelected = _selectedIndustry == _industries[index];
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIndustry = _industries[index];
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? ThymeColor.deepNight : Colors.white,
                            border: Border.all(color: isSelected ? ThymeColor.deepNight : Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _industries[index],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? Colors.white : ThymeColor.deepNight,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // 선택된 업종에 맞춘 큐레이션 안내 박스
                  if (_selectedIndustry == "카페")
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("카페에 맞춰 준비되는 것", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _cafeSkills.map((skill) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(skill, style: const TextStyle(fontSize: 13, color: ThymeColor.deepNight)),
                              );
                            }).toList(),
                          ),
                        ],
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
                    // O02 주기 설정 화면으로 넘어갈 자리
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
}