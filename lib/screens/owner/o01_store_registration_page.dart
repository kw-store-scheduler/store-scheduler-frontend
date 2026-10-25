import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/store_api.dart';
import '../../core/theme.dart';
import '../../models/store.dart';
import '../../widgets/thyme_logo.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'o02_schedule_cycle_page.dart';

/// O01 매장 정보 (매장 등록 1/6). 이름·업종 → POST /api/stores (업종 기본 교대·역량을 서버가 같이 만든다) → O02
class StoreRegistrationPage extends StatefulWidget {
  const StoreRegistrationPage({super.key});

  @override
  State<StoreRegistrationPage> createState() => _StoreRegistrationPageState();
}

class _StoreRegistrationPageState extends State<StoreRegistrationPage> {
  final _name = TextEditingController();
  String _selected = "CAFE";

  // 서버 Industry enum 과 같은 목록. 화면이 뜨자마자 고를 수 있게 두고, GET /industries 응답으로 바꾼다
  List<IndustryInfo> _industries = const [
    IndustryInfo(code: "CAFE", label: "카페", skills: ["음료 제조", "응대 속도", "오픈·마감", "외국어", "정산"], shifts: []),
    IndustryInfo(code: "CLOTHING", label: "의류", skills: ["고객 응대", "진열·VMD", "재고 관리", "오픈·마감", "정산"], shifts: []),
    IndustryInfo(code: "CONVENIENCE_STORE", label: "편의점", skills: ["계산·POS", "물품 진열", "발주·검수", "오픈·마감", "정산"], shifts: []),
    IndustryInfo(code: "PERFUME", label: "향수", skills: ["향 상담", "고객 응대", "포장", "재고 관리", "정산"], shifts: []),
    IndustryInfo(code: "RESTAURANT", label: "음식점", skills: ["조리 보조", "서빙", "주방 정리", "오픈·마감", "정산"], shifts: []),
    IndustryInfo(code: "ETC", label: "기타", skills: ["고객 응대", "오픈·마감", "정산"], shifts: []),
  ];
  bool _saving = false;

  // 뒤로 왔다가 다시 '다음'을 눌러도 매장을 두 번 만들지 않게. 서버에 이름·업종 변경 API가 없어 만든 뒤엔 잠근다
  int? _createdStoreId;

  IndustryInfo get _industry => _industries.firstWhere((i) => i.code == _selected, orElse: () => _industries.first);

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    _loadIndustries();
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _loadIndustries() async {
    try {
      final list = await StoreApi().industries();
      if (mounted && list.isNotEmpty) setState(() => _industries = list);
    } on ApiException {
      // 위 목록이 서버와 같아 그대로 진행할 수 있다
    }
  }

  Future<void> _next() async {
    if (_createdStoreId == null) {
      setState(() => _saving = true);
      try {
        _createdStoreId = (await StoreApi().create(name: _name.text.trim(), industry: _selected)).id;
      } on ApiException catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        return;
      } finally {
        if (mounted) setState(() => _saving = false);
      }
    }
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleCyclePage()));
  }

  @override
  Widget build(BuildContext context) {
    final locked = _createdStoreId != null;
    final canNext = locked || _name.text.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: const ThymeStepAppBar(
        step: 1,
        total: 6,
        group: '매장 등록',
        owner: true,
        leading: Padding(padding: EdgeInsets.only(left: 20), child: Align(alignment: Alignment.centerLeft, child: ThymeLogo(size: 26, color: ThymeColor.text))),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("어떤 매장인가요?", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                  const SizedBox(height: 10),
                  const Text("업종을 고르면 그 업종에 맞는 역량 항목과 기본 교대 시간을 미리 채워 드려요.",
                      style: TextStyle(fontSize: 15, color: ThymeColor.textSub, height: 1.5)),
                  const SizedBox(height: 28),
                  _label("매장 이름"),
                  TextField(
                    controller: _name,
                    enabled: !locked,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(hintText: "예: 구시대 커피 광운대점"),
                  ),
                  const SizedBox(height: 24),
                  _label("업종"),
                  LayoutBuilder(builder: (context, c) {
                    final w = (c.maxWidth - 20) / 3;
                    return Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [for (final i in _industries) SizedBox(width: w, child: _industryChip(i, locked))],
                    );
                  }),
                  const SizedBox(height: 24),
                  if (_industry.skills.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(color: ThymeColor.surface, borderRadius: BorderRadius.circular(20)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${_industry.label}에 맞춰 준비되는 것",
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final skill in _industry.skills)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(color: ThymeColor.surfaceSub, borderRadius: BorderRadius.circular(99)),
                                  child: Text(skill, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  if (locked) ...[
                    const SizedBox(height: 12),
                    const Text("매장을 이미 만들었어요. 이름·업종은 지금은 바꿀 수 없어요.",
                        style: TextStyle(fontSize: 13, color: ThymeColor.textSub)),
                  ],
                ],
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: !canNext || _saving ? null : _next,
                  child: Text(_saving ? "매장 만드는 중…" : (canNext ? "다음" : "매장 이름을 입력해 주세요")),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _industryChip(IndustryInfo i, bool locked) {
    final on = i.code == _selected;
    return Material(
      color: on ? ThymeColor.primary : ThymeColor.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: locked ? null : () => setState(() => _selected = i.code),
        child: Container(
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: on ? ThymeColor.primary : ThymeColor.border),
          ),
          child: Text(i.label,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: on ? ThymeColor.onPrimary : ThymeColor.text)),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.textSub)),
      );
}
