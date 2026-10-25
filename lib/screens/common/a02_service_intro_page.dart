import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'a03_login_page.dart';

class ServiceIntroPage extends StatelessWidget {
  const ServiceIntroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              const Text(
                "스마트한 스케줄 관리의 시작",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text),
              ),
              const SizedBox(height: 12),
              const Text(
                "근로자와 점주를 위한\n가장 공정한 시간 조율",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ThymeColor.text, height: 1.3),
              ),
              const SizedBox(height: 48),
              
              // 🚨 기획서 반영: 핵심 가치 3가지
              _buildValueItem(Icons.balance_rounded, "공정한 스케줄 배분", "부담 근무가 한 사람에게 몰리지 않아요."),
              const SizedBox(height: 24),
              _buildValueItem(Icons.visibility_rounded, "투명한 배정 사유", "왜 이렇게 배정되었는지 명확하게 알려드려요."),
              const SizedBox(height: 24),
              _buildValueItem(Icons.autorenew_rounded, "쉬운 대타 구하기", "당일 결원 발생 시 앱 안에서 바로 해결해요."),
              
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    );
                  }, child: Text("시작하기")),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildValueItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: ThymeColor.text, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              const SizedBox(height: 4),
              Text(description, style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}