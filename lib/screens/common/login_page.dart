import 'package:flutter/material.dart';
import '../../core/theme.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              
              // 앱 로고
              const Text(
                "thyme.",
                style: TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                  color: ThymeColor.deepNight,
                  letterSpacing: -1.0,
                ),
              ),
              const SizedBox(height: 24),
              
              // 메인 카피
              const Text(
                "점주도, 근로자도\n같은 앱으로 시작해요",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: ThymeColor.deepNight,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              
              // 서브 카피
              Text(
                "로그인한 다음 역할을 고를 수 있어요.",
                style: TextStyle(
                  fontSize: 15,
                  color: ThymeColor.textGrey,
                ),
              ),
              
              const Spacer(), // 버튼들을 하단으로 밀어냄
              
              // 소셜 로그인 버튼들
              _buildLoginButton(
                text: "카카오로 계속하기",
                backgroundColor: const Color(0xFFFEE500), // 카카오 옐로우
                textColor: Colors.black87,
              ),
              const SizedBox(height: 12),
              _buildLoginButton(
                text: "네이버로 계속하기",
                backgroundColor: const Color(0xFF03C75A), // 네이버 그린
                textColor: Colors.white,
              ),
              const SizedBox(height: 12),
              _buildLoginButton(
                text: "Apple로 계속하기",
                backgroundColor: Colors.black, // 애플 블랙
                textColor: Colors.white,
              ),
              
              const SizedBox(height: 24),
              
              // 구분선
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text("또는", style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // 휴대폰 번호 로그인 (우리가 백엔드 연동 테스트할 찐 버튼)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey.shade300),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    // A06 역할 선택 화면 또는 홈으로 이동
                  },
                  child: const Text(
                    "휴대폰 번호로 계속하기",
                    style: TextStyle(color: ThymeColor.deepNight, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // 하단 약관 안내
              Center(
                child: Text(
                  "계속하면 이용약관과 개인정보 처리방침에 동의하게 돼요.",
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // 로그인 버튼 공통 컴포넌트
  Widget _buildLoginButton({required String text, required Color backgroundColor, required Color textColor}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () {},
        child: Text(
          text,
          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}