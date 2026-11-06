import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/owner_api.dart';
import '../../core/theme.dart';
import '../../models/owner.dart';
import '../../models/store.dart' show weekdayLabels;
import '../../widgets/thyme_owner_header.dart';
import 'o03_store_shift_setup_page.dart';

/// 마감 보고로 본 필요 인원 제안 (시안 없음, P08 운영 › 교대 시간대 · 인원 아래). GET /staffing-suggestions?month=
/// 다음 달 직전 4주의 마감 보고(P01 '+ 기록' 객수)를 요일·교대별로 평균 내서 1인당 객수로 나눈 인원.
/// 서버는 제안만 하고 바꾸지 않는다 → 바꾸려면 교대 설정(O03)으로
class StaffingSuggestionPage extends StatefulWidget {
  const StaffingSuggestionPage({super.key});

  @override
  State<StaffingSuggestionPage> createState() => _StaffingSuggestionPageState();
}

class _StaffingSuggestionPageState extends State<StaffingSuggestionPage> {
  final DateTime _month = DateTime(DateTime.now().year, DateTime.now().month + 1);
  StaffingSuggestions? _data;
  String? _error;

  String get _monthParam => "${_month.year}-${_month.month.toString().padLeft(2, '0')}";

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final d = await OwnerApi().staffingSuggestions(_monthParam);
      if (mounted) setState(() => _data = d);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = _data;
    final items = [...?d?.items]..sort((a, b) => a.weekday != b.weekday ? a.weekday.compareTo(b.weekday) : a.shiftName.compareTo(b.shiftName));
    final changes = items.where((s) => s.changes).length;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: EdgeInsets.zero, children: [
          ThymeOwnerHeader(
            title: "필요 인원 제안",
            subtitle: d == null ? null : "${_month.month}월용 · ${d.from.month}/${d.from.day}–${d.to.month}/${d.to.day} 마감 보고 · 1명당 손님 ${d.customersPerStaff}명",
            showBack: true,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                TextButton(onPressed: _load, child: const Text("다시 불러오기")),
              ] else if (d == null)
                const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
              else if (items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(16)),
                  child: const Text("아직 제안할 게 없어요. 홈의 '+ 기록'으로 교대마다 마감 손님 수를 남기면 4주치를 모아 요일·교대별 인원을 제안해요.",
                      style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.5)),
                )
              else ...[
                Text(changes == 0 ? "지금 인원 설정이 마감 보고와 맞아요." : "$changes곳은 인원을 바꿔 보길 권해요.",
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                const SizedBox(height: 10),
                Material(
                  color: ThymeColor.surface,
                  borderRadius: BorderRadius.circular(20),
                  child: Column(children: [
                    for (final (i, s) in items.indexed) ...[
                      if (i > 0) const Divider(height: 1, indent: 18, endIndent: 18),
                      _row(s),
                    ],
                  ]),
                ),
                const SizedBox(height: 16),
                OutlinedButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreShiftSetupPage(editing: true))),
                  child: const Text("교대 시간대 · 인원에서 바꾸기"),
                ),
              ],
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _row(StaffingSuggestion s) {
    final avg = s.averageCustomers == null ? "보고 없음" : "평균 손님 ${s.averageCustomers!.round()}명 · ${s.sampleDays}일";
    final (text, color) = s.suggestedStaff == null
        ? ("지금 ${s.currentRequiredStaff}명", ThymeColor.textSub)
        : s.changes
            ? ("${s.currentRequiredStaff}명 → ${s.suggestedStaff}명", s.suggestedStaff! > s.currentRequiredStaff ? ThymeColor.dangerText : ThymeColor.infoText)
            : ("${s.currentRequiredStaff}명 그대로", ThymeColor.successText);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(children: [
        SizedBox(width: 28, child: Text(weekdayLabels[s.weekday], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text))),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.shiftName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            Text(s.reason == null || s.suggestedStaff != null ? avg : s.reason!, style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
          ]),
        ),
        Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
      ]),
    );
  }
}
