import 'package:flutter/material.dart';
import '../core/api_service.dart';
import '../core/session.dart';
import '../core/theme.dart';

/// 비밀번호 변경 시트 (근로자 H06 · 점주 P08 계정). PATCH /api/users/me/password
/// 바꾸면 다른 기기의 로그인은 풀리고, 이 기기는 그대로 로그인돼 있다. 바꿨으면 true
Future<bool> showPasswordChangeSheet(BuildContext context) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: ThymeColor.surface,
    builder: (_) => const _PasswordSheet(),
  );
  if (ok == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("비밀번호를 바꿨어요. 다른 기기에서는 다시 로그인해야 해요")));
  }
  return ok == true;
}

class _PasswordSheet extends StatefulWidget {
  const _PasswordSheet();

  @override
  State<_PasswordSheet> createState() => _PasswordSheetState();
}

class _PasswordSheetState extends State<_PasswordSheet> {
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final next = _next.text;
    final error = _current.text.isEmpty
        ? "지금 비밀번호를 입력해 주세요."
        : next.length < 8
            ? "새 비밀번호는 8자 이상으로 정해 주세요."
            : next != _confirm.text
                ? "새 비밀번호가 서로 달라요."
                : next == _current.text
                    ? "지금과 다른 비밀번호로 정해 주세요."
                    : null;
    if (error != null) return setState(() => _error = error);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await Session.instance.changePassword(_current.text, next);
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    InputDecoration hint(String text) => InputDecoration(hintText: text);
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, 16 + MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          const Text("비밀번호 바꾸기", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          const Text("바꾸면 다른 기기에서는 로그아웃돼요.", style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
          const SizedBox(height: 16),
          TextField(controller: _current, obscureText: true, autofocus: true, textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.password], decoration: hint("지금 비밀번호")),
          const SizedBox(height: 12),
          TextField(controller: _next, obscureText: true, textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword], decoration: hint("새 비밀번호 (8자 이상)")),
          const SizedBox(height: 12),
          TextField(controller: _confirm, obscureText: true, textInputAction: TextInputAction.done,
              decoration: hint("새 비밀번호 확인"), onSubmitted: (_) => _saving ? null : _save()),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(fontSize: 13, color: ThymeColor.dangerText)),
          ],
          const SizedBox(height: 16),
          FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? "바꾸는 중…" : "바꾸기")),
        ]),
      ),
    );
  }
}
