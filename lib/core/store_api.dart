import '../models/preference.dart' show toServerEnum;
import '../models/store.dart';
import 'api_service.dart';
import 'session.dart';

/// 매장 등록·설정 API (점주). 백엔드 StoreController · ShiftController · StaffingController · EmployeeProfileController
class StoreApi {
  StoreApi({ApiService? api, Session? session})
      : _api = api ?? ApiService(),
        _session = session ?? Session.instance;

  final ApiService _api;
  final Session _session;

  String get _store => '/api/stores/${_session.requireStoreId()}';

  /// O01: 업종 목록과 업종별로 미리 만들어지는 역량·교대
  Future<List<IndustryInfo>> industries() async =>
      [for (final j in await _api.get('/api/stores/industries') as List) IndustryInfo.fromJson(j as Map<String, dynamic>)];

  /// O01: 매장 등록. 업종 기본 교대·역량이 서버에서 같이 만들어진다. 만든 매장을 세션의 현재 매장으로 둔다
  Future<StoreInfo> create({required String name, String? industry, String? address}) async {
    final res = await _api.post('/api/stores', data: {
      'name': name,
      'industry': ?industry,
      if (address != null && address.isNotEmpty) 'address': address,
    });
    _session.storeId = res['id'] as int;
    await _session.refreshMe();
    return current();
  }

  /// 현재 매장 설정 (GET /api/stores 는 내 매장 목록이라 그중 현재 매장을 고른다)
  Future<StoreInfo> current() async {
    final id = _session.requireStoreId();
    final list = [for (final j in await _api.get('/api/stores') as List) StoreInfo.fromJson(j as Map<String, dynamic>)];
    return list.firstWhere((s) => s.id == id, orElse: () => throw ApiException('매장을 찾을 수 없어요.'));
  }

  /// O02·O03·O05: 매장 설정 변경. 넘긴 항목만 바뀐다
  Future<StoreInfo> updateSettings({
    ScheduleCycle? scheduleCycle,
    bool? autoGenerate,
    bool? allowSplitShift,
    int? maxConsecutiveDays,
    bool? fivePlusBusiness,
  }) async =>
      StoreInfo.fromJson(await _api.patch('$_store/settings', data: {
        if (scheduleCycle != null) 'scheduleCycle': toServerEnum(scheduleCycle),
        'autoGenerate': ?autoGenerate,
        'allowSplitShift': ?allowSplitShift,
        'maxConsecutiveDays': ?maxConsecutiveDays,
        'fivePlusBusiness': ?fivePlusBusiness,
      }) as Map<String, dynamic>);

  /// O03: 교대 목록 (업종 기본 교대 포함)
  Future<List<ShiftInfo>> shifts() async =>
      [for (final j in await _api.get('$_store/shifts') as List) ShiftInfo.fromJson(j as Map<String, dynamic>)];

  /// O03: 교대 추가 (요일을 비우면 매일)
  Future<ShiftInfo> addShift({required String name, required String startTime, required String endTime, int requiredStaff = 1}) async =>
      ShiftInfo.fromJson(await _api.post('$_store/shifts', data: {
        'name': name,
        'startTime': startTime,
        'endTime': endTime,
        'requiredStaff': requiredStaff,
      }) as Map<String, dynamic>);

  /// O03: 교대 이름·시간 수정. 서버가 전체를 바꾸므로 기본 인원·요일도 그대로 보낸다
  Future<ShiftInfo> updateShift(ShiftInfo shift, {required String name, required String startTime, required String endTime}) async =>
      ShiftInfo.fromJson(await _api.put('$_store/shifts/${shift.id}', data: {
        'name': name,
        'startTime': startTime,
        'endTime': endTime,
        'requiredStaff': shift.requiredStaff,
        'dayOfWeek': ?shift.dayOfWeek,
      }) as Map<String, dynamic>);

  /// O03: 교대 삭제 (마감 보고가 있으면 서버가 거절)
  Future<void> deleteShift(int shiftId) => _api.delete('$_store/shifts/$shiftId');

  /// O03: 교대 하나의 요일별 최소·목표 인원을 통째로 바꾼다 ([minStaff]는 월~일 7칸, 목표는 최소 +1)
  Future<void> replaceDayStaffing(int shiftId, List<int> minStaff) => _api.put('$_store/shifts/$shiftId/day-staffing', data: [
        for (var i = 0; i < 7; i++)
          {'dayOfWeek': weekdayNames[i], 'minStaff': minStaff[i], 'targetStaff': minStaff[i] == 0 ? 0 : minStaff[i] + 1},
      ]);

  /// O02: 다음 근무표 기간·희망 마감·자동 생성 시각 (매장 주기에 따라 서버가 계산)
  Future<SchedulePlan> plan() async => SchedulePlan.fromJson(await _api.get('$_store/schedules/plan') as Map<String, dynamic>);

  /// O06: 기간 안의 예외일
  Future<List<StaffingException>> exceptions(DateTime from, DateTime to) async => [
        for (final j in await _api.get('$_store/staffing-exceptions', query: {'from': dateParam(from), 'to': dateParam(to)}) as List)
          StaffingException.fromJson(j as Map<String, dynamic>),
      ];

  Future<StaffingException> addException(StaffingException e) async =>
      StaffingException.fromJson(await _api.post('$_store/staffing-exceptions', data: e.toJson()) as Map<String, dynamic>);

  Future<void> deleteException(int id) => _api.delete('$_store/staffing-exceptions/$id');

  /// O06: 공휴일 (서버에 2026·2027년만 있음)
  Future<Map<DateTime, String>> holidays(int year) async => {
        for (final j in await _api.get('/api/holidays', query: {'year': year}) as List)
          DateTime.parse(j['date'] as String): j['name'] as String,
      };

  /// O04: 매장 역량 목록 (업종 기본 역량 포함)
  Future<List<SkillInfo>> skills() async =>
      [for (final j in await _api.get('$_store/skills') as List) SkillInfo.fromJson(j as Map<String, dynamic>)];

  /// O04: 시간대별 필요 역량
  Future<List<SkillWindow>> skillWindows() async =>
      [for (final j in await _api.get('$_store/skill-windows') as List) SkillWindow.fromJson(j as Map<String, dynamic>)];

  Future<SkillWindow> addSkillWindow(SkillWindow w) async =>
      SkillWindow.fromJson(await _api.post('$_store/skill-windows', data: w.toJson()) as Map<String, dynamic>);

  Future<void> deleteSkillWindow(int id) => _api.delete('$_store/skill-windows/$id');

  /// O04 Q1: 직원 × 역량 등급 (합류한 직원이 없으면 빈 목록)
  Future<List<SkillMatrixRow>> skillMatrix() async =>
      [for (final j in await _api.get('$_store/skill-matrix') as List) SkillMatrixRow.fromJson(j as Map<String, dynamic>)];
}
