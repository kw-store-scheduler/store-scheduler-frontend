import 'package:flutter/material.dart';
import '../models/api_service.dart';

class AdminSetupPage extends StatefulWidget {
  const AdminSetupPage({super.key});

  @override
  State<AdminSetupPage> createState() => _AdminSetupPageState();
}

class _AdminSetupPageState extends State<AdminSetupPage> {
  final Color periwinkle = const Color(0xFF8E97FD);
  int _currentStep = 0;

  String num_days = "7"; 
  int shift_count = 3; 
  String night_bonus = "0.0"; 
  final TextEditingController base_hourly = TextEditingController(text: "9860"); 

  List<TextEditingController> _shiftNameCtrls = [];
  List<TextEditingController> _shiftHoursCtrls = [];
  List<bool> _shiftIsNight = [];
  List<TextEditingController> _minStaffCtrls = [];
  List<TextEditingController> _targetStaffCtrls = [];

  String max_hours = "52"; 
  String max_consecutive_days = "5"; 
  String hierarchy_pref = "제한 없음"; 
  bool fairness_w = true; 
  String holiday_w = "돌아가면서 균등"; 
  List<String> holiday_indices = []; 
  bool senior_open_required = false;

  @override
  void initState() {
    super.initState();
    _updateShiftFields();
  }

  void _updateShiftFields() {
    _shiftNameCtrls = List.generate(shift_count, (i) => TextEditingController(text: i == 0 ? "오픈" : i == 1 ? "오후" : "마감"));
    _shiftHoursCtrls = List.generate(shift_count, (i) => TextEditingController(text: i == 0 ? "09:00-13:00" : i == 1 ? "13:00-17:00" : "17:00-22:00"));
    _shiftIsNight = List.generate(shift_count, (i) => false);
    _minStaffCtrls = List.generate(shift_count, (i) => TextEditingController(text: "2"));
    _targetStaffCtrls = List.generate(shift_count, (i) => TextEditingController(text: "3"));
  }

  Future<void> _submitStoreSetup() async {
    List<Map<String, dynamic>> shiftsPayload = [];
    for (int i = 0; i < shift_count; i++) {
      shiftsPayload.add({
        "name": _shiftNameCtrls[i].text,
        "hours": _shiftHoursCtrls[i].text,
        "is_night": _shiftIsNight[i],
        "min_staff": int.tryParse(_minStaffCtrls[i].text) ?? 2,
        "target_staff": int.tryParse(_targetStaffCtrls[i].text) ?? 3, // 💡 오타 수정 완료!
      });
    }

    Map<String, dynamic> payload = {
      "num_days": int.parse(num_days),
      "shifts": shiftsPayload,
      "night_bonus": double.parse(night_bonus),
      "base_hourly": int.parse(base_hourly.text),
      "max_hours": int.parse(max_hours),
      "max_consecutive_days": int.parse(max_consecutive_days),
      "PREF_W": hierarchy_pref,
      "FAIRNESS_W": fairness_w,
      "HOLIDAY_W": holiday_w,
      "holiday_indices": holiday_indices,
    };
    
    await ApiService.saveStoreSettings(payload);
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("매장의 운영 정책이 성공적으로 반영되었습니다.")));
    Navigator.pop(context);
  }

  @override
  void dispose() {
    for (var c in _shiftNameCtrls) {
      c.dispose();
    }
    for (var c in _shiftHoursCtrls) {
      c.dispose();
    }
    for (var c in _minStaffCtrls) {
      c.dispose();
    }
    for (var c in _targetStaffCtrls) {
      c.dispose();
    }
    base_hourly.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("매장 환경 설정 마법사"), backgroundColor: periwinkle),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() => _currentStep += 1);
          } else {
            _submitStoreSetup();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep -= 1);
        },
        steps: [
          Step(
            isActive: _currentStep >= 0,
            title: const Text("기본 환경 구성"),
            content: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: num_days,
                  decoration: const InputDecoration(labelText: "스케줄 생성 주기를 선택해주세요", border: OutlineInputBorder()),
                  items: const [DropdownMenuItem(value: "7", child: Text("매주 단위 (7일)")), DropdownMenuItem(value: "30", child: Text("한 달 단위 (30일)"))],
                  onChanged: (v) => setState(() => num_days = v!),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<int>(
                  value: shift_count,
                  decoration: const InputDecoration(labelText: "매장 내 교대조는 몇 개인가요?", border: OutlineInputBorder()),
                  items: [1, 2, 3, 4].map((n) => DropdownMenuItem(value: n, child: Text("$n개 파트"))).toList(),
                  onChanged: (v) => setState(() { shift_count = v!; _updateShiftFields(); }),
                ),
                const SizedBox(height: 15),
                DropdownButtonFormField<String>(
                  value: night_bonus,
                  decoration: const InputDecoration(labelText: "야간 근로 수당 비율", border: OutlineInputBorder()),
                  items: const [DropdownMenuItem(value: "0.0", child: Text("해당 없음")), DropdownMenuItem(value: "0.5", child: Text("법정 가산 50% 적용"))],
                  onChanged: (v) => setState(() => night_bonus = v!),
                ),
                const SizedBox(height: 15),
                TextFormField(controller: base_hourly, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "적용할 기본 시급 (원)", border: OutlineInputBorder())),
              ],
            ),
          ),
          Step(
            isActive: _currentStep >= 1,
            title: const Text("교대조별 인원 가이드"),
            content: Column(
              children: [
                ...List.generate(shift_count, (index) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 15),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: periwinkle.withOpacity(0.5))),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("▶ ${_shiftNameCtrls[index].text} 조 상세 설정", style: TextStyle(fontWeight: FontWeight.bold, color: periwinkle)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(child: TextFormField(controller: _shiftHoursCtrls[index], decoration: const InputDecoration(labelText: "근무 시간대"))),
                              const SizedBox(width: 10),
                              Expanded(child: TextFormField(controller: _minStaffCtrls[index], keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "최소 필수 인원"))),
                            ],
                          ),
                          CheckboxListTile(title: const Text("이 파트는 야간 수당이 발생하나요?"), activeColor: periwinkle, value: _shiftIsNight[index], onChanged: (v) => setState(() => _shiftIsNight[index] = v!)),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
          Step(
            isActive: _currentStep >= 2,
            title: const Text("AI 스케줄 우선순위 룰"),
            content: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: hierarchy_pref,
                  decoration: const InputDecoration(labelText: "경력직(시니어) 직원을 어디에 배치할까요?", border: OutlineInputBorder()),
                  items: const [DropdownMenuItem(value: "오픈 우선", child: Text("오픈 파트에 우선 배치")), DropdownMenuItem(value: "마감 우선", child: Text("마감 파트에 우선 배치")), DropdownMenuItem(value: "제한 없음", child: Text("상관없음 (랜덤 배치)"))],
                  onChanged: (v) => setState(() => hierarchy_pref = v!),
                ),
                const SizedBox(height: 15),
                SwitchListTile(title: const Text("모든 직원이 골고루 근무하도록 할까요?"), subtitle: const Text("근무일수 평준화 가중치 적용"), activeColor: periwinkle, value: fairness_w, onChanged: (v) => setState(() => fairness_w = v)),
                const SizedBox(height: 15),
                OutlinedButton.icon(
                  onPressed: () async {
                    var d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 60)));
                    if (d != null) setState(() => holiday_indices.add("${d.month}/${d.day}"));
                  },
                  icon: Icon(Icons.celebration, color: periwinkle),
                  label: const Text("특별히 챙겨야 할 매장 공휴일 추가"),
                ),
                Wrap(spacing: 8, children: holiday_indices.map((d) => Chip(label: Text(d), onDeleted: () => setState(() => holiday_indices.remove(d)))).toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }
}