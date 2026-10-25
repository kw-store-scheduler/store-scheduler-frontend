import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'a04_phone_verification_page.dart';
import 'dev_login_sheet.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
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
                  color: ThymeColor.text,
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
                  color: ThymeColor.text,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              
              // 서브 카피
              Text(
                "로그인한 다음 역할을 고를 수 있어요.",
                style: TextStyle(
                  fontSize: 15,
                  color: ThymeColor.textSub,
                ),
              ),
              
              const Spacer(), // 버튼들을 하단으로 밀어냄
              
              // 소셜 로그인 버튼들
              _buildLoginButton(
                context,
                text: "카카오로 계속하기",
                backgroundColor: ThymeColor.kakaoYellow, // 카카오 옐로우
                textColor: ThymeColor.kakaoLabel,
              ),
              const SizedBox(height: 12),
              _buildLoginButton(
                context,
                text: "네이버로 계속하기",
                backgroundColor: ThymeColor.naverGreen, // 네이버 그린
                textColor: ThymeColor.onPrimary,
              ),
              const SizedBox(height: 12),
              _buildLoginButton(
                context,
                text: "Apple로 계속하기",
                backgroundColor: ThymeColor.appleBlack, // 애플 블랙
                textColor: ThymeColor.onPrimary,
              ),
              
              const SizedBox(height: 24),
              
              // 구분선
              Row(
                children: [
                  Expanded(child: Divider(color: ThymeColor.border)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text("또는", style: TextStyle(color: ThymeColor.textSub, fontSize: 13)),
                  ),
                  Expanded(child: Divider(color: ThymeColor.border)),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // 휴대폰 번호 로그인 (우리가 백엔드 연동 테스트할 찐 버튼)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: ThymeColor.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  // A03 → A04 휴대폰 인증 (대타·근무표 알림 받을 번호)
                  onPressed: () => _goPhoneVerification(context),
                  child: const Text(
                    "휴대폰 번호로 계속하기",
                    style: TextStyle(color: ThymeColor.text, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              
              // [개발용] 소셜 로그인이 백엔드에 생기기 전까지 실제 서버로 확인할 때만 (디버그 빌드 전용)
              if (kDebugMode)
                Center(
                  child: TextButton(
                    onPressed: () => showDevLoginSheet(context),
                    child: const Text("개발용 ID 로그인", style: TextStyle(color: ThymeColor.textSub, fontSize: 13)),
                  ),
                )
              else
                const SizedBox(height: 24),

              // 하단 약관 안내
              Center(
                child: Text(
                  "계속하면 이용약관과 개인정보 처리방침에 동의하게 돼요.",
                  style: TextStyle(color: ThymeColor.disabled, fontSize: 12),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  // 소셜 로그인은 백엔드에 아직 없어서 시연에서는 모두 A04로 이어 간다
  static void _goPhoneVerification(BuildContext context) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => const PhoneVerificationPage()));

  // 로그인 버튼 공통 컴포넌트
  Widget _buildLoginButton(BuildContext context, {required String text, required Color backgroundColor, required Color textColor}) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onPressed: () => _goPhoneVerification(context),
        child: Text(
          text,
          style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
} 