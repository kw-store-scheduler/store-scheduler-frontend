import 'package:flutter/material.dart';
import '../models/api_service.dart';
import 'admin_schedule_page.dart';
import 'admin_setup_page.dart'; // 💡 새로 만든 설정 마법사 페이지를 불러옵니다!

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final Color periwinkle = const Color(0xFF8E97FD);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("광운대 빽다방 관리", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: periwinkle,
        actions: [
          // 💡 [추가된 부분] 톱니바퀴 버튼! 누르면 점장님 최초 설정 화면으로 이동합니다.
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminSetupPage()));
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 70,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10367D),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminSchedulePage()));
                },
                icon: const Icon(Icons.auto_fix_high),
                label: const Text("AI 스케줄 자동 생성 하러 가기", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
            
            const SizedBox(height: 40),
            const Text("📅 알바생 가용 시간 제출 현황", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            FutureBuilder<Map<String, List<Map<String, String>>>>(
              future: ApiService.getAllAvailabilities(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return LinearProgressIndicator(color: periwinkle);
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text("아직 가용 시간을 제출한 직원이 없습니다.");
                
                return Column(
                  children: snapshot.data!.entries.map((entry) {
                    String empName = entry.key;
                    List<Map<String, String>> times = entry.value;
                    if (times.isEmpty) return const SizedBox.shrink();
                    return Card(
                      color: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ExpansionTile(
                        leading: Icon(Icons.calendar_month, color: periwinkle),
                        title: Text("$empName 님의 제출 시간", style: const TextStyle(fontWeight: FontWeight.bold)),
                        children: times.map((t) => ListTile(
                          title: Text(t["day"]!),
                          trailing: Text(t["time"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
                        )).toList(),
                      ),
                    );
                  }).toList(),
                );
              },
            ),
            
            const SizedBox(height: 30),
            const Text("👥 등록된 알바생 현황 (총 5명)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            FutureBuilder<List<Employee>>(
              future: ApiService.fetchEmployees(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return LinearProgressIndicator(color: periwinkle);
                return Column(
                  children: snapshot.data!.map((e) => Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(backgroundColor: periwinkle.withOpacity(0.2), child: Icon(Icons.person, color: periwinkle)),
                      title: Text(e.name, style: const TextStyle(fontWeight: FontWeight.bold)), 
                      subtitle: Text("시급: ${e.hourlyWage}원"),
                    ),
                  )).toList(),
                );
              },
            ),
            
            const SizedBox(height: 30),
            const Text("⏰ 시간대별 필요 인원 세팅 기준", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            FutureBuilder<List<ShiftRequirement>>(
              future: ApiService.fetchShifts(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.5,
                  children: snapshot.data!.map((s) => Card(
                    color: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Center(
                      child: Text(
                        "${s.name}\n${s.time}\n(필요: ${s.requiredStaff}명)", 
                        textAlign: TextAlign.center, 
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}