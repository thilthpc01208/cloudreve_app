import 'dart:convert';
import 'dart:io';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_windows/webview_windows.dart';

class TurnstileWindowsWidget extends StatefulWidget {
  final String siteKey;
  final String originHost;
  final ValueChanged<String> onTokenReceived;
  final ValueChanged<String>? onError;
  final int reloadNonce;

  const TurnstileWindowsWidget({
    super.key,
    required this.siteKey,
    required this.originHost,
    required this.onTokenReceived,
    this.onError,
    this.reloadNonce = 0,
  });

  @override
  State<TurnstileWindowsWidget> createState() => _TurnstileWindowsWidgetState();
}

class _TurnstileWindowsWidgetState extends State<TurnstileWindowsWidget> {
  static const double _turnstileWidth = 304;
  static const double _turnstileHeight = 68;
  static const double _turnstileBoxWidth = 300;
  static const double _turnstileBoxHeight = 65;
  static Future<void>? _environmentInitFuture;
  final WebviewController _controller = WebviewController();
  Directory? _virtualHostDir;
  String? _virtualHostName;
  bool _messageSubscribed = false;
  bool _loadErrorSubscribed = false;
  bool _initialized = false;
  bool _initializeCalled = false;
  String _initError = '';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void didUpdateWidget(covariant TurnstileWindowsWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final siteKeyChanged = oldWidget.siteKey != widget.siteKey;
    final reloadRequested = oldWidget.reloadNonce != widget.reloadNonce;
    if (_initialized && (siteKeyChanged || reloadRequested)) {
      _loadHtml();
    }
  }

  Future<void> _init() async {
    try {
      await _ensureEnvironmentInitialized();
      await _initializeControllerWithFallback();
      _initializeCalled = true;
      await _controller.setBackgroundColor(const Color(0x00000000));
      if (!_messageSubscribed) {
        _controller.webMessage.listen(_handleMessage);
        _messageSubscribed = true;
      }
      if (!_loadErrorSubscribed) {
        _controller.onLoadError.listen((status) {
          widget.onError?.call('webview_navigation_error:$status');
        });
        _loadErrorSubscribed = true;
      }
      _initialized = true;
      await _loadHtml();
      if (mounted) {
        setState(() {});
      }
    } on PlatformException catch (e) {
      _initError = e.message ?? e.code;
      widget.onError?.call('webview_init_error:${e.code}');
      if (mounted) {
        setState(() {});
      }
    } on MissingPluginException {
      _initError =
          'Turnstile Windows plugin is not loaded. Stop app and run again (no hot reload).';
      widget.onError?.call('missing_plugin');
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      _initError = e.toString();
      widget.onError?.call('init_exception:$e');
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _initializeControllerWithFallback() async {
    try {
      await _controller.initialize();
      return;
    } on PlatformException catch (e) {
      if (!_isEnvironmentCreationFailure(e)) {
        rethrow;
      }
    }

    _environmentInitFuture = null;
    await _ensureEnvironmentInitialized();
    await _controller.initialize();
  }

  bool _isEnvironmentCreationFailure(PlatformException e) {
    final code = e.code.toLowerCase();
    final message = (e.message ?? '').toLowerCase();
    return code.contains('environment_creation_failed') ||
        (message.contains('environment') && message.contains('failed'));
  }

  Future<void> _ensureEnvironmentInitialized() async {
    if (_environmentInitFuture != null) {
      return _environmentInitFuture!;
    }

    _environmentInitFuture = () async {
      final localAppData = Platform.environment['LOCALAPPDATA'];
      final userDataBase = (localAppData != null && localAppData.isNotEmpty)
          ? localAppData
          : Directory.systemTemp.path;
      final userDataDir =
          Directory('$userDataBase\\speed_app\\webview2_user_data');
      if (!userDataDir.existsSync()) {
        await userDataDir.create(recursive: true);
      }

      final fixedRuntimePath = _resolveFixedRuntimePath();

      try {
        await WebviewController.initializeEnvironment(
          userDataPath: userDataDir.path,
        );
        return;
      } on PlatformException catch (e) {
        final msg = (e.message ?? '').toLowerCase();
        // Environment can only be initialized once.
        if (e.code.toLowerCase().contains('already') ||
            msg.contains('already') ||
            msg.contains('initialized')) {
          return;
        }
        if (_isEnvironmentCreationFailure(e)) {
          if (fixedRuntimePath != null) {
            await WebviewController.initializeEnvironment(
              userDataPath: userDataDir.path,
              browserExePath: fixedRuntimePath,
            );
            return;
          }

          final version = await WebviewController.getWebViewVersion();
          if (version == null || version.trim().isEmpty) {
            throw PlatformException(
              code: 'webview2_runtime_missing',
              message:
                  'WebView2 Runtime not found. Install with: winget install --id Microsoft.EdgeWebView2Runtime --silent',
            );
          }

          // Some machines fail creating custom environment, but default
          // environment still works. Continue and let initialize() try.
          return;
        }
        rethrow;
      }
    }();

    try {
      await _environmentInitFuture!;
    } catch (_) {
      _environmentInitFuture = null;
      rethrow;
    }
  }

  String? _resolveFixedRuntimePath() {
    final exeDir = File(Platform.resolvedExecutable).parent.path;
    final candidates = <String>[
      '$exeDir\\WebView2Runtime',
      '$exeDir\\FixedVersionRuntime',
      '$exeDir\\webview2\\FixedVersionRuntime',
      '${Directory.current.path}\\WebView2Runtime',
      '${Directory.current.path}\\FixedVersionRuntime',
    ];

    for (final candidate in candidates) {
      final exe = File('$candidate\\msedgewebview2.exe');
      if (exe.existsSync()) return candidate;
    }
    return null;
  }

  Future<void> _loadHtml() async {
    try {
      if (widget.siteKey.trim().isEmpty) {
        _initError = 'Missing Turnstile site key.';
        widget.onError?.call('missing_site_key');
        if (mounted) setState(() {});
        return;
      }
      _initError = '';
      final escapedSiteKey = widget.siteKey.replaceAll("'", "\\'");
      final host = widget.originHost.trim().isEmpty
          ? 'zofiles.com'
          : widget.originHost.trim().toLowerCase();
      final html = '''
<!DOCTYPE html>
<html>
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <base href="https://$host/" />
    <script src="https://challenges.cloudflare.com/turnstile/v0/api.js" async defer></script>
    <style>
      html, body {
        width: ${_turnstileWidth}px;
        height: ${_turnstileHeight}px;
        margin: 0;
        padding: 0;
        background: transparent;
        overflow: hidden;
      }
      body {
        color: #d8dee9;
        font-family: Segoe UI, Arial, sans-serif;
        display: flex;
        align-items: center;
        justify-content: center;
      }
      #turnstile-box {
        width: ${_turnstileBoxWidth}px;
        height: ${_turnstileBoxHeight}px;
        overflow: hidden;
      }
    </style>
  </head>
  <body>
    <div id="turnstile-box"></div>
    <script>
      var rendered = false;
      function notify(obj) {
        if (window.chrome && window.chrome.webview) {
          window.chrome.webview.postMessage(JSON.stringify(obj));
        }
      }

      window.addEventListener('error', function (e) {
        notify({type: 'error', value: 'window_error:' + (e.message || 'unknown')});
      });

      function renderTurnstile() {
        if (!window.turnstile || !window.turnstile.render) {
          setTimeout(renderTurnstile, 200);
          return;
        }

        try {
          rendered = true;
          window.turnstile.render('#turnstile-box', {
            sitekey: '$escapedSiteKey',
            theme: 'dark',
            size: 'normal',
            callback: function(token) {
              notify({type: 'token', value: token});
            },
            'error-callback': function(error) {
              notify({type: 'error', value: String(error || 'turnstile_error')});
            },
            'expired-callback': function() {
              notify({type: 'expired', value: ''});
            }
          });
          notify({type: 'ready', value: 'rendered'});
        } catch (e) {
          notify({type: 'error', value: 'render_exception:' + String(e)});
        }
      }

      setTimeout(function () {
        if (!rendered) {
          notify({type: 'error', value: 'turnstile_load_timeout'});
        }
      }, 10000);

      renderTurnstile();
    </script>
  </body>
</html>
''';
      await _configureVirtualHost();
      final file = File('${_virtualHostDir!.path}\\turnstile.html');
      await file.writeAsString(html, flush: true);

      final virtualHost = _virtualHostName!;
      final turnstileUrl =
          'https://$virtualHost/turnstile.html?nonce=${DateTime.now().millisecondsSinceEpoch}';
      await _controller.loadUrl(turnstileUrl);
      if (mounted) setState(() {});
    } catch (e) {
      _initError = e.toString();
      widget.onError?.call(_initError);
      if (mounted) setState(() {});
    }
  }

  Future<void> _configureVirtualHost() async {
    final base =
        Directory('${Directory.systemTemp.path}\\speed_app_turnstile_host');
    if (!base.existsSync()) {
      await base.create(recursive: true);
    }
    _virtualHostDir = base;

    final rawHost = widget.originHost.trim().toLowerCase();
    final validHost = rawHost.isEmpty ? 'zofiles.com' : rawHost;
    _virtualHostName = validHost;

    // Remove previous mapping first to avoid stale path/host mapping.
    try {
      await _controller.removeVirtualHostNameMapping(validHost);
    } catch (_) {}

    await _controller.addVirtualHostNameMapping(
      validHost,
      base.path,
      WebviewHostResourceAccessKind.allow,
    );
  }

  Future<void> _handleMessage(dynamic rawMessage) async {
    try {
      final parsed = rawMessage is Map<String, dynamic>
          ? rawMessage
          : jsonDecode(rawMessage.toString()) as Map<String, dynamic>;
      final type = parsed['type']?.toString() ?? '';
      final value = parsed['value']?.toString() ?? '';
      if (type == 'token') {
        widget.onTokenReceived(value);
        return;
      }
      if (type == 'error') {
        widget.onError?.call(value.trim());
        return;
      }
      if (type == 'ready') {
        return;
      }
      if (type == 'expired') {
        widget.onError?.call('Captcha expired. Please verify again.');
      }
    } catch (_) {
      widget.onError?.call(rawMessage.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_initError.isNotEmpty) {
      return Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text('Turnstile unavailable: $_initError'),
      );
    }

    if (!_initialized) {
      return const SizedBox(
        height: 70,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return SizedBox(
      width: _turnstileWidth,
      height: _turnstileHeight,
      child: ClipRect(
        child: Webview(
          _controller,
          width: _turnstileWidth,
          height: _turnstileHeight,
        ),
      ),
    );
  }

  @override
  void dispose() {
    final host = _virtualHostName;
    if (host != null) {
      _controller.removeVirtualHostNameMapping(host).catchError((_) {});
    }
    if (_initializeCalled) {
      _controller.dispose().catchError((_) {});
    }
    super.dispose();
  }
}
