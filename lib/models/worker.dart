import 'owner.dart';
import 'user.dart';

/// 근로자 화면(H01·H02·W07~W10·H06·H07·H12·H13) 서버 응답 모델

DateTime? _date(Object? v) => v == null ? null : DateTime.parse(v as String);

int _int(Object? v) => (v as num?)?.toInt() ?? 0;

List<String> _strings(Object? v) => [for (final s in v as List? ?? const []) s as String];

/// 하루 근무 (근무가 없는 날은 scheduleId·시간이 null)
class DaySchedule {
  const DaySchedule({required this.date, this.scheduleId, this.shiftName, this.startTime, this.endTime});

  final DateTime date;
  final int? scheduleId;
  final String? shiftName;
  final String? startTime;
  final String? endTime;

  bool get working => scheduleId != null;

  factory DaySchedule.fromJson(Map<String, dynamic> j) => DaySchedule(
        date: DateTime.parse(j['date'] as String),
        scheduleId: j['scheduleId'] as int?,
        shiftName: j['shiftName'] as String?,
        startTime: j['startTime'] as String?,
        endTime: j['endTime'] as String?,
      );
}

/// 나에게 온 대타 요청 (홈 요약 · W08). 홈에서 온 것은 reasons 등 상세가 비어 있다
class SwapOffer {
  const SwapOffer({
    required this.offerId,
    required this.requestId,
    required this.workDate,
    required this.startTime,
    required this.endTime,
    required this.requesterName,
    required this.expectedPay,
    this.weekDaysBefore,
    this.weekDaysAfter,
    this.reasons = const [],
    this.sentCount = 0,
    this.needsOwnerApproval = false,
  });

  final int offerId;
  final int requestId;
  final DateTime workDate;
  final String startTime;
  final String endTime;
  final String requesterName;
  final int expectedPay;
  final int? weekDaysBefore;
  final int? weekDaysAfter;
  final List<String> reasons;
  final int sentCount;

  /// 동료가 보낸 요청이면 수락해도 사장님 승인 뒤에 확정
  final bool needsOwnerApproval;

  factory SwapOffer.fromJson(Map<String, dynamic> j) => SwapOffer(
        offerId: j['offerId'] as int,
        requestId: j['requestId'] as int,
        workDate: DateTime.parse(j['workDate'] as String),
        startTime: j['startTime'] as String,
        endTime: j['endTime'] as String,
        requesterName: j['requesterName'] as String? ?? '',
        expectedPay: _int(j['expectedPay']),
        weekDaysBefore: (j['weekDaysBefore'] as num?)?.toInt(),
        weekDaysAfter: (j['weekDaysAfter'] as num?)?.toInt(),
        reasons: _strings(j['reasons']),
        sentCount: _int(j['sentCount']),
        needsOwnerApproval: j['needsOwnerApproval'] as bool? ?? false,
      );
}

/// GET /home/worker (H01 알바 · H02 직원)
class WorkerHome {
  const WorkerHome({
    required this.storeName,
    required this.employeeName,
    this.employmentType,
    required this.date,
    required this.today,
    required this.coworkers,
    this.clockIn,
    this.clockOut,
    required this.week,
    required this.swapOffers,
    required this.monthHours,
    required this.monthPay,
    required this.weeklyHolidayPay,
    required this.nextMonthPreferences,
    this.leaveRemaining,
    this.leaveEntitled,
    this.latestNoticeTitle,
    this.latestNoticeAt,
  });

  final String storeName;
  final String employeeName;
  final EmploymentType? employmentType;
  final DateTime date;
  final DaySchedule today;
  final List<String> coworkers;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final List<DaySchedule> week;
  final List<SwapOffer> swapOffers;
  final double monthHours;
  final int monthPay;
  final int weeklyHolidayPay;
  final PreferenceStatus nextMonthPreferences;

  /// 정규직만
  final int? leaveRemaining;
  final int? leaveEntitled;
  final String? latestNoticeTitle;
  final DateTime? latestNoticeAt;

  factory WorkerHome.fromJson(Map<String, dynamic> j) {
    final att = j['todayAttendance'] as Map<String, dynamic>?;
    final pay = j['monthlyPay'] as Map<String, dynamic>? ?? const {};
    final leave = j['leaveBalance'] as Map<String, dynamic>?;
    final notice = j['latestNotice'] as Map<String, dynamic>?;
    return WorkerHome(
      storeName: j['storeName'] as String? ?? '',
      employeeName: j['employeeName'] as String? ?? '',
      employmentType: switch (j['employmentType']) {
        'FULL_TIME' => EmploymentType.fullTime,
        'PART_TIME' => EmploymentType.partTime,
        _ => null,
      },
      date: DateTime.parse(j['date'] as String),
      today: DaySchedule.fromJson(j['today'] as Map<String, dynamic>),
      coworkers: _strings(j['coworkers']),
      clockIn: _date(att?['clockIn']),
      clockOut: _date(att?['clockOut']),
      week: [for (final d in j['week'] as List? ?? const []) DaySchedule.fromJson(d as Map<String, dynamic>)],
      swapOffers: [for (final o in j['swapOffers'] as List? ?? const []) SwapOffer.fromJson(o as Map<String, dynamic>)],
      monthHours: (pay['totalHours'] as num?)?.toDouble() ?? 0,
      monthPay: _int(pay['totalPay']),
      weeklyHolidayPay: _int(pay['weeklyHolidayPay']),
      nextMonthPreferences: PreferenceStatus.fromJson(j['nextMonthPreferences'] as Map<String, dynamic>),
      leaveRemaining: (leave?['remaining'] as num?)?.toInt(),
      leaveEntitled: (leave?['entitled'] as num?)?.toInt(),
      latestNoticeTitle: notice?['title'] as String?,
      latestNoticeAt: _date(notice?['createdAt']),
    );
  }
}

/// 내 근무 한 건 (GET /schedules/my, W07). reasons = 자동 생성 확정 때 저장한 배정 사유
class MyShift {
  const MyShift({required this.id, required this.workDate, required this.startTime, required this.endTime, required this.reasons});

  final int id;
  final DateTime workDate;
  final String startTime;
  final String endTime;
  final List<String> reasons;

  factory MyShift.fromJson(Map<String, dynamic> j) => MyShift(
        id: j['id'] as int,
        workDate: DateTime.parse(j['workDate'] as String),
        startTime: j['startTime'] as String,
        endTime: j['endTime'] as String,
        reasons: _strings(j['reasons']),
      );
}

/// 근무 바꾸기 선택지 (W09). 넘기기는 동료만, 맞교환은 동료의 근무까지
class TradeOption {
  const TradeOption({required this.employeeId, required this.employeeName, this.scheduleId, this.workDate, this.startTime, this.endTime, required this.available, this.blocker});

  final int employeeId;
  final String employeeName;
  final int? scheduleId;
  final DateTime? workDate;
  final String? startTime;
  final String? endTime;
  final bool available;
  final String? blocker;

  factory TradeOption.fromJson(Map<String, dynamic> j) => TradeOption(
        employeeId: j['employeeId'] as int,
        employeeName: j['employeeName'] as String? ?? '',
        scheduleId: j['scheduleId'] as int?,
        workDate: _date(j['workDate']),
        startTime: j['startTime'] as String?,
        endTime: j['endTime'] as String?,
        available: j['available'] as bool? ?? false,
        blocker: j['blocker'] as String?,
      );
}

/// 근무 넘기기·맞교환 요청 (GET /trades/my). status: REQUESTED · PEER_ACCEPTED · APPROVED · DECLINED · REJECTED · CANCELLED
class Trade {
  const Trade({
    required this.id,
    required this.exchange,
    required this.status,
    required this.requesterId,
    required this.requesterName,
    required this.requesterDate,
    required this.requesterStart,
    required this.requesterEnd,
    required this.targetId,
    required this.targetName,
    this.targetDate,
    this.targetStart,
    this.targetEnd,
    required this.recurring,
  });

  final int id;
  final bool exchange;
  final String status;
  final int requesterId;
  final String requesterName;
  final DateTime requesterDate;
  final String requesterStart;
  final String requesterEnd;
  final int targetId;
  final String targetName;
  final DateTime? targetDate;
  final String? targetStart;
  final String? targetEnd;
  final bool recurring;

  bool get open => status == 'REQUESTED' || status == 'PEER_ACCEPTED';

  String get statusLabel => switch (status) {
        'REQUESTED' => '동료 응답 대기',
        'PEER_ACCEPTED' => '사장님 승인 대기',
        'APPROVED' => '확정',
        'DECLINED' => '동료가 거절',
        'REJECTED' => '사장님이 거절',
        'CANCELLED' => '취소함',
        _ => status,
      };

  factory Trade.fromJson(Map<String, dynamic> j) => Trade(
        id: j['id'] as int,
        exchange: j['type'] == 'EXCHANGE',
        status: j['status'] as String,
        requesterId: j['requesterId'] as int,
        requesterName: j['requesterName'] as String? ?? '',
        requesterDate: DateTime.parse(j['requesterDate'] as String),
        requesterStart: j['requesterStart'] as String,
        requesterEnd: j['requesterEnd'] as String,
        targetId: j['targetId'] as int,
        targetName: j['targetName'] as String? ?? '',
        targetDate: _date(j['targetDate']),
        targetStart: j['targetStart'] as String?,
        targetEnd: j['targetEnd'] as String?,
        recurring: j['recurring'] as bool? ?? false,
      );
}

/// 빈 근무 게시판 글 + 나의 지원 가능 여부 (GET /open-shifts 를 근로자가 볼 때, H07)
class BoardPost {
  const BoardPost({required this.item, this.eligible, this.blocker, this.expectedPay, this.myStatus});

  final OpenShiftItem item;
  final bool? eligible;
  final String? blocker;
  final int? expectedPay;

  /// APPLIED · APPROVED · REJECTED · WITHDRAWN, 지원 전이면 null
  final String? myStatus;

  bool get applied => myStatus == 'APPLIED' || myStatus == 'APPROVED';

  factory BoardPost.fromJson(Map<String, dynamic> j) => BoardPost(
        item: OpenShiftItem.fromJson(j),
        eligible: j['eligible'] as bool?,
        blocker: j['blocker'] as String?,
        expectedPay: (j['expectedPay'] as num?)?.toInt(),
        myStatus: j['myStatus'] as String?,
      );
}

class Board {
  const Board({required this.posts, this.myWeekDays, this.myWeekHours});

  final List<BoardPost> posts;
  final int? myWeekDays;
  final int? myWeekHours;

  factory Board.fromJson(Map<String, dynamic> j) => Board(
        posts: [for (final p in j['items'] as List? ?? const []) BoardPost.fromJson(p as Map<String, dynamic>)],
        myWeekDays: (j['myWeekDays'] as num?)?.toInt(),
        myWeekHours: (j['myWeekHours'] as num?)?.toInt(),
      );
}

/// 최근 4주 부담 근무 (WEEKEND · CLOSE · NIGHT)
class Burden {
  const Burden({required this.kind, required this.mine, required this.teamAverage});

  final String kind;
  final int mine;
  final double teamAverage;

  String get label => switch (kind) {
        'WEEKEND' => '주말',
        'CLOSE' => '마감',
        'NIGHT' => '야간',
        _ => kind,
      };

  factory Burden.fromJson(Map<String, dynamic> j) =>
      Burden(kind: j['kind'] as String, mine: _int(j['mine']), teamAverage: (j['teamAverage'] as num?)?.toDouble() ?? 0);
}

/// 원하던 교대로 못 간 근무와 그 이유
class Unfulfilled {
  const Unfulfilled({required this.scheduleId, required this.workDate, this.assignedShiftName, required this.startTime, required this.endTime, required this.preferredShiftNames, required this.reasons});

  final int scheduleId;
  final DateTime workDate;
  final String? assignedShiftName;
  final String startTime;
  final String endTime;
  final List<String> preferredShiftNames;
  final List<String> reasons;

  factory Unfulfilled.fromJson(Map<String, dynamic> j) => Unfulfilled(
        scheduleId: j['scheduleId'] as int,
        workDate: DateTime.parse(j['workDate'] as String),
        assignedShiftName: j['assignedShiftName'] as String?,
        startTime: j['startTime'] as String,
        endTime: j['endTime'] as String,
        preferredShiftNames: _strings(j['preferredShiftNames']),
        reasons: _strings(j['reasons']),
      );
}

/// GET /preference-report/my?month= (W10)
class PreferenceReport {
  const PreferenceReport({
    required this.assignedCount,
    required this.honoredCount,
    this.preferenceRate,
    required this.dayOffRequested,
    required this.dayOffHonored,
    this.dayOffRate,
    required this.burdens,
    required this.unfulfilled,
  });

  final int assignedCount;
  final int honoredCount;
  final double? preferenceRate;
  final int dayOffRequested;
  final int dayOffHonored;
  final double? dayOffRate;
  final List<Burden> burdens;
  final List<Unfulfilled> unfulfilled;

  factory PreferenceReport.fromJson(Map<String, dynamic> j) => PreferenceReport(
        assignedCount: _int(j['assignedCount']),
        honoredCount: _int(j['honoredCount']),
        preferenceRate: (j['preferenceRate'] as num?)?.toDouble(),
        dayOffRequested: _int(j['dayOffRequested']),
        dayOffHonored: _int(j['dayOffHonored']),
        dayOffRate: (j['dayOffRate'] as num?)?.toDouble(),
        burdens: [for (final b in j['burdens'] as List? ?? const []) Burden.fromJson(b as Map<String, dynamic>)],
        unfulfilled: [for (final u in j['unfulfilled'] as List? ?? const []) Unfulfilled.fromJson(u as Map<String, dynamic>)],
      );
}

/// GET /me/summary (H06 내 정보)
class MySummary {
  const MySummary({
    required this.name,
    this.employmentType,
    this.startDate,
    this.hourlyWage,
    required this.storeName,
    required this.monthDays,
    required this.monthHours,
    required this.payToDate,
    required this.cumulativeHours,
    required this.fixedScheduleCount,
    this.lastReportRate,
    required this.lastReportHonored,
    required this.lastReportAssigned,
    required this.unreadNotifications,
    required this.pushEnabled,
  });

  final String name;
  final EmploymentType? employmentType;
  final DateTime? startDate;
  final int? hourlyWage;
  final String storeName;
  final int monthDays;
  final double monthHours;
  final int payToDate;
  final double cumulativeHours;
  final int fixedScheduleCount;
  final double? lastReportRate;
  final int lastReportHonored;
  final int lastReportAssigned;
  final int unreadNotifications;
  final bool pushEnabled;

  factory MySummary.fromJson(Map<String, dynamic> j) => MySummary(
        name: j['name'] as String? ?? '',
        employmentType: switch (j['employmentType']) {
          'FULL_TIME' => EmploymentType.fullTime,
          'PART_TIME' => EmploymentType.partTime,
          _ => null,
        },
        startDate: _date(j['startDate']),
        hourlyWage: (j['hourlyWage'] as num?)?.toInt(),
        storeName: j['storeName'] as String? ?? '',
        monthDays: _int(j['monthDays']),
        monthHours: (j['monthHours'] as num?)?.toDouble() ?? 0,
        payToDate: _int(j['payToDate']),
        cumulativeHours: (j['cumulativeHours'] as num?)?.toDouble() ?? 0,
        fixedScheduleCount: _int(j['fixedScheduleCount']),
        lastReportRate: (j['lastReportRate'] as num?)?.toDouble(),
        lastReportHonored: _int(j['lastReportHonored']),
        lastReportAssigned: _int(j['lastReportAssigned']),
        unreadNotifications: _int(j['unreadNotifications']),
        pushEnabled: j['pushEnabled'] as bool? ?? true,
      );
}

/// "09:00:00" → "09:00"
String hm(String t) => t.length >= 5 ? t.substring(0, 5) : t;

/// "09:00–14:00"
String timeRange(String start, String end) => '${hm(start)}–${hm(end)}';

/// "1.5" → "1.5", "60.0" → "60"
String hours(double h) => h == h.roundToDouble() ? h.toInt().toString() : h.toStringAsFixed(1);
