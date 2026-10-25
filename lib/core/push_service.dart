import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../firebase_options.dart';
import 'api_service.dart';

/// FCM 푸시 (근무표 확정·대타 요청 알림). 서버는 등록된 디바이스 토큰으로 보낸다.
class PushService {
  PushService._();

  static bool _ready = false;

  /// firebase_messaging이 지원하는 플랫폼 (Windows·Linux 데스크톱은 미지원)
  static bool get _supported =>
      kIsWeb ||
      const {TargetPlatform.android, TargetPlatform.iOS, TargetPlatform.macOS}.contains(defaultTargetPlatform);

  /// main()에서 한 번. 실패해도 앱은 푸시 없이 동작한다
  static Future<void> init() async {
    if (!_supported) return;
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      _ready = true;
    } catch (e) {
      debugPrint('Firebase 초기화 실패, 푸시 없이 진행: $e');
    }
  }

  /// 로그인 직후 호출: 알림 권한을 묻고 이 기기 토큰을 서버에 등록한다 (A05 알림 켜기)
  static Future<void> registerDevice() async {
    if (!_ready) return;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      // 새 register()/onRegistered는 설치 ID(FID)를 주는데, 서버(firebase-admin)는 등록 토큰으로 보내서
      // 서버가 direct-send로 바뀌기 전까지는 getToken을 쓴다
      // ignore: deprecated_member_use
      final token = await messaging.getToken();
      if (token != null) await _send(token);
      // 토큰이 바뀌면 다시 등록
      // ignore: deprecated_member_use
      messaging.onTokenRefresh.listen(_send);
    } catch (e) {
      debugPrint('푸시 토큰 등록 실패: $e');
    }
  }

  static Future<void> _send(String token) => ApiService().patch('/api/users/me/device-token', data: {'deviceToken': token});
}
