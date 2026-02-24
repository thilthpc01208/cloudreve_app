import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:cloudreve_view/l10n/app_localizations.dart';
import 'package:cloudreve_view/controller.dart';

enum SnackbarAnchor {
  topLeft,
  topCenter,
  topRight,
}

abstract class Util {
  static bool isEmail(email) {
    final RegExp emailRegExp = RegExp(
        r'^[a-zA-Z0-9.!#$%&’*+/=?^_`{|}~-]+@[a-zA-Z0-9-]+(?:\.[a-zA-Z0-9-]+)*$');
    return emailRegExp.hasMatch(email);
  }

  static (EdgeInsets margin, double? maxWidth) _snackLayout(
    BuildContext context,
    SnackbarAnchor anchor,
  ) {
    final width = MediaQuery.of(context).size.width;
    final isMobile = width < 600;
    if (isMobile) {
      return (const EdgeInsets.fromLTRB(16, 14, 16, 0), null);
    }

    const cardWidth = 360.0;
    const top = 14.0;
    const side = 20.0;
    switch (anchor) {
      case SnackbarAnchor.topLeft:
        return (const EdgeInsets.fromLTRB(side, top, 0, 0), cardWidth);
      case SnackbarAnchor.topRight:
        return (const EdgeInsets.fromLTRB(0, top, side, 0), cardWidth);
      case SnackbarAnchor.topCenter:
        return (const EdgeInsets.fromLTRB(20, top, 20, 0), 420);
    }
  }

  static void showSnackbar({
    required BuildContext context,
    String? title,
    String? message,
    SnackbarAnchor anchor = SnackbarAnchor.topRight,
  }) {
    final controller = Get.find<Controller>();
    final fallbackTitle = AppLocalizations.of(context)!.tipTitle;
    final fallbackMessage = AppLocalizations.of(context)!.submitting;
    final layout = _snackLayout(context, anchor);
    Get.showSnackbar(
      GetSnackBar(
        snackPosition: SnackPosition.TOP,
        snackStyle: SnackStyle.FLOATING,
        margin: layout.$1,
        maxWidth: layout.$2,
        borderRadius: 4,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        boxShadows: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
        forwardAnimationCurve: Curves.ease,
        reverseAnimationCurve: Curves.ease,
        animationDuration: const Duration(milliseconds: 300),
        backgroundColor: Theme.of(context).dialogTheme.backgroundColor ??
            Theme.of(context).colorScheme.surface,
        title: title ??
            controller.trCloudreve('modals.tips', fallback: fallbackTitle),
        message: message ??
            controller.trCloudreve('common.loading', fallback: fallbackMessage),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  static void showErrorSnackbar({
    required BuildContext context,
    String? title,
    String? message,
    SnackbarAnchor anchor = SnackbarAnchor.topRight,
  }) {
    final controller = Get.find<Controller>();
    final fallbackTitle = AppLocalizations.of(context)!.tipTitle;
    final fallbackMessage = AppLocalizations.of(context)!.submitting;
    final layout = _snackLayout(context, anchor);
    Get.showSnackbar(GetSnackBar(
      snackPosition: SnackPosition.TOP,
      snackStyle: SnackStyle.FLOATING,
      margin: layout.$1,
      maxWidth: layout.$2,
      borderRadius: 4,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      boxShadows: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
      forwardAnimationCurve: Curves.ease,
      reverseAnimationCurve: Curves.ease,
      animationDuration: const Duration(milliseconds: 300),
      backgroundColor: Colors.red,
      title: title ??
          controller.trCloudreve('common.errorDetails',
              fallback: fallbackTitle),
      message: message ??
          controller.trCloudreve('common.unknownError',
              fallback: fallbackMessage),
      duration: const Duration(seconds: 1),
    ));
  }

  static AnimationController showTopSheet(
      {required context, required vsync, child, duration, offset}) {
    final overlay = Overlay.of(context);
    final controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: vsync,
    );
    final animation = Tween<Offset>(
      begin: Offset(0, offset ?? -5),
      end: Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: controller,
      curve: Curves.easeInOut,
    ));

    final overlayEntry = OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: controller,
        builder: (context, child) => Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: animation,
            child: Material(
              elevation: 10,
              child: child,
            ),
          ),
        ),
        child: SafeArea(
          child: child,
        ),
      ),
    );

    overlay.insert(overlayEntry);
    controller.forward();

    return controller;
  }
}
