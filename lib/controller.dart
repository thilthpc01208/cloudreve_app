import 'dart:convert';

import 'package:cloudreve_view/common/constants.dart';
import 'package:cloudreve_view/entity/user.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CloudreveLanguage {
  final String code;
  final String displayName;

  const CloudreveLanguage({required this.code, required this.displayName});
}

class RememberedAccount {
  final String id;
  final String email;
  final String nickname;
  final String avatar;
  final int updatedAt;

  const RememberedAccount({
    required this.id,
    required this.email,
    required this.nickname,
    required this.avatar,
    required this.updatedAt,
  });

  factory RememberedAccount.fromMap(Map<String, dynamic> map) {
    return RememberedAccount(
      id: (map['id'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      nickname: (map['nickname'] ?? '').toString(),
      avatar: (map['avatar'] ?? '').toString(),
      updatedAt: map['updatedAt'] is int
          ? map['updatedAt'] as int
          : int.tryParse((map['updatedAt'] ?? '0').toString()) ?? 0,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'id': id,
        'email': email,
        'nickname': nickname,
        'avatar': avatar,
        'updatedAt': updatedAt,
      };
}

class Controller extends GetxController {
  static const String _cloudreveHost = 'https://zofiles.com';
  static const List<String> _cloudreveNamespaces = [
    'common',
    'application',
    'dashboard',
  ];

  static const List<CloudreveLanguage> cloudreveLanguages = [
    CloudreveLanguage(code: 'vi-VN', displayName: 'Vietnamese'),
    CloudreveLanguage(code: 'en-US', displayName: 'English'),
    CloudreveLanguage(code: 'zh-CN', displayName: '简体中文'),
    CloudreveLanguage(code: 'zh-TW', displayName: '繁體中文'),
    CloudreveLanguage(code: 'ja-JP', displayName: '日本語'),
    CloudreveLanguage(code: 'ru-RU', displayName: 'Русский'),
    CloudreveLanguage(code: 'de-DE', displayName: 'Deutsch'),
    CloudreveLanguage(code: 'fr-FR', displayName: 'Français'),
    CloudreveLanguage(code: 'es-ES', displayName: 'Español'),
    CloudreveLanguage(code: 'pt-BR', displayName: 'Português'),
    CloudreveLanguage(code: 'it-IT', displayName: 'Italiano'),
    CloudreveLanguage(code: 'ko-KR', displayName: '한국어'),
    CloudreveLanguage(code: 'pl-PL', displayName: 'Polski'),
  ];

  var lightTheme = ThemeData.light().copyWith(
    brightness: Brightness.light,
    primaryColor: Colors.blue,
    focusColor: Colors.blue,
    dividerColor: const Color.fromRGBO(227, 227, 227, 1),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.blue,
      iconTheme: IconThemeData(color: Colors.white),
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 22),
    ),
    dialogTheme: const DialogThemeData(backgroundColor: Colors.blue),
  );

  var darkTheme = ThemeData.dark().copyWith(
    brightness: Brightness.dark,
    focusColor: Colors.white,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.black,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 22),
    ),
    scaffoldBackgroundColor: const Color.fromARGB(255, 50, 50, 50),
  );

  var isDarkMode = false.obs;
  var appLocale = Rxn<Locale>();
  String preferredLocaleTag = '';
  String cloudreveLanguageTag = 'vi-VN';
  final RxMap<String, String> cloudreveI18n = <String, String>{}.obs;
  final RxString siteTitle = 'ZoFiles'.obs;
  final RxString logoUrl = '/static/img/logo.svg'.obs;
  final RxString logoLightUrl = '/static/img/logo_light.svg'.obs;
  final RxString loginStep = 'email'.obs;
  final RxString loginCheckedEmail = ''.obs;
  final RxBool loginUseAnotherAccount = false.obs;
  final RxList<RememberedAccount> rememberedAccounts =
      <RememberedAccount>[].obs;

  User? user;
  String accessToken = "";
  String refreshToken = "";
  int tokenExpireAt = 0;

  late SharedPreferences storage;
  var isStoregeReady = false.obs;

  @override
  void onInit() {
    super.onInit();
    SharedPreferences.getInstance().then((data) {
      storage = data;
      isDarkMode.value =
          storage.getBool(Constants.appConfig['isDarkMode']!) ?? false;
      preferredLocaleTag =
          storage.getString(Constants.appConfig['preferredLocale']!) ?? '';
      var tUser = storage.getString(Constants.appConfig['userInfo']!);
      accessToken =
          storage.getString(Constants.appConfig['accessToken']!) ?? "";
      refreshToken =
          storage.getString(Constants.appConfig['refreshToken']!) ?? "";
      tokenExpireAt =
          storage.getInt(Constants.appConfig['tokenExpireAt']!) ?? 0;
      // A fresh app launch should always start login flow from email step.
      // Drafts are still kept during the current session in memory/storage.
      clearLoginDraft();
      _loadRememberedAccounts();

      if (tUser != null) {
        user = User.fromJson(tUser);
        rememberAccount(user!);
      }
      if (preferredLocaleTag.isNotEmpty) {
        cloudreveLanguageTag =
            _normalizeCloudreveLanguageTag(preferredLocaleTag);
        final preferredLocale = _localeFromCloudreve(cloudreveLanguageTag);
        if (preferredLocale != null) {
          appLocale.value = preferredLocale;
        }
        loadCloudreveI18n(cloudreveLanguageTag);
      } else {
        _applyUserLocale();
      }
      isStoregeReady.value = true;
    });
  }

  void changeTheme() {
    // Keep method for compatibility with existing button wiring.
    Get.changeThemeMode(ThemeMode.system);
  }

  void setUser(User? user) {
    this.user = user;
    if (user != null) {
      rememberAccount(user);
      storage.setString(Constants.appConfig['userInfo']!, user.toJson());
    } else {
      storage.remove(Constants.appConfig['userInfo']!);
    }
    _applyUserLocale();
  }

  void setTokens({
    required String accessToken,
    required String refreshToken,
    required int expireAt,
  }) {
    this.accessToken = accessToken;
    this.refreshToken = refreshToken;
    tokenExpireAt = expireAt;

    storage.setString(Constants.appConfig['accessToken']!, accessToken);
    storage.setString(Constants.appConfig['refreshToken']!, refreshToken);
    storage.setInt(Constants.appConfig['tokenExpireAt']!, expireAt);
  }

  void clearTokens() {
    accessToken = "";
    refreshToken = "";
    tokenExpireAt = 0;

    storage.remove(Constants.appConfig['accessToken']!);
    storage.remove(Constants.appConfig['refreshToken']!);
    storage.remove(Constants.appConfig['tokenExpireAt']!);
  }

  bool get hasToken => accessToken.isNotEmpty;

  String get authHeader => "Bearer $accessToken";

  void logout() {
    clearTokens();
    setUser(null);
    clearLoginDraft();
    Get.offAllNamed("/login");
  }

  void applyCloudreveLanguageTag(String? languageTag) {
    if (preferredLocaleTag.isNotEmpty) return;
    final normalized = _normalizeCloudreveLanguageTag(languageTag);
    cloudreveLanguageTag = normalized;
    final locale = _localeFromCloudreve(normalized);
    if (locale != null) {
      _applyLocale(locale);
    }
    loadCloudreveI18n(normalized);
  }

  void setPreferredLocale(Locale locale) {
    final language = cloudreveLanguages.firstWhereOrNull(
      (item) =>
          item.code.toLowerCase().startsWith(locale.languageCode.toLowerCase()),
    );
    final preferredCode = language?.code ?? locale.toLanguageTag();
    setPreferredLanguageTag(preferredCode);
  }

  void setPreferredLanguageTag(String languageTag) {
    preferredLocaleTag = _normalizeCloudreveLanguageTag(languageTag);
    cloudreveLanguageTag = preferredLocaleTag;
    final locale = _localeFromCloudreve(preferredLocaleTag);
    if (locale != null) {
      _applyLocale(locale);
    }
    storage.setString(
        Constants.appConfig['preferredLocale']!, preferredLocaleTag);
    loadCloudreveI18n(preferredLocaleTag);
  }

  String trCloudreve(
    String key, {
    required String fallback,
    Map<String, String> params = const {},
  }) {
    var result = cloudreveI18n[key] ?? fallback;
    params.forEach((name, value) {
      result = result.replaceAll('{{$name}}', value);
    });
    // Remove <0>...</0> markers from react-i18next rich text.
    return result.replaceAll(RegExp(r'</?0>'), '');
  }

  String trCloudreveAny(
    List<String> keys, {
    required String fallback,
    Map<String, String> params = const {},
  }) {
    for (final key in keys) {
      if (cloudreveI18n.containsKey(key)) {
        return trCloudreve(key, fallback: fallback, params: params);
      }
    }
    return trCloudreve(keys.isEmpty ? '' : keys.first,
        fallback: fallback, params: params);
  }

  void setBranding({
    String? title,
    String? logo,
    String? logoLight,
  }) {
    if ((title ?? '').trim().isNotEmpty) {
      siteTitle.value = title!.trim();
    }
    if ((logo ?? '').trim().isNotEmpty) {
      logoUrl.value = logo!.trim();
    }
    if ((logoLight ?? '').trim().isNotEmpty) {
      logoLightUrl.value = logoLight!.trim();
    }
  }

  void setLoginDraft({
    required String step,
    String? checkedEmail,
    bool? useAnotherAccount,
  }) {
    loginStep.value = step;
    storage.setString(Constants.appConfig['loginStepDraft']!, step);
    if (checkedEmail != null) {
      loginCheckedEmail.value = checkedEmail;
      storage.setString(Constants.appConfig['loginEmailDraft']!, checkedEmail);
    }
    if (useAnotherAccount != null) {
      loginUseAnotherAccount.value = useAnotherAccount;
      storage.setBool(
        Constants.appConfig['loginUseAnotherAccountDraft']!,
        useAnotherAccount,
      );
    }
  }

  void clearLoginDraft() {
    loginStep.value = 'email';
    loginCheckedEmail.value = '';
    loginUseAnotherAccount.value = false;
    storage.remove(Constants.appConfig['loginStepDraft']!);
    storage.remove(Constants.appConfig['loginEmailDraft']!);
    storage.remove(Constants.appConfig['loginUseAnotherAccountDraft']!);
  }

  void _loadRememberedAccounts() {
    final raw = storage.getString(Constants.appConfig['rememberedAccounts']!);
    if (raw == null || raw.trim().isEmpty) {
      rememberedAccounts.clear();
      return;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        final list = decoded
            .whereType<Map>()
            .map(
              (item) => RememberedAccount.fromMap(item.cast<String, dynamic>()),
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
        rememberedAccounts.assignAll(list);
      } else {
        rememberedAccounts.clear();
      }
    } catch (_) {
      rememberedAccounts.clear();
    }
  }

  void _saveRememberedAccounts() {
    final encoded =
        jsonEncode(rememberedAccounts.map((item) => item.toMap()).toList());
    storage.setString(Constants.appConfig['rememberedAccounts']!, encoded);
  }

  void rememberAccount(User user) {
    final email = user.user_name.trim();
    if (email.isEmpty) return;
    final account = RememberedAccount(
      id: user.id,
      email: email,
      nickname: user.nickname.trim().isEmpty ? email : user.nickname.trim(),
      avatar: user.avatar,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    );

    final list = rememberedAccounts.toList();
    list.removeWhere(
      (item) =>
          item.id == account.id ||
          item.email.toLowerCase() == account.email.toLowerCase(),
    );
    list.insert(0, account);
    if (list.length > 8) {
      list.removeRange(8, list.length);
    }
    rememberedAccounts.assignAll(list);
    _saveRememberedAccounts();
  }

  void removeRememberedAccount(RememberedAccount account) {
    rememberedAccounts.removeWhere(
      (item) =>
          item.id == account.id ||
          item.email.toLowerCase() == account.email.toLowerCase(),
    );
    _saveRememberedAccounts();
  }

  void _applyUserLocale() {
    applyCloudreveLanguageTag(user?.language);
  }

  Locale? _localeFromCloudreve(String? languageTag) {
    final raw = (languageTag ?? '').trim();
    if (raw.isEmpty) return null;

    final normalized = raw.replaceAll('_', '-').toLowerCase();
    if (normalized.startsWith('zh')) {
      return const Locale.fromSubtags(languageCode: 'zh');
    }
    if (normalized.startsWith('vi')) {
      return const Locale.fromSubtags(languageCode: 'vi');
    }
    if (normalized.startsWith('en')) {
      return const Locale.fromSubtags(languageCode: 'en');
    }
    return const Locale.fromSubtags(languageCode: 'en');
  }

  void _applyLocale(Locale locale) {
    appLocale.value = locale;
    Get.updateLocale(locale);
  }

  String _normalizeCloudreveLanguageTag(String? languageTag) {
    final raw = (languageTag ?? '').trim();
    if (raw.isEmpty) return 'vi-VN';

    final direct = cloudreveLanguages.firstWhereOrNull(
      (item) => item.code.toLowerCase() == raw.toLowerCase(),
    );
    if (direct != null) return direct.code;

    final lang = raw.split(RegExp(r'[-_]')).first.toLowerCase();
    final match = cloudreveLanguages.firstWhereOrNull(
      (item) => item.code.toLowerCase().startsWith('$lang-'),
    );
    return match?.code ?? 'vi-VN';
  }

  Future<void> loadCloudreveI18n([String? languageTag]) async {
    final normalized =
        _normalizeCloudreveLanguageTag(languageTag ?? cloudreveLanguageTag);
    cloudreveLanguageTag = normalized;
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 10),
      responseType: ResponseType.json,
      headers: {'Accept': 'application/json'},
    ));

    final merged = <String, String>{};
    for (final ns in _cloudreveNamespaces) {
      final url = '$_cloudreveHost/locales/$normalized/$ns.json';
      try {
        final response = await dio.get(url);
        final data = response.data;
        if (data is Map<String, dynamic>) {
          _flattenI18nMap(data, '', merged);
        }
      } catch (_) {
        continue;
      }
    }

    if (merged.isNotEmpty) {
      cloudreveI18n.assignAll(merged);
      cloudreveI18n.refresh();
    }
  }

  void _flattenI18nMap(
    Map<String, dynamic> source,
    String prefix,
    Map<String, String> target,
  ) {
    source.forEach((key, value) {
      final path = prefix.isEmpty ? key : '$prefix.$key';
      if (value is Map<String, dynamic>) {
        _flattenI18nMap(value, path, target);
      } else if (value is String) {
        target[path] = value;
      }
    });
  }
}
