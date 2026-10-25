import 'package:flutter/material.dart';
import '../../core/theme.dart';

class WorkerApprovalPage extends StatelessWidget {
  const WorkerApprovalPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: AppBar(
        backgroundColor: ThymeColor.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: ThymeColor.text, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "승인 대기",
          style: TextStyle(color: ThymeColor.text, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 초대 코드 박스
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: ThymeColor.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: ThymeColor.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("초대 코드", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                      SizedBox(height: 8),
                      Text("NLXAYE", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ThymeColor.text, letterSpacing: 2)),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      // 클립보드에 코드 복사 기능 연결할 자리
                    },
                    icon: const Icon(Icons.copy, size: 16, color: ThymeColor.text),
                    label: const Text("링크 복사", style: TextStyle(color: ThymeColor.text, fontWeight: FontWeight.bold)),
                    style: TextButton.styleFrom(
                      backgroundColor: ThymeColor.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                        side: BorderSide(color: ThymeColor.border),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 32),

            // 승인 대기 목록 헤더
            Row(
              children: [
                const Text("승인 대기", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: ThymeColor.accent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text("2", style: TextStyle(color: ThymeColor.text, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 대기자 리스트
            _buildApprovalCard(
              name: "유나",
              info: "주 15시간 이상 · 주말 가능",
              date: "11/20 가입 요청",
            ),
            const SizedBox(height: 16),
            _buildApprovalCard(
              name: "대윤",
              info: "주 20시간 · 평일 마감 선호",
              date: "11/19 가입 요청",
            ),
          ],
        ),
      ),
    );
  }

  // 승인 대기자 카드 컴포넌트
  Widget _buildApprovalCard({required String name, required String info, required String date}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ThymeColor.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThymeColor.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: ThymeColor.bg,
                    radius: 20,
                    child: Text(
                      name[0], // 이름 첫 글자
                      style: const TextStyle(color: ThymeColor.text, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                      const SizedBox(height: 4),
                      Text(date, style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
                    ],
                  ),
                ],
              ),
              const Icon(Icons.chevron_right, color: ThymeColor.textSub),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Text(info, style: const TextStyle(fontSize: 13, color: ThymeColor.text)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    side: BorderSide(color: ThymeColor.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () {
                    // 거절 처리 로직 연결할 자리
                  },
                  child: const Text("거절", style: TextStyle(color: ThymeColor.textSub, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(onPressed: () {
                    // 승인 처리 및 시급/직급 설정 바텀시트 띄울 자리
                  }, child: Text("승인")),
              ),
            ],
          ),
        ],
      ),
    );
  }
}