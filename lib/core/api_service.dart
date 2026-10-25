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

  /// 로그인하면 채워지는 JWT. 모든 요청에 `Authorization: Bearer` 로 붙는다.
  String? token;

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
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
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

  /// 응답 본문(JSON)만 돌려주고, 실패는 ApiException 하나로 바꾼다
  Future<dynamic> _send(Future<Response> Function() request) async {
    try {
      return (await request()).data;
    } on DioException catch (e) {
      throw ApiException(_messageOf(e), statusCode: e.response?.statusCode);
    }
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
