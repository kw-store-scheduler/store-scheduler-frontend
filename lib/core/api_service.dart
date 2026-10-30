import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

/// 서버 에러를 화면에서 그대로 보여줄 수 있게 정리한 예외.
/// 백엔드(GlobalExceptionHandler)는 에러를 항상 `{"message": "..."}`로 내려준다.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiService {
  // 싱글톤 패턴: 앱 전체에서 통신 객체를 딱 하나만 돌려쓰기 위함
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;

  late final Dio dio;

  /// 로그인하면 채워지는 JWT. 모든 요청에 `Authorization: Bearer` 로 붙는다. 1시간이면 만료된다
  String? token;

  /// 액세스 토큰이 만료(401)되면 POST /api/auth/refresh 로 새 쌍을 받는 데 쓴다. 14일, 한 번 쓰면 새 것으로 바뀐다
  String? refreshToken;

  /// 재발급으로 토큰이 바뀌면 부른다. Session이 저장소에 다시 쓴다
  Future<void> Function()? onTokensRefreshed;

  /// 로그인한 상태에서 401이 오고 재발급도 안 되면 부른다. main.dart가 세션을 지우고 로그인 화면으로 보낸다
  void Function()? onUnauthorized;

  /// 진행 중인 재발급. 여러 요청이 한꺼번에 401을 받아도 리프레시 토큰은 한 번만 쓴다 (두 번째는 이미 쓴 토큰이라 실패)
  Future<bool>? _refreshing;

  /// 서버 주소. 빌드할 때 바꾼다: `flutter run --dart-define=API_BASE_URL=https://...`
  /// 지정하지 않으면 로컬 서버 (안드로이드 에뮬레이터는 PC의 localhost가 10.0.2.2)
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    if (fromEnv.isNotEmpty) return fromEnv;
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    return isAndroid ? 'http://10.0.2.2:8080' : 'http://localhost:8080';
  }

  ApiService._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        // 근무표 생성(엔진 3회)은 오래 걸리고, 무료 서버는 잠들어 있다 깨어나는 데 시간이 걸린다
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 90),
        headers: {'Content-Type': 'application/json'},
      ),
    );

    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (token != null && options.extra['noAuth'] != true) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
    ));

    // 요청/응답 로그는 디버그 빌드에서만 (토큰·개인정보가 찍히므로)
    if (kDebugMode) {
      dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true, logPrint: (o) => debugPrint('$o')));
    }
  }

  Future<dynamic> get(String path, {Map<String, dynamic>? query}) =>
      _send(() => dio.get(path, queryParameters: query));

  Future<dynamic> post(String path, {Object? data, Map<String, dynamic>? query}) =>
      _send(() => dio.post(path, data: data, queryParameters: query));

  Future<dynamic> put(String path, {Object? data, Map<String, dynamic>? query}) =>
      _send(() => dio.put(path, data: data, queryParameters: query));

  Future<dynamic> patch(String path, {Object? data, Map<String, dynamic>? query}) =>
      _send(() => dio.patch(path, data: data, queryParameters: query));

  Future<dynamic> delete(String path, {Map<String, dynamic>? query}) =>
      _send(() => dio.delete(path, queryParameters: query));

  /// 응답 본문(JSON)만 돌려주고, 실패는 ApiException 하나로 바꾼다.
  /// 로그인한 상태에서 401이 오면 토큰을 재발급받아 한 번 더 보낸다 (요청 함수가 보낼 때마다 헤더를 새 토큰으로 붙인다)
  Future<dynamic> _send(Future<Response> Function() request) async {
    try {
      return (await request()).data;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // 로그인 중이 아닐 때의 401(잘못된 비밀번호 등)은 화면이 처리한다
      if (status == 401 && token != null) {
        final sentWith = e.requestOptions.headers['Authorization'];
        // 기다리는 사이 다른 요청이 이미 재발급했으면 그 토큰으로 다시 보낸다
        final renewed = sentWith != 'Bearer $token' || await _refresh();
        if (renewed) {
          try {
            return (await request()).data;
          } on DioException catch (e2) {
            if (e2.response?.statusCode == 401) onUnauthorized?.call();
            throw ApiException(_messageOf(e2), statusCode: e2.response?.statusCode);
          }
        }
        onUnauthorized?.call();
      }
      throw ApiException(_messageOf(e), statusCode: status);
    }
  }

  /// 리프레시 토큰으로 새 토큰 쌍을 받는다. 동시에 불려도 서버에는 한 번만 보낸다. 성공하면 true
  Future<bool> _refresh() {
    final rt = refreshToken;
    if (rt == null) return Future.value(false);
    return _refreshing ??= () async {
      try {
        final res = await dio.post('/api/auth/refresh', data: {'refreshToken': rt}, options: Options(extra: {'noAuth': true}));
        token = res.data['token'] as String;
        refreshToken = res.data['refreshToken'] as String;
        await onTokensRefreshed?.call();
        return true;
      } on DioException {
        return false;
      } finally {
        _refreshing = null;
      }
    }();
  }

  static String _messageOf(DioException e) {
    final body = e.response?.data;
    if (body is Map && body['message'] is String) return body['message'] as String;
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return '서버 응답이 늦어요. 잠시 후 다시 시도해 주세요.';
      case DioExceptionType.connectionError:
        return '서버에 연결할 수 없어요. 인터넷 연결을 확인해 주세요.';
      default:
        return switch (e.response?.statusCode) {
          401 => '다시 로그인해 주세요.',
          403 => '접근 권한이 없어요.',
          _ => '요청을 처리하지 못했어요.',
        };
    }
  }
}
