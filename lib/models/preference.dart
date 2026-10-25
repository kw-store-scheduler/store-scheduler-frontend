// 희망 제출(W00~W14) 모델. 백엔드 PreferenceController의 요청·응답과 필드 이름이 같다.

/// 날짜×교대 칸 상태. 서버는 가능/선호만 저장하고, 보내지 않은 칸은 불가로 본다
enum PreferenceLevel { available, preferred }

/// 희망끼리 부딪힐 때 지킬 순서 (W14). 앞에 둔 항목일수록 엔진 패널티 배율이 커진다
enum PreferencePriority {
  dayOff('희망 휴무'),
  shift('선호 교대'),
  weekend('주말 횟수'),
  hours('이번 달 근무량'),
  rhythm('근무 리듬');

  const PreferencePriority(this.label);
  final String label;
}

/// 정규직 교대 선호 (W04)
enum ShiftAttitude { prefer, neutral, avoid }

/// 고정 일정 분류 (W11). 다른 직장 시간은 주 52시간 한도에 합산된다
enum FixedScheduleCategory {
  study('학업'),
  otherJob('다른 직장'),
  care('돌봄·통학'),
  other('기타');

  const FixedScheduleCategory(this.label);
  final String label;
}

/// Dart enum 이름(camelCase) ↔ 서버 enum 이름(UPPER_SNAKE)
String toServerEnum(Enum e) => e.name.replaceAllMapped(RegExp('[A-Z]'), (m) => '_${m[0]}').toUpperCase();

T fromServerEnum<T extends Enum>(List<T> values, String raw) =>
    values.firstWhere((v) => toServerEnum(v) == raw, orElse: () => throw FormatException('알 수 없는 값: $raw'));

DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String _date(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// 서버 쿼리용 yyyy-MM
String monthParam(DateTime month) => '${month.year.toString().padLeft(4, '0')}-${month.month.toString().padLeft(2, '0')}';

/// 매장 교대 (O03에서 점주가 만든 것)
class ShiftSummary {
  const ShiftSummary({required this.id, required this.name, required this.startTime, required this.endTime});

  final int id;
  final String name;
  final String startTime; // "09:00:00"
  final String endTime;

  factory ShiftSummary.fromJson(Map<String, dynamic> j) => ShiftSummary(
      id: j['id'] as int, name: j['name'] as String, startTime: j['startTime'] as String, endTime: j['endTime'] as String);
}

/// 날짜×교대 칸 하나. locked면 고정 일정과 겹쳐서 고를 수 없다
class PreferenceCell {
  const PreferenceCell({required this.date, required this.shiftId, this.level, this.locked = false, this.lockLabel});

  final DateTime date;
  final int shiftId;
  final PreferenceLevel? level; // null = 불가
  final bool locked;
  final String? lockLabel; // 예: "수업"

  factory PreferenceCell.fromJson(Map<String, dynamic> j) => PreferenceCell(
        date: DateTime.parse(j['date'] as String),
        shiftId: j['shiftId'] as int,
        level: j['level'] == null ? null : fromServerEnum(PreferenceLevel.values, j['level'] as String),
        locked: j['locked'] as bool? ?? false,
        lockLabel: j['lockLabel'] as String?,
      );
}

/// GET /preferences/my, /preferences/my/draft 응답: 그달의 모든 칸과 지난번 제출값
class PreferenceMonth {
  const PreferenceMonth({
    required this.month,
    required this.deadline,
    required this.submitted,
    required this.shifts,
    required this.cells,
    this.submission,
  });

  final String month;
  final DateTime? deadline;
  final bool submitted;
  final List<ShiftSummary> shifts;
  final List<PreferenceCell> cells;
  final Map<String, dynamic>? submission;

  factory PreferenceMonth.fromJson(Map<String, dynamic> j) => PreferenceMonth(
        month: j['month'] as String,
        deadline: j['deadline'] == null ? null : DateTime.parse(j['deadline'] as String),
        submitted: j['submitted'] as bool? ?? false,
        shifts: [for (final s in j['shifts'] as List? ?? []) ShiftSummary.fromJson(s as Map<String, dynamic>)],
        cells: [for (final c in j['cells'] as List? ?? []) PreferenceCell.fromJson(c as Map<String, dynamic>)],
        submission: j['submission'] as Map<String, dynamic>?,
      );
}

/// 희망 신청 7단계에서 고른 값을 모아 두는 초안.
///
/// 단계마다 화면은 다르지만 같은 초안 객체를 넘겨받아 채우고,
/// 마지막 W14에서 [toJson]으로 한 번에 PUT /preferences/my 로 보낸다.
class PreferenceDraft {
  PreferenceDraft({required this.month, this.fullTime = false});

  /// 신청 대상 달 (1일)
  final DateTime month;

  /// 직원(정규직)이면 E01 → W04 → W14 3단계, 알바면 W00 → … → W14 7단계
  final bool fullTime;

  /// W00에서 받아 둔 그달의 교대·칸·잠김 정보 (W02가 이걸로 표를 그린다)
  PreferenceMonth? view;

  /// 지난달 답을 실제로 불러왔는지 (첫 달이면 불러올 답이 없다)
  bool loadedPrevious = false;

  /// W02: (날짜, 교대 id) → 가능/선호. 없는 칸은 불가
  final Map<(DateTime, int), PreferenceLevel> slots = {};

  /// W02: 주말 근무 한 달 최대 횟수
  int? maxWeekendShifts;

  /// W06: 이번 달 근무량 범위와 리듬
  int? minMonthlyHours;
  int? maxMonthlyHours;
  int? maxConsecutiveDays;
  bool noOpenAfterClose = false;

  /// W14: 지킬 순서
  List<PreferencePriority> priorities = List.of(PreferencePriority.values);

  /// W04 (정규직)
  final Map<int, ShiftAttitude> shiftAttitudes = {};
  bool restDaysTogether = false;

  void setSlot(DateTime date, int shiftId, PreferenceLevel? level) {
    final key = (_dateOnly(date), shiftId);
    if (level == null) {
      slots.remove(key);
    } else {
      slots[key] = level;
    }
  }

  PreferenceLevel? slotAt(DateTime date, int shiftId) => slots[(_dateOnly(date), shiftId)];

  /// 지난달 답이나 이미 낸 값으로 초안을 채운다 (W00 "지난달 답 불러오기")
  void fillFrom(PreferenceMonth m) {
    slots.clear();
    for (final c in m.cells) {
      if (c.level != null && !c.locked) slots[(_dateOnly(c.date), c.shiftId)] = c.level!;
    }
    final s = m.submission;
    if (s == null) return;
    maxWeekendShifts = s['maxWeekendShifts'] as int?;
    minMonthlyHours = s['minMonthlyHours'] as int?;
    maxMonthlyHours = s['maxMonthlyHours'] as int?;
    maxConsecutiveDays = s['maxConsecutiveDays'] as int?;
    noOpenAfterClose = s['noOpenAfterClose'] as bool? ?? false;
    restDaysTogether = s['restDaysTogether'] as bool? ?? false;
    // 서버는 Map<교대 id, PREFER/NEUTRAL/AVOID>를 JSON 객체(키는 문자열)로 준다
    final attitudes = s['shiftAttitudes'] as Map<String, dynamic>?;
    attitudes?.forEach((id, raw) => shiftAttitudes[int.parse(id)] = fromServerEnum(ShiftAttitude.values, raw as String));
    final p = s['priorities'] as List?;
    if (p != null && p.isNotEmpty) {
      priorities = [for (final raw in p) fromServerEnum(PreferencePriority.values, raw as String)];
    }
  }

  /// PUT /api/stores/{storeId}/preferences/my?month=yyyy-MM 요청 본문
  Map<String, dynamic> toJson() => {
        'slots': [
          for (final e in slots.entries)
            {'date': _date(e.key.$1), 'shiftId': e.key.$2, 'level': toServerEnum(e.value)},
        ],
        if (maxWeekendShifts != null) 'maxWeekendShifts': maxWeekendShifts,
        if (minMonthlyHours != null) 'minMonthlyHours': minMonthlyHours,
        if (maxMonthlyHours != null) 'maxMonthlyHours': maxMonthlyHours,
        if (maxConsecutiveDays != null) 'maxConsecutiveDays': maxConsecutiveDays,
        'noOpenAfterClose': noOpenAfterClose,
        'priorities': [for (final p in priorities) toServerEnum(p)],
        if (shiftAttitudes.isNotEmpty)
          'shiftAttitudes': [
            for (final e in shiftAttitudes.entries) {'shiftId': e.key, 'attitude': toServerEnum(e.value)},
          ],
        'restDaysTogether': restDaysTogether,
      };
}
