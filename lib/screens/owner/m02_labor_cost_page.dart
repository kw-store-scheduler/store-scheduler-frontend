import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api_service.dart';
import '../../core/owner_api.dart';
import '../../core/theme.dart';
import '../../models/owner.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_owner_header.dart';
import '../../widgets/thyme_owner_tab_bar.dart';
import 'm01_worker_approval_page.dart' show minimumWage2026;

/// M02 인건비 (점주 하단 탭 '인건비'). 확정 근무표로 계산한 월 예상 인건비 (GET /payroll)
/// 기본급 · 주휴수당 · 야간·연장(5인 이상) 합계와 직원별 시급·시간. 줄을 누르면 시급을 바꾼다
class LaborCostPage extends StatefulWidget {
  const LaborCostPage({super.key});

  @override
  State<LaborCostPage> createState() => _LaborCostPageState();
}

class _LaborCostPageState extends State<LaborCostPage> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  List<PayrollRow>? _rows;
  Map<int, RosterRow> _roster = {};
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final rows = await OwnerApi().payroll(_month);
      final roster = await OwnerApi().roster();
      if (!mounted) return;
      setState(() {
        _rows = rows..sort((a, b) => b.totalPay.compareTo(a.totalPay));
        _roster = {for (final r in roster.employees) r.employeeId: r};
      });
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  void _moveMonth(int d) {
    setState(() {
      _month = DateTime(_month.year, _month.month + d);
      _rows = null;
    });
    _load();
  }

  Future<void> _editWage(PayrollRow r) async {
    final c = TextEditingController(text: "${r.hourlyWage}");
    final wage = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: ThymeColor.surface,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: SafeArea(
          top: false,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text("${r.employeeName} 시급", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: c,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(labelText: "시급 (원)", helperText: "2026년 최저시급 10,320원"),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.pop(context, int.tryParse(c.text)), child: const Text("저장")),
          ]),
        ),
      ),
    );
    c.dispose();
    if (wage == null || wage <= 0 || !mounted) return;
    try {
      await OwnerApi().updateWage(r.employeeId, wage);
      if (!mounted) return;
      if (wage < minimumWage2026) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("저장했어요. 최저시급보다 낮으니 다시 확인해 주세요.")));
      }
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    int sum(int Function(PayrollRow) f) => rows?.fold<int>(0, (s, r) => s + f(r)) ?? 0;
    final now = DateTime.now();
    final future = !_month.isBefore(DateTime(now.year, now.month));
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: EdgeInsets.zero, children: [
          ThymeOwnerHeader(
            title: "인건비",
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              IconButton(tooltip: "지난달", onPressed: () => _moveMonth(-1), icon: const Icon(Icons.chevron_left, color: ThymeColor.onPrimarySub)),
              Text("${_month.year}. ${_month.month}${future ? ' 예상' : ''}", style: ThymeTheme.mono(context, size: 15, color: ThymeColor.onPrimarySub)),
              IconButton(tooltip: "다음 달", onPressed: () => _moveMonth(1), icon: const Icon(Icons.chevron_right, color: ThymeColor.onPrimarySub)),
            ]),
            child: rows == null
                ? null
                : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text("${_month.month}월 ${future ? '예상 ' : ''}인건비 · 확정 근무표 기준", style: const TextStyle(color: ThymeColor.onPrimarySub, fontSize: 14)),
                    const SizedBox(height: 6),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(won(sum((r) => r.totalPay)), style: ThymeTheme.mono(context, size: 40, color: ThymeColor.accent)),
                    ),
                    const SizedBox(height: 16),
                    Row(children: [
                      _part("기본급", sum((r) => r.regularWage)),
                      const SizedBox(width: 8),
                      _part("주휴수당", sum((r) => r.weeklyHolidayPay)),
                      const SizedBox(width: 8),
                      _part("야간·연장", sum((r) => r.nightPay + r.overtimePay)),
                    ]),
                  ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: _error != null
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                    TextButton(onPressed: _load, child: const Text("다시 불러오기")),
                  ])
                : rows == null
                    ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                    : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        const Row(children: [
                          Expanded(child: Text("직원별 시급 · 시간", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text))),
                          Text("2026 최저 ₩10,320", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                        ]),
                        const SizedBox(height: 10),
                        if (rows.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(16)),
                            child: const Text("이 달 확정된 근무가 없어요.", style: TextStyle(fontSize: 14, color: ThymeColor.textSub)),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
                            child: Column(children: [
                              for (var i = 0; i < rows.length; i++) ...[
                                _row(rows[i]),
                                if (i < rows.length - 1) const Divider(height: 1, indent: 12, endIndent: 12),
                              ],
                            ]),
                          ),
                        const SizedBox(height: 8),
                        const Text("줄을 누르면 시급을 바꿔요. 5인 미만 매장은 야간·연장 가산이 빠져요.",
                            style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                      ]),
          ),
        ]),
      ),
      bottomNavigationBar: const ThymeOwnerTabBar(current: OwnerTab.laborCost),
    );
  }

  Widget _part(String label, int value) => Expanded(
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          decoration: BoxDecoration(color: ThymeColor.indigoSurface, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: ThymeColor.onPrimarySub, fontSize: 13)),
            const SizedBox(height: 4),
            FittedBox(fit: BoxFit.scaleDown, child: Text(won(value), style: ThymeTheme.mono(context, size: 15, color: ThymeColor.onPrimary))),
          ]),
        ),
      );

  Widget _row(PayrollRow r) {
    final roster = _roster[r.employeeId];
    final badge = roster?.badge ?? "알바";
    final full = badge.startsWith("직원");
    final h = r.totalHours == r.totalHours.roundToDouble() ? "${r.totalHours.toInt()}" : "${r.totalHours}";
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _editWage(r),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Row(children: [
          SizedBox(width: 56, child: Text(r.employeeName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text))),
          Container(
            constraints: const BoxConstraints(maxWidth: 90),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: full ? ThymeColor.primary : ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(99)),
            child: Text(badge, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: full ? ThymeColor.onPrimary : ThymeColor.text)),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text("${won(r.hourlyWage).substring(1)}/h · ${h}h", style: ThymeTheme.mono(context, size: 13, color: ThymeColor.textSub))),
          Text(won(r.totalPay), style: ThymeTheme.mono(context, size: 15)),
        ]),
      ),
    );
  }
}
