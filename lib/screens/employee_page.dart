import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import '../models/api_service.dart';
import 'admin_login_page.dart';

class _PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    var text = newValue.text.replaceAll('-', ''); // 기존 하이픈 제거 후 순수 숫자만 추출
    if (text.length > 11) text = text.substring(0, 11); // 최대 11자리 제한

    var buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      int index = i + 1;
      // 010-1234-5678 규격에 맞춰 하이픈 자동 추가
      if ((index == 3 || index == 7) && index != text.length) {
        buffer.write('-');
      }
    }

    var string = buffer.toString();
    return TextEditingValue(
      text: string,
      selection: TextSelection.collapsed(offset: string.length),
    );
  }
}

class EmployeePage extends StatefulWidget {
  const EmployeePage({super.key});
  @override
  State<EmployeePage> createState() => _EmployeePageState();
}

class _EmployeePageState extends State<EmployeePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final Color periwinkle = const Color(0xFF8E97FD);

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("빽다방 광운대점 근무 신청"), backgroundColor: periwinkle, centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const SizedBox(height: 50),
            Icon(Icons.person_pin_rounded, size: 90, color: periwinkle),
            const SizedBox(height: 20),
            const Text("환영합니다!", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFF2D3142))),
            const Text("본인의 성함 and 연락처를 입력해 주세요.", style: TextStyle(color: Colors.grey, fontSize: 16)),
            const SizedBox(height: 40),
            TextField(controller: _nameController, decoration: InputDecoration(labelText: "이름을 알려주세요", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none), prefixIcon: Icon(Icons.account_circle, color: periwinkle))),
            const SizedBox(height: 15),
            TextField(
              controller: _phoneController, 
              keyboardType: TextInputType.phone, 
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly, 
                _PhoneNumberFormatter(), 
              ], 
              decoration: InputDecoration(labelText: "휴대폰 번호를 입력해 주세요", hintText: "010-0000-0000", filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none), prefixIcon: Icon(Icons.phone_iphone, color: periwinkle))
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: periwinkle, foregroundColor: Colors.white, minimumSize: const Size(double.infinity, 60), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), elevation: 2),
              onPressed: () {
                if (_nameController.text.isNotEmpty && _phoneController.text.length >= 12) { // 하이픈 포함 최소 12자 이상 체크
                  Navigator.push(context, MaterialPageRoute(builder: (context) => EmployeeOnboardingPage(employeeName: _nameController.text)));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("성함과 연락처를 정확히 입력해 주세요.")));
                }
              },
              child: const Text("근무 성향 등록 시작하기", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 50),
            TextButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminLoginPage())), child: const Text("관리자(점장님) 전용 모드", style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline))),
          ],
        ),
      ),
    );
  }
}

class EmployeeOnboardingPage extends StatefulWidget {
  final String employeeName;
  const EmployeeOnboardingPage({super.key, required this.employeeName});

  @override
  State<EmployeeOnboardingPage> createState() => _EmployeeOnboardingPageState();
}

class _EmployeeOnboardingPageState extends State<EmployeeOnboardingPage> {
  final Color periwinkle = const Color(0xFF8E97FD);
  int _currentStep = 0;

  final List<String> available_days = [];
  List<Map<String, String>> off_requests = []; 
  final List<String> preferred_shifts = [];
  final TextEditingController target_work_days = TextEditingController(text: "3"); 
  String work_focus = "상관없음";

  Future<void> _submitData() async {
    Map<String, dynamic> payload = {
      "available_days": available_days,
      "off_requests": off_requests,
      "preferred_shifts": preferred_shifts,
      "target_work_days": int.tryParse(target_work_days.text) ?? 3,
      "work_focus": work_focus,
    };
    
    await ApiService.saveEmployeeSettings(widget.employeeName, payload);
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("등록 성공! 🎉", style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text("입력하신 소중한 정보가 점장님께 잘 전달되었습니다."),
        actions: [TextButton(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), child: Text("확인", style: TextStyle(color: periwinkle, fontWeight: FontWeight.bold)))],
      )
    );
  }

  void _addOffRequest() {
    String tempType = "prefer";
    DateTime? tempDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("휴무 희망일 추가"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton(
                onPressed: () async {
                  var d = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 30)));
                  if (d != null) setStateDialog(() => tempDate = d);
                },
                child: Text(tempDate == null ? "날짜를 선택해 주세요" : "${tempDate!.month}월 ${tempDate!.day}일"),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: tempType,
                items: const [DropdownMenuItem(value: "must", child: Text("이 날은 무조건 쉬어야 해요")), DropdownMenuItem(value: "prefer", child: Text("가급적 쉬고 싶어요"))],
                onChanged: (v) => setStateDialog(() => tempType = v!),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                if (tempDate != null) {
                  setState(() {
                    off_requests.add({"date": "${tempDate!.year}-${tempDate!.month}-${tempDate!.day}", "type": tempType});
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text("신청"),
            )
          ],
        )
      )
    );
  }

  @override
  void dispose() {
    target_work_days.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.employeeName} 님의 근무 성향 등록"), backgroundColor: periwinkle),
      body: Stepper(
        type: StepperType.horizontal,
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 1) {
            setState(() => _currentStep += 1);
          } else {
            _submitData();
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) setState(() => _currentStep -= 1);
        },
        steps: [
          Step(
            isActive: _currentStep >= 0,
            title: const Text("근무 가능 요일"),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("출근이 가능한 요일을 모두 선택해 주세요", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                Wrap(
                  spacing: 8,
                  children: ["월", "화", "수", "목", "금", "토", "일"].map((day) {
                    final isSel = available_days.contains(day);
                    return FilterChip(
                      label: Text(day, style: TextStyle(color: isSel ? Colors.white : Colors.black87)),
                      selected: isSel,
                      selectedColor: periwinkle,
                      checkmarkColor: Colors.white,
                      onSelected: (val) => setState(() => val ? available_days.add(day) : available_days.remove(day)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 25),
                const Text("특별히 꼭 쉬어야 하는 날이 있나요?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                OutlinedButton.icon(onPressed: _addOffRequest, icon: const Icon(Icons.calendar_month), label: const Text("휴무 요청일 추가")),
                ...off_requests.map((req) => ListTile(
                  title: Text(req["date"]!, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(req["type"] == "must" ? "필수 휴무" : "희망 휴무"),
                  trailing: IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.red), onPressed: () => setState(() => off_requests.remove(req))),
                )).toList()
              ],
            ),
          ),
          Step(
            isActive: _currentStep >= 1,
            title: const Text("근무 선호도"),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("어느 시간대 근무를 가장 선호하시나요?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  children: ["오전 파트", "오후 파트", "마감 파트"].map((shift) {
                    final isSel = preferred_shifts.contains(shift);
                    return FilterChip(
                      label: Text(shift, style: TextStyle(color: isSel ? Colors.white : Colors.black87)),
                      selected: isSel,
                      selectedColor: periwinkle,
                      checkmarkColor: Colors.white,
                      onSelected: (val) => setState(() => val ? preferred_shifts.add(shift) : preferred_shifts.remove(shift)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 25),
                TextFormField(
                  controller: target_work_days,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "일주일에 며칠 정도 근무하고 싶으신가요?", border: OutlineInputBorder()),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: work_focus,
                  decoration: const InputDecoration(labelText: "특정 요일에 집중해서 일하고 싶으신가요?", border: OutlineInputBorder()),
                  items: const [DropdownMenuItem(value: "상관없음", child: Text("상관없음")), DropdownMenuItem(value: "주중 집중", child: Text("평일(월~금) 집중 근무")), DropdownMenuItem(value: "주말 집중", child: Text("주말(토~일) 집중 근무"))],
                  onChanged: (v) => setState(() => work_focus = v!),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}