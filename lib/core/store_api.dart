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

  /// O03: 교대 하나의 요일별 최소 인원을 통째로 바꾼다 ([minStaff]는 월~일 7칸)
  Future<void> replaceDayStaffing(int shiftId, List<int> minStaff) => _api.put('$_store/shifts/$shiftId/day-staffing', data: [
        for (var i = 0; i < 7; i++) {'dayOfWeek': weekdayNames[i], 'minStaff': minStaff[i]},
      ]);

  /// O06: 기간 안의 예외일
  Future<List<StaffingException>> exceptions(DateTime from, DateTime to) async => [
        for (final j in await _api.get('$_store/staffing-exceptions', query: {'from': dateParam(from), 'to': dateParam(to)}) as List)
          StaffingException.fromJson(j as Map<String, dynamic>),
      ];

  Future<StaffingException> addException(StaffingException e) async =>
      StaffingException.fromJson(await _api.post('$_store/staffing-exceptions', data: e.toJson()) as Map<String, dynamic>);

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
}
