import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'a06_role_selection_page.dart';

class TermsAgreementPage extends StatefulWidget {
  const TermsAgreementPage({super.key});

  @override
  State<TermsAgreementPage> createState() => _TermsAgreementPageState();
}

class _TermsAgreementPageState extends State<TermsAgreementPage> {
  bool _isAllChecked = false;
  bool _isServiceChecked = false;
  bool _isPrivacyChecked = false;
  bool _isNotificationChecked = false; // 🚨 기획서 반영: 알림 권한 추가

  void _checkAll(bool? value) {
    setState(() {
      _isAllChecked = value ?? false;
      _isServiceChecked = _isAllChecked;
      _isPrivacyChecked = _isAllChecked;
      _isNotificationChecked = _isAllChecked;
    });
  }

  void _updateCheck() {
    setState(() {
      _isAllChecked = _isServiceChecked && _isPrivacyChecked && _isNotificationChecked;
    });
  }

  @override
  Widget build(BuildContext context) {
    // 다음으로 넘어가려면 '필수' 2개만 체크되어 있으면 됨
    bool isNextEnabled = _isServiceChecked && _isPrivacyChecked;

    return Scaffold(
      backgroundColor: ThymeColor.bg,
      appBar: AppBar(
        backgroundColor: ThymeColor.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: ThymeColor.text),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Thyme 이용을 위해\n약관에 동의해 주세요",
                style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: ThymeColor.text, height: 1.3),
              ),
              const SizedBox(height: 40),
              
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: ThymeColor.text,
                controlAffinity: ListTileControlAffinity.leading,
                title: const Text("약관 전체 동의", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: ThymeColor.text)),
                value: _isAllChecked,
                onChanged: _checkAll,
              ),
              const Divider(),
              
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: ThymeColor.text,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text("[필수] 서비스 이용약관 동의", style: TextStyle(fontSize: 15, color: ThymeColor.charcoal)),
                value: _isServiceChecked,
                onChanged: (value) { setState(() => _isServiceChecked = value ?? false); _updateCheck(); },
              ),
              
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: ThymeColor.text,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text("[필수] 개인정보 수집 및 이용 동의", style: TextStyle(fontSize: 15, color: ThymeColor.charcoal)),
                value: _isPrivacyChecked,
                onChanged: (value) { setState(() => _isPrivacyChecked = value ?? false); _updateCheck(); },
              ),

              // 🚨 기획서 반영: 알림 켜기 안내 (선택 동의)
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: ThymeColor.text,
                controlAffinity: ListTileControlAffinity.leading,
                title: Text("[선택] 대타·근무표 알림 수신 동의", style: TextStyle(fontSize: 15, color: ThymeColor.charcoal)),
                subtitle: Text("앱을 켜지 않아도 중요한 알림을 받을 수 있어요.", style: TextStyle(fontSize: 12, color: ThymeColor.textSub)),
                value: _isNotificationChecked,
                onChanged: (value) { setState(() => _isNotificationChecked = value ?? false); _updateCheck(); },
              ),
              
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(onPressed: isNextEnabled
                      ? () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const RoleSelectionPage()),
                          );
                        }
                      : null, child: Text("동의하고 시작하기")),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}