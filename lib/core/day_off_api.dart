import '../models/preference.dart' show fromServerEnum, monthParam, toServerEnum;
import '../models/store.dart' show dateParam;
import 'api_service.dart';
import 'session.dart';

/// 필수 휴무(한 달 2일까지, 넘으면 희망으로 저장) / 희망 휴무
enum DayOffType { must, prefer }

/// 희망 휴무가 안 될 때의 대안 (백엔드 DayOffFallback). 연차·반차는 직원(정규직)용
enum DayOffFallback {
  afternoonOff('오후만 쉬기'),
  annualLeave('연차'),
  halfDay('반차'),
  swapDay('다른 날과 교환'),
  findSubstitute('대타 구하기'),
  workAnyway('그냥 출근');

  const DayOffFallback(this.label);
  final String label;
}

/// 휴무 신청 한 건 (GET /day-offs/my)
class DayOff {
  const DayOff({this.id, required this.date, required this.type, this.reason, this.fallbacks = const [], this.downgraded = false});

  final int? id;
  final DateTime date;
  final DayOffType type;
  final String? reason;
  final List<DayOffFallback> fallbacks;

  /// 필수로 냈지만 월 한도를 넘어 희망으로 저장됨
  final bool downgraded;

  /// 이번 달 연차 사용량 계산 (백엔드 PreferenceService.planLeave 와 같은 규칙: 연차 1, 반차 0.5)
  double get leaveUse => fallbacks.contains(DayOffFallback.annualLeave) ? 1 : (fallbacks.contains(DayOffFallback.halfDay) ? 0.5 : 0);

  factory DayOff.fromJson(Map<String, dynamic> j) => DayOff(
        id: j['id'] as int?,
        date: DateTime.parse(j['date'] as String),
        type: fromServerEnum(DayOffType.values, j['type'] as String),
        reason: j['reason'] as String?,
        fallbacks: [for (final f in j['fallbacks'] as List? ?? []) fromServerEnum(DayOffFallback.values, f as String)],
        downgraded: j['downgraded'] as bool? ?? false,
      );
}

/// 연차 사용 계획 (GET /preferences/my/leave-plan). 연차 정보가 없으면 remaining 이 null
class LeavePlan {
  const LeavePlan({this.remaining, required this.maxUse, this.minRemaining});

  final int? remaining;
  final double maxUse;
  final double? minRemaining;

  factory LeavePlan.fromJson(Map<String, dynamic> j) => LeavePlan(
        remaining: j['remaining'] as int?,
        maxUse: (j['maxUse'] as num?)?.toDouble() ?? 0,
        minRemaining: (j['minRemaining'] as num?)?.toDouble(),
      );
}

/// 휴무 신청 API (백엔드 DayOffRequestController)
class DayOffApi {
  DayOffApi({ApiService? api, Session? session})
      : _api = api ?? ApiService(),
        _session = session ?? Session.instance;

  final ApiService _api;
  final Session _session;

  String get _store => '/api/stores/${_session.requireStoreId()}';

  /// 그달의 내 휴무 신청
  Future<List<DayOff>> mine(DateTime month) async => [
        for (final j in await _api.get('$_store/day-offs/my') as List)
          if (DateTime.parse((j as Map)['date'] as String).month == month.month &&
              DateTime.parse(j['date'] as String).year == month.year)
            DayOff.fromJson(j as Map<String, dynamic>),
      ];

  /// 휴무 신청. 같은 날짜에 이미 있으면 서버가 막는다 → 바꿀 때는 [cancel] 후 다시 신청
  Future<DayOff> request(DayOff d) async => DayOff.fromJson(await _api.post('$_store/day-offs', data: {
        'date': dateParam(d.date),
        'type': toServerEnum(d.type),
        if (d.reason != null && d.reason!.isNotEmpty) 'reason': d.reason,
        'fallbacks': [for (final f in d.fallbacks) toServerEnum(f)],
      }) as Map<String, dynamic>);

  Future<void> cancel(int id) => _api.delete('$_store/day-offs/$id');

  /// 직원: 남은 연차와 이번 달 최대 사용
  Future<LeavePlan> leavePlan(DateTime month) async => LeavePlan.fromJson(
      await _api.get('$_store/preferences/my/leave-plan', query: {'month': monthParam(month)}) as Map<String, dynamic>);
}
