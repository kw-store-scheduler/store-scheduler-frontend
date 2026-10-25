import 'preference.dart';

/// 로그인하지 않은 시연용 데이터. 서버 응답(GET /preferences/my)과 같은 모양이라
/// 화면은 서버가 있든 없든 같은 코드로 그린다.
///
/// 시안 W02 예시: 월·목 오픈·미들은 수업으로 잠김, 지난달에는 평일 오픈 선호·미들 가능.
PreferenceMonth demoPreferenceMonth(DateTime month) {
  const shifts = [
    ShiftSummary(id: 1, name: '오픈', startTime: '09:00:00', endTime: '14:00:00'),
    ShiftSummary(id: 2, name: '미들', startTime: '12:00:00', endTime: '18:00:00'),
    ShiftSummary(id: 3, name: '마감', startTime: '17:00:00', endTime: '22:00:00'),
  ];
  final days = DateTime(month.year, month.month + 1, 0).day;
  final cells = <PreferenceCell>[];
  for (var d = 1; d <= days; d++) {
    final date = DateTime(month.year, month.month, d);
    final classDay = date.weekday == DateTime.monday || date.weekday == DateTime.thursday;
    final weekday = date.weekday <= DateTime.friday;
    for (final s in shifts) {
      final locked = classDay && s.id != 3;
      final PreferenceLevel? last = locked || !weekday
          ? null
          : switch (s.id) { 1 => PreferenceLevel.preferred, 2 => PreferenceLevel.available, _ => null };
      cells.add(PreferenceCell(date: date, shiftId: s.id, level: last, locked: locked, lockLabel: locked ? '수업' : null));
    }
  }
  return PreferenceMonth(
    month: monthParam(month),
    deadline: DateTime(month.year, month.month, 0).subtract(const Duration(days: 4)),
    submitted: false,
    shifts: shifts,
    cells: cells,
    submission: const {
      'maxWeekendShifts': 2,
      'minMonthlyHours': 64,
      'maxMonthlyHours': 86,
      'maxConsecutiveDays': 3,
      'noOpenAfterClose': true,
      // 직원(W04) 시안: 오픈 선호 · 미들 상관없음 · 마감 피하고 싶음, 휴무 이틀 붙이기
      'shiftAttitudes': {'1': 'PREFER', '2': 'NEUTRAL', '3': 'AVOID'},
      'restDaysTogether': true,
    },
  );
}
