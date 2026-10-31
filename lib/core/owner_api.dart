import '../models/owner.dart';
import '../models/preference.dart' show toServerEnum;
import '../models/store.dart';
import '../models/user.dart';
import '../models/worker.dart' show Trade;
import 'api_service.dart';
import 'session.dart';

/// 점주 운영 API (P01 홈 · 근무자 · 근무표 · 대타 · 인건비)
class OwnerApi {
  OwnerApi({ApiService? api, Session? session})
      : _api = api ?? ApiService(),
        _session = session ?? Session.instance;

  final ApiService _api;
  final Session _session;

  String get _store => '/api/stores/${_session.requireStoreId()}';

  List<T> _list<T>(Object? json, T Function(Map<String, dynamic>) from) => [for (final j in json as List) from(j as Map<String, dynamic>)];

  // ── P01 홈

  Future<OwnerHome> home() async => OwnerHome.fromJson(await _api.get('$_store/home/owner') as Map<String, dynamic>);

  /// '+ 기록': 교대 마감 보고 (같은 날짜·교대는 덮어씀)
  Future<void> addClosingReport({required int shiftId, required DateTime date, required int customerCount, int? sales}) =>
      _api.post('$_store/closing-reports', data: {
        'shiftId': shiftId,
        'date': dateParam(date),
        'customerCount': customerCount,
        'sales': ?sales,
      });

  Future<List<ClosingReport>> closingReports(DateTime from, DateTime to) async =>
      _list(await _api.get('$_store/closing-reports', query: {'from': dateParam(from), 'to': dateParam(to)}), ClosingReport.fromJson);

  // ── 근무자 (M01 · P07 · P11)

  Future<Roster> roster() async => Roster.fromJson(await _api.get('$_store/roster') as Map<String, dynamic>);

  Future<List<EmployeeInfo>> pendingEmployees() async => _list(await _api.get('$_store/employees/pending'), EmployeeInfo.fromJson);

  Future<List<EmployeeInfo>> employees() async => _list(await _api.get('$_store/employees'), EmployeeInfo.fromJson);

  /// 가입 승인. 시급은 필수, 고용 형태는 근로자가 고른 값을 그대로 보낸다 (생략하면 서버가 알바로 둔다)
  Future<void> approve(int employeeId, {required int hourlyWage, EmploymentType? employmentType}) =>
      _api.post('$_store/employees/$employeeId/approve', data: {
        'hourlyWage': hourlyWage,
        if (employmentType != null) 'employmentType': employmentType == EmploymentType.fullTime ? 'FULL_TIME' : 'PART_TIME',
      });

  Future<void> reject(int employeeId) => _api.post('$_store/employees/$employeeId/reject');

  /// 승인된 직원 한 명 (수습 시급·공제·퇴사 예정일은 프로필 응답에 없어서 목록에서 찾는다)
  Future<EmployeeInfo?> employee(int employeeId) async => (await employees()).where((e) => e.id == employeeId).firstOrNull;

  /// 수습 시급·공제 설정. 보낸 값으로 통째로 바뀐다 (probationWage 가 null 이면 수습 감액 해제).
  /// 수습 시급은 1년 이상 계약 · 단순노무 아님일 때만 받는다. 이 두 값은 서버에 저장되지 않아 매번 보낸다
  Future<EmployeeInfo> updatePaySettings(int employeeId,
          {required PayDeduction deduction, int? probationWage, bool contractOneYearOrMore = false, bool simpleLabor = false}) async =>
      EmployeeInfo.fromJson(await _api.put('$_store/employees/$employeeId/pay-settings', data: {
        'deduction': deduction.json,
        'probationWage': probationWage,
        'contractOneYearOrMore': contractOneYearOrMore,
        'simpleLabor': simpleLabor,
      }) as Map<String, dynamic>);

  /// 퇴사 처리. 마지막 근무일이 미래면 퇴사 예정(그날까지 앱 사용). 그 뒤 근무는 바로 지워진다 → 지운 근무 수
  Future<int> resign(int employeeId, DateTime lastWorkDate) async {
    final res = await _api.post('$_store/employees/$employeeId/resign', data: {'lastWorkDate': dateParam(lastWorkDate)});
    return (res['removedShifts'] as num?)?.toInt() ?? 0;
  }

  /// 퇴사 예정 취소 (지워진 근무는 돌아오지 않는다)
  Future<void> cancelResignation(int employeeId) => _api.delete('$_store/employees/$employeeId/resign');

  Future<void> updateWage(int employeeId, int hourlyWage) => _api.patch('$_store/employees/$employeeId', data: {'hourlyWage': hourlyWage});

  Future<List<LeaveRequestInfo>> leaves() async => _list(await _api.get('$_store/leaves'), LeaveRequestInfo.fromJson);

  Future<LeaveRequestInfo> approveLeave(int id) async =>
      LeaveRequestInfo.fromJson(await _api.post('$_store/leaves/$id/approve') as Map<String, dynamic>);

  Future<void> rejectLeave(int id) => _api.post('$_store/leaves/$id/reject');

  Future<List<SkillRequest>> skillRequests() async => _list(await _api.get('$_store/skill-requests'), SkillRequest.fromJson);

  Future<EmployeeProfile> profile(int employeeId) async =>
      EmployeeProfile.fromJson(await _api.get('$_store/employees/$employeeId/profile') as Map<String, dynamic>);

  /// 보낸 항목만 바뀐다. 바뀐 내용은 이력에 남고 직원에게 알림이 간다
  Future<EmployeeProfile> updateProfile(
    int employeeId, {
    List<EmployeePermission>? permissions,
    DateTime? probationUntil,
    bool clearProbation = false,
    int? contractMinWeeklyHours,
    int? contractMaxWeeklyHours,
    StaffPosition? position,
  }) async =>
      EmployeeProfile.fromJson(await _api.patch('$_store/employees/$employeeId/profile', data: {
        if (permissions != null) 'permissions': [for (final p in permissions) toServerEnum(p)],
        if (probationUntil != null) 'probationUntil': dateParam(probationUntil),
        if (clearProbation) 'clearProbation': true,
        'contractMinWeeklyHours': ?contractMinWeeklyHours,
        'contractMaxWeeklyHours': ?contractMaxWeeklyHours,
        if (position != null) 'position': toServerEnum(position),
      }) as Map<String, dynamic>);

  /// 역량 등급 확정 (신청 승인 또는 직접 지정)
  Future<EmployeeProfile> setSkillLevel(int employeeId, int skillId, SkillLevel level) async => EmployeeProfile.fromJson(
      await _api.put('$_store/employees/$employeeId/skills/$skillId/level', data: {'level': toServerEnum(level)}) as Map<String, dynamic>);

  /// 신청을 받아들이지 않고 기존 등급 유지
  Future<EmployeeProfile> keepSkillLevel(int employeeId, int skillId) async =>
      EmployeeProfile.fromJson(await _api.post('$_store/employees/$employeeId/skills/$skillId/keep') as Map<String, dynamic>);

  // ── 근무표 (근무표 탭 · P03 · M05 · P04)

  Future<List<ScheduleEntry>> schedules() async => _list(await _api.get('$_store/schedules'), ScheduleEntry.fromJson);

  /// 다음 주기 근무표 3안 만들기. 매장 주기에 맞춰 월간은 month, 주간·2주는 weekStart 로 보낸다
  Future<Proposal> automate(SchedulePlan plan) async {
    final query = switch (plan.cycle) {
      ScheduleCycle.monthly => {'month': dateParam(plan.periodStart).substring(0, 7)},
      ScheduleCycle.biweekly => {'weekStart': dateParam(plan.periodStart), 'weeks': 2},
      ScheduleCycle.weekly => {'weekStart': dateParam(plan.periodStart)},
    };
    return Proposal.fromJson(await _api.post('$_store/schedules/automate', query: query) as Map<String, dynamic>);
  }

  Future<Proposal> proposal(int id) async => Proposal.fromJson(await _api.get('$_store/schedules/proposals/$id') as Map<String, dynamic>);

  Future<void> confirm(int proposalId, int candidateIndex) =>
      _api.post('$_store/schedules/proposals/$proposalId/confirm', data: {'candidateIndex': candidateIndex});

  Future<Acknowledgements> acknowledgements(int proposalId) async =>
      Acknowledgements.fromJson(await _api.get('$_store/schedules/proposals/$proposalId/acknowledgements') as Map<String, dynamic>);

  /// 아직 안 본 사람에게 다시 알림. 보낸 인원을 돌려준다
  Future<int> remind(int proposalId) async =>
      ((await _api.post('$_store/schedules/proposals/$proposalId/remind') as Map)['remindedCount'] as num).toInt();

  // ── 대타 (P06 · P09)

  Future<List<SwapRequestInfo>> swapRequests() async => _list(await _api.get('$_store/swap-requests'), SwapRequestInfo.fromJson);

  Future<List<SwapCandidate>> candidates(int requestId) async =>
      _list(await _api.get('$_store/swap-requests/$requestId/candidates'), SwapCandidate.fromJson);

  /// 고른 동료들에게 동시에 대타 요청 (사장님이 보낸 요청은 먼저 수락한 사람으로 바로 확정)
  Future<void> sendOffers(int requestId, List<int> employeeIds) =>
      _api.post('$_store/swap-requests/$requestId/offers', data: {'employeeIds': employeeIds});

  /// 가능한 후보 모두에게
  Future<int> broadcast(int requestId) async =>
      ((await _api.post('$_store/swap-requests/$requestId/broadcast') as Map)['notifiedCount'] as num?)?.toInt() ?? 0;

  /// 직접 배정
  Future<void> assign(int requestId, int employeeId) => _api.post('$_store/swap-requests/$requestId/assign', data: {'employeeId': employeeId});

  /// 빈 근무 게시판에 올리기
  Future<void> postToBoard(int requestId) => _api.post('$_store/swap-requests/$requestId/board');

  /// 직원끼리 구한 대타 승인 / 거절
  Future<void> approveSwap(int requestId) => _api.post('$_store/swap-requests/$requestId/approve');

  // ── 근무 바꾸기 (W09 에서 직원끼리 넘기기·맞교환 → 동료 수락 → 사장님 승인)

  /// 진행 중인 근무 바꾸기 (동료 응답 대기 · 사장님 승인 대기)
  Future<List<Trade>> trades() async => _list(await _api.get('$_store/trades'), Trade.fromJson);

  /// 동료가 수락한 요청만 승인할 수 있다. 승인하면 근무표가 바뀐다 (매주 반복이면 그달 남은 같은 근무까지)
  Future<void> approveTrade(int tradeId) => _api.post('$_store/trades/$tradeId/approve');

  Future<void> rejectTrade(int tradeId) => _api.post('$_store/trades/$tradeId/reject');

  Future<void> rejectSubstitute(int requestId) => _api.post('$_store/swap-requests/$requestId/reject-substitute');

  Future<List<OpenShiftItem>> openShifts() async =>
      _list((await _api.get('$_store/open-shifts') as Map<String, dynamic>)['items'], OpenShiftItem.fromJson);

  /// 추가 인원 모집 (단체 예약·피크 등)
  Future<void> addExtraShift({required DateTime date, required String startTime, required String endTime, String? title, int headcount = 1}) =>
      _api.post('$_store/open-shifts', data: {
        'workDate': dateParam(date),
        'startTime': startTime,
        'endTime': endTime,
        if (title != null && title.isNotEmpty) 'title': title,
        'headcount': headcount,
      });

  Future<void> deleteOpenShift(int id) => _api.delete('$_store/open-shifts/$id');

  Future<List<Applicant>> applicants(int openShiftId) async =>
      _list(await _api.get('$_store/open-shifts/$openShiftId/applications'), Applicant.fromJson);

  Future<void> approveApplicant(int openShiftId, int applicationId) =>
      _api.post('$_store/open-shifts/$openShiftId/applications/$applicationId/approve');

  // ── M03 · M02

  Future<List<SkillCoverage>> skillCoverage(DateTime date) async =>
      _list(await _api.get('$_store/skill-coverage', query: {'date': dateParam(date)}), SkillCoverage.fromJson);

  Future<List<PayrollRow>> payroll(DateTime month) async =>
      _list(await _api.get('$_store/payroll', query: {'yearMonth': dateParam(month).substring(0, 7)}), PayrollRow.fromJson);

  /// P08: 매장 코드 다시 발급 (이전 코드는 더 못 씀)
  Future<String> reissueCode() async =>
      (await _api.post('$_store/reissue-code') as Map<String, dynamic>)['storeCode'] as String;
}
