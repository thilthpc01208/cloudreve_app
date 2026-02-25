// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get mainPageTitle => 'TimeRunis Cloud';

  @override
  String get loginPageTitle => 'Login';

  @override
  String get myFiles => 'My Files';

  @override
  String get fileTypeVideo => 'Video';

  @override
  String get fileTypePicture => 'Picture';

  @override
  String get fileTypeMusic => 'Music';

  @override
  String get fileTypeDocument => 'Document';

  @override
  String get myShares => 'My Shares';

  @override
  String get offlineDownload => 'Offline Download';

  @override
  String get connections => 'Connections';

  @override
  String get processQueue => 'Process Queue';

  @override
  String get settings => 'Settings';

  @override
  String get logout => 'Logout';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get invalid => 'Invalid input';

  @override
  String get invalidEmail => 'Invalid email address';

  @override
  String get tipTitle => 'Tips';

  @override
  String get submitting => 'Submitting...';

  @override
  String get loginSuccess => 'Login successful';

  @override
  String get logoutSuccess => 'Logout successful';

  @override
  String get confirmExit => 'Press back again to exit';

  @override
  String get parsingLink => 'Parsing link...';

  @override
  String get videoLoading => 'Loading video';

  @override
  String get language => 'Language';

  @override
  String get english => 'English';

  @override
  String get vietnamese => 'Vietnamese';

  @override
  String get chinese => 'Chinese';

  @override
  String get signInToYourAccount => 'Sign in to your account';

  @override
  String get next => 'Next';

  @override
  String get enterYourPassword => 'Enter your password';

  @override
  String passwordPrompt(Object email) {
    return 'Please enter password for $email';
  }

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get captcha => 'Captcha';

  @override
  String get reloadCaptcha => 'Reload captcha';

  @override
  String get captchaUnavailable => 'Captcha unavailable';

  @override
  String get captchaRequired => 'Captcha is required.';

  @override
  String get completeCaptchaVerification => 'Please complete captcha verification.';

  @override
  String get cloudflareTurnstile => 'Cloudflare Turnstile';

  @override
  String get turnstileSiteKeyMissing => 'Turnstile site key is missing.';

  @override
  String get captchaVerified => 'Captcha verified.';

  @override
  String get unableToVerifyAccount => 'Unable to verify account';

  @override
  String get passwordSignInNotSupported => 'This account does not support password sign-in.';

  @override
  String get loginFailed => 'Login failed';

  @override
  String get signIn => 'Sign in';

  @override
  String get back => 'Back';

  @override
  String get signUp => 'Sign up';

  @override
  String get noAccount => 'Don\'t have an account?';

  @override
  String get signUpNow => 'Sign up now';

  @override
  String get usePasskey => 'Use passkey';

  @override
  String get chooseAnAccount => 'Choose an account';

  @override
  String get useAnotherAccount => 'Use another account';

  @override
  String get removeAccount => 'Remove account';

  @override
  String get loggedOut => 'Logged out';

  @override
  String get termsOfUse => 'Terms of Use';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String signUpPrompt(Object email) {
    return 'The account $email does not exist.\nSign up now?';
  }
}
