import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/push_service.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../models/user.dart';
import '../owner/p01_owner_home_page.dart';
import '../owner/o01_store_registration_page.dart';
import '../worker/j04_approval_waiting_page.dart';
import '../worker/h01_part_timer_home_page.dart';
import '../worker/h02_employee_home_page.dart';
import 'a06_role_selection_page.dart';

/// [개발용] 아이디·비밀번호 로그인.
///
/// 백엔드에 소셜·휴대폰 로그인이 아직 없어서 실제 서버로 흐름을 확인할 때만 쓴다.
/// LoginPage가 디버그 빌드에서만 띄우고, 소셜 로그인이 생기면 이 파일을 지운다.
Future<void> showDevLoginSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: ThymeColor.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (_) => const _DevLoginSheet(),
  );
}

class _DevLoginSheet extends StatefulWidget {
  const _DevLoginSheet();

  @override
  State<_DevLoginSheet> createState() => _DevLoginSheetState();
}

class _DevLoginSheetState extends State<_DevLoginSheet> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;
  bool _signup = false; // 처음 쓰는 아이디면 가입부터
  String? _error;

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final username = _username.text.trim();
      // 가입은 근로자로 해 두고 A06에서 역할을 확정한다 (매장·합류 신청 전에는 /me/role 로 바꿀 수 있다)
      if (_signup) await Session.instance.signup(username, _password.text, Role.employee);
      final me = await Session.instance.login(username, _password.text);
      await PushService.registerDevice();
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => _homeFor(me)), (route) => false);
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// /api/users/me 를 보고 첫 화면을 고른다 (백엔드 README 10. 인증 · 권한)
  static Widget _homeFor(Me me) {
    // 매장도 합류 신청도 없으면 아직 역할을 고르지 않은 계정 → A06
    if (me.ownedStores.isEmpty && me.memberships.isEmpty) return const RoleSelectionPage();
    switch (me.role) {
      case Role.manager:
        return me.ownedStores.isEmpty ? const StoreRegistrationPage() : const OwnerHomePage();
      case Role.employee:
        final approved = me.memberships.where((m) => m.isApproved).firstOrNull;
        if (approved != null) {
          return approved.employmentType == EmploymentType.fullTime ? const EmployeeHomePage() : const PartTimerHomePage();
        }
        final pending = me.memberships.last;
        return ApprovalWaitingPage(
          fullTime: pending.employmentType == EmploymentType.fullTime,
          name: pending.displayName ?? me.username,
          storeName: pending.storeName,
        );
      case null:
        return const RoleSelectionPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.viewInsetsOf(context).bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_signup ? "개발용 회원가입" : "개발용 로그인",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThymeColor.text)),
          const SizedBox(height: 6),
          Text("서버 ${ApiService.baseUrl}", style: const TextStyle(fontSize: 12, color: ThymeColor.textSub)),
          const SizedBox(height: 20),
          TextField(controller: _username, decoration: const InputDecoration(hintText: "아이디 (예: staff01)")),
          const SizedBox(height: 12),
          TextField(
            controller: _password,
            obscureText: true,
            decoration: const InputDecoration(hintText: "비밀번호"),
            onSubmitted: (_) => _login(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(fontSize: 13, color: ThymeColor.dangerText)),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _loading ? null : _login,
              child: Text(_loading ? "처리 중…" : (_signup ? "가입하고 시작" : "로그인")),
            ),
          ),
          Center(
            child: TextButton(
              onPressed: () => setState(() {
                _signup = !_signup;
                _error = null;
              }),
              child: Text(_signup ? "이미 아이디가 있어요" : "처음이에요 · 회원가입",
                  style: const TextStyle(fontSize: 13, color: ThymeColor.textSub)),
            ),
          ),
        ],
      ),
    );
  }
}
