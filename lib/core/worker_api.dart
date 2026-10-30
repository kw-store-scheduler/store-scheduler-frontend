import '../models/owner.dart';
import '../models/preference.dart' show toServerEnum;
import '../models/worker.dart';
import 'api_service.dart';
import 'session.dart';

/// 근로자 운영 API (홈 · 내 근무표 · 결원 · 대타 · 근무 바꾸기 · 빈 근무 · 출퇴근 · 내 정보)
class WorkerApi {
  WorkerApi({ApiService? api, Session? session})
      : _api = api ?? ApiService(),
        _session = session ?? Session.instance;

  final ApiService _api;
  final Session _session;

  String get _store => '/api/stores/${_session.requireStoreId()}';

  List<T> _list<T>(Object? json, T Function(Map<String, dynamic>) from) => [for (final j in json as List) from(j as Map<String, dynamic>)];

  /// 지금 매장에서의 내 직원 번호 (근무 바꾸기에서 내가 보낸 요청인지 가를 때)
  int? get myEmployeeId => _session.currentMembership?.employeeId;

  /// 인사말에 쓰는 내 이름 (합류할 때 적은 닉네임·이름)
  String? get myDisplayName => _session.currentMembership?.displayName;

  String? get myStoreName => _session.currentMembership?.storeName;

  // ── H01 · H02 홈

  Future<WorkerHome> home() async => WorkerHome.fromJson(await _api.get('$_store/home/worker') as Map<String, dynamic>);

  Future<void> clockIn() => _api.post('$_store/attendance/clock-in');

  Future<void> clockOut() => _api.post('$_store/attendance/clock-out');

  // ── W07 내 근무표 (열면 서버가 확정 근무표를 확인한 것으로 기록한다)

  Future<List<MyShift>> mySchedules() async => _list(await _api.get('$_store/schedules/my'), MyShift.fromJson);

  // ── H12 · H13 결원 신고 → 빈자리 채우기

  /// 결원 신고. partialFrom 을 주면 그 시각부터만 빠진다. 사유(reason)는 사장님만 본다
  Future<SwapRequestInfo> reportAbsence(int scheduleId, {required AbsenceReason category, String? reason, String? partialFrom}) async =>
      SwapRequestInfo.fromJson(await _api.post('$_store/schedules/$scheduleId/swap-requests', data: {
        'reasonCategory': toServerEnum(category),
        if (reason != null && reason.isNotEmpty) 'reason': reason,
        'partialFrom': ?partialFrom,
      }) as Map<String, dynamic>);

  Future<List<SwapCandidate>> candidates(int requestId) async =>
      _list(await _api.get('$_store/swap-requests/$requestId/candidates'), SwapCandidate.fromJson);

  /// 고른 동료들에게 동시에 대타 요청 (먼저 수락한 1명 → 사장님 승인)
  Future<void> sendOffers(int requestId, List<int> employeeIds) =>
      _api.post('$_store/swap-requests/$requestId/offers', data: {'employeeIds': employeeIds});

  /// 빈 근무 게시판에 올리기 → 알림 받은 인원 수
  Future<int> postToBoard(int requestId) async =>
      ((await _api.post('$_store/swap-requests/$requestId/board') as Map)['notifiedCount'] as num?)?.toInt() ?? 0;

  Future<void> cancelAbsence(int requestId) => _api.post('$_store/swap-requests/$requestId/cancel');

  // ── W08 나에게 온 대타 요청

  Future<List<SwapOffer>> myOffers() async => _list(await _api.get('$_store/swap-offers/my'), SwapOffer.fromJson);

  Future<void> acceptOffer(int offerId) => _api.post('$_store/swap-offers/$offerId/accept');

  Future<void> declineOffer(int offerId) => _api.post('$_store/swap-offers/$offerId/decline');

  // ── W09 근무 바꾸기

  Future<(List<TradeOption> handover, List<TradeOption> exchange)> tradeOptions(int scheduleId) async {
    final j = await _api.get('$_store/schedules/$scheduleId/trade-options') as Map<String, dynamic>;
    return (_list(j['handover'], TradeOption.fromJson), _list(j['exchange'], TradeOption.fromJson));
  }

  /// 넘기기(targetEmployeeId) 또는 맞교환(targetScheduleId)
  Future<void> requestTrade(int scheduleId, {required bool exchange, int? targetEmployeeId, int? targetScheduleId, bool recurring = false}) =>
      _api.post('$_store/schedules/$scheduleId/trades', data: {
        'type': exchange ? 'EXCHANGE' : 'HANDOVER',
        'targetEmployeeId': ?targetEmployeeId,
        'targetScheduleId': ?targetScheduleId,
        'recurring': recurring,
      });

  Future<List<Trade>> myTrades() async => _list(await _api.get('$_store/trades/my'), Trade.fromJson);

  Future<void> acceptTrade(int id) => _api.post('$_store/trades/$id/accept');

  Future<void> declineTrade(int id) => _api.post('$_store/trades/$id/decline');

  Future<void> cancelTrade(int id) => _api.post('$_store/trades/$id/cancel');

  // ── H07 빈 근무 게시판

  Future<Board> board() async => Board.fromJson(await _api.get('$_store/open-shifts') as Map<String, dynamic>);

  Future<void> apply(int openShiftId) => _api.post('$_store/open-shifts/$openShiftId/applications');

  Future<void> withdraw(int openShiftId) => _api.delete('$_store/open-shifts/$openShiftId/applications/my');

  // ── W10 · H06

  /// month = 확정된 달 (서버는 yyyy-MM)
  Future<PreferenceReport> preferenceReport(DateTime month) async => PreferenceReport.fromJson(await _api.get(
        '$_store/preference-report/my',
        query: {'month': '${month.year}-${month.month.toString().padLeft(2, '0')}'},
      ) as Map<String, dynamic>);

  /// 알림 받기 켜기·끄기 (계정 단위)
  Future<void> setPushEnabled(bool on) => _api.patch('/api/users/me/notification-settings', data: {'pushEnabled': on});

  Future<MySummary> summary() async => MySummary.fromJson(await _api.get('$_store/me/summary') as Map<String, dynamic>);
}
