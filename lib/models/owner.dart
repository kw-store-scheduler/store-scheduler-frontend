// 점주 운영 화면(P01·M01·P07·P11·M03·P03·M05·P04·P06·P09·M02) 모델.
// 백엔드 HomeController·StoreOverviewController·StoreEmployeeController·EmployeeProfileController·LeaveController·
// ScheduleController·SwapRequestController·OpenShiftController·PayrollController·StaffingController 응답과 필드 이름이 같다.

import 'preference.dart' show fromServerEnum;
import 'store.dart';
import 'user.dart';

DateTime? _date(Object? v) => v == null ? null : DateTime.parse(v as String);

EmploymentType? _employment(Object? v) => switch (v) {
      'PART_TIME' => EmploymentType.partTime,
      'FULL_TIME' => EmploymentType.fullTime,
      _ => null,
    };

String employmentLabel(EmploymentType? t) => t == EmploymentType.fullTime ? '직원' : '알바';

/// 정규직 직책 (서버 StaffPosition)
enum StaffPosition {
  manager('매니저'),
  senior('시니어'),
  junior('주니어');

  const StaffPosition(this.label);
  final String label;
}

/// 결원 사유 (서버 AbsenceReason)
enum AbsenceReason {
  sick('병가'),
  familyEvent('경조사'),
  personal('개인 사정'),
  other('기타');

  const AbsenceReason(this.label);
  final String label;
}

/// GET /home/owner 의 결원 한 건
class Vacancy {
  const Vacancy({required this.requestId, required this.workDate, required this.startTime, required this.endTime, required this.requesterName, this.reason, required this.status, this.substituteName});

  final int requestId;
  final DateTime workDate;
  final String startTime;
  final String endTime;
  final String requesterName;
  final String? reason;
  final String status; // REQUESTED · OFFERED · PENDING_APPROVAL
  final String? substituteName;

  factory Vacancy.fromJson(Map<String, dynamic> j) => Vacancy(
        requestId: j['requestId'] as int,
        workDate: DateTime.parse(j['workDate'] as String),
        startTime: j['startTime'] as String,
        endTime: j['endTime'] as String,
        requesterName: j['requesterName'] as String? ?? '',
        reason: j['reason'] as String?,
        status: j['status'] as String,
        substituteName: j['substituteName'] as String?,
      );
}

/// 오늘 교대 하나의 인원
class ShiftStatus {
  const ShiftStatus({required this.shiftName, required this.startTime, required this.endTime, required this.requiredStaff, required this.employeeNames, required this.shortage});

  final String shiftName;
  final String startTime;
  final String endTime;
  final int requiredStaff;
  final List<String> employeeNames;
  final int shortage;

  factory ShiftStatus.fromJson(Map<String, dynamic> j) => ShiftStatus(
        shiftName: j['shiftName'] as String,
        startTime: j['startTime'] as String,
        endTime: j['endTime'] as String,
        requiredStaff: j['requiredStaff'] as int? ?? 0,
        employeeNames: [for (final n in j['employeeNames'] as List? ?? []) n as String],
        shortage: j['shortage'] as int? ?? 0,
      );
}

/// 다음 달 희망 제출 현황 (daysUntilDeadline 이 음수면 마감 지남)
class PreferenceStatus {
  const PreferenceStatus({required this.month, required this.deadline, required this.daysUntilDeadline, required this.submittedCount, required this.employeeCount, required this.submittedByMe});

  final String month; // "2026-11"
  final DateTime deadline;
  final int daysUntilDeadline;
  final int submittedCount;
  final int employeeCount;
  final bool submittedByMe;

  int get monthNumber => int.parse(month.substring(5, 7));

  factory PreferenceStatus.fromJson(Map<String, dynamic> j) => PreferenceStatus(
        month: j['month'] as String,
        deadline: DateTime.parse(j['deadline'] as String),
        daysUntilDeadline: (j['daysUntilDeadline'] as num).toInt(),
        submittedCount: (j['submittedCount'] as num).toInt(),
        employeeCount: (j['employeeCount'] as num).toInt(),
        submittedByMe: j['submittedByMe'] as bool? ?? false,
      );
}

/// 직원별 희망 제출 현황 한 줄 (GET /preferences?month=, M01)
/// needsContractApproval = 계약 상한을 넘겨 신청했고 아직 승인되지 않음 (서버는 거절도 같은 값으로 준다)
class PreferenceSubmissionRow {
  const PreferenceSubmissionRow({required this.employeeId, required this.name, required this.submitted, required this.late, required this.needsContractApproval});

  final int employeeId;
  final String name;
  final bool submitted;
  final bool late;
  final bool needsContractApproval;

  factory PreferenceSubmissionRow.fromJson(Map<String, dynamic> j) => PreferenceSubmissionRow(
        employeeId: j['employeeId'] as int,
        name: j['name'] as String? ?? '',
        submitted: j['submitted'] as bool? ?? false,
        late: j['late'] as bool? ?? false,
        needsContractApproval: j['needsContractApproval'] as bool? ?? false,
      );
}

/// GET /api/stores/{storeId}/home/owner (P01)
class OwnerHome {
  const OwnerHome({
    required this.storeName,
    required this.date,
    required this.weeklyLaborCost,
    required this.employeeCount,
    required this.pendingApprovals,
    required this.pendingLeaves,
    required this.vacancies,
    required this.todayShifts,
    required this.preferences,
  });

  final String storeName;
  final DateTime date;
  final int weeklyLaborCost;
  final int employeeCount;
  final int pendingApprovals;
  final int pendingLeaves;
  final List<Vacancy> vacancies;
  final List<ShiftStatus> todayShifts;
  final PreferenceStatus preferences;

  int get todayRequired => todayShifts.fold(0, (s, e) => s + e.requiredStaff);
  int get todayAssigned => todayShifts.fold(0, (s, e) => s + e.employeeNames.length);

  factory OwnerHome.fromJson(Map<String, dynamic> j) => OwnerHome(
        storeName: j['storeName'] as String,
        date: DateTime.parse(j['date'] as String),
        weeklyLaborCost: (j['weeklyLaborCost'] as num).toInt(),
        employeeCount: (j['employeeCount'] as num).toInt(),
        pendingApprovals: (j['pendingApprovals'] as num).toInt(),
        pendingLeaves: (j['pendingLeaves'] as num?)?.toInt() ?? 0,
        vacancies: [for (final v in j['activeVacancies'] as List? ?? []) Vacancy.fromJson(v as Map<String, dynamic>)],
        todayShifts: [for (final s in j['todayShifts'] as List? ?? []) ShiftStatus.fromJson(s as Map<String, dynamic>)],
        preferences: PreferenceStatus.fromJson(j['nextMonthPreferences'] as Map<String, dynamic>),
      );
}

/// GET /roster 한 줄 (P07). todayStatus: WORKING(근무 중·예정) · VACANCY(결원 신고) · OFF(휴무)
class RosterRow {
  const RosterRow({
    required this.employeeId,
    required this.name,
    this.employmentType,
    this.position,
    required this.newcomer,
    required this.todayStatus,
    this.todayStart,
    this.todayEnd,
    required this.monthHours,
    required this.nextMonthSubmitted,
  });

  final int employeeId;
  final String name;
  final EmploymentType? employmentType;
  final String? position; // "매니저" 처럼 서버가 한글로 준다
  final bool newcomer;
  final String todayStatus;
  final String? todayStart;
  final String? todayEnd;
  final double monthHours;
  final bool nextMonthSubmitted;

  /// "직원 · 매니저", "알바 · 신입"
  String get badge => [employmentLabel(employmentType), ?position, if (newcomer) '신입'].join(' · ');

  factory RosterRow.fromJson(Map<String, dynamic> j) => RosterRow(
        employeeId: j['employeeId'] as int,
        name: j['name'] as String? ?? '',
        employmentType: _employment(j['employmentType']),
        position: j['position'] as String?,
        newcomer: j['newcomer'] as bool? ?? false,
        todayStatus: j['todayStatus'] as String? ?? 'OFF',
        todayStart: j['todayStart'] as String?,
        todayEnd: j['todayEnd'] as String?,
        monthHours: (j['monthHours'] as num?)?.toDouble() ?? 0,
        nextMonthSubmitted: j['nextMonthSubmitted'] as bool? ?? false,
      );
}

class Roster {
  const Roster({required this.pendingApprovals, required this.employees});

  final int pendingApprovals;
  final List<RosterRow> employees;

  factory Roster.fromJson(Map<String, dynamic> j) => Roster(
        pendingApprovals: (j['pendingApprovals'] as num?)?.toInt() ?? 0,
        employees: [for (final e in j['employees'] as List? ?? []) RosterRow.fromJson(e as Map<String, dynamic>)],
      );
}

/// GET /employees, /employees/pending 한 줄 (M01)
class EmployeeInfo {
  const EmployeeInfo({
    required this.id,
    required this.name,
    this.nickname,
    this.hourlyWage,
    this.probationWage,
    this.deduction = PayDeduction.none,
    required this.status,
    this.employmentType,
    this.startDate,
    this.resignedOn,
    required this.minor,
    this.requestedAt,
    this.skills = const [],
  });

  final int id;
  final String name;
  final String? nickname;
  final int? hourlyWage;

  /// 수습 시급 (수습 기간·시작 3개월까지만 적용). null = 감액 없음
  final int? probationWage;
  final PayDeduction deduction;
  final String status;
  final EmploymentType? employmentType;
  final DateTime? startDate;

  /// 승인된 직원이면 퇴사 예정일(마지막 근무일), 퇴사한 직원이면 퇴사일
  final DateTime? resignedOn;
  final bool minor;
  final DateTime? requestedAt;
  final List<String> skills;

  String get displayName => nickname != null && nickname!.isNotEmpty ? nickname! : name;

  factory EmployeeInfo.fromJson(Map<String, dynamic> j) => EmployeeInfo(
        id: j['id'] as int,
        name: j['name'] as String? ?? '',
        nickname: j['nickname'] as String?,
        hourlyWage: j['hourlyWage'] as int?,
        probationWage: j['probationWage'] as int?,
        deduction: PayDeduction.fromJson(j['deduction']),
        status: j['status'] as String? ?? '',
        employmentType: _employment(j['employmentType']),
        startDate: _date(j['startDate']),
        resignedOn: _date(j['resignedOn']),
        minor: j['minor'] as bool? ?? false,
        requestedAt: _date(j['requestedAt']),
        skills: [for (final s in j['skills'] as List? ?? []) s as String],
      );
}

/// 연차 신청 (M01). hasSchedule = 그날 이미 확정된 근무가 있음
class LeaveRequestInfo {
  const LeaveRequestInfo({required this.id, required this.employeeName, required this.date, this.reason, required this.status, this.hasSchedule});

  final int id;
  final String employeeName;
  final DateTime date;
  final String? reason;
  final String status; // PENDING · APPROVED · REJECTED
  final bool? hasSchedule;

  factory LeaveRequestInfo.fromJson(Map<String, dynamic> j) => LeaveRequestInfo(
        id: j['id'] as int,
        employeeName: j['employeeName'] as String? ?? '',
        date: DateTime.parse(j['date'] as String),
        reason: j['reason'] as String?,
        status: j['status'] as String,
        hasSchedule: j['hasSchedule'] as bool?,
      );
}

/// 역량 등급 신청 (GET /skill-requests, M01·P11)
class SkillRequest {
  const SkillRequest({required this.employeeId, required this.employeeName, required this.skillId, required this.skillName, this.level, this.requestedLevel});

  final int employeeId;
  final String employeeName;
  final int skillId;
  final String skillName;
  final SkillLevel? level;
  final SkillLevel? requestedLevel;

  factory SkillRequest.fromJson(Map<String, dynamic> j) => SkillRequest(
        employeeId: j['employeeId'] as int,
        employeeName: j['employeeName'] as String? ?? '',
        skillId: j['skillId'] as int,
        skillName: j['skillName'] as String? ?? '',
        level: j['level'] == null ? null : fromServerEnum(SkillLevel.values, j['level'] as String),
        requestedLevel: j['requestedLevel'] == null ? null : fromServerEnum(SkillLevel.values, j['requestedLevel'] as String),
      );
}

/// 근무자 프로필 (P11)
class EmployeeProfile {
  const EmployeeProfile({
    required this.employeeId,
    required this.name,
    required this.displayName,
    this.employmentType,
    this.position,
    this.startDate,
    this.hourlyWage,
    this.contractMinWeeklyHours,
    this.contractMaxWeeklyHours,
    this.probationUntil,
    required this.promiseScore,
    required this.skills,
    required this.permissions,
    required this.history,
  });

  final int employeeId;
  final String name;
  final String displayName;
  final EmploymentType? employmentType;
  final StaffPosition? position;
  final DateTime? startDate;
  final int? hourlyWage;
  final int? contractMinWeeklyHours;
  final int? contractMaxWeeklyHours;
  final DateTime? probationUntil;
  final int promiseScore;
  final List<SkillRequest> skills; // 등급과 확인 대기 신청 (employeeName 은 비어 있음)
  final Map<EmployeePermission, bool> permissions;
  final List<(DateTime, String)> history;

  factory EmployeeProfile.fromJson(Map<String, dynamic> j) => EmployeeProfile(
        employeeId: j['employeeId'] as int,
        name: j['name'] as String? ?? '',
        displayName: j['displayName'] as String? ?? j['name'] as String? ?? '',
        employmentType: _employment(j['employmentType']),
        position: j['position'] == null ? null : fromServerEnum(StaffPosition.values, j['position'] as String),
        startDate: _date(j['startDate']),
        hourlyWage: j['hourlyWage'] as int?,
        contractMinWeeklyHours: j['contractMinWeeklyHours'] as int?,
        contractMaxWeeklyHours: j['contractMaxWeeklyHours'] as int?,
        probationUntil: _date(j['probationUntil']),
        promiseScore: j['promiseScore'] as int? ?? 0,
        skills: [
          for (final s in j['skills'] as List? ?? [])
            SkillRequest.fromJson({...s as Map<String, dynamic>, 'employeeId': j['employeeId'], 'skillName': s['name']}),
        ],
        permissions: {
          for (final p in j['permissions'] as List? ?? [])
            fromServerEnum(EmployeePermission.values, p['code'] as String): p['allowed'] as bool? ?? false,
        },
        history: [
          for (final h in j['history'] as List? ?? []) (DateTime.parse(h['changedAt'] as String), h['description'] as String? ?? ''),
        ],
      );
}

/// 시간대별 필요 역량 충족 (GET /skill-coverage, M03)
class SkillCoverage {
  const SkillCoverage({required this.window, required this.matchedNames, required this.satisfied, required this.vacancies});

  final SkillWindow window;
  final List<String> matchedNames;
  final bool satisfied;
  final List<(int requestId, String requesterName, String status)> vacancies;

  factory SkillCoverage.fromJson(Map<String, dynamic> j) => SkillCoverage(
        window: SkillWindow.fromJson({...j, 'id': j['requirementId'], 'skillName': j['skillName']}),
        matchedNames: [for (final n in j['matchedNames'] as List? ?? []) n as String],
        satisfied: j['satisfied'] as bool? ?? false,
        vacancies: [
          for (final v in j['vacancies'] as List? ?? [])
            (v['requestId'] as int, v['requesterName'] as String? ?? '', v['status'] as String? ?? ''),
        ],
      );
}

/// 확정 근무 한 칸 (GET /schedules)
class ScheduleEntry {
  const ScheduleEntry({required this.id, required this.employeeId, required this.employeeName, required this.workDate, required this.startTime, required this.endTime, this.reasons = const []});

  final int id;
  final int employeeId;
  final String employeeName;
  final DateTime workDate;
  final String startTime;
  final String endTime;
  final List<String> reasons;

  factory ScheduleEntry.fromJson(Map<String, dynamic> j) => ScheduleEntry(
        id: j['id'] as int,
        employeeId: j['employeeId'] as int,
        employeeName: j['employeeName'] as String? ?? '',
        workDate: DateTime.parse(j['workDate'] as String),
        startTime: j['startTime'] as String,
        endTime: j['endTime'] as String,
        reasons: [for (final r in j['reasons'] as List? ?? []) r as String],
      );
}

/// 후보안 하나의 배정 (M05 배정 사유)
class ProposalAssignment {
  const ProposalAssignment({required this.employeeName, required this.workDate, this.shiftName, required this.startTime, required this.endTime, required this.reasons});

  final String employeeName;
  final DateTime workDate;
  final String? shiftName;
  final String startTime;
  final String endTime;
  final List<String> reasons;

  factory ProposalAssignment.fromJson(Map<String, dynamic> j) => ProposalAssignment(
        employeeName: j['employeeName'] as String? ?? '',
        workDate: DateTime.parse(j['workDate'] as String),
        shiftName: j['shiftName'] as String?,
        startTime: j['startTime'] as String,
        endTime: j['endTime'] as String,
        reasons: [for (final r in j['reasons'] as List? ?? []) r as String],
      );
}

/// 후보안 A·B·C 하나 (M05)
class ProposalCandidate {
  const ProposalCandidate({
    required this.index,
    required this.label,
    this.description,
    required this.estimatedCost,
    this.preferenceRate,
    required this.weekendGap,
    required this.laborLawViolations,
    required this.minStaffCoverage,
    required this.warnings,
    required this.assignments,
  });

  final int index;
  final String label;
  final String? description;
  final int estimatedCost;
  final double? preferenceRate; // % (희망이 없으면 null)
  final int weekendGap;
  final int laborLawViolations;
  final double minStaffCoverage; // %
  final List<String> warnings;
  final List<ProposalAssignment> assignments;

  factory ProposalCandidate.fromJson(Map<String, dynamic> j) {
    final m = j['metrics'] as Map<String, dynamic>? ?? const {};
    return ProposalCandidate(
      index: j['index'] as int,
      label: j['label'] as String? ?? '',
      description: j['description'] as String?,
      estimatedCost: (j['estimatedCost'] as num?)?.toInt() ?? 0,
      preferenceRate: (m['preferenceRate'] as num?)?.toDouble(),
      weekendGap: (m['weekendGap'] as num?)?.toInt() ?? 0,
      laborLawViolations: (m['laborLawViolations'] as num?)?.toInt() ?? 0,
      minStaffCoverage: (m['minStaffCoverage'] as num?)?.toDouble() ?? 0,
      warnings: [for (final w in m['warnings'] as List? ?? []) w as String],
      assignments: [for (final a in j['assignments'] as List? ?? []) ProposalAssignment.fromJson(a as Map<String, dynamic>)],
    );
  }
}

/// POST /schedules/automate, GET /schedules/proposals/{id} 응답 (P03 → M05)
class Proposal {
  const Proposal({
    required this.proposalId,
    required this.success,
    this.message,
    required this.periodStart,
    this.periodEnd,
    this.solveMs,
    this.confirmedIndex,
    required this.candidates,
    this.noticeSummary,
    required this.needsAttention,
  });

  final int? proposalId;
  final bool success;
  final String? message;
  final DateTime periodStart;
  final DateTime? periodEnd;
  final int? solveMs;
  final int? confirmedIndex;
  final List<ProposalCandidate> candidates;
  final String? noticeSummary;
  final bool needsAttention;

  factory Proposal.fromJson(Map<String, dynamic> j) {
    final n = j['notice'] as Map<String, dynamic>?;
    final count = n == null
        ? 0
        : (n['shortageCount'] as int? ?? 0) + (n['mustDayOffViolationCount'] as int? ?? 0) + (n['preferDayOffViolationCount'] as int? ?? 0);
    return Proposal(
      proposalId: j['proposalId'] as int?,
      success: j['success'] as bool? ?? false,
      message: j['message'] as String?,
      periodStart: DateTime.parse(j['weekStart'] as String),
      periodEnd: _date(j['periodEnd']),
      solveMs: (j['solveMs'] as num?)?.toInt(),
      confirmedIndex: j['confirmedIndex'] as int?,
      candidates: [for (final c in j['candidates'] as List? ?? []) ProposalCandidate.fromJson(c as Map<String, dynamic>)],
      noticeSummary: n?['summary'] as String?,
      needsAttention: count > 0,
    );
  }
}

/// 확정 근무표를 누가 봤는지 (P04)
class Acknowledgements {
  const Acknowledgements({required this.seenCount, required this.total, required this.employees});

  final int seenCount;
  final int total;
  final List<(String name, bool seen)> employees;

  factory Acknowledgements.fromJson(Map<String, dynamic> j) => Acknowledgements(
        seenCount: (j['seenCount'] as num).toInt(),
        total: (j['total'] as num).toInt(),
        employees: [for (final e in j['employees'] as List? ?? []) (e['name'] as String? ?? '', e['seen'] as bool? ?? false)],
      );
}

/// 결원 요청 (GET /swap-requests, P06)
class SwapRequestInfo {
  const SwapRequestInfo({
    required this.id,
    required this.workDate,
    required this.startTime,
    required this.endTime,
    this.partialFrom,
    required this.requesterName,
    this.substituteName,
    this.reason,
    this.reasonCategory,
    required this.status,
  });

  final int id;
  final DateTime workDate;
  final String startTime;
  final String endTime;
  final String? partialFrom;
  final String requesterName;
  final String? substituteName;
  final String? reason;
  final AbsenceReason? reasonCategory;
  final String status; // REQUESTED · OFFERED · PENDING_APPROVAL · ACCEPTED · CANCELLED

  bool get active => status == 'REQUESTED' || status == 'OFFERED' || status == 'PENDING_APPROVAL';

  factory SwapRequestInfo.fromJson(Map<String, dynamic> j) => SwapRequestInfo(
        id: j['id'] as int,
        workDate: DateTime.parse(j['workDate'] as String),
        startTime: j['startTime'] as String,
        endTime: j['endTime'] as String,
        partialFrom: j['partialFrom'] as String?,
        requesterName: j['requesterName'] as String? ?? '',
        substituteName: j['substituteName'] as String?,
        reason: j['reason'] as String?,
        reasonCategory: j['reasonCategory'] == null ? null : fromServerEnum(AbsenceReason.values, j['reasonCategory'] as String),
        status: j['status'] as String,
      );
}

/// 대타 후보 (P06). contactStatus: SENT(확인 중)·ACCEPTED·DECLINED·EXPIRED·CLOSED·PENDING_APPROVAL·게시판 지원 상태, 연락 전이면 null
class SwapCandidate {
  const SwapCandidate({required this.employeeId, required this.name, required this.eligible, required this.weeklyHours, required this.coveredSkills, required this.reasons, this.contactStatus, this.waitingMinutes});

  final int employeeId;
  final String name;
  final bool eligible;
  final int weeklyHours;
  final List<String> coveredSkills;
  final List<String> reasons;
  final String? contactStatus;
  final int? waitingMinutes;

  factory SwapCandidate.fromJson(Map<String, dynamic> j) => SwapCandidate(
        employeeId: j['employeeId'] as int,
        name: j['name'] as String? ?? '',
        eligible: j['eligible'] as bool? ?? false,
        weeklyHours: (j['weeklyHours'] as num?)?.toInt() ?? 0,
        coveredSkills: [for (final s in j['coveredSkills'] as List? ?? []) s as String],
        reasons: [for (final s in j['reasons'] as List? ?? []) s as String],
        contactStatus: j['contactStatus'] as String?,
        waitingMinutes: (j['waitingMinutes'] as num?)?.toInt(),
      );
}

/// 빈 근무 게시판 글 (GET /open-shifts, P09·H07). kind: VACANCY(결원) · EXTRA(추가 모집)
class OpenShiftItem {
  const OpenShiftItem({
    required this.id,
    required this.kind,
    this.swapRequestId,
    required this.workDate,
    required this.startTime,
    required this.endTime,
    this.title,
    this.note,
    required this.headcount,
    this.requiredSkill,
    this.applyDeadline,
    required this.applicantCount,
  });

  final int id;
  final String kind;
  final int? swapRequestId;
  final DateTime workDate;
  final String startTime;
  final String endTime;
  final String? title;
  final String? note;
  final int headcount;
  final String? requiredSkill;
  final DateTime? applyDeadline;
  final int applicantCount;

  factory OpenShiftItem.fromJson(Map<String, dynamic> j) => OpenShiftItem(
        id: j['id'] as int,
        kind: j['kind'] as String? ?? 'VACANCY',
        swapRequestId: j['swapRequestId'] as int?,
        workDate: DateTime.parse(j['workDate'] as String),
        startTime: j['startTime'] as String,
        endTime: j['endTime'] as String,
        title: j['title'] as String?,
        note: j['note'] as String?,
        headcount: j['headcount'] as int? ?? 1,
        requiredSkill: j['requiredSkill'] as String?,
        applyDeadline: _date(j['applyDeadline']),
        applicantCount: j['applicantCount'] as int? ?? 0,
      );
}

/// 빈 근무 지원자 (P09). 이번 달 추가 근무가 적은 순
class Applicant {
  const Applicant({required this.id, required this.employeeName, required this.status, required this.monthExtraCount, required this.weekHours, required this.expectedPay, required this.overtime});

  final int id;
  final String employeeName;
  final String status; // APPLIED · APPROVED · REJECTED · WITHDRAWN
  final int monthExtraCount;
  final double weekHours;
  final int expectedPay;
  final bool overtime;

  factory Applicant.fromJson(Map<String, dynamic> j) => Applicant(
        id: j['id'] as int,
        employeeName: j['employeeName'] as String? ?? '',
        status: j['status'] as String? ?? 'APPLIED',
        monthExtraCount: (j['monthExtraCount'] as num?)?.toInt() ?? 0,
        weekHours: (j['weekHours'] as num?)?.toDouble() ?? 0,
        expectedPay: (j['expectedPay'] as num?)?.toInt() ?? 0,
        overtime: j['overtime'] as bool? ?? false,
      );
}

/// 예상 실수령액 계산용 공제 (백엔드 PayDeduction). 근로소득세는 빠진 예상치
enum PayDeduction {
  none('없음'),
  freelance('3.3%'),
  fourInsurance('4대 보험');

  const PayDeduction(this.label);
  final String label;

  String get json => switch (this) { none => 'NONE', freelance => 'FREELANCE', fourInsurance => 'FOUR_INSURANCE' };

  static PayDeduction fromJson(Object? v) => switch (v) { 'FREELANCE' => freelance, 'FOUR_INSURANCE' => fourInsurance, _ => none };
}

/// 월 급여 한 줄 (GET /payroll, M02). deduction·netPay 는 공제 설정으로 계산한 예상치
class PayrollRow {
  const PayrollRow({required this.employeeId, required this.employeeName, required this.totalHours, required this.hourlyWage, required this.regularWage, required this.weeklyHolidayPay, required this.nightPay, required this.overtimePay, this.holidayPay = 0, required this.totalPay, this.deductionType = PayDeduction.none, this.deduction = 0, int? netPay}) : netPay = netPay ?? totalPay;

  final int employeeId;
  final String employeeName;
  final double totalHours;
  final int hourlyWage;
  final int regularWage;
  final int weeklyHolidayPay;
  final int nightPay;
  final int overtimePay;
  /// 공휴일 가산 (5인 이상)
  final int holidayPay;
  final int totalPay;
  final PayDeduction deductionType;
  final int deduction;
  final int netPay;

  factory PayrollRow.fromJson(Map<String, dynamic> j) => PayrollRow(
        employeeId: j['employeeId'] as int,
        employeeName: j['employeeName'] as String? ?? '',
        totalHours: (j['totalHours'] as num?)?.toDouble() ?? 0,
        hourlyWage: (j['hourlyWage'] as num?)?.toInt() ?? 0,
        regularWage: (j['regularWage'] as num?)?.toInt() ?? 0,
        weeklyHolidayPay: (j['weeklyHolidayPay'] as num?)?.toInt() ?? 0,
        nightPay: (j['nightPay'] as num?)?.toInt() ?? 0,
        overtimePay: (j['overtimePay'] as num?)?.toInt() ?? 0,
        holidayPay: (j['holidayPay'] as num?)?.toInt() ?? 0,
        totalPay: (j['totalPay'] as num?)?.toInt() ?? 0,
        deductionType: PayDeduction.fromJson(j['deductionType']),
        deduction: (j['deduction'] as num?)?.toInt() ?? 0,
        netPay: (j['netPay'] as num?)?.toInt(),
      );
}

/// 마감 보고 (P01 '+ 기록')
class ClosingReport {
  const ClosingReport({required this.id, required this.shiftId, required this.shiftName, required this.date, required this.customerCount, this.sales});

  final int id;
  final int shiftId;
  final String shiftName;
  final DateTime date;
  final int customerCount;
  final int? sales;

  factory ClosingReport.fromJson(Map<String, dynamic> j) => ClosingReport(
        id: j['id'] as int,
        shiftId: j['shiftId'] as int,
        shiftName: j['shiftName'] as String? ?? '',
        date: DateTime.parse(j['date'] as String),
        customerCount: (j['customerCount'] as num).toInt(),
        sales: (j['sales'] as num?)?.toInt(),
      );
}

/// "₩1,640,000"
String won(int v) {
  final s = v.abs().toString();
  final b = StringBuffer(v < 0 ? '-₩' : '₩');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

/// "₩1.64M" (요약 카드용)
String wonShort(int v) => v >= 1000000
    ? '₩${(v / 1000000).toStringAsFixed(2)}M'
    : v >= 10000
        ? '₩${(v / 10000).toStringAsFixed(v % 10000 == 0 ? 0 : 1)}만'
        : won(v);

/// "11/20(금)"
String mdw(DateTime d) => '${d.month}/${d.day}(${weekdayLabels[d.weekday - 1]})';

/// "17:00:00", "22:00:00" → "17–22" (정시면 시만)
String hourRange(String start, String end) {
  String h(String t) => t.substring(3, 5) == '00' ? t.substring(0, 2) : hhmm(t);
  return '${h(start)}–${h(end)}';
}
