import 'package:flutter/material.dart';
import 'admin_dashboard.dart';

class AdminLoginPage extends StatefulWidget {
  const AdminLoginPage({super.key});
  @override
  State<AdminLoginPage> createState() => _AdminLoginPageState();
}

class _AdminLoginPageState extends State<AdminLoginPage> {
  final TextEditingController _pwController = TextEditingController();
  final Color periwinkle = const Color(0xFF8E97FD);

  void _checkPassword() {
    if (_pwController.text == "0000") {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const AdminDashboard()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("비밀번호가 틀렸습니다!")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("관리자 로그인"), backgroundColor: periwinkle),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_person_rounded, size: 100, color: periwinkle),
            const SizedBox(height: 20),
            const Text("관리자 로그인", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextField(
              controller: _pwController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: "관리자 비밀번호", 
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
                prefixIcon: const Icon(Icons.vpn_key_rounded),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: periwinkle, 
                foregroundColor: Colors.white, 
                minimumSize: const Size(double.infinity, 60),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              ),
              onPressed: _checkPassword,
              child: const Text("로그인", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}