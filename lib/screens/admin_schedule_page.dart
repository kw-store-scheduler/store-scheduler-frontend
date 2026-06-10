import 'package:flutter/material.dart';
import '../models/api_service.dart';

class AdminSchedulePage extends StatefulWidget {
  const AdminSchedulePage({super.key});

  @override
  State<AdminSchedulePage> createState() => _AdminSchedulePageState();
}

class _AdminSchedulePageState extends State<AdminSchedulePage> {
  bool _isAiCalculating = false;
  bool _isScheduleGenerated = false;
  final Color periwinkle = const Color(0xFF8E97FD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI 최적화 스케줄 생성"),
        backgroundColor: periwinkle,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("🚀 AI 엔진 가동", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            const Text("노동법과 알바생 가용 시간을 분석하여 최적의 스케줄을 계산합니다.", style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 20),
            
            SizedBox(
              width: double.infinity,
              height: 70,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isAiCalculating ? Colors.grey : const Color(0xFF10367D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: _isAiCalculating ? null : () async {
                  setState(() {
                    _isAiCalculating = true;
                    _isScheduleGenerated = false;
                  });
                  
                  bool success = await ApiService.requestAutoGenerate();
                  
                  setState(() {
                    _isAiCalculating = false;
                    _isScheduleGenerated = true;
                  });
                  
                  if (success && mounted) {
                    showDialog(
                      context: context, 
                      builder: (ctx) => AlertDialog(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        title: const Text("AI 생성 완료 🎉", style: TextStyle(fontWeight: FontWeight.bold)),
                        content: const Text("노동법 제약 조건을 모두 충족하는\n최적 스케줄이 생성되었습니다."),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text("결과 확인", style: TextStyle(fontWeight: FontWeight.bold, color: periwinkle)),
                          )
                        ],
                      ),
                    );
                  }
                },
                icon: _isAiCalculating 
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.auto_fix_high),
                label: Text(_isAiCalculating ? "AI 제약조건 분석 중..." : "엔진 가동 시작", 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            
            if (_isScheduleGenerated) ...[
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("🗓️ 확정 스케줄 (월요일)", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF10367D))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF3F744E), borderRadius: BorderRadius.circular(8)),
                    child: const Text("노동법 위반 0건", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                  )
                ],
              ),
              const SizedBox(height: 15),
              
              _buildResultCard(
                shiftName: "오전 교대 조 (09:00 ~ 13:00)",
                requiredCount: 2,
                assignedStaff: ["누리 (id: 4)", "참빛 (id: 1)"],
                cardColor: Colors.blue[50]!,
              ),
              _buildResultCard(
                shiftName: "오후 교대 조 (13:00 ~ 17:00)",
                requiredCount: 3,
                assignedStaff: ["참빛 (id: 1)", "새빛 (id: 2)", "한울 (id: 5)"],
                cardColor: Colors.orange[50]!,
              ),
              _buildResultCard(
                shiftName: "저녁 교대 조 (17:00 ~ 22:00)",
                requiredCount: 2,
                assignedStaff: ["비마 (id: 3)", "한울 (id: 5)"],
                cardColor: Colors.purple[50]!,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard({
    required String shiftName, 
    required int requiredCount, 
    required List<String> assignedStaff,
    required Color cardColor,
  }) {
    return Card(
      color: cardColor,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shiftName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 10),
            Row(
              children: [
                Text("배정 인원 ($requiredCount명 필요): ", style: const TextStyle(fontSize: 14, color: Colors.black54)),
                const SizedBox(width: 5),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: assignedStaff.map((staff) => Chip(
                      label: Text(staff, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.white,
                      side: BorderSide.none,
                    )).toList(),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}