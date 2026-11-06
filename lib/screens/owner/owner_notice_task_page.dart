import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/notice_api.dart';
import '../../core/owner_api.dart';
import '../../core/store_api.dart';
import '../../core/theme.dart';
import '../../models/owner.dart';
import '../../models/store.dart';
import '../../widgets/thyme_owner_header.dart';

/// 점주 공지 · 업무 관리 (시안 없음: 근로자 H03 에 보일 내용을 쓰는 곳, P08 '사람'에서 연다)
/// - 공지: 쓰기(직원 모두에게 알림, 고정 = 필독) · 지우기. POST·DELETE /notices
/// - 업무: 날짜별 목록 · 등록(그날 근무자 모두 / 교대 / 한 사람) · 지우기. GET·POST /tasks, DELETE /tasks/{id}
class NoticeTaskManagePage extends StatefulWidget {
  const NoticeTaskManagePage({super.key});

  @override
  State<NoticeTaskManagePage> createState() => _NoticeTaskManagePageState();
}

class _NoticeTaskManagePageState extends State<NoticeTaskManagePage> {
  bool _taskTab = false;
  DateTime _date = DateUtils.dateOnly(DateTime.now());
  List<Notice>? _notices;
  List<StoreTask>? _tasks;
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
      final api = NoticeApi();
      final notices = await api.notices();
      final tasks = await api.tasks(_date);
      if (mounted) {
        setState(() {
          _notices = notices;
          _tasks = tasks;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _moveDay(int d) {
    setState(() {
      _date = _date.add(Duration(days: d));
      _tasks = null;
    });
    _load();
  }

  Future<void> _run(Future<void> Function(NoticeApi api) action, String done) async {
    setState(() => _busy = true);
    try {
      await action(NoticeApi());
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(done)));
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String body) async =>
      await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(title),
          content: Text(body),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("취소")),
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text("지우기", style: TextStyle(color: ThymeColor.dangerText))),
          ],
        ),
      ) ==
      true;

  Future<void> _writeNotice() async {
    final r = await showModalBottomSheet<({String title, String content, bool pinned})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThymeColor.surface,
      builder: (_) => const _NoticeSheet(),
    );
    if (r == null || !mounted) return;
    await _run((api) => api.createNotice(title: r.title, content: r.content.isEmpty ? null : r.content, pinned: r.pinned),
        "공지를 올렸어요. 직원 모두에게 알림이 가요");
  }

  Future<void> _addTask() async {
    // 교대·직원 목록은 고를 때만 받는다 (못 받으면 '그날 근무자 모두'만)
    final shifts = await StoreApi().shifts().catchError((_) => <ShiftInfo>[]);
    final people = await OwnerApi().roster().then((r) => r.employees).catchError((_) => <RosterRow>[]);
    if (!mounted) return;
    final r = await showModalBottomSheet<({String title, int? shiftId, int? assigneeId})>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThymeColor.surface,
      builder: (_) => _TaskSheet(date: _date, shifts: shifts, people: people),
    );
    if (r == null || !mounted) return;
    await _run((api) => api.createTask(_date, r.title, shiftId: r.shiftId, assigneeId: r.assigneeId), "업무를 등록했어요");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: EdgeInsets.zero, children: [
          const ThymeOwnerHeader(title: "공지 · 업무", showBack: true),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  Expanded(child: _segment("매장 공지${_notices == null ? '' : ' ${_notices!.length}'}", !_taskTab, () => setState(() => _taskTab = false))),
                  Expanded(child: _segment("업무", _taskTab, () => setState(() => _taskTab = true))),
                ]),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                TextButton(onPressed: _load, child: const Text("다시 불러오기")),
              ] else if (_taskTab)
                ..._taskSection()
              else
                ..._noticeSection(),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _segment(String label, bool selected, VoidCallback onTap) => Material(
        color: selected ? ThymeColor.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(label,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: selected ? ThymeColor.onPrimary : ThymeColor.textSub)),
            ),
          ),
        ),
      );

  Widget _empty(String text) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(16)),
        child: Text(text, style: const TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.5)),
      );

  List<Widget> _noticeSection() {
    final notices = _notices;
    return [
      FilledButton.icon(onPressed: _busy ? null : _writeNotice, icon: const Icon(Icons.edit), label: const Text("공지 쓰기")),
      const SizedBox(height: 12),
      if (notices == null)
        const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
      else if (notices.isEmpty)
        _empty("아직 공지가 없어요. 올리면 직원 화면 '공지 · 업무'에 보이고 알림이 가요.")
      else
        for (final n in notices)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.fromLTRB(20, 12, 8, 16),
            decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const SizedBox(height: 4),
                  Row(children: [
                    if (n.pinned) ...[
                      const Icon(Icons.circle, size: 8, color: ThymeColor.danger),
                      const SizedBox(width: 6),
                      const Text("필독", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.dangerText)),
                      const SizedBox(width: 8),
                    ],
                    Text("${n.createdAt.month}/${n.createdAt.day}", style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                  ]),
                  const SizedBox(height: 8),
                  Text(n.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                  if (n.content.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(n.content, style: const TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.5)),
                  ],
                ]),
              ),
              IconButton(
                tooltip: "공지 지우기",
                onPressed: _busy
                    ? null
                    : () async {
                        if (await _confirm("공지 지우기", "'${n.title}' 공지를 지워요. 직원 화면에서도 사라져요.")) {
                          await _run((api) => api.deleteNotice(n.id), "공지를 지웠어요");
                        }
                      },
                icon: const Icon(Icons.delete_outline, color: ThymeColor.textSub),
              ),
            ]),
          ),
    ];
  }

  List<Widget> _taskSection() {
    final tasks = _tasks;
    final today = DateUtils.dateOnly(DateTime.now());
    final label = _date == today ? "오늘" : (_date == today.add(const Duration(days: 1)) ? "내일" : "");
    return [
      Row(children: [
        IconButton(tooltip: "전날", onPressed: () => _moveDay(-1), icon: const Icon(Icons.chevron_left)),
        Expanded(
          child: Text("${mdw(_date)}${label.isEmpty ? '' : ' · $label'}",
              textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text)),
        ),
        IconButton(tooltip: "다음 날", onPressed: () => _moveDay(1), icon: const Icon(Icons.chevron_right)),
      ]),
      const SizedBox(height: 8),
      FilledButton.icon(onPressed: _busy ? null : _addTask, icon: const Icon(Icons.add), label: const Text("업무 추가")),
      const SizedBox(height: 12),
      if (tasks == null)
        const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
      else if (tasks.isEmpty)
        _empty("이날 등록한 업무가 없어요. 등록하면 그날 근무자 화면의 '오늘 내 업무'에 떠요.")
      else
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
          child: Column(children: [
            for (final (i, t) in tasks.indexed) ...[
              if (i > 0) const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Icon(t.done ? Icons.check_circle : Icons.radio_button_unchecked, color: t.done ? ThymeColor.accent : ThymeColor.disabled),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(t.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                      Text(
                        [
                          t.assigneeName ?? t.shiftName ?? "그날 근무자 모두",
                          if (t.done && t.doneByName != null) "${t.doneByName} 완료",
                        ].join(" · "),
                        style: const TextStyle(fontSize: 13, color: ThymeColor.textSub),
                      ),
                    ]),
                  ),
                  IconButton(
                    tooltip: "업무 지우기",
                    onPressed: _busy
                        ? null
                        : () async {
                            if (await _confirm("업무 지우기", "'${t.title}' 업무를 지워요.")) {
                              await _run((api) => api.deleteTask(t.id), "업무를 지웠어요");
                            }
                          },
                    icon: const Icon(Icons.delete_outline, color: ThymeColor.textSub),
                  ),
                ]),
              ),
            ],
          ]),
        ),
    ];
  }
}

/// 공지 쓰기 시트: 제목 · 내용 · 필독 고정
class _NoticeSheet extends StatefulWidget {
  const _NoticeSheet();

  @override
  State<_NoticeSheet> createState() => _NoticeSheetState();
}

class _NoticeSheetState extends State<_NoticeSheet> {
  final _title = TextEditingController();
  final _content = TextEditingController();
  bool _pinned = false;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text("공지 쓰기", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text("올리면 직원 모두에게 알림이 가요.", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
            const SizedBox(height: 16),
            TextField(controller: _title, autofocus: true, decoration: const InputDecoration(hintText: "제목")),
            const SizedBox(height: 12),
            TextField(controller: _content, minLines: 3, maxLines: 6, decoration: const InputDecoration(hintText: "내용 (선택)")),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: _pinned,
              onChanged: (v) => setState(() => _pinned = v ?? false),
              title: const Text("필독으로 맨 위에 고정"),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: _title.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, (title: _title.text.trim(), content: _content.text.trim(), pinned: _pinned)),
              child: const Text("올리기"),
            ),
          ]),
        ),
      );
}

/// 업무 추가 시트: 내용 · 누구에게 (그날 근무자 모두 / 교대 / 한 사람)
class _TaskSheet extends StatefulWidget {
  const _TaskSheet({required this.date, required this.shifts, required this.people});

  final DateTime date;
  final List<ShiftInfo> shifts;
  final List<RosterRow> people;

  @override
  State<_TaskSheet> createState() => _TaskSheetState();
}

class _TaskSheetState extends State<_TaskSheet> {
  final _title = TextEditingController();

  /// 'all' · 's<교대 id>' · 'e<직원 id>'
  String _who = 'all';

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Widget _chip(String key, String label) => ChoiceChip(
        label: Text(label),
        selected: _who == key,
        onSelected: (_) => setState(() => _who = key),
        selectedColor: ThymeColor.primary,
        labelStyle: TextStyle(color: _who == key ? ThymeColor.onPrimary : ThymeColor.text, fontWeight: FontWeight.bold),
        showCheckmark: false,
      );

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text("${mdw(widget.date)} 업무 추가", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(controller: _title, autofocus: true, decoration: const InputDecoration(hintText: "예) 우유 입고 확인")),
            const SizedBox(height: 16),
            const Text("누가 할까요", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _chip('all', "그날 근무자 모두"),
              for (final s in widget.shifts) _chip('s${s.id}', "${s.name} 교대"),
              for (final p in widget.people) _chip('e${p.employeeId}', p.name),
            ]),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _title.text.trim().isEmpty
                  ? null
                  : () => Navigator.pop(context, (
                        title: _title.text.trim(),
                        shiftId: _who.startsWith('s') ? int.parse(_who.substring(1)) : null,
                        assigneeId: _who.startsWith('e') ? int.parse(_who.substring(1)) : null,
                      )),
              child: const Text("등록"),
            ),
          ]),
        ),
      );
}
