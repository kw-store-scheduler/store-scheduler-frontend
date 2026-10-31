import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/api_service.dart';
import '../../core/home_router.dart';
import '../../core/join_api.dart';
import '../../core/owner_api.dart';
import '../../core/session.dart';
import '../../core/store_api.dart';
import '../../core/theme.dart';
import '../../models/store.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_owner_header.dart';
import '../../widgets/thyme_owner_tab_bar.dart';
import '../../widgets/thyme_password_sheet.dart';
import '../common/a03_login_page.dart';
import 'm01_worker_approval_page.dart';
import 'o02_schedule_cycle_page.dart';
import 'o03_store_shift_setup_page.dart';
import 'o04_curation_page.dart';
import 'o05_labor_law_page.dart';
import 'o06_exception_days_page.dart';
import 'owner_attendance_page.dart';
import 'owner_notice_task_page.dart';
import 'p07_worker_list_page.dart';
import 'p09_open_shift_post_page.dart';

/// P08 매장 설정 (점주 하단 탭 '매장'). 근무 규칙은 매장 등록 화면(O02~O06)을 수정 모드로 다시 쓰고,
/// 사람 · 계정(매장 코드 재발급 · 비밀번호 · 로그아웃)을 모은다. 구독·요금제와 기록·명세서·서류는 서버에 없어 뺐다
class StoreSettingsPage extends StatefulWidget {
  const StoreSettingsPage({super.key});

  @override
  State<StoreSettingsPage> createState() => _StoreSettingsPageState();
}

class _StoreSettingsPageState extends State<StoreSettingsPage> {
  StoreInfo? _store;
  List<IndustryInfo> _industries = [];
  int _shifts = 0;
  int _windows = 0;
  int _exceptions = 0;
  int _todo = 0;
  int _openShifts = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final api = StoreApi();
      final store = await api.current();
      final shifts = await api.shifts();
      final windows = await api.skillWindows();
      final now = DateTime.now();
      final exceptions = await api.exceptions(DateTime(now.year, now.month), DateTime(now.year, now.month + 3, 0));
      final home = await OwnerApi().home();
      final open = await OwnerApi().openShifts();
      if (!mounted) return;
      setState(() {
        _store = store;
        _shifts = shifts.length;
        _windows = windows.length;
        _exceptions = exceptions.length;
        _todo = home.pendingApprovals + home.pendingLeaves;
        _openShifts = open.length;
      });
      _industries = await api.industries();
      if (mounted) setState(() {});
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _open(Widget page) async {
    await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    if (mounted) _load();
  }

  String get _cycleLabel => switch (_store?.scheduleCycle) {
        ScheduleCycle.weekly => "주간",
        ScheduleCycle.biweekly => "2주",
        ScheduleCycle.monthly => "월간",
        null => "",
      };

  String get _industryLabel => _industries.where((i) => i.code == _store?.industry).firstOrNull?.label ?? "";

  Future<void> _storeInfo() async {
    final s = _store!;
    await showModalBottomSheet(
      context: context,
      backgroundColor: ThymeColor.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(title: const Text("매장 이름"), trailing: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold))),
            ListTile(title: const Text("업종"), trailing: Text(_industryLabel, style: const TextStyle(fontWeight: FontWeight.bold))),
            ListTile(
              title: const Text("근무표 주기"),
              subtitle: const Text("눌러서 바꾸기"),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(_cycleLabel, style: const TextStyle(fontWeight: FontWeight.bold)),
                const Icon(Icons.chevron_right),
              ]),
              onTap: () {
                Navigator.pop(context);
                _open(const ScheduleCyclePage(editing: true));
              },
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text("매장 이름·업종은 지금은 바꿀 수 없어요.", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _reissue() async {
    final ok = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: ThymeColor.surface,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            const Text("매장 코드를 새로 만들까요?", style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            const Text("지금 코드와 초대 링크는 더 이상 쓸 수 없어요. 이미 합류한 직원은 그대로예요.", style: TextStyle(color: ThymeColor.textSub, height: 1.5)),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text("새 코드 만들기")),
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("취소")),
          ]),
        ),
      ),
    );
    if (ok != true || !mounted) return;
    try {
      final code = await OwnerApi().reissueCode();
      await Session.instance.refreshMe();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("새 매장 코드: $code")));
      _load();
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _logout() async {
    await Session.instance.logout();
    if (mounted) resetTo(context, const LoginPage());
  }

  @override
  Widget build(BuildContext context) {
    final s = _store;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(padding: EdgeInsets.zero, children: [
          ThymeOwnerHeader(title: "매장", child: s == null ? null : _storeCard(s)),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: _error != null
                ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                    TextButton(onPressed: _load, child: const Text("다시 불러오기")),
                  ])
                : s == null
                    ? const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator()))
                    : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                        _group("근무 규칙", [
                          _row("매장 정보 · 업종 · 주기", trailing: _cycleLabel, onTap: _storeInfo),
                          _row("교대 시간대 · 인원", trailing: "$_shifts개", onTap: () => _open(const StoreShiftSetupPage(editing: true))),
                          _row("평소와 다른 날", trailing: _exceptions == 0 ? null : "$_exceptions개", onTap: () => _open(const ExceptionDaysPage(editing: true))),
                          _row("리테일 큐레이션", badge: _windows, onTap: () => _open(const CurationPage(editing: true))),
                          _row("노동법 한도 · 수당",
                              trailing: switch (s.fivePlusBusiness) { true => "5인 이상", false => "5인 미만", null => "자동" },
                              onTap: () => _open(const LaborLawPage(editing: true))),
                        ]),
                        _group("사람", [
                          _row("근무자 목록 · 직원/알바", onTap: () => _open(const WorkerListPage())),
                          _row("가입 · 연차 승인", badge: _todo, onTap: () => _open(const WorkerApprovalPage())),
                          _row("빈 근무 게시판", badge: _openShifts, onTap: () => _open(const OpenShiftPostPage())),
                          _row("공지 · 업무", onTap: () => _open(const NoticeTaskManagePage())),
                          _row("출퇴근 기록", onTap: () => _open(const OwnerAttendancePage())),
                        ]),
                        _group("계정", [
                          _row("매장 코드 다시 만들기", onTap: _reissue),
                          _row("비밀번호 바꾸기", onTap: () => showPasswordChangeSheet(context)),
                          _row("로그아웃", danger: true, onTap: _logout),
                        ]),
                      ]),
          ),
        ]),
      ),
      bottomNavigationBar: const ThymeOwnerTabBar(current: OwnerTab.store),
    );
  }

  Widget _storeCard(StoreInfo s) => Material(
        color: ThymeColor.indigoSurface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            await Clipboard.setData(ClipboardData(text: JoinApi.inviteLink(s.storeCode)));
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("초대 링크를 복사했어요")));
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(s.name, style: const TextStyle(color: ThymeColor.onPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text([if (_industryLabel.isNotEmpty) _industryLabel, "$_cycleLabel 근무표", "누르면 초대 링크 복사"].join(" · "),
                      style: const TextStyle(color: ThymeColor.onPrimarySub, fontSize: 13)),
                ]),
              ),
              Text(s.storeCode, style: ThymeTheme.mono(context, size: 17, color: ThymeColor.accent)),
            ]),
          ),
        ),
      );

  Widget _group(String title, List<Widget> rows) => Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.only(left: 6, bottom: 8),
            child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
          ),
          Container(
            decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
            child: Column(children: [
              for (var i = 0; i < rows.length; i++) ...[rows[i], if (i < rows.length - 1) const Divider(height: 1, indent: 18, endIndent: 18)],
            ]),
          ),
        ]),
      );

  Widget _row(String title, {String? trailing, int badge = 0, bool danger = false, required VoidCallback onTap}) => InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
          child: Row(children: [
            Expanded(child: Text(title, style: TextStyle(fontSize: 16, color: danger ? ThymeColor.dangerText : ThymeColor.text))),
            if (trailing != null) Text(trailing, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                decoration: BoxDecoration(color: ThymeColor.primary, borderRadius: BorderRadius.circular(99)),
                child: Text("$badge", style: const TextStyle(color: ThymeColor.onPrimary, fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: ThymeColor.icon),
          ]),
        ),
      );
}
