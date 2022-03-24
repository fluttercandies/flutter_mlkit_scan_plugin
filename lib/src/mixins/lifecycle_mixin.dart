///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2021/11/10 15:12
///
import 'package:flutter/material.dart';

import '../plugin/scan_plugin.dart';

mixin ScanLifecycleMixin on WidgetsBindingObserver, RouteAware {
  bool isInCurrentPage = true;

  @override
  void didPushNext() {
    super.didPushNext();
    isInCurrentPage = false;
  }

  @override
  void didPopNext() {
    super.didPopNext();
    isInCurrentPage = true;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        if (ScanPlugin.isScanningPaused) {
          ScanPlugin.resumeScan();
        }
        break;
      case AppLifecycleState.inactive:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        if (!ScanPlugin.isScanningPaused) {
          ScanPlugin.pauseScan();
        }
        break;
    }
  }
}
