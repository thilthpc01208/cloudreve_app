// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get mainPageTitle => 'TimeRunis云';

  @override
  String get loginPageTitle => '登录';

  @override
  String get myFiles => '我的文件';

  @override
  String get fileTypeVideo => '视频';

  @override
  String get fileTypePicture => '图片';

  @override
  String get fileTypeMusic => '音乐';

  @override
  String get fileTypeDocument => '文档';

  @override
  String get myShares => '我的分享';

  @override
  String get offlineDownload => '离线下载';

  @override
  String get connections => '连接';

  @override
  String get processQueue => '任务队列';

  @override
  String get settings => '设置';

  @override
  String get logout => '退出登录';

  @override
  String get email => '邮箱';

  @override
  String get password => '密码';

  @override
  String get invalid => '输入无效';

  @override
  String get invalidEmail => '邮箱格式无效';

  @override
  String get tipTitle => '提示';

  @override
  String get submitting => '提交中...';

  @override
  String get loginSuccess => '登录成功';

  @override
  String get logoutSuccess => '退出成功';

  @override
  String get confirmExit => '再按一次返回键退出';

  @override
  String get parsingLink => '正在解析链接...';

  @override
  String get videoLoading => '正在加载视频';

  @override
  String get language => '语言';

  @override
  String get english => '英语';

  @override
  String get vietnamese => '越南语';

  @override
  String get chinese => '中文';

  @override
  String get signInToYourAccount => '登录到你的账户';

  @override
  String get next => '下一步';

  @override
  String get enterYourPassword => '输入密码';

  @override
  String passwordPrompt(Object email) {
    return '请输入 $email 的密码';
  }

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get captcha => '验证码';

  @override
  String get reloadCaptcha => '刷新验证码';

  @override
  String get captchaUnavailable => '验证码不可用';

  @override
  String get captchaRequired => '需要验证码。';

  @override
  String get completeCaptchaVerification => '请完成验证码验证。';

  @override
  String get cloudflareTurnstile => 'Cloudflare Turnstile';

  @override
  String get turnstileSiteKeyMissing => '缺少 Turnstile site key。';

  @override
  String get captchaVerified => '验证码已通过。';

  @override
  String get unableToVerifyAccount => '无法验证账户';

  @override
  String get passwordSignInNotSupported => '该账户不支持密码登录。';

  @override
  String get loginFailed => '登录失败';

  @override
  String get signIn => '登录';

  @override
  String get back => '返回';

  @override
  String get signUp => '注册';

  @override
  String get noAccount => '还没有账号？';

  @override
  String get signUpNow => '立即注册';

  @override
  String get usePasskey => '使用通行密钥';

  @override
  String get termsOfUse => '使用条款';

  @override
  String get privacyPolicy => '隐私政策';

  @override
  String signUpPrompt(Object email) {
    return '账户 $email 不存在。\n立即注册？';
  }
}
