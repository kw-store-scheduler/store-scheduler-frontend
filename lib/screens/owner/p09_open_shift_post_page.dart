import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/owner_api.dart';
import '../../core/theme.dart';
import '../../models/owner.dart';
import '../../models/store.dart' show hhmm;
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_owner_header.dart';

/// P09 빈 근무 게시판 (점주). [openShiftId]가 있으면 그 글의 지원자(이번 달 추가 근무가 적은 순)를 보고 한 명을 확정한다.
/// 없으면 열린 글 목록과 '추가 인원 모집'.
class OpenShiftPostPage extends StatefulWidget {
  const OpenShiftPostPage({super.key, this.openShiftId});

  final int? openShiftId;

  @override
  State<OpenShiftPostPage> createState() => _OpenShiftPostPageState();
}

class _OpenShiftPostPageState extends State<OpenShiftPostPage> {
  List<OpenShiftItem>? _posts;
  late int? _openId = widget.openShiftId;
  List<Applicant>? _applicants;
  int? _picked;
  String? _error;
  bool _busy = false;

  OpenShiftItem? get _post => _posts?.where((p) => p.id == _openId).firstOrNull;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final posts = await OwnerApi().openShifts();
      List<Applicant>? applicants;
      if (_openId != null && posts.any((p) => p.id == _openId)) applicants = await OwnerApi().applicants(_openId!);
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _applicants = applicants;
        _picked = applicants?.where((a) => a.status == 'APPLIED').firstOrNull?.id;
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _openPost(int id) {
    setState(() {
      _openId = id;
      _applicants = null;
    });
    _load();
  }

  Future<void> _approve() async {
    setState(() => _busy = true);
    try {
      await OwnerApi().approveApplicant(_openId!, _picked!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("확정했어요. 근무표에 바로 반영돼요.")));
      Navigator.maybePop(context);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addExtra() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThymeColor.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _ExtraSheet(),
    );
    if (ok == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final post = _post;
    final detail = _openId != null && post != null;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: Column(children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: ListView(padding: EdgeInsets.zero, children: [
              ThymeOwnerHeader(title: detail ? "빈 근무 올리기" : "빈 근무 게시판", showBack: true, child: detail ? _postCard(post) : null),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: _error != null
                    ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                        TextButton(onPressed: _load, child: const Text("다시 불러오기")),
                      ])
                    : _posts == null
                        ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                        : detail
                            ? _applicantsSection()
                            : _listSection(),
              ),
            ]),
          ),
        ),
        if (detail && _picked != null)
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _busy ? null : _approve,
                  child: Text("${_applicants!.firstWhere((a) => a.id == _picked).employeeName} 님으로 확정"),
                ),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _chip(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(color: ThymeColor.primary, borderRadius: BorderRadius.circular(99)),
        child: Text(text, style: const TextStyle(color: ThymeColor.onPrimary, fontSize: 14)),
      );

  static String _deadline(DateTime d) => "${d.month}/${d.day} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";

  Widget _postCard(OpenShiftItem p) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: ThymeColor.indigoSurface, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.circle, size: 8, color: p.kind == 'VACANCY' ? ThymeColor.danger : ThymeColor.accent),
            const SizedBox(width: 6),
            Text(p.kind == 'VACANCY' ? "결원" : "추가 모집",
                style: TextStyle(fontWeight: FontWeight.bold, color: p.kind == 'VACANCY' ? ThymeColor.danger : ThymeColor.accent)),
            const SizedBox(width: 10),
            Expanded(
              child: Text([mdw(p.workDate), ?p.title, ?p.note].join(" · "),
                  overflow: TextOverflow.ellipsis, style: const TextStyle(color: ThymeColor.onPrimarySub, fontSize: 14)),
            ),
          ]),
          const SizedBox(height: 8),
          Text("${hhmm(p.startTime)}–${hhmm(p.endTime)}", style: ThymeTheme.mono(context, size: 28, color: ThymeColor.onPrimary)),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (p.requiredSkill != null) _chip(p.requiredSkill!),
            _chip("${p.headcount}명"),
            if (p.applyDeadline != null) _chip("지원 마감 ${_deadline(p.applyDeadline!)}"),
          ]),
        ]),
      );

  Widget _applicantsSection() {
    final list = _applicants;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(child: Text("지원자 ${list?.length ?? 0}명", style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text))),
        const Text("추가 근무 적은 순 · 규칙 통과만", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
      ]),
      const SizedBox(height: 10),
      if (list == null) const Center(child: CircularProgressIndicator()),
      if (list != null && list.isEmpty)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(16)),
          child: const Text("아직 지원자가 없어요. 직원들에게 게시판 알림이 갔어요.", style: TextStyle(fontSize: 14, color: ThymeColor.textSub)),
        ),
      for (final a in list ?? const <Applicant>[]) _applicantRow(a),
      const SizedBox(height: 8),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: ThymeColor.infoBg, borderRadius: BorderRadius.circular(16)),
        child: const Text("이번 달 추가 근무가 적은 사람이 위로 와요. 한 사람에게 몰리지 않게.",
            style: TextStyle(fontSize: 14, color: ThymeColor.infoText, height: 1.5)),
      ),
    ]);
  }

  Widget _applicantRow(Applicant a) {
    final on = a.id == _picked;
    final open = a.status == 'APPLIED';
    final h = a.weekHours == a.weekHours.roundToDouble() ? "${a.weekHours.toInt()}" : "${a.weekHours}";
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: ThymeColor.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: open ? () => setState(() => _picked = a.id) : null,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), border: Border.all(color: on ? ThymeColor.primary : Colors.transparent, width: 2)),
            child: Row(children: [
              CircleAvatar(
                radius: 26,
                backgroundColor: on ? ThymeColor.primary : ThymeColor.selectedSoft,
                child: Text(a.employeeName.isEmpty ? "?" : a.employeeName.characters.first,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: on ? ThymeColor.onPrimary : ThymeColor.text)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(a.employeeName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                  const SizedBox(height: 2),
                  Text(
                    open ? "이번 달 추가 근무 ${a.monthExtraCount}회${a.overtime ? ' · 주 40h 넘어 연장근무' : ''}" : (a.status == 'APPROVED' ? "확정됨" : "지원 끝남"),
                    style: const TextStyle(fontSize: 13, color: ThymeColor.textSub),
                  ),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text("주 ${h}h", style: ThymeTheme.mono(context, size: 16)),
                Text("+${won(a.expectedPay)}", style: TextStyle(fontSize: 13, color: a.overtime ? ThymeColor.dangerText : ThymeColor.textSub)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _listSection() {
    final posts = _posts!;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      if (posts.isEmpty)
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(16)),
          child: const Text("열린 빈 근무가 없어요.", style: TextStyle(fontSize: 14, color: ThymeColor.textSub)),
        ),
      for (final p in posts)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: ThymeColor.surface,
            borderRadius: BorderRadius.circular(20),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              leading: Icon(Icons.circle, size: 10, color: p.kind == 'VACANCY' ? ThymeColor.danger : ThymeColor.accent),
              title: Text("${mdw(p.workDate)} ${hourRange(p.startTime, p.endTime)} · ${p.kind == 'VACANCY' ? '결원' : (p.title ?? '추가 모집')}",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text("지원 ${p.applicantCount}명 · ${p.headcount}명 모집"),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _openPost(p.id),
            ),
          ),
        ),
      const SizedBox(height: 8),
      OutlinedButton.icon(onPressed: _addExtra, icon: const Icon(Icons.add), label: const Text("추가 인원 모집")),
    ]);
  }
}

/// 추가 인원 모집: 날짜 · 시간(30분 단위) · 이름 · 인원 → POST /open-shifts
class _ExtraSheet extends StatefulWidget {
  const _ExtraSheet();

  @override
  State<_ExtraSheet> createState() => _ExtraSheetState();
}

class _ExtraSheetState extends State<_ExtraSheet> {
  DateTime _date = DateUtils.dateOnly(DateTime.now()).add(const Duration(days: 1));
  int _start = 12 * 60;
  int _end = 16 * 60;
  int _count = 1;
  final _title = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  static String _fmt(int m) => "${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}";

  Future<void> _pickTime(bool start) async {
    var value = start ? _start : _end;
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: ThymeColor.surface,
      builder: (context) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          SizedBox(
            height: 200,
            child: CupertinoPicker(
              itemExtent: 36,
              scrollController: FixedExtentScrollController(initialItem: value ~/ 30),
              onSelectedItemChanged: (i) => value = i * 30,
              children: [for (var i = 0; i < 48; i++) Center(child: Text(_fmt(i * 30), style: ThymeTheme.mono(context, size: 18)))],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(width: double.infinity, child: FilledButton(onPressed: () => Navigator.pop(context, value), child: const Text("확인"))),
          ),
        ]),
      ),
    );
    if (picked != null) setState(() => start ? _start = picked : _end = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await OwnerApi().addExtraShift(date: _date, startTime: _fmt(_start), endTime: _fmt(_end), title: _title.text.trim(), headcount: _count);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              const Text("추가 인원 모집", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              const SizedBox(height: 16),
              TextField(controller: _title, decoration: const InputDecoration(hintText: "이름 (예: 단체 예약)")),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                icon: const Icon(Icons.event, size: 18),
                label: Text(mdw(_date)),
                onPressed: () async {
                  final now = DateTime.now();
                  final d = await showDatePicker(context: context, initialDate: _date, firstDate: DateUtils.dateOnly(now), lastDate: DateTime(now.year + 1));
                  if (d != null) setState(() => _date = d);
                },
              ),
              const SizedBox(height: 8),
              Row(children: [
                Expanded(child: OutlinedButton(onPressed: () => _pickTime(true), child: Text("시작 ${_fmt(_start)}"))),
                const SizedBox(width: 8),
                Expanded(child: OutlinedButton(onPressed: () => _pickTime(false), child: Text("끝 ${_fmt(_end)}"))),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Expanded(child: Text("모집 인원", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold))),
                IconButton(tooltip: "1명 줄이기", onPressed: _count > 1 ? () => setState(() => _count--) : null, icon: const Icon(Icons.remove_circle_outline)),
                Text("$_count명", style: ThymeTheme.mono(context, size: 16)),
                IconButton(tooltip: "1명 늘리기", onPressed: _count < 10 ? () => setState(() => _count++) : null, icon: const Icon(Icons.add_circle_outline)),
              ]),
              const SizedBox(height: 12),
              FilledButton(onPressed: _saving || _start == _end ? null : _save, child: Text(_saving ? "올리는 중…" : "게시판에 올리기")),
            ]),
          ),
        ),
      );
}
