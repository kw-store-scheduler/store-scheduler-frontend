import 'dart:async';

class Employee {
  final int id;
  final String name;
  final int hourlyWage;
  Employee({required this.id, required this.name, required this.hourlyWage});
}

class ShiftRequirement {
  final String name;
  final String time;
  final int requiredStaff;
  ShiftRequirement({required this.name, required this.time, required this.requiredStaff});
}

class ApiService {
  static final Map<String, List<Map<String, String>>> _mockTimeDB = {};

  // 매장 기본 설정 데이터 전송
  static Future<void> saveStoreSettings(Map<String, dynamic> storeData) async {
    await Future.delayed(const Duration(milliseconds: 500));
    print("🔔 [시스템] 매장 운영 정책 설정 완료: $storeData");
  }

  // 직원 개인별 선호도 데이터 전송
  static Future<void> saveEmployeeSettings(String name, Map<String, dynamic> empData) async {
    await Future.delayed(const Duration(milliseconds: 500));
    print("🔔 [시스템] $name 님의 근무 성향 등록 완료: $empData");
    
    _mockTimeDB[name] = [
      {"day": "출근 가능일", "time": empData['available_days'].join(', ')},
      {"day": "특별 휴무", "time": "${empData['off_requests'].length}일 신청됨"},
      {"day": "선호 시간대", "time": empData['preferred_shifts'].join(', ')},
      {"day": "집중 패턴", "time": "${empData['work_focus']}"},
    ];
  }

  static Future<List<Map<String, String>>> getUserTimes(String name) async {
    await Future.delayed(const Duration(milliseconds: 300));
    return List<Map<String, String>>.from(_mockTimeDB[name] ?? []);
  }

  static Future<Map<String, List<Map<String, String>>>> getAllAvailabilities() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockTimeDB;
  }

  static Future<List<Employee>> fetchEmployees() async {
    await Future.delayed(const Duration(milliseconds: 500)); 
    return [
      Employee(id: 1, name: "참빛", hourlyWage: 9860),
      Employee(id: 2, name: "새빛", hourlyWage: 9860),
      Employee(id: 3, name: "비마", hourlyWage: 9860),
      Employee(id: 4, name: "누리", hourlyWage: 9860),
      Employee(id: 5, name: "한울", hourlyWage: 9860),
    ];
  }

  static Future<List<ShiftRequirement>> fetchShifts() async {
    return [
      ShiftRequirement(name: "오픈", time: "09:00 - 13:00", requiredStaff: 2),
      ShiftRequirement(name: "오후", time: "13:00 - 17:00", requiredStaff: 3),
      ShiftRequirement(name: "마감", time: "17:00 - 22:00", requiredStaff: 2),
    ];
  }

  static Future<bool> requestAutoGenerate() async {
    await Future.delayed(const Duration(seconds: 2)); 
    return true; 
  }
}