import 'package:flutter/material.dart';
import '../../core/theme.dart';

class WorkerProfileConfirmPage extends StatefulWidget {
  const WorkerProfileConfirmPage({super.key});

  @override
  State<WorkerProfileConfirmPage> createState() => _WorkerProfileConfirmPageState();
}

class _WorkerProfileConfirmPageState extends State<WorkerProfileConfirmPage> {
  bool _canOpenAlone = false;
  bool _canCloseSettle = false;
  bool _hasKey = true;
  bool _hasOrderSystem = false;
  bool _isSkillApproved = false;

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
        title: const Text("김유나 · 알바 · 9/1 입사", style: TextStyle(color: ThymeColor.textSub, fontSize: 14, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              
              // 요약 스탯
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatCol("계약", "주 15~20h"),
                    _buildStatCol("시급", "₩10,320"),
                    _buildStatCol("수습", "~ 11/30"),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // 역량 승인 대기 박스 (로즈 계열 강조)
              if (!_isSkillApproved)
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: ThymeColor.dangerBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: ThymeColor.dangerBg),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.circle, size: 8, color: ThymeColor.danger),
                          SizedBox(width: 8),
                          Text("확인 대기: 중국어 중 · 상 신청", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text("학생회관 12~14시 중국어 필요 자리에 배치될 수 있어요.", style: TextStyle(fontSize: 12, color: ThymeColor.charcoal)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(child: OutlinedButton(style: OutlinedButton.styleFrom(side: BorderSide(color: ThymeColor.border), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))), onPressed: () {}, child: const Text("중으로 유지", style: TextStyle(color: ThymeColor.textSub, fontWeight: FontWeight.bold)))),
                          const SizedBox(width: 12),
                          Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: ThymeColor.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)), elevation: 0), onPressed: () => setState(() => _isSkillApproved = true), child: const Text("상으로 확정", style: TextStyle(color: ThymeColor.onPrimary, fontWeight: FontWeight.bold)))),
                        ],
                      ),
                    ],
                  ),
                ),
              
              if (!_isSkillApproved) const SizedBox(height: 32),

              // 매니저 권한 토글 리스트
              _buildToggleRow("혼자 오픈", _canOpenAlone, (val) => setState(() => _canOpenAlone = val)),
              const Divider(),
              _buildToggleRow("마감 정산", _canCloseSettle, (val) => setState(() => _canCloseSettle = val)),
              const Divider(),
              _buildToggleRow("매장 열쇠", _hasKey, (val) => setState(() => _hasKey = val)),
              const Divider(),
              _buildToggleRow("발주 시스템", _hasOrderSystem, (val) => setState(() => _hasOrderSystem = val)),
              
              const SizedBox(height: 32),
              
              // 고정 일정
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("고정 일정 대신 입력", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                  Text("수정 · 예외일 >", style: TextStyle(fontSize: 13, color: ThymeColor.textSub, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              Text("변경 이력 · 바꾸면 유나에게 알림이 가요.", style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
              const SizedBox(height: 8),
              Text("11/07  사장님 · 혼자 오픈 허용 (오픈 교육 1회 완료)", style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
              Text("09/01  사장님 · 수습 기간 3개월로 설정", style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCol(String title, String value) {
    return Column(
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: ThymeColor.textSub)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
      ],
    );
  }

  Widget _buildToggleRow(String title, bool value, Function(bool) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
          Switch(
            value: value,
            activeTrackColor: ThymeColor.primary, // 스위치 켜짐 = 딥 나이트
            activeThumbColor: ThymeColor.onPrimary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}