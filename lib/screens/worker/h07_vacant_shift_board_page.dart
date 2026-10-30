import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../core/worker_api.dart';
import '../../models/owner.dart';
import '../../models/worker.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_back_button.dart';
import '../../widgets/thyme_worker_tab_bar.dart';
import 'h12_absence_report_page.dart';
import 'w09_shift_swap_page.dart';

/// H07 빈 근무 게시판 (근로자 하단 탭 '대타·교대'). GET /open-shifts
/// 결원·추가 모집 글에 지원하거나(POST applications) 지원을 취소한다(DELETE applications/my).
/// 규칙에 걸리는 근무는 서버가 eligible=false 와 사유(blocker)를 준다 → 회색 '불가'
class VacantShiftBoardPage extends StatefulWidget {
  const VacantShiftBoardPage({super.key});

  @override
  State<VacantShiftBoardPage> createState() => _VacantShiftBoardPageState();
}

class _VacantShiftBoardPageState extends State<VacantShiftBoardPage> {
  Board? _board;
  String? _error;
  int? _busyId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final b = await WorkerApi().board();
      if (mounted) setState(() => _board = b);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _toggle(BoardPost p) async {
    setState(() => _busyId = p.item.id);
    try {
      final api = WorkerApi();
      p.applied ? await api.withdraw(p.item.id) : await api.apply(p.item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(p.applied ? "지원을 취소했어요" : "지원했어요. 사장님이 고르면 알려 드려요")));
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final b = _board;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: AppBar(
        backgroundColor: ThymeColor.bg,
        elevation: 0,
        // 탭 첫 화면이면 뒤로가기 자리를 비우지 않는다
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context) ? const ThymeBackButton(size: 20) : null,
        title: const Text("빈 근무", style: TextStyle(color: ThymeColor.text, fontSize: 22, fontWeight: FontWeight.bold)),
        centerTitle: false,
        actions: [
          _headerButton("근무 바꾸기", () => _open(const ShiftSwapPage())),
          const SizedBox(width: 8),
          // 내 근무 내놓기 = H12 결원 신고
          _headerButton("내 근무 내놓기", () => _open(const AbsenceReportPage())),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 32), children: [
          if (_error != null) ...[
            Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
            TextButton(onPressed: _load, child: const Text("다시 불러오기")),
          ] else if (b == null)
            const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
          else ...[
            if (b.myWeekDays != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(16)),
                child: Text.rich(TextSpan(style: const TextStyle(fontSize: 15, color: ThymeColor.text), children: [
                  const TextSpan(text: "이번 주 "),
                  TextSpan(text: "${b.myWeekDays}일 · ${b.myWeekHours ?? 0}시간", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: " 근무 중"),
                ])),
              ),
            const SizedBox(height: 12),
            if (b.posts.isEmpty)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(16)),
                child: const Text("지금 올라온 빈 근무가 없어요. 새 글이 올라오면 알림으로 알려 드려요.",
                    style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.5)),
              )
            else
              for (final p in b.posts) _card(p),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: ThymeColor.infoBg, borderRadius: BorderRadius.circular(16)),
              child: const Text("지원하면 사장님이 고르고, 승인되면 근무표와 수당이 바로 바뀌어요. 규칙에 걸리는 근무는 지원할 수 없어요.",
                  style: TextStyle(fontSize: 14, color: ThymeColor.infoText, height: 1.5)),
            ),
          ],
        ]),
      ),
      bottomNavigationBar: const ThymeWorkerTabBar(current: WorkerTab.swap),
    );
  }

  Widget _headerButton(String label, VoidCallback onPressed) => Center(
        child: OutlinedButton(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 36),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
            side: const BorderSide(color: ThymeColor.border),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onPressed: onPressed,
          child: Text(label, style: const TextStyle(color: ThymeColor.text, fontSize: 13, fontWeight: FontWeight.bold)),
        ),
      );

  Widget _card(BoardPost p) {
    final o = p.item;
    final vacancy = o.kind == 'VACANCY';
    final blocked = p.eligible == false && !p.applied;
    final dim = blocked ? ThymeColor.disabled : ThymeColor.text;
    final sub = blocked ? (p.blocker ?? "지원할 수 없어요") : [o.requiredSkill == null ? "누구나" : "${o.requiredSkill} 가능자", "규칙 통과"].join(" · ");
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: blocked ? ThymeColor.surfaceSub : ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (vacancy) ...[
            const Icon(Icons.circle, size: 8, color: ThymeColor.danger),
            const SizedBox(width: 6),
            const Text("결원", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.dangerText)),
          ] else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: ThymeColor.selectedSoft, borderRadius: BorderRadius.circular(12)),
              child: const Text("추가 인원", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text([mdw(o.workDate), if (o.title != null && o.title!.isNotEmpty) o.title!].join(" · "),
                overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, color: ThymeColor.textSub)),
          ),
          if (p.expectedPay != null) Text(won(p.expectedPay!), style: ThymeTheme.mono(context, size: 15, color: dim)),
        ]),
        const SizedBox(height: 10),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(timeRange(o.startTime, o.endTime), style: ThymeTheme.mono(context, size: 24, color: dim)),
              const SizedBox(height: 4),
              Text(sub, style: TextStyle(fontSize: 13, color: blocked ? ThymeColor.dangerText : ThymeColor.textSub)),
            ]),
          ),
          const SizedBox(width: 10),
          if (p.applied)
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44), backgroundColor: ThymeColor.selectedSoft, foregroundColor: ThymeColor.text),
              onPressed: _busyId != null || p.myStatus == 'APPROVED' ? null : () => _toggle(p),
              icon: const Icon(Icons.check, size: 18),
              label: Text(p.myStatus == 'APPROVED' ? "배정됨" : "지원함"),
            )
          else
            FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              onPressed: blocked || _busyId != null ? null : () => _toggle(p),
              child: Text(blocked ? "불가" : "지원하기"),
            ),
        ]),
      ]),
    );
  }
}
