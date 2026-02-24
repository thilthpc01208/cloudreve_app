// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get mainPageTitle => 'TimeRunis云';

  @override
  String get loginPageTitle => 'Đăng nhập';

  @override
  String get myFiles => 'Tệp của tôi';

  @override
  String get fileTypeVideo => 'Video';

  @override
  String get fileTypePicture => 'Hình ảnh';

  @override
  String get fileTypeMusic => 'Âm nhạc';

  @override
  String get fileTypeDocument => 'Tài liệu';

  @override
  String get myShares => 'Chia sẻ của tôi';

  @override
  String get offlineDownload => 'Tải xuống ngoại tuyến';

  @override
  String get connections => 'Kết nối';

  @override
  String get processQueue => 'Hàng đợi tác vụ';

  @override
  String get settings => 'Cài đặt';

  @override
  String get logout => 'Đăng xuất';

  @override
  String get email => 'Email';

  @override
  String get password => 'Mật khẩu';

  @override
  String get invalid => 'Không hợp lệ';

  @override
  String get invalidEmail => 'Email không hợp lệ';

  @override
  String get tipTitle => 'Thông báo';

  @override
  String get submitting => 'Đang gửi...';

  @override
  String get loginSuccess => 'Đăng nhập thành công';

  @override
  String get logoutSuccess => 'Đăng xuất thành công';

  @override
  String get confirmExit => 'Nhấn quay lại lần nữa để thoát';

  @override
  String get parsingLink => 'Đang phân tích liên kết...';

  @override
  String get videoLoading => 'Đang tải video';

  @override
  String get language => 'Ngôn ngữ';

  @override
  String get english => 'Tiếng Anh';

  @override
  String get vietnamese => 'Tiếng Việt';

  @override
  String get chinese => 'Tiếng Trung';

  @override
  String get signInToYourAccount => 'Đăng nhập vào tài khoản';

  @override
  String get next => 'Tiếp theo';

  @override
  String get enterYourPassword => 'Nhập mật khẩu';

  @override
  String passwordPrompt(Object email) {
    return 'Vui lòng nhập mật khẩu cho $email';
  }

  @override
  String get forgotPassword => 'Quên mật khẩu?';

  @override
  String get captcha => 'Captcha';

  @override
  String get reloadCaptcha => 'Tải lại captcha';

  @override
  String get captchaUnavailable => 'Captcha không khả dụng';

  @override
  String get captchaRequired => 'Cần nhập captcha.';

  @override
  String get completeCaptchaVerification =>
      'Vui lòng hoàn tất xác minh captcha.';

  @override
  String get cloudflareTurnstile => 'Cloudflare Turnstile';

  @override
  String get turnstileSiteKeyMissing => 'Thiếu site key của Turnstile.';

  @override
  String get captchaVerified => 'Captcha đã xác minh.';

  @override
  String get unableToVerifyAccount => 'Không thể xác minh tài khoản';

  @override
  String get passwordSignInNotSupported =>
      'Tài khoản này không hỗ trợ đăng nhập bằng mật khẩu.';

  @override
  String get loginFailed => 'Đăng nhập thất bại';

  @override
  String get signIn => 'Đăng nhập';

  @override
  String get back => 'Quay lại';

  @override
  String get signUp => 'Đăng ký';

  @override
  String get noAccount => 'Chưa có tài khoản?';

  @override
  String get signUpNow => 'Đăng ký ngay';

  @override
  String get usePasskey => 'Dùng mã khóa';

  @override
  String get termsOfUse => 'Điều khoản sử dụng';

  @override
  String get privacyPolicy => 'Chính sách quyền riêng tư';

  @override
  String signUpPrompt(Object email) {
    return 'Tài khoản $email không tồn tại.\nĐăng ký ngay?';
  }
}
