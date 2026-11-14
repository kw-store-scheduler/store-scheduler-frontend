import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/store_api.dart';
import '../../core/theme.dart';
import '../../core/worker_api.dart';
import '../../models/owner.dart';
import '../../models/worker.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_back_button.dart';
import '../../widgets/thyme_pickers.dart';

/// 직원(정규직) 연차 (시안 없음, H02 '남은 연차'에서). GET /leaves/my · POST /leaves · POST /leaves/{id}/cancel
/// 근무표가 나온 뒤 쉬어야 할 때 신청한다. 사장님이 승인하면 그날은 필수 휴무가 된다 (승인 화면은 M01).
/// 다음 달 근무표를 만들기 전이면 E01 희망 신청에서 '안 되면 연차'로 미리 적을 수 있다
class AnnualLeavePage extends StatefulWidget {
  const AnnualLeavePage({super.key});

  @override
  State<AnnualLeavePage> createState() => _AnnualLeavePageState();
}

class _AnnualLeavePageState extends State<AnnualLeavePage> {
  MyLeaves? _leaves;
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
      final l = await WorkerApi().myLeaves();
      if (mounted) setState(() => _leaves = l);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  static DateTime get _today => DateUtils.dateOnly(DateTime.now());

  /// 승인 대기·승인 = 이미 쓴 날 (서버가 같은 날 두 번은 막는다)
  static bool _counted(LeaveRequestInfo r) => r.status == 'PENDING' || r.status == 'APPROVED';

  Future<void> _request() async {
    final taken = {for (final r in _leaves!.requests.where(_counted)) DateUtils.dateOnly(r.date)};
    final date = await showThymeDatePicker(
      context,
      first: _today,
      last: _today.add(const Duration(days: 365)),
      selectable: (d) => !taken.contains(d),
      title: "연차 쓸 날",
      holidays: StoreApi().holidays,
    );
    if (date == null || !mounted) return;
    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: ThymeColor.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (_) => _ReasonSheet(date: date),
    );
    if (reason == null || !mounted) return;
    setState(() => _busy = true);
    try {
      await WorkerApi().requestLeave(date, reason: reason);
      _toast("${thymeMdw(date)} 연차를 신청했어요. 사장님이 승인하면 알려 드려요");
      await _load();
    } on ApiException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _cancel(LeaveRequestInfo r) async {
    final approved = r.status == 'APPROVED';
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("${thymeMdw(r.date)} 연차를 취소할까요?"),
        content: Text(approved ? "승인된 연차예요. 취소하면 그날 휴무도 풀리고, 사장님께 알림이 가요." : "사장님께 취소 알림이 가요."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("아니요")),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("연차 취소")),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _busy = true);
    try {
      await WorkerApi().cancelLeave(r.id);
      _toast("${thymeMdw(r.date)} 연차를 취소했어요");
      await _load();
    } on ApiException catch (e) {
      _toast(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = _leaves;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: AppBar(
        backgroundColor: ThymeColor.bg,
        leading: const ThymeBackButton(),
        title: const Text("연차", style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _error != null
          ? ListView(padding: const EdgeInsets.all(20), children: [
              Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
              TextButton(onPressed: _load, child: const Text("다시 불러오기")),
            ])
          : l == null
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 32), children: [
                    if (!l.fullTime)
                      _note("연차는 정규직만 신청할 수 있어요. 알바는 희망 신청에서 쉬고 싶은 날을 내 주세요.")
                    else ...[
                      _balance(l),
                      const SizedBox(height: 12),
                      _note("근무표가 나온 뒤에 쉬어야 할 때 신청해요. 사장님이 승인하면 그날은 휴무가 되고, "
                          "이미 잡힌 근무가 있으면 사장님이 대타를 구해요.\n"
                          "다음 달 근무표를 만들기 전이라면 희망 신청에서 미리 쉬는 날을 적을 수 있어요."),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _busy || (l.remaining ?? 0) < 1 ? null : _request,
                          child: Text((l.remaining ?? 0) < 1 ? "남은 연차가 없어요" : "연차 신청"),
                        ),
                      ),
                    ],
                    const SizedBox(height: 28),
                    const Text("신청한 연차", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                    const SizedBox(height: 10),
                    if (l.requests.isEmpty)
                      const Text("아직 신청한 연차가 없어요.", style: TextStyle(fontSize: 14, color: ThymeColor.textSub))
                    else
                      Container(
                        decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
                        child: Column(children: [
                          for (final (i, r) in l.requests.indexed) ...[
                            if (i > 0) const Divider(height: 1, indent: 18, endIndent: 18),
                            _row(r),
                          ],
                        ]),
                      ),
                  ]),
                ),
    );
  }

  Widget _balance(MyLeaves l) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: ThymeColor.primary, borderRadius: BorderRadius.circular(22)),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text("남은 연차", style: TextStyle(fontSize: 13, color: ThymeColor.onPrimarySub)),
              const SizedBox(height: 4),
              Text.rich(TextSpan(children: [
                TextSpan(text: "${l.remaining}", style: ThymeTheme.mono(context, size: 34, color: ThymeColor.accent)),
                const TextSpan(text: " 일", style: TextStyle(fontSize: 16, color: ThymeColor.onPrimarySub)),
              ])),
            ]),
          ),
          _mini("올해 생긴", "${l.entitled}일"),
          const SizedBox(width: 16),
          _mini("쓴 연차", "${l.used}일", sub: "대기 포함"),
        ]),
      );

  Widget _mini(String label, String value, {String? sub}) => Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(label, style: const TextStyle(fontSize: 12, color: ThymeColor.onPrimarySub)),
        Text(value, style: ThymeTheme.mono(context, size: 18, color: ThymeColor.onPrimary)),
        if (sub != null) Text(sub, style: const TextStyle(fontSize: 11, color: ThymeColor.onPrimarySub)),
      ]);

  Widget _note(String text) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: ThymeColor.infoBg, borderRadius: BorderRadius.circular(16)),
        child: Text(text, style: const TextStyle(fontSize: 13, color: ThymeColor.infoText, height: 1.5)),
      );

  Widget _row(LeaveRequestInfo r) {
    final (fg, label) = switch (r.status) {
      'PENDING' => (ThymeColor.infoText, "승인 대기"),
      'APPROVED' => (ThymeColor.successText, "승인"),
      'REJECTED' => (ThymeColor.dangerText, "반려"),
      _ => (ThymeColor.textSub, "취소함"),
    };
    final canCancel = _counted(r) && !r.date.isBefore(_today);
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 8, 12),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(thymeMdw(r.date), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            if (r.reason != null && r.reason!.isNotEmpty) Text(r.reason!, style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
          ]),
        ),
        Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: fg)),
        if (canCancel) TextButton(onPressed: _busy ? null : () => _cancel(r), child: const Text("취소")) else const SizedBox(width: 12),
      ]),
    );
  }
}

/// 날짜를 고른 뒤: 사유(선택) 적고 신청
class _ReasonSheet extends StatefulWidget {
  const _ReasonSheet({required this.date});

  final DateTime date;

  @override
  State<_ReasonSheet> createState() => _ReasonSheetState();
}

class _ReasonSheetState extends State<_ReasonSheet> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text("${thymeMdw(widget.date)} 연차 신청", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              const SizedBox(height: 4),
              const Text("사장님께 알림이 가요. 사유는 사장님만 봐요.", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
              const SizedBox(height: 16),
              TextField(
                controller: _reason,
                maxLength: 100,
                decoration: const InputDecoration(hintText: "사유 (선택) · 예: 가족 행사"),
              ),
              const SizedBox(height: 8),
              FilledButton(onPressed: () => Navigator.pop(context, _reason.text), child: const Text("신청하기")),
            ]),
          ),
        ),
      );
}
