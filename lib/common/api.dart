import 'dart:async';
import 'dart:convert';

import 'package:cloudreve_view/controller.dart';
import 'package:cloudreve_view/entity/file.dart';
import 'package:cloudreve_view/entity/user.dart';
import 'package:dio/dio.dart';
import 'package:get/get.dart' as getx;

enum LoginCaptchaType {
  none,
  plain,
  turnstile,
  recaptchaV2,
  cap,
}

class LoginCaptchaConfig {
  final LoginCaptchaType type;
  final String rawType;
  final bool enabled;
  final String siteKey;
  final String image;
  final String ticket;

  const LoginCaptchaConfig({
    required this.type,
    required this.rawType,
    required this.enabled,
    this.siteKey = '',
    this.image = '',
    this.ticket = '',
  });

  const LoginCaptchaConfig.none()
      : type = LoginCaptchaType.none,
        rawType = '',
        enabled = false,
        siteKey = '',
        image = '',
        ticket = '';

  bool get requiresToken =>
      type == LoginCaptchaType.turnstile ||
      type == LoginCaptchaType.recaptchaV2 ||
      type == LoginCaptchaType.cap;

  bool get requiresCode => type == LoginCaptchaType.plain;
}

class CaptchaData {
  final String image;
  final String ticket;

  const CaptchaData({required this.image, required this.ticket});

  bool get isValid => image.isNotEmpty && ticket.isNotEmpty;
}

class PrepareLoginResult {
  final bool success;
  final bool passwordEnabled;
  final bool ssoEnabled;
  final bool qqEnabled;
  final bool webauthnEnabled;
  final String message;

  const PrepareLoginResult({
    required this.success,
    required this.passwordEnabled,
    required this.ssoEnabled,
    required this.qqEnabled,
    required this.webauthnEnabled,
    this.message = '',
  });

  bool get accountExists =>
      passwordEnabled || ssoEnabled || qqEnabled || webauthnEnabled;
}

abstract class ApiConfig {
  static String env = "dev";
  static String host = "https://zofiles.com";
  static String baseUrl = "$host/api/v4";

  static String resolveUrl(String url) {
    if (url.isEmpty) return "";
    if (url.startsWith("http://") || url.startsWith("https://")) {
      return url;
    }
    if (url.startsWith("/")) {
      return "$host$url";
    }
    return "$host/$url";
  }

  static const Map<String, String> apis = {
    "prepare": "/session/prepare",
    "login": "/session/token",
    "refresh": "/session/token/refresh",
    "captcha": "/site/captcha",
    "siteConfig": "/site/config/site",
    "me": "/user/me",
    "directory": "/file",
    "fileUrl": "/file/url",
  };
}

class Api {
  static final Dio _dio = Dio();
  static final Controller controller = getx.Get.find<Controller>();
  static bool _isInitialized = false;
  static Map<String, dynamic>? _siteConfigCache;
  static DateTime? _siteConfigCacheAt;
  static Future<Map<String, dynamic>>? _siteConfigPending;

  Api() {
    if (_isInitialized) return;

    _dio
      ..options.baseUrl = ApiConfig.baseUrl
      ..options.connectTimeout = const Duration(seconds: 10)
      ..options.receiveTimeout = const Duration(seconds: 20)
      ..options.headers = {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (controller.hasToken) {
            options.headers['Authorization'] = controller.authHeader;
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (ApiConfig.env == "dev") {
            print(
                "API ${response.requestOptions.method} ${response.requestOptions.path}");
            print(jsonEncode(response.data));
          }
          handler.next(response);
        },
        onError: (error, handler) async {
          final request = error.requestOptions;
          final unauthorized = error.response?.statusCode == 401 ||
              (error.response?.data is Map &&
                  (error.response?.data['code'] == 401 ||
                      error.response?.data['code'] == 10001));
          final alreadyRetried = request.extra['retried'] == true;

          if (unauthorized &&
              !alreadyRetried &&
              controller.refreshToken.isNotEmpty) {
            final refreshed = await _refreshAccessToken();
            if (refreshed) {
              request.extra['retried'] = true;
              request.headers['Authorization'] = controller.authHeader;
              final retryResponse = await _dio.fetch(request);
              return handler.resolve(retryResponse);
            }
          }

          if (unauthorized) {
            controller.logout();
          }

          handler.next(error);
        },
      ),
    );

    _isInitialized = true;
  }

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw Exception('Failed to load data: $e');
    }
  }

  Future<Response<dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
    } on DioException catch (e) {
      throw Exception('Failed to post data: $e');
    }
  }

  Future<Map<String, dynamic>> getSiteConfig(
      {bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _siteConfigCache != null &&
        _siteConfigCacheAt != null &&
        DateTime.now().difference(_siteConfigCacheAt!).inSeconds < 60) {
      return _siteConfigCache!;
    }
    if (!forceRefresh && _siteConfigPending != null) {
      return _siteConfigPending!;
    }

    _siteConfigPending = () async {
      try {
        final response = await get(
          ApiConfig.apis['siteConfig']!,
          options: Options(headers: {'Authorization': null}),
        );
        final data = response.data as Map<String, dynamic>;
        if (data['code'] != 0) return <String, dynamic>{};
        final payload = (data['data'] as Map?)?.cast<String, dynamic>() ??
            <String, dynamic>{};

        final userMap = payload['user'] is Map<String, dynamic>
            ? payload['user'] as Map<String, dynamic>
            : <String, dynamic>{};
        final userLanguage = _stringOf(userMap['language']);
        final siteLanguage = _stringOf(payload['language']);
        controller.setBranding(
          title: _stringOf(payload['title']),
          logo: _stringOf(payload['logo']),
          logoLight: _stringOf(payload['logo_light']),
        );
        controller.applyCloudreveLanguageTag(
          userLanguage.isNotEmpty ? userLanguage : siteLanguage,
        );

        _siteConfigCache = payload;
        _siteConfigCacheAt = DateTime.now();
        return payload;
      } catch (_) {
        return <String, dynamic>{};
      } finally {
        _siteConfigPending = null;
      }
    }();

    return _siteConfigPending!;
  }

  Future<CaptchaData> getPlainCaptcha() async {
    try {
      final response = await get(
        ApiConfig.apis['captcha']!,
        options: Options(headers: {'Authorization': null}),
      );
      final data = response.data as Map<String, dynamic>;
      if (data['code'] != 0) {
        return const CaptchaData(image: '', ticket: '');
      }

      final payload = (data['data'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      return CaptchaData(
        image: _stringOf(payload['image']),
        ticket: _stringOf(payload['ticket']),
      );
    } catch (_) {
      return const CaptchaData(image: '', ticket: '');
    }
  }

  Future<LoginCaptchaConfig> getLoginCaptchaConfig() async {
    final siteConfig = await getSiteConfig();
    final rawType = _stringOf(siteConfig['captcha_type']).trim().toLowerCase();
    final turnstileKey = _stringOf(siteConfig['turnstile_site_id']).trim();
    final recaptchaKey = _stringOf(siteConfig['captcha_ReCaptchaKey']).trim();

    if (rawType == 'turnstile' ||
        (rawType.isEmpty && turnstileKey.isNotEmpty)) {
      return LoginCaptchaConfig(
        type: LoginCaptchaType.turnstile,
        rawType: rawType.isEmpty ? 'turnstile' : rawType,
        enabled: true,
        siteKey: turnstileKey,
      );
    }

    if (rawType == 'recaptcha_v2' || rawType == 'recaptcha') {
      return LoginCaptchaConfig(
        type: LoginCaptchaType.recaptchaV2,
        rawType: rawType,
        enabled: true,
        siteKey: recaptchaKey,
      );
    }

    if (rawType == 'cap') {
      return LoginCaptchaConfig(
        type: LoginCaptchaType.cap,
        rawType: rawType,
        enabled: true,
        siteKey: recaptchaKey,
      );
    }

    final isPlainLike = rawType == 'plain' ||
        rawType == 'graphic' ||
        rawType == 'image' ||
        rawType == 'captcha' ||
        rawType == 'normal';
    if (!isPlainLike) {
      return const LoginCaptchaConfig.none();
    }

    final plainCaptcha = await getPlainCaptcha();

    if (plainCaptcha.isValid) {
      return LoginCaptchaConfig(
        type: LoginCaptchaType.plain,
        rawType: rawType,
        enabled: true,
        image: plainCaptcha.image,
        ticket: plainCaptcha.ticket,
      );
    }

    return const LoginCaptchaConfig.none();
  }

  Future<PrepareLoginResult> prepareLogin(String email) async {
    try {
      final response = await get(
        ApiConfig.apis['prepare']!,
        queryParameters: {'email': email},
        options: Options(headers: {'Authorization': null}),
      );

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      if (data['code'] != 0) {
        final code = _intOf(data['code']) ?? -1;
        final msg = _stringOf(data['msg']).toLowerCase();
        // Cloudreve returns 404/"User not found" for non-existing account.
        // This is a valid branch in login flow and should go to sign-up step.
        if (code == 404 || msg.contains('user not found')) {
          return const PrepareLoginResult(
            success: true,
            passwordEnabled: false,
            ssoEnabled: false,
            qqEnabled: false,
            webauthnEnabled: false,
          );
        }
        return PrepareLoginResult(
          success: false,
          passwordEnabled: false,
          ssoEnabled: false,
          qqEnabled: false,
          webauthnEnabled: false,
          message: _stringOf(data['msg']),
        );
      }

      final payload = (data['data'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      return PrepareLoginResult(
        success: true,
        passwordEnabled: payload['password_enabled'] == true,
        ssoEnabled: payload['sso_enabled'] == true,
        qqEnabled: payload['qq_enabled'] == true,
        webauthnEnabled: payload['webauthn_enabled'] == true,
        message: _stringOf(data['msg']),
      );
    } on DioException catch (e) {
      final raw = e.response?.data;
      final data = raw is Map<String, dynamic>
          ? raw
          : <String, dynamic>{'code': e.response?.statusCode, 'msg': e.message};
      final code = _intOf(data['code']) ?? _intOf(e.response?.statusCode) ?? -1;
      final msg = _stringOf(data['msg']);

      // Some deployments return HTTP 404 for non-existing account in prepare API.
      if (code == 404 || msg.toLowerCase().contains('user not found')) {
        return const PrepareLoginResult(
          success: true,
          passwordEnabled: false,
          ssoEnabled: false,
          qqEnabled: false,
          webauthnEnabled: false,
        );
      }

      return PrepareLoginResult(
        success: false,
        passwordEnabled: false,
        ssoEnabled: false,
        qqEnabled: false,
        webauthnEnabled: false,
        message: msg.isEmpty ? 'Unable to verify account' : msg,
      );
    } catch (_) {
      return const PrepareLoginResult(
        success: false,
        passwordEnabled: false,
        ssoEnabled: false,
        qqEnabled: false,
        webauthnEnabled: false,
        message: 'Unable to verify account',
      );
    }
  }

  Future<bool> _refreshAccessToken() async {
    try {
      final response = await _dio.post(
        ApiConfig.apis["refresh"]!,
        data: {"refresh_token": controller.refreshToken},
        options: Options(headers: {'Authorization': null}),
      );

      final data = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : <String, dynamic>{};
      if (data['code'] != 0) return false;

      final tokenData = (data['data'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final accessToken = _stringOf(
        tokenData['access_token'] ?? tokenData['token'],
      );
      final refreshToken = _stringOf(
        tokenData['refresh_token'] ?? controller.refreshToken,
      );
      final expiresIn = _intOf(tokenData['expires_in']) ?? 3600;
      if (accessToken.isEmpty) return false;

      controller.setTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expireAt: DateTime.now().millisecondsSinceEpoch + expiresIn * 1000,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Response<dynamic>> login({
    required String email,
    required String password,
    String captcha = '',
    String ticket = '',
  }) async {
    final payload = <String, dynamic>{
      "email": email,
      "password": password,
    };
    if (captcha.isNotEmpty) {
      payload["captcha"] = captcha;
    }

    if (ticket.isNotEmpty) {
      payload["ticket"] = ticket;
    }
    if (ApiConfig.env == "dev") {
      print(
          "Login payload debug: captcha_len=${captcha.length}, has_ticket=${ticket.isNotEmpty}, ticket_len=${ticket.length}");
    }

    final response = await post(
      ApiConfig.apis["login"]!,
      data: payload,
      options: Options(headers: {'Authorization': null}),
    );

    final data = response.data as Map<String, dynamic>;
    if (data["code"] == 0) {
      final loginData = (data['data'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{};
      final tokenData = _extractTokenData(loginData);
      final accessToken = _stringOf(tokenData['access_token']);
      final refreshToken = _stringOf(tokenData['refresh_token']);
      final expiresAt = _stringOf(tokenData['access_expires']);
      final expiresIn = _expiresInFromIsoTime(expiresAt) ?? 3600;

      if (accessToken.isNotEmpty) {
        controller.setTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
          expireAt: DateTime.now().millisecondsSinceEpoch + expiresIn * 1000,
        );
      }

      final userMap =
          _extractUserMap(loginData) ?? await _fetchCurrentUserMap();
      if (userMap != null) {
        controller.setUser(User.fromMap(userMap));
      }
    }

    return response;
  }

  Future<Response<dynamic>> directory({String path = ""}) {
    return get(
      ApiConfig.apis["directory"]!,
      queryParameters: {
        'uri': _pathToUri(path),
      },
    );
  }

  Future<String> getPreviewFileUrl(File file) async {
    try {
      final response = await post(
        ApiConfig.apis["fileUrl"]!,
        data: {
          "uris": [file.uri],
          "redirect": false,
        },
      );
      return _extractFileUrl(response.data, file.uri);
    } catch (_) {
      return "";
    }
  }

  Future<String> getThumbnailUrl(File file) async {
    if (file.thumbnail.isNotEmpty) {
      return ApiConfig.resolveUrl(file.thumbnail);
    }

    try {
      final response = await post(
        ApiConfig.apis["fileUrl"]!,
        data: {
          "uris": [file.uri],
          "redirect": false,
        },
      );
      return _extractFileUrl(response.data, file.uri);
    } catch (_) {
      return "";
    }
  }

  Future<Map<String, dynamic>?> _fetchCurrentUserMap() async {
    try {
      final candidates = [ApiConfig.apis["me"]!, "/user"];
      for (final endpoint in candidates) {
        try {
          final response = await get(endpoint);
          final data = response.data as Map<String, dynamic>;
          if (data["code"] == 0) {
            final userMap = _extractUserMap(
              (data['data'] as Map?)?.cast<String, dynamic>() ??
                  <String, dynamic>{},
            );
            if (userMap != null) return userMap;
          }
        } catch (_) {
          continue;
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic>? _extractUserMap(Map<String, dynamic> source) {
    if (source['data'] is Map<String, dynamic>) {
      final nested = source['data'] as Map<String, dynamic>;
      final nestedUser = _extractUserMap(nested);
      if (nestedUser != null) return nestedUser;
    }
    if (source['user'] is Map<String, dynamic>) {
      return source['user'] as Map<String, dynamic>;
    }
    if (source['profile'] is Map<String, dynamic>) {
      return source['profile'] as Map<String, dynamic>;
    }
    if (source['id'] != null &&
        (source['nickname'] != null || source['username'] != null)) {
      return source;
    }
    return null;
  }

  Map<String, dynamic> _extractTokenData(Map<String, dynamic> source) {
    if (source['token'] is Map<String, dynamic>) {
      return source['token'] as Map<String, dynamic>;
    }
    if (source['data'] is Map<String, dynamic>) {
      return _extractTokenData(source['data'] as Map<String, dynamic>);
    }
    return source;
  }

  String _extractFileUrl(dynamic payload, String uri) {
    if (payload is! Map<String, dynamic>) return "";
    if (payload['code'] != 0) return "";

    final data = (payload['data'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{};

    if (data['url'] is String) {
      return data['url'] as String;
    }

    if (data['urls'] is List && (data['urls'] as List).isNotEmpty) {
      final item = (data['urls'] as List).first;
      if (item is String) return item;
      if (item is Map<String, dynamic>) {
        return _stringOf(item['url'] ?? item['download_url']);
      }
    }

    if (data['map'] is Map<String, dynamic>) {
      final map = data['map'] as Map<String, dynamic>;
      final entry = map[uri];
      if (entry is String) return entry;
      if (entry is Map<String, dynamic>) {
        return _stringOf(entry['url'] ?? entry['download_url']);
      }
    }

    return "";
  }

  String _pathToUri(String path) {
    if (path.isEmpty) return "cloudreve://my/";

    final sanitized = path.startsWith('/') ? path.substring(1) : path;
    final normalized = sanitized.endsWith('/') ? sanitized : '$sanitized/';
    return 'cloudreve://my/$normalized';
  }

  static String _stringOf(dynamic value) {
    if (value == null) return "";
    return value.toString();
  }

  int? _intOf(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  int? _expiresInFromIsoTime(String value) {
    if (value.isEmpty) return null;
    final expiresAt = DateTime.tryParse(value);
    if (expiresAt == null) return null;
    final seconds = expiresAt.difference(DateTime.now()).inSeconds;
    if (seconds <= 0) return 1;
    return seconds;
  }
}
