import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/owner_api.dart';
import '../../core/theme.dart';
import '../../models/owner.dart';
import '../../models/user.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_owner_header.dart';
import 'm01_worker_approval_page.dart';
import 'p11_worker_profile_confirm_page.dart';

/// P07 근무자 목록. GET /roster: 직원/알바, 오늘 상태(근무 중·결원·휴무), 이번 달 시간, 다음 달 희망 제출 여부
class WorkerListPage extends StatefulWidget {
  const WorkerListPage({super.key});

  @override
  State<WorkerListPage> createState() => _WorkerListPageState();
}

class _WorkerListPageState extends State<WorkerListPage> {
  Roster? _roster;
  EmploymentType? _filter; // null = 전체
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final r = await OwnerApi().roster();
      if (mounted) setState(() => _roster = r);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final r = _roster;
    final all = r?.employees ?? const <RosterRow>[];
    final full = all.where((e) => e.employmentType == EmploymentType.fullTime).length;
    final shown = _filter == null ? all : all.where((e) => (e.employmentType ?? EmploymentType.partTime) == _filter).toList();
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: EdgeInsets.zero, children: [
          ThymeOwnerHeader(
            title: "근무자 ${all.length}명",
            showBack: true,
            trailing: r == null
                ? null
                : FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: ThymeColor.surface,
                      foregroundColor: ThymeColor.text,
                      minimumSize: const Size(0, 48),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                    ),
                    onPressed: () => _open(const WorkerApprovalPage()),
                    child: Text("승인 대기 ${r.pendingApprovals}"),
                  ),
            child: _tabs(all.length, full, all.length - full),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: _error != null
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                    TextButton(onPressed: _load, child: const Text("다시 불러오기")),
                  ])
                : r == null
                    ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                    : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        if (shown.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(16)),
                            child: const Text("아직 승인된 근무자가 없어요. 매장 코드를 보내 초대하고, 가입 요청을 승인해 주세요.",
                                style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.5)),
                          ),
                        for (final e in shown) _row(e),
                        if (shown.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 6),
                            child: Text("● 민트 근무 중 · 회색 휴무 · 로즈 결원 · 오른쪽은 다음 달 희망 제출 상태",
                                style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                          ),
                      ]),
          ),
        ]),
      ),
    );
  }

  Widget _tabs(int all, int full, int part) => Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(color: ThymeColor.indigoSurface, borderRadius: BorderRadius.circular(18)),
        child: Row(children: [
          for (final (type, label) in [(null, "전체 $all"), (EmploymentType.fullTime, "직원 $full"), (EmploymentType.partTime, "알바 $part")])
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _filter = type),
                child: Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(color: _filter == type ? ThymeColor.surface : Colors.transparent, borderRadius: BorderRadius.circular(14)),
                  child: Text(label,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _filter == type ? ThymeColor.text : ThymeColor.onPrimarySub)),
                ),
              ),
            ),
        ]),
      );

  Widget _row(RosterRow e) {
    final (dot, status) = switch (e.todayStatus) {
      'WORKING' => (ThymeColor.accent, "근무 · ${e.todayStart == null ? '' : hourRange(e.todayStart!, e.todayEnd!)}"),
      'VACANCY' => (ThymeColor.danger, "결원${e.todayStart == null ? '' : ' · ${hourRange(e.todayStart!, e.todayEnd!)}'}"),
      _ => (ThymeColor.disabled, "휴무"),
    };
    final full = e.employmentType == EmploymentType.fullTime;
    final hours = e.monthHours == e.monthHours.roundToDouble() ? "${e.monthHours.toInt()}h" : "${e.monthHours}h";
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: ThymeColor.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _open(WorkerProfileConfirmPage(employeeId: e.employeeId)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Stack(clipBehavior: Clip.none, children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: ThymeColor.selectedSoft,
                  child: Text(e.name.isEmpty ? "?" : e.name.characters.first,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                ),
                Positioned(
                  right: -2,
                  bottom: -2,
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(color: dot, shape: BoxShape.circle, border: Border.all(color: ThymeColor.surface, width: 3)),
                  ),
                ),
              ]),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    Text(e.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: full ? ThymeColor.primary : ThymeColor.selectedSoft, borderRadius: BorderRadius.circular(99)),
                      child: Text(e.badge,
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: full ? ThymeColor.onPrimary : ThymeColor.text)),
                    ),
                  ]),
                  const SizedBox(height: 4),
                  Text(status, style: const TextStyle(fontSize: 14, color: ThymeColor.textSub)),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(hours, style: ThymeTheme.mono(context, size: 16)),
                const SizedBox(height: 6),
                Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.circle, size: 8, color: e.nextMonthSubmitted ? ThymeColor.accent : ThymeColor.danger),
                  const SizedBox(width: 4),
                  Text(e.nextMonthSubmitted ? "제출" : "미제출",
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: e.nextMonthSubmitted ? ThymeColor.successText : ThymeColor.dangerText)),
                ]),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
