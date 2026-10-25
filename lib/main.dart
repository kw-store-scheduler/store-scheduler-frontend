import 'package:flutter/material.dart';
import 'core/theme.dart';

void main() {
  runApp(const ThymeApp());
}

class ThymeApp extends StatelessWidget {
  const ThymeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Thyme',
      theme: thymeTheme,
      home: const Scaffold(
        body: Center(
          child: Text(
            'Thyme 앱 뼈대 세팅 완료',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}