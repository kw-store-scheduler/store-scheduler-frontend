import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/theme.dart';
import '../../core/worker_api.dart';
import '../../models/owner.dart';
import '../../models/worker.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'h13_fill_vacancy_page.dart';

/// H12 오늘 못 나가요 (결원 신고 1/2). POST /schedules/{scheduleId}/swap-requests
///
/// 홈의 오늘 근무에서 오면 [shift]가 정해져 있고, 게시판의 '내 근무 내놓기'에서 오면 앞으로의 내 근무 중에서 고른다.
/// 신고하면 사장님께 알림이 가고 H13 빈자리 채우기로 넘어간다.
class AbsenceReportPage extends StatefulWidget {
  const AbsenceReportPage({super.key, this.shift});

  final DaySchedule? shift;

  @override
  State<AbsenceReportPage> createState() => _AbsenceReportPageState();
}

class _AbsenceReportPageState extends State<AbsenceReportPage> {
  List<MyShift>? _upcoming;
  MyShift? _shift;
  String? _error;

  /// null = 근무 전체, 값 = 그 시각부터만 빠짐 ("11:00")
  String? _partialFrom;
  AbsenceReason? _reason;
  final _memo = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _memo.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final now = DateTime.now();
      final mine = await WorkerApi().mySchedules();
      // 아직 시작하지 않은 근무만 신고할 수 있다
      final upcoming = [for (final s in mine) if (_startOf(s.workDate, s.startTime).isAfter(now)) s]
        ..sort((a, b) => _startOf(a.workDate, a.startTime).compareTo(_startOf(b.workDate, b.startTime)));
      if (!mounted) return;
      setState(() {
        _upcoming = upcoming;
        _shift = upcoming.where((s) => s.id == widget.shift?.scheduleId).firstOrNull ?? upcoming.firstOrNull;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  static DateTime _startOf(DateTime d, String t) => DateTime(d.year, d.month, d.day, int.parse(t.substring(0, 2)), int.parse(t.substring(3, 5)));

  /// 근무 중간에 빠질 수 있는 정시 (시작 1시간 뒤 ~ 끝 1시간 전)
  List<String> _partialHours(MyShift s) {
    final start = int.parse(s.startTime.substring(0, 2));
    var end = int.parse(s.endTime.substring(0, 2));
    if (end <= start) end += 24;
    return [for (var h = start + 1; h < end; h++) '${(h % 24).toString().padLeft(2, '0')}:00'];
  }

  String _until(MyShift s) {
    final diff = _startOf(s.workDate, s.startTime).difference(DateTime.now());
    if (diff.inHours >= 24) return "${diff.inDays}일 뒤";
    if (diff.inHours >= 1) return "시작 ${diff.inHours}시간 ${diff.inMinutes % 60}분 전";
    return "시작 ${diff.inMinutes}분 전";
  }

  Future<void> _submit() async {
    final s = _shift!;
    setState(() => _busy = true);
    try {
      final request = await WorkerApi().reportAbsence(
        s.id,
        category: _reason!,
        reason: _reason == AbsenceReason.other ? _memo.text.trim() : null,
        partialFrom: _partialFrom,
      );
      if (!mounted) return;
      // 신고는 되돌릴 수 없으니 뒤로가기로 이 화면에 다시 오지 않게 바꿔 끼운다
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => FillVacancyPage(request: request)));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = _shift;
    final ready = s != null && _reason != null && (_reason != AbsenceReason.other || _memo.text.trim().isNotEmpty);
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: const ThymeStepAppBar(step: 1, total: 2, group: '결원 신고', closeIcon: true),
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 24), children: [
              const Text("오늘 못 나가요", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              const SizedBox(height: 8),
              const Text("사유를 고르면 사장님께 바로 알리고, 다음 화면에서 빈자리를 채워요.",
                  style: TextStyle(fontSize: 15, color: ThymeColor.textSub, height: 1.5)),
              const SizedBox(height: 20),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                TextButton(onPressed: _load, child: const Text("다시 불러오기")),
              ] else if (_upcoming == null)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
              else if (s == null)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(16)),
                  child: const Text("앞으로 잡힌 근무가 없어요.", style: TextStyle(fontSize: 14, color: ThymeColor.textSub)),
                )
              else ...[
                _shiftCard(s),
                if (_upcoming!.length > 1 && widget.shift == null) ...[
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 40,
                    child: ListView(scrollDirection: Axis.horizontal, children: [
                      for (final u in _upcoming!.take(10))
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text("${mdw(u.workDate)} ${hourRange(u.startTime, u.endTime)}"),
                            selected: u.id == s.id,
                            onSelected: (_) => setState(() {
                              _shift = u;
                              _partialFrom = null;
                            }),
                            selectedColor: ThymeColor.primary,
                            labelStyle: TextStyle(color: u.id == s.id ? ThymeColor.onPrimary : ThymeColor.text, fontWeight: FontWeight.bold),
                            showCheckmark: false,
                          ),
                        ),
                    ]),
                  ),
                ],
                const SizedBox(height: 24),
                _label("얼마나 빠지나요"),
                Row(children: [
                  Expanded(child: _choice("근무 전체", null, _partialFrom == null, () => setState(() => _partialFrom = null))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _choice(
                      _partialFrom == null ? "일부만" : "일부만 (${int.parse(_partialFrom!.substring(0, 2))}시부터)",
                      null,
                      _partialFrom != null,
                      _partialHours(s).isEmpty ? null : () => setState(() => _partialFrom ??= _partialHours(s).first),
                    ),
                  ),
                ]),
                if (_partialFrom != null) ...[
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final h in _partialHours(s))
                      ChoiceChip(
                        label: Text("${int.parse(h.substring(0, 2))}시부터"),
                        selected: h == _partialFrom,
                        onSelected: (_) => setState(() => _partialFrom = h),
                        selectedColor: ThymeColor.selectedSoft,
                        showCheckmark: false,
                      ),
                  ]),
                ],
                const SizedBox(height: 24),
                _label("사유"),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.4,
                  children: [
                    for (final (r, title) in [
                      (AbsenceReason.sick, "아파요"),
                      (AbsenceReason.familyEvent, "가족 경조사"),
                      (AbsenceReason.personal, "개인 사정"),
                      (AbsenceReason.other, "기타"),
                    ])
                      _choice(title, r == AbsenceReason.other ? "직접 적기" : r.label, _reason == r, () => setState(() => _reason = r)),
                  ],
                ),
                if (_reason == AbsenceReason.other) ...[
                  const SizedBox(height: 10),
                  TextField(
                    controller: _memo,
                    maxLength: 100,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(hintText: "사장님께 전할 사유"),
                  ),
                ],
                const SizedBox(height: 16),
                const Text('사유는 사장님만 봐요. 동료에게는 "사정이 생겼어요"로만 보여요.',
                    style: TextStyle(fontSize: 13, color: ThymeColor.textSub, height: 1.5)),
              ],
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: ready && !_busy ? _submit : null, child: Text(_busy ? "알리는 중…" : "신고하고 빈자리 채우기")),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _shiftCard(MyShift s) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text("${mdw(s.workDate)} · ${_until(s)}", style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
              const SizedBox(height: 4),
              Text(timeRange(s.startTime, s.endTime), style: ThymeTheme.mono(context, size: 26)),
            ]),
          ),
          const Icon(Icons.circle, size: 8, color: ThymeColor.danger),
          const SizedBox(width: 6),
          const Text("빠질 근무", style: TextStyle(fontWeight: FontWeight.bold, color: ThymeColor.dangerText)),
        ]),
      );

  Widget _label(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(t, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
      );

  Widget _choice(String title, String? sub, bool selected, VoidCallback? onTap) => Material(
        color: selected ? ThymeColor.primary : ThymeColor.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: selected ? ThymeColor.primary : ThymeColor.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: sub == null ? CrossAxisAlignment.center : CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: onTap == null ? ThymeColor.disabled : (selected ? ThymeColor.onPrimary : ThymeColor.text))),
                if (sub != null)
                  Text(sub, style: TextStyle(fontSize: 13, color: selected ? ThymeColor.onPrimarySub : ThymeColor.textSub)),
              ],
            ),
          ),
        ),
      );
}
