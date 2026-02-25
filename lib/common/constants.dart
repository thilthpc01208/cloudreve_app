abstract class Constants {
  static const String appConfigPrefix = "app_config";

  static const Map<String, String> appConfig = {
    "isDarkMode": "$appConfigPrefix.isDarkMode",
    "preferredLocale": "$appConfigPrefix.preferredLocale",
    "userInfo": "$appConfigPrefix.userInfo",
    "accessToken": "$appConfigPrefix.accessToken",
    "refreshToken": "$appConfigPrefix.refreshToken",
    "tokenExpireAt": "$appConfigPrefix.tokenExpireAt",
    "loginStepDraft": "$appConfigPrefix.loginStepDraft",
    "loginEmailDraft": "$appConfigPrefix.loginEmailDraft",
    "loginUseAnotherAccountDraft": "$appConfigPrefix.loginUseAnotherAccountDraft",
    "rememberedAccounts": "$appConfigPrefix.rememberedAccounts",
  };

  static const Map<String, String> fileType = {
    "dir": "dir",
    "file": "file",
  };

  static const Set<String> canPrePicSet = {
    "png",
    "jpg",
    "jpeg",
    "gif",
    "webp",
  };

  static const Set<String> canPreVideoSet = {
    "mp4",
    "avi",
    "mov",
    "mkv",
    "webm",
  };
}
