import 'package:flutter/material.dart';
import 'screens/employee_page.dart';

void main() => runApp(const SchedulingApp());

class SchedulingApp extends StatelessWidget {
  const SchedulingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // 페리윙클 블루 계열 (#8E97FD) 메인 컬러 세팅
        primaryColor: const Color(0xFF8E97FD),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF8E97FD),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        // 배경색을 아주 연한 쿨 화이트/블루로 변경 (#F8F9FF)
        scaffoldBackgroundColor: const Color(0xFFF8F9FF),
        fontFamily: 'Pretendard',
      ),
      home: const EmployeePage(),
    );
  }
}