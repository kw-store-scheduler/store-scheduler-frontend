import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/home_router.dart';
import '../../core/push_service.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../models/user.dart';
import '../../widgets/thyme_logo.dart';
import 'a05_terms_agreement_page.dart';

/// A03 로그인 · 회원가입 (아이디·비밀번호)
///
/// 백엔드는 아이디·비밀번호 로그인만 있다 (POST /api/auth/signup, /login). 카카오·네이버·Apple·휴대폰 로그인은 준비 중.
/// - 로그인 → GET /api/users/me 로 첫 화면을 고른다 ([homeFor])
/// - 회원가입 → 근로자로 가입하고 로그인 → A05 약관·알림 → A06 역할 선택 (역할은 A06에서 /me/role 로 확정)
class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.notice, this.startInSignup = false});

  /// 로그인 화면으로 돌아온 이유 (예: 토큰 만료)
  final String? notice;

  /// A02 '시작하기'로 오면 회원가입, '이미 계정이 있어요'로 오면 로그인
  final bool startInSignup;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _username = TextEditingController();
  final _password = TextEditingController();
  final _passwordConfirm = TextEditingController();
  late bool _signup = widget.startInSignup;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.notice;
  }

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    _passwordConfirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final username = _username.text.trim();
    final password = _password.text;
    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = "아이디와 비밀번호를 입력해 주세요.");
      return;
    }
    if (_signup && password != _passwordConfirm.text) {
      setState(() => _error = "비밀번호가 서로 달라요.");
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // 가입은 근로자로 해 두고 A06에서 역할을 확정한다 (매장·합류 신청 전에는 /me/role 로 바꿀 수 있다)
      if (_signup) await Session.instance.signup(username, password, Role.employee);
      final me = await Session.instance.login(username, password);
      await PushService.registerDevice();
      if (!mounted) return;
      if (_signup) {
        resetTo(context, const TermsAgreementPage());
      } else {
        goHome(context, me);
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toggleMode() => setState(() {
        _signup = !_signup;
        _error = null;
      });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 64),

                    // 앱 로고
                    const ThymeLogo(size: 36, color: ThymeColor.text),
                    const SizedBox(height: 24),

                    // 메인 카피
                    const Text(
                      "점주도, 근로자도\n같은 앱으로 시작해요",
                      style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ThymeColor.text, height: 1.3),
                    ),
                    const SizedBox(height: 12),

                    // 서브 카피
                    Text(
                      _signup ? "가입한 다음 역할(점주·근로자)을 골라요." : "로그인한 다음 역할을 고를 수 있어요.",
                      style: const TextStyle(fontSize: 15, color: ThymeColor.textSub),
                    ),

                    const Spacer(),
                    const SizedBox(height: 32),

                    TextField(
                      controller: _username,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.username],
                      decoration: const InputDecoration(hintText: "아이디"),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _password,
                      obscureText: true,
                      textInputAction: _signup ? TextInputAction.next : TextInputAction.done,
                      autofillHints: [_signup ? AutofillHints.newPassword : AutofillHints.password],
                      decoration: const InputDecoration(hintText: "비밀번호"),
                      onSubmitted: (_) => _signup ? null : _submit(),
                    ),
                    if (_signup) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: _passwordConfirm,
                        obscureText: true,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(hintText: "비밀번호 확인"),
                        onSubmitted: (_) => _submit(),
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(fontSize: 13, color: ThymeColor.dangerText)),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _loading ? null : _submit,
                        child: Text(_loading ? "잠시만요…" : (_signup ? "가입하고 시작하기" : "로그인")),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton(
                        onPressed: _loading ? null : _toggleMode,
                        child: Text(
                          _signup ? "이미 계정이 있어요 · 로그인" : "처음이에요 · 회원가입",
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text),
                        ),
                      ),
                    ),
                    // 서버가 잠들어 있으면(무료 플랜) 첫 요청이 오래 걸린다
                    if (_loading)
                      const Center(
                        child: Text("서버를 깨우는 중이면 30초~1분 걸릴 수 있어요.",
                            style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
                      ),
                    const SizedBox(height: 16),

                    // 소셜·휴대폰 로그인 (백엔드에 아직 없음)
                    const Center(
                      child: Text("카카오 · 네이버 · Apple · 휴대폰 로그인은 준비 중이에요.",
                          style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        "계속하면 이용약관과 개인정보 처리방침에 동의하게 돼요.",
                        style: TextStyle(color: ThymeColor.disabled, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
