import 'package:flutter_test/flutter_test.dart';
import 'package:thyme_frontend/models/preference.dart';

void main() {
  test('enum 이름을 서버 형식(UPPER_SNAKE)으로 바꾼다', () {
    expect(toServerEnum(PreferencePriority.dayOff), 'DAY_OFF');
    expect(toServerEnum(FixedScheduleCategory.otherJob), 'OTHER_JOB');
    expect(fromServerEnum(PreferenceLevel.values, 'PREFERRED'), PreferenceLevel.preferred);
  });

  test('초안을 PUT /preferences/my 본문으로 만든다', () {
    final draft = PreferenceDraft(month: DateTime(2026, 11))
      ..setSlot(DateTime(2026, 11, 3, 15), 1, PreferenceLevel.preferred) // 시각은 버리고 날짜만 본다
      ..setSlot(DateTime(2026, 11, 3), 2, PreferenceLevel.available)
      ..setSlot(DateTime(2026, 11, 4), 1, PreferenceLevel.available)
      ..setSlot(DateTime(2026, 11, 4), 1, null) // 다시 눌러 불가로
      ..maxWeekendShifts = 2
      ..priorities = [PreferencePriority.weekend, PreferencePriority.dayOff];

    final json = draft.toJson();
    expect(json['slots'], [
      {'date': '2026-11-03', 'shiftId': 1, 'level': 'PREFERRED'},
      {'date': '2026-11-03', 'shiftId': 2, 'level': 'AVAILABLE'},
    ]);
    expect(json['maxWeekendShifts'], 2);
    expect(json.containsKey('minMonthlyHours'), isFalse); // 안 고른 규칙은 보내지 않는다
    expect(json['priorities'], ['WEEKEND', 'DAY_OFF']);
    expect(monthParam(draft.month), '2026-11');
  });

  test('지난달 답으로 초안을 채울 때 잠긴 칸은 건너뛴다', () {
    final month = PreferenceMonth.fromJson({
      'month': '2026-11',
      'deadline': '2026-10-28',
      'submitted': false,
      'shifts': [
        {'id': 1, 'name': '오픈', 'startTime': '09:00:00', 'endTime': '14:00:00'},
      ],
      'cells': [
        {'date': '2026-11-02', 'shiftId': 1, 'level': 'AVAILABLE', 'locked': false},
        {'date': '2026-11-03', 'shiftId': 1, 'level': 'PREFERRED', 'locked': true, 'lockLabel': '수업'},
        {'date': '2026-11-04', 'shiftId': 1, 'level': null, 'locked': false},
      ],
      'submission': {'maxWeekendShifts': 3, 'priorities': ['HOURS']},
    });
    final draft = PreferenceDraft(month: DateTime(2026, 11))..fillFrom(month);
    expect(draft.slots.length, 1);
    expect(draft.slotAt(DateTime(2026, 11, 2), 1), PreferenceLevel.available);
    expect(draft.maxWeekendShifts, 3);
    expect(draft.priorities, [PreferencePriority.hours]);
  });
}
