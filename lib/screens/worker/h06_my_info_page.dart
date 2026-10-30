import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/home_router.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../core/worker_api.dart';
import '../../models/owner.dart';
import '../../models/worker.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_leaf.dart';
import '../../widgets/thyme_password_sheet.dart';
import '../../widgets/thyme_worker_tab_bar.dart';
import '../common/a03_login_page.dart'; // 로그아웃
import 'j01_store_code_page.dart'; // 다른 매장 추가
import 'w10_preference_report_page.dart'; // 희망 반영 리포트
import 'w11_fixed_schedule_page.dart'; // 고정 일정

/// H06 내 정보 (근로자 하단 탭). GET /me/summary
/// 프로필(고용 형태·입사일·시급), 이번 달 근무일·누적 시간·지금까지 급여, 내 매장, 메뉴, 로그아웃
/// 서버에 화면이 없는 메뉴(근무 기록·서류함·고객센터)는 회색 '준비 중'으로 둔다
class MyInfoPage extends StatefulWidget {
  const MyInfoPage({super.key});

  @override
  State<MyInfoPage> createState() => _MyInfoPageState();
}

class _MyInfoPageState extends State<MyInfoPage> {
  MySummary? _s;
  String? _error;
  bool? _push;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final s = await WorkerApi().summary();
      if (mounted) {
        setState(() {
          _s = s;
          _push = s.pushEnabled;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _setPush(bool on) async {
    setState(() => _push = on);
    try {
      await WorkerApi().setPushEnabled(on);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _push = !on);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _load();
  }

  @override
  Widget build(BuildContext context) {
    final s = _s;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _load,
          child: ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 24), children: [
            const Text("내 정보", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            const SizedBox(height: 16),
            if (_error != null) ...[
              Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
              TextButton(onPressed: _load, child: const Text("다시 불러오기")),
            ] else if (s == null)
              const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
            else ...[
              _profile(s),
              const SizedBox(height: 12),
              Row(children: [
                Expanded(child: _stat("${DateTime.now().month}월 근무", "${s.monthDays}일")),
                const SizedBox(width: 8),
                Expanded(child: _stat("누적 시간", "${hours(s.cumulativeHours)}h")),
                const SizedBox(width: 8),
                Expanded(child: _stat("지금까지", won(s.payToDate), dark: true)),
              ]),
              const SizedBox(height: 12),
              _card([
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Text("내 매장", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
                ),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  leading: const ThymeLeaf(size: 22),
                  title: Text(s.storeName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                  trailing: const Text("지금 보는 중", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: ThymeColor.successText)),
                ),
                const Divider(height: 1, indent: 20, endIndent: 20),
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  title: const Text("+ 다른 매장 추가", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                  onTap: () => _open(const StoreCodePage()),
                ),
              ]),
              const SizedBox(height: 12),
              _card([
                _menu("근무 기록 · 정정", null),
                _menu("서류함 · 임금명세서", null),
                // 고정 일정 화면은 희망 신청 흐름(W11)을 그대로 쓴다
                _menu("고정 일정", () => _open(const FixedSchedulePage()), trailing: s.fixedScheduleCount == 0 ? "없음" : "${s.fixedScheduleCount}건"),
                _menu("희망 반영 리포트", () => _open(const PreferenceReportPage()),
                    trailing: s.lastReportAssigned == 0 ? null : "${s.lastReportHonored}/${s.lastReportAssigned}"),
                SwitchListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  value: _push ?? true,
                  onChanged: _setPush,
                  title: const Text("알림 받기", style: TextStyle(fontSize: 15, color: ThymeColor.text)),
                ),
                _menu("비밀번호 바꾸기", () => showPasswordChangeSheet(context)),
                _menu("고객센터 · 약관", null),
              ]),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () async {
                  // 저장된 로그인까지 지워야 새로고침해도 다시 로그인되지 않는다
                  await Session.instance.logout();
                  if (!context.mounted) return;
                  resetTo(context, const LoginPage());
                },
                child: const Text("로그아웃", style: TextStyle(fontSize: 14, color: ThymeColor.textSub, decoration: TextDecoration.underline)),
              ),
            ),
          ]),
        ),
      ),
      bottomNavigationBar: const ThymeWorkerTabBar(current: WorkerTab.me),
    );
  }

  Widget _profile(MySummary s) {
    final type = employmentLabel(s.employmentType);
    final start = s.startDate == null ? null : "${s.startDate!.month}/${s.startDate!.day} 입사";
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(24)),
      child: Row(children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: ThymeColor.selectedSoft,
          child: Text(s.name.isEmpty ? "?" : s.name.characters.first,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: ThymeColor.text)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(s.name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThymeColor.text)),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 6, children: [
              _pill([type, ?start].join(" · ")),
              if (s.hourlyWage != null) _pill("${won(s.hourlyWage!)}/h", mono: true),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _pill(String text, {bool mono = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(12)),
        child: Text(text,
            style: mono ? ThymeTheme.mono(context, size: 12) : const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: ThymeColor.text)),
      );

  Widget _stat(String label, String value, {bool dark = false}) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: dark ? ThymeColor.primary : ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: 12, color: dark ? ThymeColor.onPrimarySub : ThymeColor.textSub)),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: ThymeTheme.mono(context, size: 20, color: dark ? ThymeColor.accent : ThymeColor.text)),
          ),
        ]),
      );

  Widget _card(List<Widget> children) => Material(
        color: ThymeColor.surface,
        borderRadius: BorderRadius.circular(24),
        clipBehavior: Clip.antiAlias,
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children),
      );

  /// [onTap]이 없으면 서버 기능이 없는 메뉴 → 회색 '준비 중'
  Widget _menu(String title, VoidCallback? onTap, {String? trailing}) => ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        enabled: onTap != null,
        title: Text(title, style: TextStyle(fontSize: 15, color: onTap == null ? ThymeColor.disabled : ThymeColor.text)),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(onTap == null ? "준비 중" : (trailing ?? ""), style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, size: 20, color: ThymeColor.disabled),
          ],
        ]),
        onTap: onTap,
      );
}
