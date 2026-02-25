import 'dart:convert';

import 'package:cloudreve_view/common/api.dart';
import 'package:cloudreve_view/common/util.dart';
import 'package:cloudreve_view/controller.dart';
import 'package:cloudreve_view/l10n/app_localizations.dart';
import 'package:cloudreve_view/widget/common/turnstile_windows_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_turnstile/flutter_turnstile.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

enum _LoginStep { email, password, signup }

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<StatefulWidget> createState() => _LoginPage();
}

class _LoginPage extends State<LoginPage> with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _captchaCodeController = TextEditingController();
  final TurnstileController _turnstileController = TurnstileController();

  final TurnstileOptions _turnstileOptions = TurnstileOptions(
    mode: TurnstileMode.managed,
    size: TurnstileSize.normal,
    theme: TurnstileTheme.light,
    retryAutomatically: true,
  );

  _LoginStep _step = _LoginStep.email;
  bool _checkingEmail = false;
  bool _submittingLogin = false;
  String _checkedEmail = '';

  LoginCaptchaConfig _captchaConfig = const LoginCaptchaConfig.none();
  Uint8List? _captchaBytes;
  String _captchaToken = '';
  String _captchaTicket = '';
  String _captchaError = '';
  int _turnstileReloadNonce = 0;
  bool _captchaLoading = false;
  bool _useAnotherAccount = false;
  String _hoveredRememberedAccountId = '';
  String _hoveredRememberedDeleteAccountId = '';
  bool _hoverUseAnotherAccount = false;
  bool _hoverLanguageButton = false;
  Worker? _storageReadyWorker;
  late final AnimationController _entranceController;
  int _motionEpoch = 0;
  bool _slideForward = true;
  final GlobalKey _languageButtonKey = GlobalKey();

  String _stepToStorage(_LoginStep step) {
    switch (step) {
      case _LoginStep.password:
        return 'password';
      case _LoginStep.signup:
        return 'signup';
      case _LoginStep.email:
        return 'email';
    }
  }

  void _persistLoginDraft() {
    final controller = Get.find<Controller>();
    controller.setLoginDraft(
      step: _stepToStorage(_step),
      checkedEmail: _checkedEmail,
      useAnotherAccount: _useAnotherAccount,
    );
  }

  _LoginStep _stepFromStorage(String step) {
    switch (step) {
      case 'password':
        return _LoginStep.password;
      case 'signup':
        return _LoginStep.signup;
      default:
        return _LoginStep.email;
    }
  }

  Future<void> _restoreLoginDraft() async {
    final controller = Get.find<Controller>();
    final restoredStep = _stepFromStorage(controller.loginStep.value);
    final restoredEmail = controller.loginCheckedEmail.value;
    final restoredUseAnother = controller.loginUseAnotherAccount.value;

    if (!mounted) return;
    setState(() {
      _step = restoredStep;
      _checkedEmail = restoredEmail;
      _captchaConfig = const LoginCaptchaConfig.none();
      _captchaBytes = null;
      _captchaToken = '';
      _captchaTicket = '';
      _captchaError = '';
      _captchaLoading = false;
      _useAnotherAccount =
          restoredUseAnother ||
          restoredStep != _LoginStep.email ||
          restoredEmail.trim().isNotEmpty;
      _emailController.text = restoredEmail;
      _passwordController.clear();
      _captchaCodeController.clear();
    });
    _playStepMotion();

    if (restoredStep == _LoginStep.password && restoredEmail.isNotEmpty) {
      await _loadCaptchaConfig();
    }
  }

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    Api().getSiteConfig();
    final controller = Get.find<Controller>();
    if (controller.isStoregeReady.value) {
      _restoreLoginDraft();
    } else {
      _storageReadyWorker = ever<bool>(controller.isStoregeReady, (ready) {
        if (ready) {
          _restoreLoginDraft();
          _storageReadyWorker?.dispose();
          _storageReadyWorker = null;
        }
      });
    }
    _playStepMotion();
  }

  String _tr(
    String key,
    String fallback, {
    Map<String, String> params = const {},
  }) {
    final controller = Get.find<Controller>();
    return controller.trCloudreve(
      key,
      fallback: fallback,
      params: params,
    );
  }

  String _trAny(
    List<String> keys,
    String fallback, {
    Map<String, String> params = const {},
  }) {
    final controller = Get.find<Controller>();
    return controller.trCloudreveAny(
      keys,
      fallback: fallback,
      params: params,
    );
  }

  @override
  void dispose() {
    _storageReadyWorker?.dispose();
    _entranceController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _captchaCodeController.dispose();
    _turnstileController.dispose();
    super.dispose();
  }

  void _playStepMotion() {
    _motionEpoch++;
    _entranceController.forward(from: 0);
  }

  void _goStep(_LoginStep nextStep) {
    _slideForward = nextStep.index >= _step.index;
    _step = nextStep;
    _playStepMotion();
  }

  Widget _staggered({
    required int index,
    required Widget child,
    double beginY = 8,
  }) {
    return child;
  }

  bool _isValidEmail(String value) => value.isEmail;
  bool get _isWindowsDesktopTurnstile =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.windows;
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _pageBackground =>
      _isDark ? const Color(0xFF0F1218) : const Color(0xFFF2F3F5);
  Color get _cardBackground =>
      _isDark ? const Color(0xFF14171D) : const Color(0xFFF9F9FA);
  Color get _cardBorder =>
      _isDark ? const Color(0xFF212733) : const Color(0xFFD9DEE7);
  Color get _titleColor => _isDark ? Colors.white : const Color(0xFF161A23);
  Color get _hintColor =>
      _isDark ? const Color(0xFFD2D7E0) : const Color(0xFF566074);
  Color get _inputBg =>
      _isDark ? const Color(0xFF171A20) : const Color(0xFFFFFFFF);
  Color get _inputBorder =>
      _isDark ? const Color(0xFF383F4D) : const Color(0xFFCCD2DE);
  Color get _inputLabel =>
      _isDark ? const Color(0xFFBFC4CF) : const Color(0xFF5F6776);
  Color get _inputIcon =>
      _isDark ? const Color(0xFFDDE3EC) : const Color(0xFF4E5666);
  Color get _buttonBg =>
      _isDark ? const Color(0xFF87C8FF) : const Color(0xFF76B8EF);
  Color get _buttonFg =>
      _isDark ? const Color(0xFF14253A) : const Color(0xFF11263F);
  static const double _captchaBaseWidth = 304;
  static const Duration _hoverTransitionDuration =
      Duration(milliseconds: 150);
  static const Curve _hoverTransitionCurve = Cubic(0.4, 0, 0.2, 1);
  static const double _iconRippleRadius = 20;

  Future<void> _loadCaptchaConfig() async {
    if (mounted) {
      setState(() {
        _captchaLoading = true;
      });
    }

    final config = await Api().getLoginCaptchaConfig();
    final resolvedConfig = config;

    if (!mounted) return;

    setState(() {
      _captchaConfig = resolvedConfig;
      _captchaBytes = _decodeDataImage(resolvedConfig.image);
      _captchaTicket = resolvedConfig.ticket;
      _captchaToken = '';
      _captchaError = '';
      _captchaCodeController.clear();
      _captchaLoading = false;
    });
  }

  Future<void> _reloadCaptcha() async {
    if (_captchaConfig.type == LoginCaptchaType.plain) {
      final plain = await Api().getPlainCaptcha();
      if (!mounted) return;
      setState(() {
        _captchaBytes = _decodeDataImage(plain.image);
        _captchaTicket = plain.ticket;
        _captchaError = '';
        _captchaCodeController.clear();
      });
      return;
    }

    if (_captchaConfig.type == LoginCaptchaType.turnstile) {
      setState(() {
        _captchaToken = '';
        _captchaError = '';
        _turnstileReloadNonce++;
      });
      if (_isWindowsDesktopTurnstile) {
        return;
      }
      try {
        await _turnstileController.refreshToken();
      } catch (_) {}
      return;
    }

    await _loadCaptchaConfig();
  }

  Uint8List? _decodeDataImage(String dataImage) {
    if (dataImage.isEmpty || !dataImage.contains(',')) return null;
    try {
      final base64Data = dataImage.split(',').last;
      return base64Decode(base64Data);
    } catch (_) {
      return null;
    }
  }

  Future<void> _nextFromEmail() async {
    final l10n = AppLocalizations.of(context)!;
    final email = _emailController.text.trim();
    if (!_isValidEmail(email)) {
      Util.showErrorSnackbar(
        context: context,
        message: l10n.invalidEmail,
      );
      return;
    }

    setState(() {
      _checkingEmail = true;
    });

    final result = await Api().prepareLogin(email);

    if (!mounted) return;
    setState(() {
      _checkingEmail = false;
    });

    if (!result.success) {
      final lowerMsg = result.message.toLowerCase();
      if (lowerMsg.contains('user not found')) {
        _checkedEmail = email;
        setState(() {
          _goStep(_LoginStep.signup);
        });
        _persistLoginDraft();
        return;
      }
      Util.showErrorSnackbar(
        context: context,
        message: result.message.isEmpty
            ? l10n.unableToVerifyAccount
            : result.message,
      );
      return;
    }

    _checkedEmail = email;

    if (result.passwordEnabled) {
      setState(() {
        _goStep(_LoginStep.password);
        _passwordController.clear();
      });
      _persistLoginDraft();
      await _loadCaptchaConfig();
      return;
    }

    if (!result.accountExists) {
      setState(() {
        _goStep(_LoginStep.signup);
      });
      _persistLoginDraft();
      return;
    }

    Util.showErrorSnackbar(
      context: context,
      message: l10n.passwordSignInNotSupported,
    );
  }

  Future<void> _goToSignUp() async {
    final uri = Uri.parse('${ApiConfig.host}/session');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _selectRememberedAccount(RememberedAccount account) async {
    _checkedEmail = account.email.trim();
    if (_checkedEmail.isEmpty) return;
    setState(() {
      _useAnotherAccount = false;
      _goStep(_LoginStep.password);
      _emailController.text = _checkedEmail;
      _passwordController.clear();
      _captchaToken = '';
      _captchaError = '';
    });
    _persistLoginDraft();
    await _loadCaptchaConfig();
  }

  void _removeRememberedAccount(RememberedAccount account) {
    final controller = Get.find<Controller>();
    controller.removeRememberedAccount(account);
    if (controller.rememberedAccounts.isEmpty && mounted) {
      setState(() {
        _useAnotherAccount = true;
      });
      _persistLoginDraft();
    }
  }

  Future<void> _doLogin() async {
    final l10n = AppLocalizations.of(context)!;
    final password = _passwordController.text;
    if (password.length < 6) {
      Util.showErrorSnackbar(
        context: context,
        message: l10n.invalid,
      );
      return;
    }

    String captchaValue = '';
    String ticketValue = '';

    if (_captchaConfig.requiresCode) {
      captchaValue = _captchaCodeController.text.trim();
      ticketValue = _captchaTicket;
      if (captchaValue.isEmpty || ticketValue.isEmpty) {
        Util.showErrorSnackbar(context: context, message: l10n.captchaRequired);
        return;
      }
    }

    if (_captchaConfig.requiresToken) {
      final token = _captchaToken.trim();
      if (token.isEmpty) {
        Util.showErrorSnackbar(
          context: context,
          message: l10n.completeCaptchaVerification,
        );
        return;
      }
      captchaValue = '';
      ticketValue = token;
    }

    setState(() {
      _submittingLogin = true;
    });

    final response = await Api().login(
      email: _checkedEmail,
      password: password,
      captcha: captchaValue,
      ticket: ticketValue,
    );

    if (!mounted) return;
    setState(() {
      _submittingLogin = false;
    });

    if (response.data['code'] == 0) {
      Util.showSnackbar(
        context: context,
        message: l10n.loginSuccess,
      );
      Get.offAllNamed('/');
      return;
    }

    Util.showErrorSnackbar(
      context: context,
      message: response.data['msg']?.toString() ?? l10n.loginFailed,
    );

    final int? code =
        response.data['code'] is int ? response.data['code'] : null;
    if (code == 40026 || code == 40027 || code == 40028) {
      await _reloadCaptcha();
    }
  }

  InputDecoration _authInputDecoration({
    required String label,
    required IconData icon,
  }) {
    const focusedColor = Color(0xFF7DBAF0);
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: _inputLabel),
      prefixIcon: Icon(icon, color: _inputIcon),
      filled: true,
      fillColor: _inputBg,
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: focusedColor, width: 1),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: _inputBorder, width: 0.85),
      ),
      border: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
    );
  }

  Widget _responsiveCaptcha(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth.clamp(0.0, _captchaBaseWidth).toDouble()
            : _captchaBaseWidth;
        return SizedBox(
          width: double.infinity,
          child: Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: width,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: _captchaBaseWidth,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLanguageButton(Controller controller) {
    final currentTag = controller.cloudreveLanguageTag;
    final tooltip =
        _tr('login.switchLanguage', AppLocalizations.of(context)!.language);
    return _webLikeTooltip(
      message: tooltip,
      verticalOffset: 27,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          if (_hoverLanguageButton) return;
          setState(() {
            _hoverLanguageButton = true;
          });
        },
        onExit: (_) {
          if (!_hoverLanguageButton) return;
          setState(() {
            _hoverLanguageButton = false;
          });
        },
        child: AnimatedContainer(
          duration: _hoverTransitionDuration,
          curve: _hoverTransitionCurve,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _hoverLanguageButton
                ? (_isDark ? const Color(0xFF3A3B40) : const Color(0x1A000000))
                : Colors.transparent,
          ),
          child: Material(
            type: MaterialType.transparency,
            shape: const CircleBorder(),
              child: IconButton(
              key: _languageButtonKey,
              tooltip: null,
              splashColor:
                  (_isDark ? Colors.white : Colors.black).withValues(alpha: 0.07),
              highlightColor: Colors.transparent,
              style: IconButton.styleFrom(
                hoverColor: Colors.transparent,
                splashFactory: InkSplash.splashFactory,
              ),
              splashRadius: _iconRippleRadius,
              mouseCursor: SystemMouseCursors.click,
              icon: Icon(Icons.translate, color: _titleColor),
              onPressed: () async {
                final buttonContext = _languageButtonKey.currentContext;
                if (buttonContext == null) return;

                final buttonBox = buttonContext.findRenderObject() as RenderBox?;
                final overlayBox =
                    Overlay.of(context).context.findRenderObject() as RenderBox?;
                if (buttonBox == null || overlayBox == null) return;

                final buttonRect = Rect.fromPoints(
                  buttonBox.localToGlobal(Offset.zero, ancestor: overlayBox),
                  buttonBox.localToGlobal(
                    buttonBox.size.bottomRight(Offset.zero),
                    ancestor: overlayBox,
                  ),
                );

                final screenSize = overlayBox.size;

                var menuWidth = screenSize.width - 24.0;
                if (menuWidth > 188.0) menuWidth = 188.0;
                if (menuWidth < 160.0) menuWidth = 160.0;
                final menuHeight =
                    (Controller.cloudreveLanguages.length * 36.0) + 12.0;

                final maxLeft = (screenSize.width - menuWidth - 12.0)
                    .clamp(12.0, double.infinity);
                var left = buttonRect.right - menuWidth + 8.0;
                left = left.clamp(12.0, maxLeft);

                final spaceBelow = (screenSize.height - buttonRect.bottom - 12.0);
                final spaceAbove = (buttonRect.top - 12.0);
                final openBelow = spaceBelow >= 180.0 ||
                    (spaceBelow >= spaceAbove && spaceBelow > 0);
                final maxMenuHeight = (openBelow ? spaceBelow : spaceAbove)
                    .clamp(140.0, screenSize.height - 24.0);
                final actualMenuHeight =
                    (menuHeight <= maxMenuHeight ? menuHeight : maxMenuHeight);

                final maxTop = (screenSize.height - actualMenuHeight - 12.0)
                    .clamp(12.0, double.infinity);
                var top = openBelow
                    ? buttonRect.bottom + 6.0
                    : buttonRect.top - actualMenuHeight - 6.0;
                top = top.clamp(12.0, maxTop);

                final selected = await showMenu<String>(
                  context: context,
                  color: _inputBg,
                  elevation: 6,
                  shadowColor: const Color(0x33000000),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  position: RelativeRect.fromLTRB(
                    left,
                    top,
                    (screenSize.width - left - menuWidth)
                        .clamp(0.0, screenSize.width),
                    (screenSize.height - top - actualMenuHeight)
                        .clamp(0.0, screenSize.height),
                  ),
                  constraints: BoxConstraints(
                    minWidth: menuWidth,
                    maxWidth: menuWidth,
                    maxHeight: maxMenuHeight,
                  ),
                  items: Controller.cloudreveLanguages
                      .map(
                        (lang) => PopupMenuItem<String>(
                          value: lang.code,
                          height: 36,
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Row(
                            children: [
                              Icon(
                                currentTag.toLowerCase() == lang.code.toLowerCase()
                                    ? Icons.check
                                    : Icons.language,
                                size: 16,
                                color: currentTag.toLowerCase() ==
                                        lang.code.toLowerCase()
                                    ? const Color(0xFF87C8FF)
                                    : _titleColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                lang.displayName,
                                style: TextStyle(color: _titleColor),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                );

                if (selected != null) {
                  _persistLoginDraft();
                  controller.setPreferredLanguageTag(selected);
                  if (mounted) setState(() {});
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandLogo(Controller controller) {
    final logoPath = _isDark
        ? (controller.logoLightUrl.value.isNotEmpty
            ? controller.logoLightUrl.value
            : controller.logoUrl.value)
        : (controller.logoUrl.value.isNotEmpty
            ? controller.logoUrl.value
            : controller.logoLightUrl.value);
    final logoUrl = ApiConfig.resolveUrl(logoPath);
    return SvgPicture.network(
      logoUrl,
      height: 32,
      placeholderBuilder: (_) => Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color:
                  _isDark ? const Color(0xFF0D1015) : const Color(0xFFE9EEF5),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    _isDark ? const Color(0xFF2C384A) : const Color(0xFFBBC4D2),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(3),
              child: Image.asset('assets/images/pic.png'),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            controller.siteTitle.value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: _titleColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptchaSection() {
    final l10n = AppLocalizations.of(context)!;
    final panelColor = _inputBg;
    final borderColor = _inputBorder;

    if (_captchaLoading) {
      return Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (!_captchaConfig.enabled ||
        _captchaConfig.type == LoginCaptchaType.none) {
      return const SizedBox.shrink();
    }

    if (_captchaConfig.type == LoginCaptchaType.plain) {
      return Container(
        margin: const EdgeInsets.only(top: 14),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: panelColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    _tr('login.captcha', l10n.captcha),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  onPressed: _reloadCaptcha,
                  icon: const Icon(Icons.refresh),
                  tooltip: _tr('login.clickToRefresh', l10n.reloadCaptcha),
                )
              ],
            ),
            const SizedBox(height: 8),
            Container(
              height: 64,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: borderColor),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _captchaBytes == null
                  ? Center(
                      child: Text(
                          _tr('login.captchaError', l10n.captchaUnavailable)))
                  : Image.memory(_captchaBytes!, fit: BoxFit.contain),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _captchaCodeController,
              decoration: _authInputDecoration(
                label: l10n.captcha,
                icon: Icons.shield_outlined,
              ),
            )
          ],
        ),
      );
    }

    if (_captchaConfig.type == LoginCaptchaType.turnstile) {
      final unsupported = _captchaConfig.siteKey.isEmpty;
      return Container(
        margin: const EdgeInsets.only(top: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (unsupported)
              Text(
                _tr('login.captchaError', l10n.turnstileSiteKeyMissing),
                style: const TextStyle(color: Colors.redAccent),
              )
            else if (_isWindowsDesktopTurnstile)
              _responsiveCaptcha(
                TurnstileWindowsWidget(
                  key: ValueKey(
                    'turnstile-win-${_captchaConfig.siteKey}-${_turnstileReloadNonce}',
                  ),
                  siteKey: _captchaConfig.siteKey,
                  originHost: Uri.parse(ApiConfig.host).host,
                  reloadNonce: _turnstileReloadNonce,
                  onTokenReceived: (token) {
                    if (mounted) {
                      setState(() {
                        _captchaToken = token;
                        _captchaError = '';
                      });
                    }
                  },
                  onError: (message) {
                    if (!mounted) return;
                    setState(() {
                      _captchaError = message.trim().isEmpty
                          ? _tr('login.captchaError', 'Unable to load captcha')
                          : message;
                    });
                  },
                ),
              )
            else
              _responsiveCaptcha(
                CloudFlareTurnstile(
                  key: ValueKey(
                      'turnstile-${_captchaConfig.siteKey}-${_turnstileReloadNonce}'),
                  siteKey: _captchaConfig.siteKey,
                  baseUrl: ApiConfig.host,
                  options: _turnstileOptions,
                  controller: _turnstileController,
                  onTokenReceived: (token) {
                    if (mounted) {
                      setState(() {
                        _captchaToken = token;
                        _captchaError = '';
                      });
                    }
                  },
                  onTokenExpired: () {
                    if (mounted) {
                      setState(() {
                        _captchaToken = '';
                        _captchaError = '';
                      });
                    }
                  },
                  onError: (error) {
                    if (!mounted) return;
                    setState(() {
                      _captchaError = error.trim().isEmpty
                          ? _tr('login.captchaError', 'Unable to load captcha')
                          : error;
                    });
                  },
                ),
              ),
            if (_captchaError.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                '${_tr('login.captchaError', 'Unable to load CAPTCHA')}: $_captchaError',
                style: const TextStyle(color: Colors.redAccent),
              ),
            ],
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildEmailStep(AppLocalizations l10n) {
    return Column(
      key: ValueKey('email-step-$_motionEpoch'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _staggered(
          index: 0,
          child: Text(
            _tr('login.siginToYourAccount', l10n.signInToYourAccount),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _titleColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(height: 16),
        _staggered(
          index: 1,
          child: TextField(
            controller: _emailController,
            style: TextStyle(color: _titleColor),
            keyboardType: TextInputType.emailAddress,
            decoration: _authInputDecoration(
              label: l10n.email,
              icon: Icons.mail_outline,
            ),
          ),
        ),
        const SizedBox(height: 16),
        _staggered(
          index: 2,
          child: SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                backgroundColor: _buttonBg,
                foregroundColor: _buttonFg,
              ),
              onPressed: _checkingEmail ? null : _nextFromEmail,
              child: _checkingEmail
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _tr('login.continue', l10n.next),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        _staggered(
          index: 3,
          child: Center(
            child: GestureDetector(
              onTap: _goToSignUp,
              child: Text(
                _trAny(
                  const ['login.noAccountSignupNow'],
                  '${l10n.noAccount} ${l10n.signUpNow}',
                ),
                style: TextStyle(color: _hintColor, fontSize: 13),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Divider(height: 1, thickness: 1, color: _cardBorder),
        const SizedBox(height: 12),
        _staggered(
          index: 4,
          child: SizedBox(
            width: double.infinity,
            child: TextButton.icon(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: const Color(0xFF5C96C6)),
                ),
                backgroundColor: Colors.transparent,
                foregroundColor: const Color(0xFF87C8FF),
              ),
              onPressed: () {},
              icon: const Icon(Icons.fingerprint, size: 18),
              label: Text(
                _trAny(const ['login.useFIDO2'], l10n.usePasskey),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        _staggered(
          index: 5,
          child: Center(
            child: Text(
              '${_trAny(const ['login.termOfUse'], l10n.termsOfUse)} | '
              '${_trAny(const ['login.privacyPolicy'], l10n.privacyPolicy)}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _hintColor.withValues(alpha: 0.88),
                fontSize: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRememberedAccountsStep(AppLocalizations l10n) {
    final controller = Get.find<Controller>();
    final remembered = controller.rememberedAccounts;
    return Column(
      key: ValueKey('remembered-accounts-$_motionEpoch'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _staggered(
          index: 0,
          child: Text(
            _trAny(
              const ['login.selectAccountToUse', 'login.chooseAccount'],
              l10n.chooseAnAccount,
            ),
            style: TextStyle(
              color: _titleColor,
              fontWeight: FontWeight.w700,
              fontSize: 20,
              height: 1.25,
              letterSpacing: 0,
            ),
          ),
        ),
        const SizedBox(height: 14),
        ...remembered.asMap().entries.map((entry) {
          final account = entry.value;
          final isDeleteHovered =
              _hoveredRememberedDeleteAccountId == account.id;
          final isHovered =
              _hoveredRememberedAccountId == account.id && !isDeleteHovered;
          final avatarUrl = _rememberedAvatarUrl(account);
          final fallbackAvatarUrl = ApiConfig.resolveUrl(account.avatar);
          return _staggered(
            index: 1 + entry.key,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) {
                  if (_hoveredRememberedAccountId == account.id) return;
                  setState(() {
                    _hoveredRememberedAccountId = account.id;
                  });
                },
                onExit: (_) {
                  if (_hoveredRememberedAccountId != account.id) return;
                  setState(() {
                    _hoveredRememberedAccountId = '';
                    if (_hoveredRememberedDeleteAccountId == account.id) {
                      _hoveredRememberedDeleteAccountId = '';
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: _hoverTransitionDuration,
                  curve: _hoverTransitionCurve,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8.5, vertical: 8),
                  decoration: BoxDecoration(
                    color: isHovered
                        ? (_isDark
                            ? const Color(0xFF2E2F33)
                            : const Color(0x1F000000))
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Material(
                    type: MaterialType.transparency,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      mouseCursor: SystemMouseCursors.click,
                      onTap: () => _selectRememberedAccount(account),
                      splashFactory: InkSplash.splashFactory,
                      splashColor: (_isDark ? Colors.white : Colors.black)
                          .withValues(alpha: 0.045),
                      highlightColor: Colors.transparent,
                      hoverColor: Colors.transparent,
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16.5,
                            backgroundColor: const Color(0xFF2A3443),
                            child: ClipOval(
                              child: Image.network(
                                avatarUrl,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Image.network(
                                  fallbackAvatarUrl,
                                  width: 32,
                                  height: 32,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Text(
                                    account.nickname.isEmpty
                                        ? '?'
                                        : account.nickname[0].toUpperCase(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        account.nickname,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: _titleColor,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16.2,
                                          height: 1.22,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.5,
                                        vertical: 2.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _isDark
                                            ? const Color(0xFF5A5A5A)
                                            : const Color(0xFFE7E7E7),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        _logoutBadgeLabel(
                                          _trAny(
                                            const [
                                              'login.loggedOutBadge',
                                              'login.loggedOut',
                                              'login.logout',
                                            ],
                                            l10n.loggedOut,
                                          ),
                                        ),
                                        style: TextStyle(
                                          color: _isDark
                                              ? const Color(0xFFF2F2F2)
                                              : const Color(0xFF4E4E4E),
                                          fontWeight: FontWeight.w700,
                                          fontSize: 10.2,
                                          height: 1.12,
                                          letterSpacing: 0,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  account.email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: _hintColor.withValues(
                                      alpha: _isDark ? 0.92 : 0.9,
                                    ),
                                    fontSize: 13.9,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 4),
                          _webLikeTooltip(
                            message: _trAny(
                              const [
                                'login.logout',
                                'setting.delete',
                                'fileManager.delete',
                                'delete',
                                'login.removeAccount',
                                'login.deleteAccount',
                              ],
                              l10n.removeAccount,
                            ),
                            verticalOffset: 25,
                            child: AnimatedContainer(
                              duration: _hoverTransitionDuration,
                              curve: _hoverTransitionCurve,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isDeleteHovered
                                    ? (_isDark
                                        ? const Color(0xFF3A3B40)
                                        : const Color(0x1A000000))
                                    : Colors.transparent,
                              ),
                              child: Material(
                                type: MaterialType.transparency,
                                shape: const CircleBorder(),
                                child: IconButton(
                                  tooltip: null,
                                  mouseCursor: SystemMouseCursors.click,
                                  splashColor:
                                      (_isDark ? Colors.white : Colors.black)
                                          .withValues(alpha: 0.07),
                                  highlightColor: Colors.transparent,
                                  onHover: (hovering) {
                                    if (hovering) {
                                      if (_hoveredRememberedDeleteAccountId ==
                                          account.id) {
                                        return;
                                      }
                                      setState(() {
                                        _hoveredRememberedDeleteAccountId =
                                            account.id;
                                      });
                                      return;
                                    }
                                    if (_hoveredRememberedDeleteAccountId !=
                                        account.id) {
                                      return;
                                    }
                                    setState(() {
                                      _hoveredRememberedDeleteAccountId = '';
                                    });
                                  },
                                  onPressed: () =>
                                      _removeRememberedAccount(account),
                                  style: IconButton.styleFrom(
                                    foregroundColor: _hintColor,
                                    hoverColor: Colors.transparent,
                                    splashFactory: InkSplash.splashFactory,
                                  ),
                                  splashRadius: _iconRippleRadius,
                                  icon: const Icon(Icons.delete_outline, size: 22),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(height: 1),
        _staggered(
          index: 3 + remembered.length,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            onEnter: (_) {
              if (_hoverUseAnotherAccount) return;
              setState(() {
                _hoverUseAnotherAccount = true;
              });
            },
            onExit: (_) {
              if (!_hoverUseAnotherAccount) return;
              setState(() {
                _hoverUseAnotherAccount = false;
              });
            },
            child: AnimatedContainer(
                duration: _hoverTransitionDuration,
                curve: _hoverTransitionCurve,
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.5, vertical: 8),
                decoration: BoxDecoration(
                  color: _hoverUseAnotherAccount
                      ? (_isDark
                          ? const Color(0xFF2E2F33)
                          : const Color(0x1F000000))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Material(
                  type: MaterialType.transparency,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    mouseCursor: SystemMouseCursors.click,
                    splashFactory: InkSplash.splashFactory,
                    splashColor:
                        (_isDark ? Colors.white : Colors.black).withValues(
                      alpha: 0.045,
                    ),
                    highlightColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    onTap: () {
                      setState(() {
                        _useAnotherAccount = true;
                        _checkedEmail = '';
                        _emailController.clear();
                      });
                      _playStepMotion();
                      _persistLoginDraft();
                    },
                    child: Row(
                      children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: _isDark ? Colors.white : const Color(0xFF121212),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.add,
                        size: 23,
                        color:
                            _isDark ? const Color(0xFF121212) : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _trAny(
                          const [
                            'login.useOtherAccount',
                            'login.useAnotherAccount',
                          ],
                          l10n.useAnotherAccount,
                        ),
                        style: TextStyle(
                          color: _titleColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 16.8,
                          height: 1.2,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                      ],
                    ),
                  ),
                ),
            ),
          ),
        ),
      ],
    );
  }

  String _rememberedAvatarUrl(RememberedAccount account) {
    final byId = ApiConfig.userAvatarUrl(account.id);
    if (byId.isNotEmpty) return byId;
    return ApiConfig.resolveUrl(account.avatar);
  }

  String _logoutBadgeLabel(String source) {
    final text = source.trim();
    if (text.isEmpty) return _trAny(const ['login.logout'], 'Logged out');

    final normalized = text.toLowerCase();
    if (normalized.startsWith('you are signed out')) {
      return 'Signed out';
    }
    if (normalized.startsWith('bạn đã đăng xuất')) {
      return 'Đã đăng xuất';
    }

    final compact = text.replaceAll(RegExp(r'[.!?。！？]$'), '').trim();
    if (compact.length <= 18) return compact;

    final logoutLabel = _trAny(const ['login.logout'], compact).trim();
    if (logoutLabel.isNotEmpty) return logoutLabel;
    return compact;
  }

  Widget _webLikeTooltip({
    required String message,
    required Widget child,
    double verticalOffset = 10,
  }) {
    return Tooltip(
      message: message,
      waitDuration: const Duration(milliseconds: 380),
      showDuration: const Duration(milliseconds: 1200),
      preferBelow: true,
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        height: 1.43,
        letterSpacing: 0.01,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      margin: const EdgeInsets.symmetric(horizontal: 12),
      verticalOffset: verticalOffset,
      decoration: BoxDecoration(
        color: const Color(0xFF313131),
        borderRadius: BorderRadius.circular(4),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 5,
            spreadRadius: -1,
            offset: Offset(0, 3),
          ),
          BoxShadow(
            color: Color(0x24000000),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
          BoxShadow(
            color: Color(0x1F000000),
            blurRadius: 18,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildPasswordStep(AppLocalizations l10n) {
    return Column(
      key: ValueKey('password-step-$_motionEpoch'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _staggered(
          index: 0,
          child: Text(
            _tr('login.enterPassword', l10n.enterYourPassword),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _titleColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(height: 6),
        _staggered(
          index: 1,
          child: Text(
            _tr(
              'login.enterPasswordHint',
              l10n.passwordPrompt(_checkedEmail),
              params: {'email': _checkedEmail},
            ),
            style: TextStyle(color: _hintColor, fontSize: 14),
          ),
        ),
        const SizedBox(height: 12),
        _staggered(
          index: 2,
          child: TextField(
            controller: _passwordController,
            obscureText: true,
            style: TextStyle(color: _titleColor),
            decoration: _authInputDecoration(
              label: l10n.password,
              icon: Icons.lock_outline,
            ),
          ),
        ),
        const SizedBox(height: 10),
        _staggered(
          index: 3,
          child: TextButton(
            onPressed: () {},
            style:
                TextButton.styleFrom(foregroundColor: const Color(0xFF87C8FF)),
            child: Text(_tr('login.forgetPassword', l10n.forgotPassword)),
          ),
        ),
        _staggered(index: 4, beginY: 10, child: _buildCaptchaSection()),
        const SizedBox(height: 14),
        _staggered(
          index: 5,
          child: SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                backgroundColor: _buttonBg,
                foregroundColor: _buttonFg,
              ),
              onPressed: _submittingLogin ? null : _doLogin,
              child: _submittingLogin
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _tr('login.signIn', l10n.signIn),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        _staggered(
          index: 6,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _goStep(_LoginStep.email);
                _captchaConfig = const LoginCaptchaConfig.none();
                _useAnotherAccount = false;
              });
              _persistLoginDraft();
            },
            icon: const Icon(Icons.arrow_back_ios_new, size: 14),
            label: Text(_tr('login.back', l10n.back)),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF87C8FF),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSignUpStep(AppLocalizations l10n) {
    return Column(
      key: ValueKey('signup-step-$_motionEpoch'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _staggered(
          index: 0,
          child: Text(
            _tr('login.siginToYourAccount', l10n.signInToYourAccount),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: _titleColor,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(height: 10),
        _staggered(
          index: 1,
          child: Text(
            _tr(
              'login.accountNotFoundHint',
              l10n.signUpPrompt(_checkedEmail),
              params: {'email': _checkedEmail},
            ),
            style: TextStyle(color: _hintColor),
          ),
        ),
        const SizedBox(height: 12),
        _staggered(
          index: 2,
          child: SizedBox(
            width: double.infinity,
            child: TextButton(
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                backgroundColor: _buttonBg,
                foregroundColor: _buttonFg,
              ),
              onPressed: _goToSignUp,
              child: Text(
                _tr('login.signUp', l10n.signUp),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        _staggered(
          index: 3,
          child: TextButton.icon(
            onPressed: () {
              setState(() {
                _goStep(_LoginStep.email);
                _useAnotherAccount = false;
              });
              _persistLoginDraft();
            },
            icon: const Icon(Icons.arrow_back_ios_new, size: 14),
            label: Text(_tr('login.back', l10n.back)),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF87C8FF),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<Controller>();
    if (controller.user != null) {
      Future.microtask(() => Navigator.pushNamed(context, '/'));
      return Container();
    }

    return Obx(() {
      // Rebuild when runtime i18n payload changes.
      controller.cloudreveI18n.length;
      final l10n = AppLocalizations.of(context)!;

      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) SystemNavigator.pop();
        },
        child: Scaffold(
          backgroundColor: _pageBackground,
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 344),
                  child: TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.ease,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value,
                        child: Transform.translate(
                          offset: Offset(0, (1 - value) * 10),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: _cardBackground,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _cardBorder, width: 0.75),
                        boxShadow: [
                          BoxShadow(
                            color: _isDark
                                ? const Color(0x33000000)
                                : const Color(0x1A000000),
                            blurRadius: 16,
                            spreadRadius: 0,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _staggered(
                              index: 0,
                              beginY: 10,
                              child: Row(
                                children: [
                                  _buildBrandLogo(controller),
                                  const Spacer(),
                                  _buildLanguageButton(controller),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            _staggered(
                              index: 1,
                              beginY: 12,
                              child: ClipRect(
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 480),
                                  switchInCurve: Curves.fastOutSlowIn,
                                  switchOutCurve: Curves.fastOutSlowIn,
                                  layoutBuilder:
                                      (currentChild, previousChildren) {
                                    return Stack(
                                      clipBehavior: Clip.hardEdge,
                                      alignment: Alignment.topCenter,
                                      children: <Widget>[
                                        ...previousChildren,
                                        if (currentChild != null) currentChild,
                                      ],
                                    );
                                  },
                                  transitionBuilder: (child, animation) {
                                    final isOutgoing = animation.status ==
                                        AnimationStatus.reverse;
                                    final inFrom = _slideForward ? 1.0 : -1.0;
                                    final outTo = _slideForward ? -1.0 : 1.0;
                                    final tween = isOutgoing
                                        ? Tween<Offset>(
                                            begin: Offset.zero,
                                            end: Offset(outTo, 0),
                                          )
                                        : Tween<Offset>(
                                            begin: Offset(inFrom, 0),
                                            end: Offset.zero,
                                          );
                                    final slide = tween.animate(
                                      CurvedAnimation(
                                        parent: animation,
                                        curve: Curves.fastOutSlowIn,
                                      ),
                                    );
                                    return SlideTransition(
                                      position: slide,
                                      child: child,
                                    );
                                  },
                                  child: KeyedSubtree(
                                    key: ValueKey(
                                        'step-${_step.name}-${_motionEpoch}'),
                                    child: Container(
                                      width: double.infinity,
                                      color: _cardBackground,
                                      child: _step == _LoginStep.email
                                          ? (!_useAnotherAccount &&
                                                  controller.rememberedAccounts
                                                      .isNotEmpty
                                              ? _buildRememberedAccountsStep(
                                                  l10n)
                                              : _buildEmailStep(l10n))
                                          : (_step == _LoginStep.password
                                              ? _buildPasswordStep(l10n)
                                              : _buildSignUpStep(l10n)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    });
  }
}
