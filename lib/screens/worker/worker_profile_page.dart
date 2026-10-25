import 'package:flutter/material.dart';
import '../../core/theme.dart';

class WorkerProfilePage extends StatefulWidget {
  const WorkerProfilePage({super.key});

  @override
  State<WorkerProfilePage> createState() => _WorkerProfilePageState();
}

class _WorkerProfilePageState extends State<WorkerProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _nicknameController = TextEditingController();
  final TextEditingController _dateController = TextEditingController(text: "2026. 11. 20"); // 오늘 날짜 기본 세팅
  bool _isUnderage = false;

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
              child: Text("가입 3 / 3", style: TextStyle(color: ThymeColor.textGrey, fontSize: 13, fontWeight: FontWeight.bold)),
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
                    "동료들에게 보일 정보",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ThymeColor.deepNight),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "근무표와 대타 요청에 이 이름이 나와요.",
                    style: TextStyle(fontSize: 14, color: ThymeColor.textGrey, height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  // 프로필 사진 등록 (선택)
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: const Icon(Icons.person, size: 40, color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: const Text("사진 바꾸기 (선택)", style: TextStyle(fontSize: 12, color: ThymeColor.deepNight, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 이름 입력
                  const Text("이름", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                  const SizedBox(height: 12),
                  _buildTextField(_nameController, "김남용"),
                  const SizedBox(height: 24),

                  // 닉네임 입력 (선택)
                  const Text("매장에서 부르는 이름 (선택)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                  const SizedBox(height: 12),
                  _buildTextField(_nicknameController, "남용"),
                  const SizedBox(height: 24),

                  // 근무 시작일
                  const Text("근무 시작일", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _dateController,
                    readOnly: true,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: ThymeColor.deepNight),
                    decoration: InputDecoration(
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
                      suffixIcon: const Icon(Icons.calendar_today, color: ThymeColor.deepNight, size: 20),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 미성년자 체크박스
                  GestureDetector(
                    onTap: () => setState(() => _isUnderage = !_isUnderage),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _isUnderage ? ThymeColor.rose.withValues(alpha: 0.05) : Colors.white,
                        border: Border.all(color: _isUnderage ? ThymeColor.rose : Colors.grey.shade300, width: _isUnderage ? 1.5 : 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _isUnderage ? Icons.check_box : Icons.check_box_outline_blank,
                            color: _isUnderage ? ThymeColor.rose : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "만 18세 미만이에요",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: _isUnderage ? ThymeColor.rose : ThymeColor.deepNight,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  "22시~06시·하루 7시간 넘는 근무는 자동으로 빠지고, 친권자 동의서를 올리게 돼요.",
                                  style: TextStyle(fontSize: 12, color: ThymeColor.textGrey, height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 하단 안내 문구
                  Center(
                    child: Text(
                      "시급은 사장님이 승인하면서 정해요.\n내 정보에서 언제든 확인할 수 있어요.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 하단 버튼
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
                    // J04 승인 대기 화면으로 넘어가거나 바로 홈으로 갈 자리
                  },
                  child: const Text("가입 요청 보내기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 텍스트 필드 공통 위젯
  Widget _buildTextField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade300),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: ThymeColor.deepNight, width: 2.0),
        ),
      ),
    );
  }
}