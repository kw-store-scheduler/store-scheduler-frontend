import 'package:flutter/material.dart';
import '../core/home_router.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../screens/owner/o01_store_registration_page.dart';
import '../screens/owner/p01_owner_home_page.dart';

/// 점주 홈 매장 이름 ▼: 내 매장 중 하나를 고르거나 새 매장을 등록한다
Future<void> showStorePicker(BuildContext context) async {
  final session = Session.instance;
  final stores = session.me?.ownedStores ?? const [];
  final picked = await showModalBottomSheet<Object>(
    context: context,
    backgroundColor: ThymeColor.surface,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text("매장 고르기", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: ThymeColor.text)),
          ),
          const SizedBox(height: 8),
          for (final s in stores)
            ListTile(
              title: Text(s.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: s.storeCode == null ? null : Text("매장 코드 ${s.storeCode}"),
              trailing: s.id == session.storeId ? const Icon(Icons.check, color: ThymeColor.text) : null,
              onTap: () => Navigator.pop(context, s.id),
            ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text("새 매장 등록", style: TextStyle(fontWeight: FontWeight.bold)),
            onTap: () => Navigator.pop(context, 'new'),
          ),
        ]),
      ),
    ),
  );
  if (!context.mounted || picked == null) return;
  if (picked == 'new') {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const StoreRegistrationPage()));
  } else if (picked is int && picked != session.storeId) {
    session.storeId = picked;
    resetTo(context, const OwnerHomePage());
  }
}
