import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/notice_api.dart';
import '../../core/theme.dart';
import '../../widgets/thyme_worker_tab_bar.dart';

/// H03 공지·업무 (근로자 하단 탭). 매장 공지(고정 = 필독이 먼저)와 오늘 내 업무 체크.
/// 서버에 공지 '확인했어요'(읽은 사람 수) 기능이 없어서 시안의 확인 버튼·진행바는 뺐다
class NoticeTaskPage extends StatefulWidget {
  const NoticeTaskPage({super.key});

  @override
  State<NoticeTaskPage> createState() => _NoticeTaskPageState();
}

class _NoticeTaskPageState extends State<NoticeTaskPage> {
  bool _taskTab = false;
  List<Notice>? _notices;
  List<StoreTask>? _tasks;
  String? _error;

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
      final tasks = await api.myTasks();
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

  Future<void> _toggle(StoreTask t) async {
    try {
      final updated = await NoticeApi().check(t.id, !t.done);
      if (mounted) setState(() => _tasks = [for (final x in _tasks!) x.id == t.id ? updated : x]);
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
            children: [
              const Text("공지 · 업무", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ThymeColor.text)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(16)),
                child: Row(children: [
                  Expanded(child: _segment("매장 공지${_notices == null ? '' : ' ${_notices!.length}'}", !_taskTab, () => setState(() => _taskTab = false))),
                  Expanded(child: _segment("오늘 내 업무${_tasks == null ? '' : ' ${_tasks!.length}'}", _taskTab, () => setState(() => _taskTab = true))),
                ]),
              ),
              const SizedBox(height: 16),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                TextButton(onPressed: _load, child: const Text("다시 불러오기")),
              ] else if (_notices == null)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
              else if (_taskTab)
                ..._taskList()
              else
                ..._noticeList(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const ThymeWorkerTabBar(current: WorkerTab.notice),
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

  List<Widget> _noticeList() {
    if (_notices!.isEmpty) return [_empty("아직 매장 공지가 없어요.")];
    return [
      for (final n in _notices!)
        Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (n.pinned) ...[
                const Icon(Icons.circle, size: 8, color: ThymeColor.danger),
                const SizedBox(width: 6),
                const Text("필독", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.dangerText)),
                const SizedBox(width: 8),
              ],
              Text(_when(n.createdAt), style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
            ]),
            const SizedBox(height: 8),
            Text(n.title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            if (n.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(n.content, style: const TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.5)),
            ],
          ]),
        ),
    ];
  }

  List<Widget> _taskList() {
    if (_tasks!.isEmpty) return [_empty("오늘 맡은 업무가 없어요.")];
    return [
      Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
        child: Column(children: [
          for (final t in _tasks!)
            CheckboxListTile(
              value: t.done,
              onChanged: (_) => _toggle(t),
              activeColor: ThymeColor.primary,
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(t.title,
                  style: TextStyle(
                      fontSize: 15,
                      color: t.done ? ThymeColor.textSub : ThymeColor.text,
                      decoration: t.done ? TextDecoration.lineThrough : null)),
              subtitle: t.shiftName == null && t.doneByName == null
                  ? null
                  : Text([?t.shiftName, if (t.done && t.doneByName != null) "${t.doneByName} 완료"].join(" · "),
                      style: const TextStyle(fontSize: 12, color: ThymeColor.textSub)),
            ),
        ]),
      ),
    ];
  }

  String _when(DateTime t) {
    final now = DateTime.now();
    final hm = "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
    if (t.year == now.year && t.month == now.month && t.day == now.day) return "오늘 $hm";
    return "${t.month}/${t.day}";
  }
}
