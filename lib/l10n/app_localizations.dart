import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
    Locale('zh')
  ];

  /// No description provided for @mainPageTitle.
  ///
  /// In en, this message translates to:
  /// **'TimeRunis Cloud'**
  String get mainPageTitle;

  /// No description provided for @loginPageTitle.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get loginPageTitle;

  /// No description provided for @myFiles.
  ///
  /// In en, this message translates to:
  /// **'My Files'**
  String get myFiles;

  /// No description provided for @fileTypeVideo.
  ///
  /// In en, this message translates to:
  /// **'Video'**
  String get fileTypeVideo;

  /// No description provided for @fileTypePicture.
  ///
  /// In en, this message translates to:
  /// **'Picture'**
  String get fileTypePicture;

  /// No description provided for @fileTypeMusic.
  ///
  /// In en, this message translates to:
  /// **'Music'**
  String get fileTypeMusic;

  /// No description provided for @fileTypeDocument.
  ///
  /// In en, this message translates to:
  /// **'Document'**
  String get fileTypeDocument;

  /// No description provided for @myShares.
  ///
  /// In en, this message translates to:
  /// **'My Shares'**
  String get myShares;

  /// No description provided for @offlineDownload.
  ///
  /// In en, this message translates to:
  /// **'Offline Download'**
  String get offlineDownload;

  /// No description provided for @connections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get connections;

  /// No description provided for @processQueue.
  ///
  /// In en, this message translates to:
  /// **'Process Queue'**
  String get processQueue;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @invalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid input'**
  String get invalid;

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Invalid email address'**
  String get invalidEmail;

  /// No description provided for @tipTitle.
  ///
  /// In en, this message translates to:
  /// **'Tips'**
  String get tipTitle;

  /// No description provided for @submitting.
  ///
  /// In en, this message translates to:
  /// **'Submitting...'**
  String get submitting;

  /// No description provided for @loginSuccess.
  ///
  /// In en, this message translates to:
  /// **'Login successful'**
  String get loginSuccess;

  /// No description provided for @logoutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Logout successful'**
  String get logoutSuccess;

  /// No description provided for @confirmExit.
  ///
  /// In en, this message translates to:
  /// **'Press back again to exit'**
  String get confirmExit;

  /// No description provided for @parsingLink.
  ///
  /// In en, this message translates to:
  /// **'Parsing link...'**
  String get parsingLink;

  /// No description provided for @videoLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading video'**
  String get videoLoading;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @vietnamese.
  ///
  /// In en, this message translates to:
  /// **'Vietnamese'**
  String get vietnamese;

  /// No description provided for @chinese.
  ///
  /// In en, this message translates to:
  /// **'Chinese'**
  String get chinese;

  /// No description provided for @signInToYourAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your account'**
  String get signInToYourAccount;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @enterYourPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password'**
  String get enterYourPassword;

  /// No description provided for @passwordPrompt.
  ///
  /// In en, this message translates to:
  /// **'Please enter password for {email}'**
  String passwordPrompt(Object email);

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @captcha.
  ///
  /// In en, this message translates to:
  /// **'Captcha'**
  String get captcha;

  /// No description provided for @reloadCaptcha.
  ///
  /// In en, this message translates to:
  /// **'Reload captcha'**
  String get reloadCaptcha;

  /// No description provided for @captchaUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Captcha unavailable'**
  String get captchaUnavailable;

  /// No description provided for @captchaRequired.
  ///
  /// In en, this message translates to:
  /// **'Captcha is required.'**
  String get captchaRequired;

  /// No description provided for @completeCaptchaVerification.
  ///
  /// In en, this message translates to:
  /// **'Please complete captcha verification.'**
  String get completeCaptchaVerification;

  /// No description provided for @cloudflareTurnstile.
  ///
  /// In en, this message translates to:
  /// **'Cloudflare Turnstile'**
  String get cloudflareTurnstile;

  /// No description provided for @turnstileSiteKeyMissing.
  ///
  /// In en, this message translates to:
  /// **'Turnstile site key is missing.'**
  String get turnstileSiteKeyMissing;

  /// No description provided for @captchaVerified.
  ///
  /// In en, this message translates to:
  /// **'Captcha verified.'**
  String get captchaVerified;

  /// No description provided for @unableToVerifyAccount.
  ///
  /// In en, this message translates to:
  /// **'Unable to verify account'**
  String get unableToVerifyAccount;

  /// No description provided for @passwordSignInNotSupported.
  ///
  /// In en, this message translates to:
  /// **'This account does not support password sign-in.'**
  String get passwordSignInNotSupported;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed'**
  String get loginFailed;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get noAccount;

  /// No description provided for @signUpNow.
  ///
  /// In en, this message translates to:
  /// **'Sign up now'**
  String get signUpNow;

  /// No description provided for @usePasskey.
  ///
  /// In en, this message translates to:
  /// **'Use passkey'**
  String get usePasskey;

  /// No description provided for @termsOfUse.
  ///
  /// In en, this message translates to:
  /// **'Terms of Use'**
  String get termsOfUse;

  /// No description provided for @privacyPolicy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// No description provided for @signUpPrompt.
  ///
  /// In en, this message translates to:
  /// **'The account {email} does not exist.\nSign up now?'**
  String signUpPrompt(Object email);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
