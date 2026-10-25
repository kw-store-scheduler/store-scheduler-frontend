import 'package:flutter/material.dart';
import '../../core/theme.dart';

class StoreCodePage extends StatefulWidget {
  const StoreCodePage({super.key});

  @override
  State<StoreCodePage> createState() => _StoreCodePageState();
}

class _StoreCodePageState extends State<StoreCodePage> {
  final TextEditingController _codeController = TextEditingController();
  bool _isCodeValid = false;

  @override
  void initState() {
    super.initState();
    // 글자가 6자리 꽉 차면 자동으로 매장 검색 결과 카드 띄우기
    _codeController.addListener(() {
      setState(() {
        _isCodeValid = _codeController.text.trim().length == 6;
      });
    });
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
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
        actions: [
          const Center(
            child: Padding(
              padding: EdgeInsets.only(right: 24.0),
              child: Text("가입 1 / 3", style: TextStyle(color: ThymeColor.textGrey, fontSize: 13, fontWeight: FontWeight.bold)),
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
                    "어느 매장에서\n일하세요?",
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ThymeColor.deepNight, height: 1.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    "사장님에게 받은 6자리 코드를 넣거나, 받은 링크를\n누르면 바로 채워져요.",
                    style: TextStyle(fontSize: 14, color: ThymeColor.textGrey, height: 1.5),
                  ),
                  const SizedBox(height: 40),

                  // 6자리 매장 코드 입력 필드
                  const Text("매장 코드", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _codeController,
                    maxLength: 6,
                    textCapitalization: TextCapitalization.characters,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 8, color: ThymeColor.deepNight),
                    decoration: InputDecoration(
                      hintText: "NLXAYE",
                      hintStyle: TextStyle(color: Colors.grey.shade300, letterSpacing: 8),
                      counterText: "", // 하단 글자 수 카운트 숨기기
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
                  const SizedBox(height: 24),

                  // 코드가 6자리 입력되었을 때만 보여주는 매장 정보 카드
                  if (_isCodeValid)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: const Icon(Icons.storefront_outlined, color: ThymeColor.deepNight),
                          ),
                          const SizedBox(width: 16),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("구시대 커피 광운대점", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.deepNight)),
                                SizedBox(height: 6),
                                Text("카페 · 서울 노원구 · 근무자 7명", style: TextStyle(fontSize: 13, color: ThymeColor.textGrey)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Row(
                            children: [
                              Icon(Icons.check_circle, size: 14, color: ThymeColor.mint),
                              SizedBox(width: 4),
                              Text("찾았어요", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ThymeColor.mint)),
                            ],
                          )
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),
                  Center(
                    child: Text(
                      "코드가 없어요 · 사장님에게 요청 보내기",
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade500, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 하단 계속하기 버튼
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isCodeValid ? ThymeColor.deepNight : Colors.grey.shade300,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  onPressed: _isCodeValid ? () {
                    // 다음 단계인 J02 직원/알바 선택 화면으로 넘어가는 로직
                  } : null,
                  child: Text(
                    "이 매장으로 계속",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: _isCodeValid ? Colors.white : ThymeColor.textGrey,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}