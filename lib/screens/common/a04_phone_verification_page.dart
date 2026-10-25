import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'a05_terms_agreement_page.dart';

class PhoneVerificationPage extends StatelessWidget {
  const PhoneVerificationPage({super.key});

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
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "휴대폰 번호를\n인증해 주세요",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text, height: 1.3),
              ),
              const SizedBox(height: 12),
              // 🚨 기획서 반영: 대타·근무표 알림 목적 명시
              Text(
                "대타 요청과 확정된 근무표 알림을 받을 번호를 확인해요.",
                style: TextStyle(fontSize: 15, color: ThymeColor.textSub),
              ),
              const SizedBox(height: 40),
              
              TextField(
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: "휴대폰 번호 (- 없이 입력)",
                  hintStyle: TextStyle(color: ThymeColor.disabled),
                  filled: true,
                  fillColor: ThymeColor.surfaceSub,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: ThymeColor.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {},
                  child: const Text("인증번호 받기", style: TextStyle(color: ThymeColor.text, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (context) => const TermsAgreementPage()));
                  }, child: Text("다음")),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}