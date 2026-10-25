import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/notification_api.dart';
import '../../core/theme.dart';
import '../../widgets/thyme_back_button.dart';

/// H04 알림 (점주·근로자 공통). 대타 요청·근무표 확정·마감 알림 등 서버가 보낸 알림 목록.
/// 누르면 읽음, '모두 읽음'으로 한 번에 정리한다
class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  List<NotificationItem>? _items;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final (_, items) = await NotificationApi().list();
      if (mounted) setState(() => _items = items);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _read(NotificationItem n) async {
    if (n.read) return;
    try {
      await NotificationApi().markRead(n.id);
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _readAll() async {
    try {
      await NotificationApi().markAllRead();
      await _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  static String _when(DateTime t) {
    final now = DateTime.now();
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return "방금";
    if (diff.inHours < 1) return "${diff.inMinutes}분 전";
    if (DateUtils.isSameDay(now, t)) return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
    return "${t.month}/${t.day}";
  }

  @override
  Widget build(BuildContext context) {
    final items = _items;
    final hasUnread = items?.any((n) => !n.read) ?? false;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: AppBar(
        backgroundColor: ThymeColor.bg,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: const ThymeBackButton(),
        title: const Text("알림", style: TextStyle(color: ThymeColor.text, fontSize: 17, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: hasUnread ? _readAll : null,
            child: const Text("모두 읽음", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: _error != null
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                TextButton(onPressed: _load, child: const Text("다시 불러오기")),
              ]),
            )
          : items == null
              ? const Center(child: CircularProgressIndicator())
              : items.isEmpty
                  ? const Center(child: Text("아직 알림이 없어요.", style: TextStyle(fontSize: 15, color: ThymeColor.textSub)))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                        itemCount: items.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final n = items[i];
                          return Material(
                            color: n.read ? ThymeColor.surfaceSub : ThymeColor.surface,
                            borderRadius: BorderRadius.circular(16),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(16),
                              onTap: () => _read(n),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Icon(Icons.circle, size: 8, color: n.read ? Colors.transparent : ThymeColor.info),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                      Text(n.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: n.read ? ThymeColor.textSub : ThymeColor.text)),
                                      if (n.body.isNotEmpty) ...[
                                        const SizedBox(height: 4),
                                        Text(n.body, style: const TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.4)),
                                      ],
                                    ]),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(_when(n.createdAt), style: const TextStyle(fontSize: 12, color: ThymeColor.textSub)),
                                ]),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
