import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/home_router.dart';
import '../../core/join_api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../models/user.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_leaf.dart';
import '../common/a03_login_page.dart';
import 'e01_employee_leave_page.dart';
import 'j01_store_code_page.dart';
import 'w00_load_last_month_page.dart';

/// J04 승인 대기 ↔ 승인 완료. 점주가 승인하면 첫 희망 제출로 (알바 → W00, 직원 → E01)
///
/// 열 때와 '승인 확인'을 누를 때 GET /api/users/me 로 합류 상태(PENDING·APPROVED·REJECTED)를 다시 본다.
class ApprovalWaitingPage extends StatefulWidget {
  const ApprovalWaitingPage({super.key, required this.fullTime, required this.name, required this.storeName, this.requestedAt});

  /// J02에서 고른 형태 (직원이면 true)
  final bool fullTime;
  final String name;
  final String storeName;

  /// 방금 신청했으면 그 시각 (다시 열었을 때는 서버가 시각을 주지 않아 null)
  final DateTime? requestedAt;

  @override
  State<ApprovalWaitingPage> createState() => _ApprovalWaitingPageState();
}

class _ApprovalWaitingPageState extends State<ApprovalWaitingPage> {
  String _status = "PENDING";
  late bool _fullTime = widget.fullTime;
  bool _checking = false;

  bool get _approved => _status == "APPROVED";
  bool get _rejected => _status == "REJECTED";

  @override
  void initState() {
    super.initState();
    _check(quiet: true);
  }

  Future<void> _check({bool quiet = false}) async {
    setState(() => _checking = true);
    try {
      final m = await JoinApi().refresh();
      if (!mounted || m == null) return;
      setState(() {
        _status = m.status;
        if (m.employmentType != null) _fullTime = m.employmentType == EmploymentType.fullTime; // 사장님이 승인하면서 바꿀 수 있다
      });
      if (!quiet && !_approved && !_rejected) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("아직 승인 전이에요. 승인되면 알림으로 알려드려요.")));
      }
    } on ApiException catch (e) {
      if (mounted && !quiet) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _logout() async {
    await Session.instance.logout();
    if (mounted) resetTo(context, const LoginPage());
  }

  String? get _requestedText {
    final t = widget.requestedAt;
    if (t == null) return null;
    String two(int v) => v.toString().padLeft(2, '0');
    return "${t.month}/${t.day} ${two(t.hour)}:${two(t.minute)}";
  }

  @override
  Widget build(BuildContext context) {
    final requested = _requestedText;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  TextButton(onPressed: _logout, child: const Text("로그아웃", style: TextStyle(color: ThymeColor.textSub))),
                  const Spacer(),
                  if (!_approved && !_rejected)
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40), shape: const StadiumBorder()),
                      onPressed: _checking ? null : () => _check(),
                      child: Text(_checking ? "확인 중…" : "승인 확인", style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const Spacer(),

              // 점선 잎 = 아직 정해지지 않음, 채워진 민트 잎 = 확정 (가이드 4-5)
              Row(
                children: [
                  ThymeLeaf(size: 40, dashed: !_approved, color: _approved ? ThymeColor.accent : (_rejected ? ThymeColor.danger : ThymeColor.icon)),
                  const SizedBox(width: 8),
                  ThymeLeaf(size: 40, dashed: !_approved, flip: true, color: _approved ? ThymeColor.accent : (_rejected ? ThymeColor.danger : ThymeColor.icon)),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                _approved ? "승인됐어요" : (_rejected ? "가입 요청이 거절됐어요" : "사장님이 확인하고 있어요"),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ThymeColor.text),
              ),
              const SizedBox(height: 12),
              Text(
                _approved
                    ? "이제 첫 근무 희망을 내면 다음 근무표에 반영돼요."
                    : (_rejected ? "매장 코드가 맞는지 사장님께 확인하고 다시 신청해 주세요." : "승인되면 알림으로 알려드려요. 보통 하루 안에 처리돼요."),
                style: const TextStyle(fontSize: 15, color: ThymeColor.textSub, height: 1.5),
              ),
              const SizedBox(height: 24),

              // 가입 요청 정보
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(18)),
                child: Column(
                  children: [
                    _buildRow("매장", Text(widget.storeName, style: _valueStyle)),
                    _buildRow("형태", Text(_fullTime ? "직원 (월급제)" : "알바 (시간제)", style: _valueStyle)),
                    _buildRow("이름", Text(widget.name, style: _valueStyle)),
                    if (_approved || _rejected)
                      _buildRow(
                        "상태",
                        Row(children: [
                          Icon(Icons.circle, size: 8, color: _approved ? ThymeColor.accent : ThymeColor.danger),
                          const SizedBox(width: 6),
                          Text(_approved ? "승인 완료" : "거절됨",
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: _approved ? ThymeColor.successText : ThymeColor.dangerText)),
                        ]),
                      )
                    else if (requested != null)
                      _buildRow("요청 시각", Text(requested, style: ThymeTheme.mono(context, size: 15))),
                  ],
                ),
              ),
              const Spacer(flex: 2),

              if (_approved)
                SizedBox(
                  width: double.infinity,
                  child: ThymeFinalButton(
                    label: "첫 근무 희망 내기",
                    onPressed: () => resetTo(context, _fullTime ? const EmployeeLeavePage() : const LoadLastMonthPage()),
                  ),
                )
              else if (_rejected)
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => resetTo(context, const StoreCodePage()),
                    child: const Text("다른 매장 코드 넣기"),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static const _valueStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.text);

  Widget _buildRow(String label, Widget value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(fontSize: 14, color: ThymeColor.textSub))),
          Expanded(child: value),
        ],
      ),
    );
  }
}
