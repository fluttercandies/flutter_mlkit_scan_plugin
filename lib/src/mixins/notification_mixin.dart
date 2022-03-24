///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2021/11/9 19:40
///
import 'dart:async';
import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../plugin/constants.dart';
import '../resources.dart';

@optionalTypeArgs
mixin ScanNotificationMixin<T extends StatefulWidget> on State<T> {
  final ValueNotifier<bool> _isShowing = ValueNotifier<bool>(false);
  final ValueNotifier<ScanNotificationContent?> _content =
      ValueNotifier<ScanNotificationContent?>(null);

  /// 用于控制通知显示的计时器
  Timer? _notificationTimer;

  @override
  void dispose() {
    _isShowing.dispose();
    _content.dispose();
    _notificationTimer?.cancel();
    super.dispose();
  }

  void showNotification(ScanNotificationContent content) {
    if (mounted) {
      _content.value = content;
      _isShowing.value = true;
      _notificationTimer?.cancel();
      _notificationTimer = Timer(const Duration(seconds: 3), () {
        _isShowing.value = false;
      });
    }
  }

  Color _typeColor(ScanNotificationContent? content) {
    switch (content?.type) {
      case ScanNotificationType.error:
        return const Color(0xffe2423f);
      case ScanNotificationType.success:
        return const Color(0xff2ddf6e);
      case ScanNotificationType.warning:
        return const Color(0xfff6b005);
      default:
        return const Color(0xff3271f6);
    }
  }

  Widget _typeIcon(ScanNotificationContent? content) {
    switch (content?.type) {
      case ScanNotificationType.info:
      case ScanNotificationType.warning:
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Image.asset(
            ScanPluginR.ASSETS_NOTIFICATION_WARNING_ICON_PNG,
            width: 20,
            height: 20,
            package: ScanPluginPackage,
          ),
        );
      case ScanNotificationType.success:
        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: Image.asset(
            ScanPluginR.ASSETS_NOTIFICATION_SUCCESS_ICON_PNG,
            width: 20,
            height: 20,
            package: ScanPluginPackage,
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _contentWidget(
    BuildContext context,
    ScanNotificationContent? content,
  ) {
    return Flexible(
      child: Text(
        content?.content ?? '',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Positioned notificationOverlay(BuildContext context) {
    return Positioned.fill(
      top: 0,
      bottom: null,
      child: ValueListenableBuilder<bool>(
        valueListenable: _isShowing,
        builder: (_, bool isShowing, Widget? child) => AnimatedAlign(
          curve: Curves.ease,
          duration: kThemeAnimationDuration * 2,
          alignment: Alignment.bottomCenter,
          heightFactor: isShowing ? 1 : 0,
          child: child!,
        ),
        child: ValueListenableBuilder<ScanNotificationContent?>(
          valueListenable: _content,
          builder: (_, ScanNotificationContent? content, __) {
            return AnimatedContainer(
              duration: kThemeAnimationDuration,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(15),
                  bottomRight: Radius.circular(15),
                ),
                color: _typeColor(content),
              ),
              child: Container(
                margin: EdgeInsets.only(
                  top: MediaQueryData.fromWindow(ui.window).padding.top,
                ),
                padding: const EdgeInsets.all(10),
                constraints: const BoxConstraints(minHeight: kToolbarHeight),
                child: DefaultTextStyle.merge(
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    inherit: false,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      _typeIcon(content),
                      _contentWidget(context, content),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

enum ScanNotificationType { success, info, warning, error }

class ScanNotificationContent {
  const ScanNotificationContent({
    this.content = '',
    this.type = ScanNotificationType.info,
  });

  factory ScanNotificationContent.success([String content = '']) {
    return ScanNotificationContent(
      content: content,
      type: ScanNotificationType.success,
    );
  }

  factory ScanNotificationContent.warning([String content = '']) {
    return ScanNotificationContent(
      content: content,
      type: ScanNotificationType.warning,
    );
  }

  factory ScanNotificationContent.error([String content = '']) {
    return ScanNotificationContent(
      content: content,
      type: ScanNotificationType.error,
    );
  }

  final String content;
  final ScanNotificationType type;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'content': content,
        'type': type.toString(),
      };

  @override
  String toString() => const JsonEncoder.withIndent('  ').convert(toJson());
}
