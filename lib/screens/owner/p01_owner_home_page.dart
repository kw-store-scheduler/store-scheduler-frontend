import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api_service.dart';
import '../../core/notification_api.dart';
import '../../core/owner_api.dart';
import '../../core/store_api.dart';
import '../../core/theme.dart';
import '../../models/owner.dart';
import '../../models/store.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_leaf.dart';
import '../../widgets/thyme_owner_header.dart';
import '../../widgets/thyme_owner_tab_bar.dart';
import '../../widgets/thyme_store_picker.dart';
import '../worker/h04_notification_page.dart';
import 'm01_worker_approval_page.dart';
import 'm03_skill_matching_page.dart';
import 'p03_generating_schedule_page.dart';
import 'p06_substitute_manage_page.dart';

/// P01 점주 홈. GET /home/owner (오늘 교대별 인원·결원·승인 대기·희망 제출 현황·이번 주 인건비)
/// + 오늘 마감 보고(입객) · 안 읽은 알림
class OwnerHomePage extends StatefulWidget {
  const OwnerHomePage({super.key});

  @override
  State<OwnerHomePage> createState() => _OwnerHomePageState();
}

class _OwnerHomePageState extends State<OwnerHomePage> {
  OwnerHome? _home;
  List<ClosingReport> _reports = [];
  int _unread = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final api = OwnerApi();
      final home = await api.home();
      final today = DateUtils.dateOnly(DateTime.now());
      final reports = await api.closingReports(today, today);
      if (!mounted) return;
      setState(() {
        _home = home;
        _reports = reports;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
    try {
      final (unread, _) = await NotificationApi().list(limit: 1);
      if (mounted) setState(() => _unread = unread);
    } on ApiException {
      // 종 버튼의 빨간 점만 빠진다
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _load(); // 승인·대타 처리 후 숫자 갱신
  }

  Future<void> _record() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThymeColor.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _ClosingReportSheet(),
    );
    if (saved == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("입객을 기록했어요. 다음 달 인원 제안에 쓰여요.")));
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final h = _home;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ThymeOwnerHeader(
              title: h?.storeName ?? " ",
              onTitleTap: () => showStorePicker(context),
              trailing: _bell(),
              child: h == null ? null : _stats(h),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: _error != null
                  ? _errorBox()
                  : h == null
                      ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                      : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                          for (final v in h.vacancies) ...[_vacancyBanner(v), const SizedBox(height: 10)],
                          _todoCard(h),
                          const SizedBox(height: 12),
                          _shiftsCard(h),
                          const SizedBox(height: 12),
                          _recordCard(),
                        ]),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const ThymeOwnerTabBar(current: OwnerTab.home),
    );
  }

  Widget _bell() => Material(
        color: ThymeColor.indigoSurface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _open(const NotificationPage()),
          child: SizedBox(
            width: 52,
            height: 52,
            child: Stack(alignment: Alignment.center, children: [
              const Icon(Icons.notifications_none, color: ThymeColor.onPrimary, size: 26),
              if (_unread > 0)
                const Positioned(top: 12, right: 13, child: Icon(Icons.circle, size: 10, color: ThymeColor.danger)),
            ]),
          ),
        ),
      );

  Widget _stats(OwnerHome h) {
    final customers = _reports.fold<int>(0, (s, r) => s + r.customerCount);
    Widget card(String label, Widget value) => Expanded(
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            decoration: BoxDecoration(color: ThymeColor.indigoSurface, borderRadius: BorderRadius.circular(18)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(color: ThymeColor.onPrimarySub, fontSize: 13)),
              const SizedBox(height: 6),
              FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: value),
            ]),
          ),
        );
    return Row(children: [
      card(
        "오늘 인원",
        Text.rich(TextSpan(children: [
          TextSpan(text: "${h.todayAssigned}", style: ThymeTheme.mono(context, size: 24, color: ThymeColor.onPrimary)),
          TextSpan(text: "/${h.todayRequired}", style: ThymeTheme.mono(context, size: 15, color: ThymeColor.onPrimarySub)),
        ])),
      ),
      const SizedBox(width: 8),
      card("이번 주 인건비", Text(wonShort(h.weeklyLaborCost), style: ThymeTheme.mono(context, size: 18, color: ThymeColor.accent))),
      const SizedBox(width: 8),
      card("오늘 입객", Text(_reports.isEmpty ? "–" : "$customers", style: ThymeTheme.mono(context, size: 24, color: ThymeColor.onPrimary))),
    ]);
  }

  static String _statusLabel(String s) => switch (s) {
        'OFFERED' => "대타 응답 대기",
        'PENDING_APPROVAL' => "대타 승인 필요",
        _ => "대타 구하는 중",
      };

  Widget _vacancyBanner(Vacancy v) => Material(
        color: ThymeColor.dangerBg,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _open(SubstituteManagePage(requestId: v.requestId)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(children: [
              Expanded(
                child: Text("${mdw(v.workDate)} ${hourRange(v.startTime, v.endTime)}시 결원 · ${_statusLabel(v.status)}",
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              ),
              const Icon(Icons.circle, size: 8, color: ThymeColor.danger),
              const SizedBox(width: 6),
              const Text("긴급", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.dangerText)),
            ]),
          ),
        ),
      );

  Widget _todoCard(OwnerHome h) {
    final p = h.preferences;
    final todo = h.pendingApprovals + h.pendingLeaves;
    final ratio = p.employeeCount == 0 ? 0.0 : p.submittedCount / p.employeeCount;
    final dday = p.daysUntilDeadline > 0 ? "D-${p.daysUntilDeadline}" : (p.daysUntilDeadline == 0 ? "오늘 마감" : "마감 지남");
    return _card(Column(children: [
      InkWell(
        onTap: () => _open(const WorkerApprovalPage()),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(children: [
            Icon(Icons.circle, size: 10, color: todo > 0 ? ThymeColor.warn : ThymeColor.disabled),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                todo > 0 ? "승인할 것 $todo · 가입 ${h.pendingApprovals} · 연차 ${h.pendingLeaves}" : "승인할 것이 없어요",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text),
              ),
            ),
            const Icon(Icons.arrow_forward, size: 18, color: ThymeColor.textSub),
          ]),
        ),
      ),
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(children: [
          Row(children: [
            Expanded(
              child: Text("${p.monthNumber}월 희망 제출 ${p.submittedCount}/${p.employeeCount} · 마감 $dday",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: ThymeColor.infoText, padding: EdgeInsets.zero),
              onPressed: () => _open(const GeneratingSchedulePage()),
              child: const Text("근무표 만들기 →", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ]),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(value: ratio, minHeight: 8, color: ThymeColor.info, backgroundColor: ThymeColor.selectedSoft),
          ),
        ]),
      ),
    ]));
  }

  Widget _shiftsCard(OwnerHome h) => _card(Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(children: [
          Row(children: [
            Expanded(child: Text("오늘 ${mdw(h.date)} 교대별", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text))),
            InkWell(
              onTap: () => _open(const SkillMatchingPage()),
              child: const Text("역량 보기 →", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text, decoration: TextDecoration.underline)),
            ),
          ]),
          const SizedBox(height: 12),
          if (h.todayShifts.isEmpty)
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("오늘은 정해진 교대가 없어요.", style: TextStyle(fontSize: 14, color: ThymeColor.textSub)),
            ),
          for (final s in h.todayShifts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(children: [
                SizedBox(width: 72, child: Text(s.shiftName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text))),
                Expanded(
                  child: Tooltip(
                    message: s.employeeNames.isEmpty ? "아직 아무도 없어요" : s.employeeNames.join(", "),
                    child: Wrap(spacing: 6, runSpacing: 6, children: [
                      // 채운 사람 = 민트 잎, 모자란 자리 = 로즈 점선 잎 (가이드 4-5)
                      for (var i = 0; i < s.employeeNames.length; i++) ThymeLeaf(size: 26, flip: i.isOdd),
                      for (var i = 0; i < s.shortage; i++) const ThymeLeaf(size: 26, color: ThymeColor.danger, dashed: true),
                    ]),
                  ),
                ),
                Text("${s.employeeNames.length}/${s.requiredStaff}",
                    style: ThymeTheme.mono(context, size: 16, color: s.shortage > 0 ? ThymeColor.dangerText : ThymeColor.successText)),
              ]),
            ),
        ]),
      ));

  Widget _recordCard() => _card(Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(children: [
          const Expanded(child: Text("지금 입객 체크하기", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text))),
          if (_reports.isNotEmpty) Text("오늘 ${_reports.length}건", style: const TextStyle(fontSize: 14, color: ThymeColor.textSub)),
          const SizedBox(width: 12),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 48), padding: const EdgeInsets.symmetric(horizontal: 20)),
            onPressed: _record,
            child: const Text("+ 기록"),
          ),
        ]),
      ));

  Widget _card(Widget child) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
        child: child,
      );

  Widget _errorBox() => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: ThymeColor.dangerBg, borderRadius: BorderRadius.circular(16)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
          TextButton(onPressed: _load, child: const Text("다시 불러오기")),
        ]),
      );
}

/// '+ 기록': 교대를 고르고 객수(매출은 선택)를 적어 POST /closing-reports. 직전 4주 객수로 다음 달 인원을 제안한다
class _ClosingReportSheet extends StatefulWidget {
  const _ClosingReportSheet();

  @override
  State<_ClosingReportSheet> createState() => _ClosingReportSheetState();
}

class _ClosingReportSheetState extends State<_ClosingReportSheet> {
  List<ShiftInfo>? _shifts;
  ShiftInfo? _shift;
  final _count = TextEditingController();
  final _sales = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _count.addListener(() => setState(() {}));
    StoreApi().shifts().then((s) {
      if (!mounted) return;
      // 지금 시각이 들어가는 교대를 먼저 골라 둔다
      final now = TimeOfDay.now();
      final minutes = now.hour * 60 + now.minute;
      int m(String t) => int.parse(t.substring(0, 2)) * 60 + int.parse(t.substring(3, 5));
      setState(() {
        _shifts = s;
        _shift = s.where((x) => m(x.startTime) <= minutes && minutes < m(x.endTime)).firstOrNull ?? s.firstOrNull;
      });
    }, onError: (Object e) {
      if (mounted) setState(() => _error = e is ApiException ? e.message : "$e");
    });
  }

  @override
  void dispose() {
    _count.dispose();
    _sales.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await OwnerApi().addClosingReport(
        shiftId: _shift!.id,
        date: DateUtils.dateOnly(DateTime.now()),
        customerCount: int.parse(_count.text),
        sales: int.tryParse(_sales.text),
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shifts = _shifts;
    final valid = _shift != null && int.tryParse(_count.text) != null;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text("오늘 입객 기록", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            const SizedBox(height: 4),
            const Text("같은 교대를 다시 적으면 덮어써요.", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
            const SizedBox(height: 16),
            if (shifts == null && _error == null) const Center(child: CircularProgressIndicator()),
            if (shifts != null)
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in shifts)
                  ChoiceChip(
                    label: Text("${s.name} ${hourRange(s.startTime, s.endTime)}"),
                    selected: _shift?.id == s.id,
                    onSelected: (_) => setState(() => _shift = s),
                    selectedColor: ThymeColor.primary,
                    labelStyle: TextStyle(color: _shift?.id == s.id ? ThymeColor.onPrimary : ThymeColor.text, fontWeight: FontWeight.bold),
                    showCheckmark: false,
                  ),
              ]),
            const SizedBox(height: 16),
            TextField(
              controller: _count,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: "객수 (명)"),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _sales,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: "매출 (원, 선택)"),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: valid && !_saving ? _save : null, child: Text(_saving ? "저장 중…" : "기록")),
            ),
          ]),
        ),
      ),
    );
  }
}
