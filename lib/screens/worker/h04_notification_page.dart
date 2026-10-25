import 'package:flutter/material.dart';
import '../../core/theme.dart';
// 행님이 이미 깎아두신 화면들 실전 임포트!
import 'h07_vacant_shift_board_page.dart'; // 대타 요청 ➔ 빈 근무 게시판
import 'w07_my_schedule_page.dart';        // 근무표 확정 ➔ 내 근무표

class NotificationPage extends StatelessWidget {
  const NotificationPage({super.key});

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
        title: const Text("알림", style: TextStyle(color: ThymeColor.text, fontSize: 16, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              // 모두 읽음 처리 로직 (상태관리 연동 시 구현)
            },
            child: const Text("모두 읽음", style: TextStyle(color: ThymeColor.textSub, fontSize: 14, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          children: [
            const Text("오늘", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
            const SizedBox(height: 12),
            
            // 대타 요청 (Rose)
            _buildNotificationItem(
              context,
              dotColor: ThymeColor.danger,
              backgroundColor: ThymeColor.dangerBg,
              title: "대타 요청 · 11/25(수) 마감 17~22시",
              content: "신은지 님 결원 · 가능하다고 한 2명에게 보냈어요",
              time: "08:40",
              targetPage: const VacantShiftBoardPage(), // 행님 파일로 이동!
            ),
            
            // 새 공지 (Periwinkle)
            _buildNotificationItem(
              context,
              dotColor: ThymeColor.info,
              backgroundColor: ThymeColor.surface,
              title: "새 공지 · 겨울 신메뉴 레시피",
              content: "사장님이 필독으로 올렸어요",
              time: "08:12",
              targetPage: const VacantShiftBoardPage(), // 공지 상세가 없으니 일단 빈 근무 게시판으로 매핑
            ),
            
            // 희망 제출 마감 (Yellow)
            _buildNotificationItem(
              context,
              dotColor: ThymeColor.warn,
              backgroundColor: ThymeColor.surface,
              title: "12월 희망 제출 마감 D-7",
              content: "지난달 답을 불러오면 1분이면 끝나요",
              time: "07:30",
              targetPage: const MySchedulePage(), // 마감 알림 클릭 시 스케줄 페이지로
            ),
            
            const SizedBox(height: 24),
            const Text("이번 주", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
            const SizedBox(height: 12),

            // 교대 요청 승인 (Mint)
            _buildNotificationItem(
              context,
              dotColor: ThymeColor.accent,
              backgroundColor: ThymeColor.surface,
              title: "교대 요청이 승인됐어요",
              content: "11/18(수) 마감 ➔ 우다현 님과 교대 · 수정된 근무표 확인",
              time: "11/17",
              targetPage: const MySchedulePage(), // 행님 파일로 이동!
            ),

            // 근무표 확정 (Mint)
            _buildNotificationItem(
              context,
              dotColor: ThymeColor.accent,
              backgroundColor: ThymeColor.surface,
              title: "11월 근무표가 확정됐어요",
              content: "10일 · 62.5시간 · 희망 반영 18/18",
              time: "10/28",
              targetPage: const MySchedulePage(), // 행님 파일로 이동!
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationItem(BuildContext context, {required Color dotColor, required Color backgroundColor, required String title, required String content, required String time, required Widget targetPage}) {
    return GestureDetector(
      onTap: () {
        // 주석 없음! 바로 실제 페이지로 꽂아버립니다 행님!
        Navigator.push(context, MaterialPageRoute(builder: (context) => targetPage));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: backgroundColor == ThymeColor.surface ? Border.all(color: ThymeColor.border) : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: Icon(Icons.circle, size: 8, color: dotColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text))),
                      Text(time, style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(content, style: TextStyle(fontSize: 13, color: ThymeColor.charcoal, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}