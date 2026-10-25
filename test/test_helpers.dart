import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thyme_frontend/theme/thyme_theme.dart';

/// 테스트 기본 폰트는 글자가 전부 정사각형이라 실제보다 넓다.
/// Windows의 맑은 고딕이 있으면 실제와 비슷한 폭으로 레이아웃을 잰다.
String _family = 'IBM Plex Sans KR';

Future<void> loadTestFonts() async {
  // 테스트 환경에서는 폰트를 내려받지 않는다
  GoogleFonts.config.allowRuntimeFetching = false;
  final regular = File('C:/Windows/Fonts/malgun.ttf');
  final bold = File('C:/Windows/Fonts/malgunbd.ttf');
  if (regular.existsSync() && bold.existsSync()) {
    final loader = FontLoader('Malgun')
      ..addFont(Future.value(ByteData.sublistView(regular.readAsBytesSync())))
      ..addFont(Future.value(ByteData.sublistView(bold.readAsBytesSync())));
    await loader.load();
    _family = 'Malgun';
  }
}

/// 390×844 (가이드 4-1 기준 화면) 에서 앱 테마로 화면을 띄운다
Future<void> pumpScreen(WidgetTester tester, Widget home) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final theme = ThymeTheme.light();
  await tester.pumpWidget(MaterialApp(
    theme: theme.copyWith(textTheme: theme.textTheme.apply(fontFamily: _family)),
    home: home,
  ));
}
