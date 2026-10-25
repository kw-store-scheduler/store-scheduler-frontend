import 'package:flutter/material.dart';
import '../../core/home_router.dart';
import '../../core/api_service.dart';
import '../../core/join_api.dart';
import '../../core/session.dart';
import '../../core/theme.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_leaf.dart';
import 'e01_employee_leave_page.dart';
import 'w00_load_last_month_page.dart';

/// J04 승인 대기 ↔ 승인 완료. 점주 승인 뒤 첫 희망 제출로 연결한다 (알바 → W00, 직원 → E01)
class ApprovalWaitingPage extends StatefulWidget {
  const ApprovalWaitingPage({super.key, this.fullTime = false, this.name = "김유나", this.storeName = "구시대 커피 광운대점", this.requestedAt});

  /// J02에서 고른 형태 (직원이면 true)
  final bool fullTime;
  final String name;
  final String storeName;
  final DateTime? requestedAt;

  @override
  State<ApprovalWaitingPage> createState() => _ApprovalWaitingPageState();
}

class _ApprovalWaitingPageState extends State<ApprovalWaitingPage> {
  // 승인 결과는 알림(H04)으로 온다. 로그인했으면 오른쪽 위 버튼으로 서버에 다시 확인하고,
  // 시연 중이면 시안처럼 승인된 화면을 미리 본다
  bool _approved = false;
  bool _checking = false;

  bool get _live => Session.instance.isLoggedIn;

  Future<void> _checkApproval() async {
    setState(() => _checking = true);
    try {
      final m = await JoinApi().refresh();
      if (!mounted) return;
      if (m != null && m.isApproved) {
        setState(() => _approved = true);
      } else {
        final rejected = m?.status == "REJECTED";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(rejected ? "사장님이 가입 요청을 거절했어요." : "아직 승인 전이에요. 승인되면 알림으로 알려드려요.")),
        );
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  String get _requestedText {
    final t = widget.requestedAt;
    if (t == null) return "10/23 20:14";
    String two(int v) => v.toString().padLeft(2, '0');
    return "${t.month}/${t.day} ${two(t.hour)}:${two(t.minute)}";
  }

  void _startFirstPreference() {
    resetTo(context, widget.fullTime ? const EmployeeLeavePage() : const LoadLastMonthPage());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(minimumSize: const Size(0, 40), shape: const StadiumBorder()),
                  onPressed: _live
                      ? (_approved || _checking ? null : _checkApproval)
                      : () => setState(() => _approved = !_approved),
                  child: Text(
                    _live ? (_checking ? "확인 중…" : "승인 확인") : (_approved ? "대기 화면 보기" : "승인된 화면 보기"),
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const Spacer(),

              // 점선 잎 두 장 = 아직 정해지지 않음, 채워진 민트 잎 = 확정 (가이드 4-5)
              Row(
                children: [
                  ThymeLeaf(size: 40, dashed: !_approved, color: _approved ? ThymeColor.accent : ThymeColor.icon),
                  const SizedBox(width: 8),
                  ThymeLeaf(size: 40, dashed: !_approved, flip: true, color: _approved ? ThymeColor.accent : ThymeColor.icon),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                _approved ? "승인됐어요" : "사장님이 확인하고 있어요",
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: ThymeColor.text),
              ),
              const SizedBox(height: 12),
              Text(
                _approved
                    ? "이제 첫 근무 희망을 내면 다음 근무표에 반영돼요."
                    : "승인되면 알림으로 알려드려요. 보통 하루 안에 처리돼요.",
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
                    _buildRow("형태", Text(widget.fullTime ? "직원 (월급제)" : "알바 (시간제)", style: _valueStyle)),
                    _buildRow("이름", Text(widget.name, style: _valueStyle)),
                    _buildRow(
                      _approved ? "상태" : "요청 시각",
                      _approved
                          ? const Row(children: [
                              Icon(Icons.circle, size: 8, color: ThymeColor.accent),
                              SizedBox(width: 6),
                              Text("승인 완료", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: ThymeColor.successText)),
                            ])
                          : Text(_requestedText, style: ThymeTheme.mono(context, size: 15)),
                    ),
                  ],
                ),
              ),
              const Spacer(flex: 2),

              SizedBox(
                width: double.infinity,
                child: _approved
                    ? ThymeFinalButton(label: "첫 근무 희망 내기", onPressed: _startFirstPreference)
                    // 요청 취소는 보조 버튼 (가이드 4-4). 서버에 취소 API가 없어서 시연 중에만 보인다
                    : (_live ? null : OutlinedButton(onPressed: () => Navigator.maybePop(context), child: const Text("요청 취소"))),
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
