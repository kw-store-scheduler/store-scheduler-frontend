import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class Employee {
  final int id;
  final String name;
  final int hourlyWage;
  Employee({required this.id, required this.name, required this.hourlyWage});

  factory Employee.fromJson(Map<String, dynamic> json) {
    return Employee(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      hourlyWage: json['hourlyWage'] ?? 9860,
    );
  }
}

class ShiftRequirement {
  final String name;
  final String time;
  final int requiredStaff;
  ShiftRequirement({required this.name, required this.time, required this.requiredStaff});

  factory ShiftRequirement.fromJson(Map<String, dynamic> json) {
    return ShiftRequirement(
      name: json['name'] ?? '',
      time: json['time'] ?? '',
      requiredStaff: json['requiredStaff'] ?? 0,
    );
  }
}

class ApiService {
  static const String baseUrl = "http://192.168.0.3:8080"; 
  static final Map<String, List<Map<String, String>>> _mockTimeDB = {};

  // 1. 매장 기본 설정 데이터 전송 (POST)
  static Future<void> saveStoreSettings(Map<String, dynamic> storeData) async {
    final url = Uri.parse("$baseUrl/api/store/settings");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(storeData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("🔔 [시스템] 매장 운영 정책 서버 전송 완료");
      } else {
        print("❌ [서버 에러] 매장 설정 실패: ${response.statusCode}");
      }
    } catch (e) {
      print("🔔 [시스템] 서버 연결 실패 (로컬 디버깅 모드): $storeData");
    }
  }

  // 2. 직원 개인별 선호도 데이터 전송 (POST)
  static Future<void> saveEmployeeSettings(String name, Map<String, dynamic> empData) async {
    final url = Uri.parse("$baseUrl/api/employee/settings");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, ...empData}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("🔔 [시스템] $name 님의 근무 성향 서버 등록 완료");
      }
    } catch (e) {
      print("🔔 [시스템] 서버 연결 실패 (로컬 가용성 DB 등록): $name");
      _mockTimeDB[name] = [
        {"day": "출근 가능일", "time": empData['available_days'].join(', ')},
        {"day": "특별 휴무", "time": "${empData['off_requests'].length}일 신청됨"},
        {"day": "선호 시간대", "time": empData['preferred_shifts'].join(', ')},
        {"day": "집중 패턴", "time": "${empData['work_focus']}"},
      ];
    }
  }

  // 3. 특정 직원 가용 시간 조회 (GET)
  static Future<List<Map<String, String>>> getUserTimes(String name) async {
    final url = Uri.parse("$baseUrl/api/employee/availability/$name");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, String>.from(e)).toList();
      }
    } catch (e) {
      print("⚠️ 서버 조회 실패로 기존 로컬 데이터를 반환합니다.");
    }
    return List<Map<String, String>>.from(_mockTimeDB[name] ?? []);
  }

  // 4. 모든 직원 가용 시간 현황 조회 (GET)
  static Future<Map<String, List<Map<String, String>>>> getAllAvailabilities() async {
    final url = Uri.parse("$baseUrl/api/employee/availability/all");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        Map<String, dynamic> data = jsonDecode(response.body);
        Map<String, List<Map<String, String>>> result = {};
        data.forEach((key, value) {
          result[key] = (value as List).map((e) => Map<String, String>.from(e)).toList();
        });
        return result;
      }
    } catch (e) {
      print("⚠️ 서버 조회 실패로 로컬 가용 시간 현황을 보여줍니다.");
    }
    return _mockTimeDB;
  }

  // 5. 등록된 알바생 현황 목록 조회 (GET)
  static Future<List<Employee>> fetchEmployees() async {
    final url = Uri.parse("$baseUrl/api/employees");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Employee.fromJson(json)).toList();
      }
    } catch (e) {
      print("⚠️ 서버 연결 실패로 기본 알바생 목록을 출력합니다.");
    }
    return [
      Employee(id: 1, name: "참빛", hourlyWage: 9860),
      Employee(id: 2, name: "새빛", hourlyWage: 9860),
      Employee(id: 3, name: "비마", hourlyWage: 9860),
      Employee(id: 4, name: "누리", hourlyWage: 9860),
      Employee(id: 5, name: "한울", hourlyWage: 9860),
    ];
  }

  // 6. 시간대별 필요 인원 기준 조회 (GET)
  static Future<List<ShiftRequirement>> fetchShifts() async {
    final url = Uri.parse("$baseUrl/api/shifts");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ShiftRequirement.fromJson(json)).toList();
      }
    } catch (e) {
      print("⚠️ 서버 연결 실패로 기본 필요 인원 세팅을 출력합니다.");
    }
    return [
      ShiftRequirement(name: "오픈", time: "09:00 - 13:00", requiredStaff: 2),
      ShiftRequirement(name: "오후", time: "13:00 - 17:00", requiredStaff: 3),
      ShiftRequirement(name: "마감", time: "17:00 - 22:00", requiredStaff: 2),
    ];
  }

  // 7. AI 스케줄 자동 생성 트리거 API 호출 (POST)
  static Future<bool> requestAutoGenerate() async {
    final url = Uri.parse("$baseUrl/api/schedule/generate"); 
    try {
      print("🚀 [FE] 백엔드 서버($baseUrl)로 AI 스케줄 생성 요청을 보냅니다...");
      
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"status": "start_request"}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("🟩 [BE 통신 성공] 백엔드 응답 완료!");
        return true; 
      } else {
        print("❌ [BE 에러] 상태코드: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ [네트워크 에러] 연결 실패: $e");
      return true; 
    }
  }
}