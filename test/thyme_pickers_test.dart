import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thyme_frontend/widgets/thyme_pickers.dart';

import 'test_helpers.dart';

/// 공통 입력 시트 (시계 다이얼·전체 화면 달력 대신, 2026-11 UI 점검)
void main() {
  setUpAll(loadTestFonts);

  /// [open] 을 누르면 시트를 띄우고, 돌아온 값을 [result] 에 담는 화면
  Future<void> host(WidgetTester tester, Future<Object?> Function(BuildContext) open, void Function(Object?) result) async {
    await pumpScreen(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(child: FilledButton(onPressed: () async => result(await open(context)), child: const Text('OPEN'))),
        ),
      ),
    );
    await tester.tap(find.text('OPEN'));
    await tester.pumpAndSettle();
  }

  testWidgets('시간: 직접 입력에 숫자만 쳐도 된다 (930 → 09:30)', (tester) async {
    Object? got;
    await host(tester, (c) => showThymeTimePicker(c, initial: const TimeOfDay(hour: 9, minute: 0), title: '출근 시각'), (v) => got = v);
    expect(find.text('09'), findsWidgets); // 휠에 지금 값 (시)
    await tester.tap(find.text('직접 입력'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '930');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(got, const TimeOfDay(hour: 9, minute: 30));
  });

  testWidgets('시간: 이상한 값이면 닫지 않고 알려 준다', (tester) async {
    Object? got = 'untouched';
    await host(tester, (c) => showThymeTimePicker(c, initial: const TimeOfDay(hour: 9, minute: 0)), (v) => got = v);
    await tester.tap(find.text('직접 입력'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '2575');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(find.text('시간을 09:30 처럼 적어 주세요'), findsOneWidget);
    expect(got, 'untouched');
  });

  testWidgets('시간 범위: 시작·끝을 한 시트에서', (tester) async {
    Object? got;
    await host(
        tester,
        (c) => showThymeTimeRangePicker(c, start: const TimeOfDay(hour: 9, minute: 0), end: const TimeOfDay(hour: 13, minute: 0), title: '수업 시간'),
        (v) => got = v);
    expect(find.text('시작'), findsOneWidget);
    expect(find.text('끝'), findsOneWidget);
    await tester.tap(find.text('직접 입력'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '10:30');
    await tester.enterText(find.byType(TextField).at(1), '1500');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(got, (const TimeOfDay(hour: 10, minute: 30), const TimeOfDay(hour: 15, minute: 0)));
  });

  testWidgets('숫자: 범위 밖이면 알려 주고, 맞으면 돌려준다', (tester) async {
    Object? got;
    await host(tester, (c) => showThymeNumberInput(c, title: '이번 달 최대', initial: 80, min: 0, max: 250, unit: '시간'), (v) => got = v);
    await tester.enterText(find.byType(TextField), '300');
    await tester.tap(find.text('확인'));
    await tester.pump();
    expect(find.text('0~250시간 사이로 적어 주세요'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '120');
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(got, 120);
  });

  testWidgets('기간: 시작 → 끝 두 번 누르면 사이가 칠해지고 며칠인지 보인다', (tester) async {
    Object? got;
    final first = DateTime(2026, 12, 1);
    await host(tester, (c) => showThymeDateRangePicker(c, first: first, last: DateTime(2027, 1, 31), title: '못 나오는 기간'), (v) => got = v);
    expect(find.text('시작일을 골라 주세요'), findsOneWidget);
    expect(tester.widget<FilledButton>(find.widgetWithText(FilledButton, '확인')).onPressed, isNull);

    await tester.tap(find.byKey(thymeDayKey(DateTime(2026, 12, 14))));
    await tester.pump();
    expect(find.textContaining('12/14(월) ~ 끝나는 날을 골라 주세요'), findsOneWidget);
    await tester.tap(find.byKey(thymeDayKey(DateTime(2026, 12, 18))));
    await tester.pump();
    expect(find.text('12/14(월) ~ 12/18(금) · 5일'), findsOneWidget);

    // 끝보다 앞을 다시 누르면 새로 시작
    await tester.tap(find.byKey(thymeDayKey(DateTime(2026, 12, 2))));
    await tester.pump();
    expect(find.textContaining('12/2(수) ~ 끝나는 날을'), findsOneWidget);
    await tester.tap(find.byKey(thymeDayKey(DateTime(2026, 12, 4))));
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(got, DateTimeRange(start: DateTime(2026, 12, 2), end: DateTime(2026, 12, 4)));
  });

  testWidgets('기간: 끝을 안 고르고 확인하면 하루', (tester) async {
    Object? got;
    await host(tester, (c) => showThymeDateRangePicker(c, first: DateTime(2026, 12, 1), last: DateTime(2026, 12, 31)), (v) => got = v);
    await tester.tap(find.byKey(thymeDayKey(DateTime(2026, 12, 25))));
    await tester.pump();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(got, DateTimeRange(start: DateTime(2026, 12, 25), end: DateTime(2026, 12, 25)));
  });

  testWidgets('날짜 하나: 고를 수 없는 날은 눌러도 안 골라지고, 공휴일은 이름이 읽힌다', (tester) async {
    Object? got;
    await host(
      tester,
      (c) => showThymeDatePicker(
        c,
        first: DateTime(2026, 12, 1),
        last: DateTime(2026, 12, 31),
        selectable: (d) => d.day != 10, // 이미 낸 날
        holidays: (y) async => {DateTime(2026, 12, 25): '기독탄신일'},
      ),
      (v) => got = v,
    );
    final semantics = tester.ensureSemantics();
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(thymeDayKey(DateTime(2026, 12, 10))));
    await tester.pump();
    expect(find.text('날짜를 골라 주세요'), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('12월 25일 기독탄신일')), findsOneWidget);
    semantics.dispose();
    await tester.tap(find.byKey(thymeDayKey(DateTime(2026, 12, 11))));
    await tester.pump();
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(got, DateTime(2026, 12, 11));
  });

  testWidgets('먼 날짜: 휠 시트는 지금 값을 그대로 돌려준다', (tester) async {
    Object? got;
    await host(tester, (c) => showThymeDateWheel(c, initial: DateTime(2024, 3, 2), first: DateTime(2021), last: DateTime(2027, 12, 31), title: '근무 시작일'),
        (v) => got = v);
    expect(find.text('2024. 3. 2 (토)'), findsOneWidget);
    await tester.tap(find.text('확인'));
    await tester.pumpAndSettle();
    expect(got, DateTime(2024, 3, 2));
  });
}
