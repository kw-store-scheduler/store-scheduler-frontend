import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/home_router.dart';
import '../../core/owner_api.dart';
import '../../core/theme.dart';
import '../../models/owner.dart';
import '../../theme/thyme_colors.dart';
import '../../theme/thyme_theme.dart';
import '../../widgets/thyme_leaf.dart';
import '../../widgets/thyme_owner_tab_bar.dart';
import 'p01_owner_home_page.dart';

/// P04 확정 · 공유. 확정한 안의 요약과 누가 근무표를 확인했는지 (GET /acknowledgements), 안 본 사람에게 다시 알림 (POST /remind)
class ShareCompletePage extends StatefulWidget {
  const ShareCompletePage({super.key, required this.proposalId, required this.letter, required this.period, required this.candidate});

  final int proposalId;
  final String letter; // "A"
  final String period; // "12월"
  final ProposalCandidate candidate;

  @override
  State<ShareCompletePage> createState() => _ShareCompletePageState();
}

class _ShareCompletePageState extends State<ShareCompletePage> {
  Acknowledgements? _ack;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final a = await OwnerApi().acknowledgements(widget.proposalId);
      if (mounted) setState(() => _ack = a);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    }
  }

  Future<void> _remind() async {
    setState(() => _sending = true);
    try {
      final n = await OwnerApi().remind(widget.proposalId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$n명에게 다시 알렸어요")));
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.candidate;
    final a = _ack;
    final unseen = a == null ? 0 : a.total - a.seenCount;
    return Scaffold(
      backgroundColor: ThymePalette.mint50,
      body: SafeArea(
        child: Column(children: [
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.fromLTRB(20, 32, 20, 24), children: [
                const Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  ThymeLeaf(size: 46),
                  SizedBox(width: 10),
                  ThymeLeaf(size: 32, color: ThymePalette.mint300, flip: true),
                ]),
                const SizedBox(height: 18),
                Text("OWNER · ${widget.letter}안 확정", style: ThymeTheme.mono(context, size: 13, color: ThymeColor.successText)),
                const SizedBox(height: 8),
                Text(
                  a == null ? "${widget.period} 근무표를 확정했어요" : "${widget.period} 근무표를 ${a.total}명에게 보냈어요",
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text, height: 1.35),
                ),
                const SizedBox(height: 18),
                Row(children: [
                  _stat("희망 반영", c.preferenceRate == null ? "–" : "${c.preferenceRate!.toStringAsFixed(c.preferenceRate! % 1 == 0 ? 0 : 1)}%"),
                  const SizedBox(width: 8),
                  _stat("노동법 위반", "${c.laborLawViolations}건"),
                  const SizedBox(width: 8),
                  _stat("예상 인건비", wonShort(c.estimatedCost), dark: true),
                ]),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
                  child: _error != null
                      ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_error!, style: const TextStyle(color: ThymeColor.dangerText)),
                          TextButton(onPressed: _load, child: const Text("다시 불러오기")),
                        ])
                      : a == null
                          ? const Center(child: CircularProgressIndicator())
                          : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                              Row(children: [
                                const Expanded(child: Text("누가 확인했나요", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: ThymeColor.text))),
                                Text("${a.seenCount} / ${a.total}", style: ThymeTheme.mono(context, size: 16, color: ThymeColor.successText)),
                              ]),
                              const SizedBox(height: 14),
                              Wrap(spacing: 10, runSpacing: 10, children: [for (final (name, seen) in a.employees) _person(name, seen)]),
                              if (unseen > 0) ...[
                                const SizedBox(height: 16),
                                FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: ThymeColor.dangerBg, foregroundColor: ThymeColor.dangerText),
                                  onPressed: _sending ? null : _remind,
                                  child: Text(_sending ? "보내는 중…" : "안 본 $unseen명에게 다시 알리기"),
                                ),
                              ],
                              const SizedBox(height: 8),
                              const Text("아래로 당기면 새로 고쳐요", textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
                            ]),
                ),
              ]),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => ThymeOwnerTabBar.go(context, OwnerTab.schedule), child: const Text("근무표 보기"))),
              const SizedBox(width: 10),
              Expanded(child: FilledButton(onPressed: () => resetTo(context, const OwnerHomePage()), child: const Text("매장 홈으로"))),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _stat(String label, String value, {bool dark = false}) => Expanded(
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          decoration: BoxDecoration(color: dark ? ThymeColor.primary : ThymeColor.surface, borderRadius: BorderRadius.circular(18)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 13, color: dark ? ThymeColor.onPrimarySub : ThymeColor.textSub)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: ThymeTheme.mono(context, size: 20, color: dark ? ThymeColor.accent : ThymeColor.successText)),
            ),
          ]),
        ),
      );

  Widget _person(String name, bool seen) => Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: seen ? ThymeColor.successBg : ThymeColor.surfaceSub,
            shape: BoxShape.circle,
            border: Border.all(color: seen ? ThymeColor.accent : ThymeColor.warn, width: 3),
          ),
          child: Text(name.isEmpty ? "?" : name.characters.first,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: seen ? ThymeColor.successText : ThymeColor.textSub)),
        ),
        const SizedBox(height: 4),
        Text(seen ? "확인" : "안 봄", style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: seen ? ThymeColor.successText : ThymeColor.dangerText)),
      ]);
}
