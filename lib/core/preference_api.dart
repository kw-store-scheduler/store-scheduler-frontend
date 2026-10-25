import '../models/preference.dart';
import '../models/preference_demo.dart';
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
  /// 로그인했으면 서버에서, 아니면 시연용 데이터로 채운다. 실패하면 ApiException
  Future<PreferenceDraft> startDraft(DateTime month, {required bool fromLastMonth, bool fullTime = false}) async {
    final draft = PreferenceDraft(month: month, fullTime: fullTime);
    if (_session.isLoggedIn) {
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
    } else {
      draft.view = demoPreferenceMonth(month);
      if (fromLastMonth) {
        draft.fillFrom(draft.view!);
        draft.loadedPrevious = true;
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

  /// W14 "신청 제출". 다시 내면 그달 칸을 통째로 바꾼다
  Future<PreferenceMonth> submit(PreferenceDraft draft) async => PreferenceMonth.fromJson(
      await _api.put('$_base/my', query: {'month': monthParam(draft.month)}, data: draft.toJson()) as Map<String, dynamic>);
}
