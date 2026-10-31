import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api_service.dart';
import '../../core/join_api.dart';
import '../../core/owner_api.dart';
import '../../core/store_api.dart';
import '../../core/theme.dart';
import '../../models/owner.dart';
import '../../models/user.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_owner_header.dart';
import 'p11_worker_profile_confirm_page.dart';

/// 2026년 최저시급 (승인할 때 시급 기본값)
const minimumWage2026 = 10320;

/// M01 근무자 승인. 매장 코드 공유 · 다음 달 희망 제출 현황 · 가입 승인(시급) · 연차 승인 · 계약 초과 근무량 · 역량 신청
class WorkerApprovalPage extends StatefulWidget {
  const WorkerApprovalPage({super.key});

  @override
  State<WorkerApprovalPage> createState() => _WorkerApprovalPageState();
}

class _WorkerApprovalPageState extends State<WorkerApprovalPage> {
  String? _storeCode;
  PreferenceStatus? _prefs;
  List<EmployeeInfo>? _pending;
  List<LeaveRequestInfo> _leaves = [];
  List<SkillRequest> _skillRequests = [];

  /// 다음 달 희망에서 계약 상한을 넘겨 신청한 사람 (W06). 못 받아도 나머지는 보여 준다
  List<PreferenceSubmissionRow> _exceed = [];
  List<RosterRow> _approved = [];
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final api = OwnerApi();
      final store = await StoreApi().current();
      final home = await api.home();
      final pending = await api.pendingEmployees();
      final leaves = await api.leaves();
      final skillRequests = await api.skillRequests();
      final roster = await api.roster();
      final submissions = await api.preferenceSubmissions(home.preferences.month).catchError((_) => <PreferenceSubmissionRow>[]);
      if (!mounted) return;
      setState(() {
        _storeCode = store.storeCode;
        _prefs = home.preferences;
        _pending = pending;
        _leaves = [for (final l in leaves) if (l.status == 'PENDING') l];
        _skillRequests = skillRequests;
        _exceed = [for (final s in submissions) if (s.needsContractApproval) s];
        _approved = roster.employees;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _run(Future<void> Function() action, String done) async {
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) _toast(done);
      await _load();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _approve(EmployeeInfo e) async {
    final result = await showModalBottomSheet<(int, EmploymentType)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThymeColor.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ApproveSheet(employee: e),
    );
    if (result == null || !mounted) return;
    final (wage, type) = result;
    await _run(() => OwnerApi().approve(e.id, hourlyWage: wage, employmentType: type), "${e.displayName}님을 승인했어요");
  }

  Future<void> _approveLeave(LeaveRequestInfo l) async {
    setState(() => _busy = true);
    try {
      final r = await OwnerApi().approveLeave(l.id);
      if (!mounted) return;
      _toast(r.hasSchedule == true
          ? "승인했어요. 그날 이미 근무가 있어요 — 대타를 구하거나 근무표를 다시 만들어 주세요."
          : "${l.employeeName}님 연차를 승인했어요");
      await _load();
    } on ApiException catch (e) {
      if (mounted) _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = _pending;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: EdgeInsets.zero, children: [
          const ThymeOwnerHeader(title: "가입 · 연차 승인", showBack: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: _error != null
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                    TextButton(onPressed: _load, child: const Text("다시 불러오기")),
                  ])
                : pending == null
                    ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                    : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        _codeCard(),
                        const SizedBox(height: 12),
                        if (_prefs != null) _prefsBanner(_prefs!),
                        const SizedBox(height: 20),
                        _section("가입 대기 ${pending.length}", "승인할 때 시급을 정해요"),
                        if (pending.isEmpty) _empty("새 가입 요청이 없어요. 매장 코드를 보내 직원을 초대해 보세요."),
                        for (final e in pending) _pendingCard(e),
                        if (_leaves.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _section("연차 신청 ${_leaves.length}", "승인하면 그날은 필수 휴무"),
                          for (final l in _leaves) _leaveCard(l),
                        ],
                        if (_exceed.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _section("${_prefs!.monthNumber}월 계약보다 많이 일하기 ${_exceed.length}", "승인 안 하면 계약 시간까지만"),
                          for (final s in _exceed) _exceedCard(s),
                        ],
                        if (_skillRequests.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _section("역량 확인 대기 ${_skillRequests.length}", "프로필에서 확정해요"),
                          for (final r in _skillRequests) _skillRequestRow(r),
                        ],
                        const SizedBox(height: 16),
                        _approvedRow(),
                      ]),
          ),
        ]),
      ),
    );
  }

  Widget _codeCard() => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("매장 코드 · 직원에게 보내 주세요", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(_storeCode ?? "", style: ThymeTheme.mono(context, size: 30, color: ThymeColor.text).copyWith(letterSpacing: 4)),
              ),
            ]),
          ),
          OutlinedButton(
            onPressed: _storeCode == null
                ? null
                : () async {
                    await Clipboard.setData(ClipboardData(text: JoinApi.inviteLink(_storeCode!)));
                    if (mounted) _toast("초대 링크를 복사했어요");
                  },
            child: const Text("링크 복사"),
          ),
        ]),
      );

  Widget _prefsBanner(PreferenceStatus p) {
    final dday = p.daysUntilDeadline > 0 ? "마감 D-${p.daysUntilDeadline}" : (p.daysUntilDeadline == 0 ? "오늘 마감" : "마감 지남");
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(color: ThymeColor.infoBg, borderRadius: BorderRadius.circular(16)),
      child: Row(children: [
        const Icon(Icons.circle, size: 10, color: ThymeColor.info),
        const SizedBox(width: 12),
        Expanded(
          child: Text("${p.monthNumber}월 희망 제출 ${p.submittedCount}/${p.employeeCount} · $dday",
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.infoText)),
        ),
      ]),
    );
  }

  Widget _section(String title, String hint) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(children: [
          Expanded(child: Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text))),
          Text(hint, style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
        ]),
      );

  Widget _empty(String text) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(16)),
        child: Text(text, style: const TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.5)),
      );

  static String _ymd(DateTime d) => "${d.year}. ${d.month}. ${d.day}";

  Widget _avatar(String name, {Color bg = ThymeColor.selectedSoft, Color fg = ThymeColor.text, double size = 48}) => CircleAvatar(
        radius: size / 2,
        backgroundColor: bg,
        child: Text(name.isEmpty ? "?" : name.characters.first, style: TextStyle(fontSize: size * 0.4, fontWeight: FontWeight.bold, color: fg)),
      );

  Widget _pendingCard(EmployeeInfo e) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _avatar(e.displayName),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.nickname != null && e.nickname!.isNotEmpty && e.nickname != e.name ? "${e.nickname} (${e.name})" : e.name,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                const SizedBox(height: 4),
                Text(
                  [
                    employmentLabel(e.employmentType),
                    if (e.startDate != null) "${_ymd(e.startDate!)} 시작",
                    if (e.minor) "만 18세 미만",
                  ].join(" · "),
                  style: const TextStyle(fontSize: 14, color: ThymeColor.textSub),
                ),
              ]),
            ),
          ]),
          if (e.skills.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final s in e.skills)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(99)),
                  child: Text(s, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                ),
            ]),
          ],
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _busy ? null : () => _run(() => OwnerApi().reject(e.id), "${e.displayName}님 가입을 거절했어요"),
                child: const Text("거절"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(child: FilledButton(onPressed: _busy ? null : () => _approve(e), child: const Text("승인"))),
          ]),
        ]),
      );

  Widget _leaveCard(LeaveRequestInfo l) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("${l.employeeName} · ${mdw(l.date)}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              if (l.reason != null && l.reason!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(l.reason!, style: const TextStyle(fontSize: 14, color: ThymeColor.textSub)),
              ],
            ]),
          ),
          TextButton(
            onPressed: _busy ? null : () => _run(() => OwnerApi().rejectLeave(l.id), "연차를 거절했어요"),
            child: const Text("거절"),
          ),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 18)),
            onPressed: _busy ? null : () => _approveLeave(l),
            child: const Text("승인"),
          ),
        ]),
      );

  /// 계약 상한을 넘긴 근무량 신청 (W06). 서버가 거절한 것도 '승인 전'으로 주기 때문에 승인 버튼은 남는다
  Widget _exceedCard(PreferenceSubmissionRow s) {
    final month = _prefs!.month;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            const SizedBox(height: 4),
            const Text("계약 상한보다 많이 일하고 싶대요", style: TextStyle(fontSize: 14, color: ThymeColor.textSub)),
          ]),
        ),
        TextButton(
          onPressed: _busy ? null : () => _run(() => OwnerApi().decideContractExceed(s.employeeId, month, approved: false), "계약 시간까지만 배치해요"),
          child: const Text("거절"),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(0, 44), padding: const EdgeInsets.symmetric(horizontal: 18)),
          onPressed: _busy ? null : () => _run(() => OwnerApi().decideContractExceed(s.employeeId, month, approved: true), "${s.name}님 추가 근무를 승인했어요"),
          child: const Text("승인"),
        ),
      ]),
    );
  }

  Widget _skillRequestRow(SkillRequest r) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: ThymeColor.surface,
          borderRadius: BorderRadius.circular(16),
          child: ListTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text("${r.employeeName} · ${r.skillName}", style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text("${r.level?.label ?? '없음'} → ${r.requestedLevel?.label ?? ''} 신청"),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (_) => WorkerProfileConfirmPage(employeeId: r.employeeId)));
              if (mounted) _load();
            },
          ),
        ),
      );

  Widget _approvedRow() => Row(children: [
        Text("승인됨 ${_approved.length}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
        const SizedBox(width: 10),
        Expanded(
          child: SizedBox(
            height: 40,
            child: Stack(children: [
              for (var i = 0; i < _approved.length && i < 6; i++)
                Positioned(
                  left: i * 26.0,
                  child: _avatar(_approved[i].name, bg: ThymeColor.successBg, fg: ThymeColor.successText, size: 40),
                ),
            ]),
          ),
        ),
      ]);
}

/// 가입 승인: 시급(필수)과 고용 형태(근로자가 고른 값이 기본)
class _ApproveSheet extends StatefulWidget {
  const _ApproveSheet({required this.employee});

  final EmployeeInfo employee;

  @override
  State<_ApproveSheet> createState() => _ApproveSheetState();
}

class _ApproveSheetState extends State<_ApproveSheet> {
  // 승인 전 시급은 서버가 0으로 준다 → 최저시급으로 시작
  late final _wage = TextEditingController(text: "${(widget.employee.hourlyWage ?? 0) > 0 ? widget.employee.hourlyWage : minimumWage2026}");
  late EmploymentType _type = widget.employee.employmentType ?? EmploymentType.partTime;

  @override
  void initState() {
    super.initState();
    _wage.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _wage.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wage = int.tryParse(_wage.text) ?? 0;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("${widget.employee.displayName}님 승인", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            const SizedBox(height: 16),
            SegmentedButton<EmploymentType>(
              segments: const [
                ButtonSegment(value: EmploymentType.partTime, label: Text("알바")),
                ButtonSegment(value: EmploymentType.fullTime, label: Text("직원")),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _wage,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: "시급 (원)", helperText: "2026년 최저시급 10,320원"),
            ),
            if (wage > 0 && wage < minimumWage2026) ...[
              const SizedBox(height: 8),
              const Text("최저시급보다 낮아요.", style: TextStyle(color: ThymeColor.dangerText, fontWeight: FontWeight.bold)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: wage > 0 ? () => Navigator.pop(context, (wage, _type)) : null,
                child: Text("시급 ${won(wage)}로 승인"),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
