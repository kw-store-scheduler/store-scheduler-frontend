import '../models/preference.dart';
import '../models/store.dart' show SkillLevel;
import 'api_service.dart';
import 'session.dart';

/// 희망 제출 API (백엔드 PreferenceController)
class PreferenceApi {
  PreferenceApi({ApiService? api, Session? session})
      : _api = api ?? ApiService(),
        _session = session ?? Session.instance;

  final ApiService _api;
  final Session _session;

  String get _base => '/api/stores/${_session.requireStoreId()}/preferences';

  /// 희망 신청 첫 단계(알바 W00, 직원 E01)에서 초안을 만든다.
  /// 서버의 그달 칸·지난번 제출값으로 채운다. 실패하면 ApiException
  Future<PreferenceDraft> startDraft(DateTime month, {required bool fromLastMonth, bool fullTime = false}) async {
    final draft = PreferenceDraft(month: month, fullTime: fullTime);
    draft.view = await getMine(month);
    if (fromLastMonth) {
      try {
        draft.fillFrom(await draftFromPrevious(month));
        draft.loadedPrevious = true;
      } on ApiException catch (e) {
        // 첫 달이면 서버가 "2026-10에 제출한 희망이 없습니다."(400)를 준다 → 빈 초안으로 시작
        if (!(e.statusCode == 400 && e.message.endsWith('제출한 희망이 없습니다.'))) rethrow;
      }
    }
    return draft;
  }

  /// 이번 달 칸 목록과 이미 낸 값
  Future<PreferenceMonth> getMine(DateTime month) async =>
      PreferenceMonth.fromJson(await _api.get('$_base/my', query: {'month': monthParam(month)}) as Map<String, dynamic>);

  /// W00 "지난달 답 불러오기": 지난달 같은 요일·교대 값으로 채운 초안 (서버에 저장되지 않음)
  Future<PreferenceMonth> draftFromPrevious(DateTime month) async => PreferenceMonth.fromJson(
      await _api.get('$_base/my/draft', query: {'month': monthParam(month)}) as Map<String, dynamic>);

  String get _store => '/api/stores/${_session.requireStoreId()}';

  /// W11 고정 일정 (요일마다 한 건)
  Future<List<FixedSchedule>> fixedSchedules() async =>
      [for (final j in await _api.get('$_store/fixed-schedules/my') as List) FixedSchedule.fromJson(j as Map<String, dynamic>)];

  /// 통째로 바꾼다 (빈 목록이면 모두 삭제)
  Future<void> replaceFixedSchedules(List<FixedSchedule> list) =>
      _api.put('$_store/fixed-schedules/my', data: [for (final f in list) f.toJson()]);

  /// W11 "이번 달만 예외" 기간
  Future<List<UnavailablePeriod>> unavailablePeriods() async =>
      [for (final j in await _api.get('$_store/unavailable-periods/my') as List) UnavailablePeriod.fromJson(j as Map<String, dynamic>)];

  Future<void> replaceUnavailablePeriods(List<UnavailablePeriod> list) =>
      _api.put('$_store/unavailable-periods/my', data: [for (final p in list) p.toJson()]);

  /// W06 이번 달 근무량: 계약 범위와 예상 급여. min·max 를 주면 그 값으로 계산한다
  Future<Workload> workload(DateTime month, {int? min, int? max}) async => Workload.fromJson(await _api.get('$_base/my/workload', query: {
        'month': monthParam(month),
        'minMonthlyHours': ?min,
        'maxMonthlyHours': ?max,
      }) as Map<String, dynamic>);

  /// W05 내 역량
  Future<MySkills> mySkills() async => MySkills.fromJson(await _api.get('$_store/my-skills') as Map<String, dynamic>);

  /// 역량 등급 신청 (매니저가 확정하기 전까지는 배치에 안 쓰인다). 확정 등급과 같은 값이면 신청 취소
  Future<void> requestSkillLevels(Map<int, SkillLevel> levels) => _api.put('$_store/my-skills', data: [
        for (final e in levels.entries) {'skillId': e.key, 'level': toServerEnum(e.value)},
      ]);

  /// W14 "신청 제출". 다시 내면 그달 칸을 통째로 바꾼다
  Future<PreferenceMonth> submit(PreferenceDraft draft) async => PreferenceMonth.fromJson(
      await _api.put('$_base/my', query: {'month': monthParam(draft.month)}, data: draft.toJson()) as Map<String, dynamic>);
}
