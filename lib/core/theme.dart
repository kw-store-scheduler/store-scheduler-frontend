import 'package:flutter/material.dart';

class ThymeColor {
  static const Color deepNight = Color(0xFF1A1D29);
  static const Color neutralBase = Color(0xFFF4F5F7);
  static const Color mint = Color(0xFF34C78F);
  static const Color rose = Color(0xFFF05B72);
  static const Color periwinkle = Color(0xFF8E97FD);
  static const Color yellow = Color(0xFFFFD166);
  static const Color textGrey = Color(0xFF8A8E9B);
}

final ThemeData thymeTheme = ThemeData(
  scaffoldBackgroundColor: ThymeColor.neutralBase,
  primaryColor: ThymeColor.deepNight,
  appBarTheme: const AppBarTheme(
    backgroundColor: ThymeColor.deepNight,
    elevation: 0,
    foregroundColor: Colors.white,
    centerTitle: true,
  ),
  fontFamily: 'Pretendard', // 폰트는 추후 펍스펙(pubspec.yaml)에 추가 필요
);