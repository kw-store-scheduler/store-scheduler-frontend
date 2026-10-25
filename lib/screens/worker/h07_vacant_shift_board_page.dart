import 'package:flutter/material.dart';
import '../../widgets/thyme_back_button.dart';
import '../../core/theme.dart';
import 'h12_absence_report_page.dart';

class VacantShiftBoardPage extends StatefulWidget {
  const VacantShiftBoardPage({super.key});

  @override
  State<VacantShiftBoardPage> createState() => _VacantShiftBoardPageState();
}

class _VacantShiftBoardPageState extends State<VacantShiftBoardPage> {
  // 지원 상태 관리 (0: 불가, 1: 지원 가능, 2: 지원 완료)
  // 샘플 데이터 상태
  int _status1 = 1; // 첫 번째 카드 (결원)
  int _status2 = 2; // 두 번째 카드 (지원함)
  int _status3 = 1; // 세 번째 카드 (단체 손님)
  
  // 상태 변경 함수 (플러터 잔소리 방지용 중괄호 추가 완료!)
  void _toggleApply(int cardIndex) {
    setState(() {
      if (cardIndex == 1 && _status1 == 1) {
        _status1 = 2;
      } else if (cardIndex == 1 && _status1 == 2) {
        _status1 = 1;
      }
      
      if (cardIndex == 2 && _status2 == 1) {
        _status2 = 2;
      } else if (cardIndex == 2 && _status2 == 2) {
        _status2 = 1;
      }
      
      if (cardIndex == 3 && _status3 == 1) {
        _status3 = 2;
      } else if (cardIndex == 3 && _status3 == 2) {
        _status3 = 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: AppBar(
        backgroundColor: ThymeColor.bg,
        elevation: 0,
        leading: ThymeBackButton(size: 20),
        title: const Text(
          "빈 근무",
          style: TextStyle(color: ThymeColor.text, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  side: BorderSide(color: ThymeColor.border),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                // 내 근무 내놓기 = H12 오늘 못 나가요
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AbsenceReportPage())),
                child: const Text("내 근무 내놓기", style: TextStyle(color: ThymeColor.text, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 내 이번 주 요약
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("이번 주 4일 · 22시간 근무 중", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: ThymeColor.surfaceSub,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text("한도까지 1일", style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 빈 근무 카드 리스트
            _buildVacantCard(
              tag: "결원 · 급구",
              isUrgent: true,
              date: "11/25(수) 인호 결원",
              time: "17:00~22:00",
              desc: "누구나 · 규칙 통과",
              pay: "₩51,600",
              status: _status1,
              onTap: () => _toggleApply(1),
            ),
            const SizedBox(height: 16),
            
            _buildVacantCard(
              tag: "추가 인원",
              isUrgent: false,
              date: "11/28(토) 내일쇼",
              time: "18:00~22:00",
              desc: "누구나 규칙 통과",
              pay: "₩41,280",
              status: _status2,
              onTap: () => _toggleApply(2),
            ),
            const SizedBox(height: 16),

            _buildVacantCard(
              tag: "단체 손님",
              isUrgent: false,
              date: "12/05(토) 예약 20명",
              time: "12:00~14:00",
              desc: "중국어 가능자 우대 · 내 역량 맞음",
              pay: "₩20,640",
              status: _status3,
              onTap: () => _toggleApply(3),
            ),
            const SizedBox(height: 16),

            _buildVacantCard(
              tag: "추가 인원",
              isUrgent: false,
              date: "11/27(금) 저녁 피크",
              time: "18:00~20:00",
              desc: "금요일 18시에 내 고정 일정이에요",
              pay: "₩20,640",
              status: 0, // 0: 불가 상태 (고정)
              onTap: () {},
            ),
            
            const SizedBox(height: 32),
            // 하단 설명
            Text(
              "지원하면 사장님이 고르고, 승인되면 근무표와 수당이 바로 바뀌어요. 규칙에 걸리는 근무는 지원할 수 없어요.",
              style: TextStyle(fontSize: 12, color: ThymeColor.disabled, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // 빈 근무 카드 컴포넌트
  Widget _buildVacantCard({
    required String tag,
    required bool isUrgent,
    required String date,
    required String time,
    required String desc,
    required String pay,
    required int status, // 0: 불가, 1: 지원하기, 2: 지원함
    required VoidCallback onTap,
  }) {
    bool isUnavailable = status == 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isUnavailable ? ThymeColor.surfaceSub : ThymeColor.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: ThymeColor.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isUnavailable ? ThymeColor.border : (isUrgent ? ThymeColor.danger.withValues(alpha: 0.1) : ThymeColor.surfaceSub),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    if (isUrgent && !isUnavailable) ...[
                      Container(width: 4, height: 4, decoration: const BoxDecoration(color: ThymeColor.danger, shape: BoxShape.circle)),
                      const SizedBox(width: 4),
                    ],
                    Text(
                      tag,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isUnavailable ? ThymeColor.textSub : (isUrgent ? ThymeColor.danger : ThymeColor.textSub),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                date,
                style: TextStyle(fontSize: 13, color: isUnavailable ? ThymeColor.disabled : ThymeColor.textSub),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            time,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isUnavailable ? ThymeColor.disabled : ThymeColor.text,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            desc,
            style: TextStyle(
              fontSize: 12,
              color: isUnavailable ? ThymeColor.danger.withValues(alpha: 0.7) : ThymeColor.textSub,
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                pay,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isUnavailable ? ThymeColor.disabled : ThymeColor.text,
                ),
              ),
              if (status == 1) // 지원 가능
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ThymeColor.primary,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  onPressed: onTap,
                  child: const Text("지원하기", style: TextStyle(color: ThymeColor.onPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                )
              else if (status == 2) // 지원 완료
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    side: BorderSide(color: ThymeColor.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: onTap, // 다시 누르면 취소되게 임시 연결
                  icon: const Icon(Icons.check, size: 16, color: ThymeColor.textSub),
                  label: const Text("지원함", style: TextStyle(color: ThymeColor.textSub, fontWeight: FontWeight.bold, fontSize: 13)),
                )
              else // 불가
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Text("불가", style: TextStyle(color: ThymeColor.textSub, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}