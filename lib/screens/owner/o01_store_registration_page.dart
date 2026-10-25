import 'package:flutter/material.dart';
import '../../core/api_service.dart';
import '../../core/session.dart';
import '../../core/store_api.dart';
import '../../core/theme.dart';
import '../../models/store.dart';
import '../../widgets/thyme_step_app_bar.dart';
import 'o02_schedule_cycle_page.dart';

class StoreRegistrationPage extends StatefulWidget {
  const StoreRegistrationPage({super.key});

  @override
  State<StoreRegistrationPage> createState() => _StoreRegistrationPageState();
}

class _StoreRegistrationPageState extends State<StoreRegistrationPage> {
  final TextEditingController _nameController = TextEditingController();
  String _selectedIndustry = "CAFE"; // 기본 선택값

  // 시연용 업종 목록 (백엔드 Industry enum과 같은 값). 로그인했으면 GET /industries 로 바꾼다
  List<IndustryInfo> _industries = const [
    IndustryInfo(code: "CAFE", label: "카페", skills: ["음료 제조", "응대 속도", "오픈·마감", "외국어", "정산"], shifts: []),
    IndustryInfo(code: "CLOTHING", label: "의류", skills: ["고객 응대", "진열·VMD", "재고 관리", "오픈·마감", "정산"], shifts: []),
    IndustryInfo(code: "CONVENIENCE_STORE", label: "편의점", skills: ["계산·POS", "물품 진열", "발주·검수", "오픈·마감", "정산"], shifts: []),
    IndustryInfo(code: "PERFUME", label: "향수", skills: ["향 상담", "고객 응대", "포장", "재고 관리", "정산"], shifts: []),
    IndustryInfo(code: "RESTAURANT", label: "음식점", skills: ["조리 보조", "서빙", "주방 정리", "오픈·마감", "정산"], shifts: []),
    IndustryInfo(code: "ETC", label: "기타", skills: ["고객 응대", "오픈·마감", "정산"], shifts: []),
  ];
  bool _saving = false;
  int? _createdStoreId; // 뒤로 왔다가 다시 '다음'을 눌러도 매장을 두 번 만들지 않게

  IndustryInfo get _industry => _industries.firstWhere((i) => i.code == _selectedIndustry, orElse: () => _industries.first);

  @override
  void initState() {
    super.initState();
    if (Session.instance.isLoggedIn) _loadIndustries();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadIndustries() async {
    try {
      final list = await StoreApi().industries();
      if (mounted && list.isNotEmpty) setState(() => _industries = list);
    } on ApiException {
      // 목록을 못 받아도 시연용 목록(서버와 같은 값)으로 진행할 수 있다
    }
  }

  /// 로그인했으면 매장을 만들고(업종 기본 교대·역량도 서버가 같이 만든다) O02로
  Future<void> _next() async {
    final name = _nameController.text.trim();
    if (Session.instance.isLoggedIn && _createdStoreId == null) {
      if (name.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("매장 이름을 입력해 주세요.")));
        return;
      }
      setState(() => _saving = true);
      try {
        _createdStoreId = (await StoreApi().create(name: name, industry: _selectedIndustry)).id;
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
    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: ThymeStepAppBar(step: 1, total: 6, group: '매장 등록', owner: true),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "어떤 매장인가요?",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: ThymeColor.text),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "업종을 고르면 그 업종에 맞는 역량 항목과 기본 교대 시간을 미리 채워 드려요.",
                    style: TextStyle(fontSize: 14, color: ThymeColor.textSub, height: 1.5),
                  ),
                  const SizedBox(height: 32),

                  // 매장 이름 입력
                  const Text("매장 이름", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: "구시대 커피 광운대점",
                      hintStyle: TextStyle(color: ThymeColor.disabled),
                      filled: true,
                      fillColor: ThymeColor.surface,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: ThymeColor.text, width: 1.5),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: ThymeColor.text, width: 2.0),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 업종 선택 그리드
                  const Text("업종", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 2.5,
                    ),
                    itemCount: _industries.length,
                    itemBuilder: (context, index) {
                      final industry = _industries[index];
                      bool isSelected = _selectedIndustry == industry.code;
                      return GestureDetector(
                        onTap: () {
                          // 매장을 만든 뒤에는 업종을 바꿀 수 없다 (서버에 업종 변경 API 없음)
                          if (_createdStoreId != null) return;
                          setState(() {
                            _selectedIndustry = industry.code;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected ? ThymeColor.text : ThymeColor.surface,
                            border: Border.all(color: isSelected ? ThymeColor.text : ThymeColor.border),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            industry.label,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? ThymeColor.surface : ThymeColor.text,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 32),

                  // 선택된 업종에 맞춘 큐레이션 안내 박스
                  if (_industry.skills.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: ThymeColor.surfaceSub,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("${_industry.label}에 맞춰 준비되는 것", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _industry.skills.map((skill) {
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: ThymeColor.surface,
                                  border: Border.all(color: ThymeColor.border),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(skill, style: const TextStyle(fontSize: 13, color: ThymeColor.text)),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 하단 다음 버튼
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: _saving ? null : _next, child: Text(_saving ? "매장 만드는 중…" : "다음")),
              ),
            ),
          ),
        ],
      ),
    );
  }
}