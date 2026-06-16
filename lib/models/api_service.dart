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
  static const String baseUrl = "https://bless-sensually-viewpoint.ngrok-free.dev"; 
  static final Map<String, List<Map<String, String>>> _mockTimeDB = {};

  static Future<void> saveStoreSettings(Map<String, dynamic> storeData) async {
    final url = Uri.parse("$baseUrl/api/store/settings");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(storeData),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("[System] Store settings sent to server successfully.");
      } else {
        print("[Server Error] Status Code: ${response.statusCode}");
      }
    } catch (e) {
      print("[System] Connection failed. Local debugging mode active.");
    }
  }

  static Future<void> saveEmployeeSettings(String name, Map<String, dynamic> empData) async {
    final url = Uri.parse("$baseUrl/api/employee/settings");
    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"name": name, ...empData}),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        print("[System] Employee settings for $name sent to server successfully.");
      }
    } catch (e) {
      print("[System] Connection failed. Saved to local mock database: $name");
      _mockTimeDB[name] = [
        {"day": "출근 가능일", "time": empData['available_days'].join(', ')},
        {"day": "특별 휴무", "time": "${empData['off_requests'].length}일 신청됨"},
        {"day": "선호 시간대", "time": empData['preferred_shifts'].join(', ')},
        {"day": "집중 패턴", "time": "${empData['work_focus']}"},
      ];
    }
  }

  static Future<List<Map<String, String>>> getUserTimes(String name) async {
    final url = Uri.parse("$baseUrl/api/employee/availability/$name");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Map<String, String>.from(e)).toList();
      }
    } catch (e) {
      print("[Warning] Server fetch failed. Returning local mock data.");
    }
    return List<Map<String, String>>.from(_mockTimeDB[name] ?? []);
  }

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
      print("[Warning] Server fetch failed. Showing local data status.");
    }
    return _mockTimeDB;
  }

  static Future<List<Employee>> fetchEmployees() async {
    final url = Uri.parse("$baseUrl/api/employees");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Employee.fromJson(json)).toList();
      }
    } catch (e) {
      print("[Warning] Connection failed. Outputting default employee list.");
    }
    return [
      Employee(id: 1, name: "참빛", hourlyWage: 9860),
      Employee(id: 2, name: "새빛", hourlyWage: 9860),
      Employee(id: 3, name: "비마", hourlyWage: 9860),
      Employee(id: 4, name: "누리", hourlyWage: 9860),
      Employee(id: 5, name: "한울", hourlyWage: 9860),
    ];
  }

  static Future<List<ShiftRequirement>> fetchShifts() async {
    final url = Uri.parse("$baseUrl/api/shifts");
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => ShiftRequirement.fromJson(json)).toList();
      }
    } catch (e) {
      print("[Warning] Connection failed. Outputting default shift requirements.");
    }
    return [
      ShiftRequirement(name: "오픈", time: "09:00 - 13:00", requiredStaff: 2),
      ShiftRequirement(name: "오후", time: "13:00 - 17:00", requiredStaff: 3),
      ShiftRequirement(name: "마감", time: "17:00 - 22:00", requiredStaff: 2),
    ];
  }

  static Future<bool> requestAutoGenerate() async {
    final url = Uri.parse("$baseUrl/api/schedules/automate"); 
    try {
      print("[FE] Sending automated schedule generation request to: $baseUrl");
      
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({}), 
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print("[BE Communication Success] Server responded successfully.");
        return true; 
      } else {
        print("[BE Error] Status Code: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("[Network Error] Connection failed: $e");
      return true; 
    }
  }
}