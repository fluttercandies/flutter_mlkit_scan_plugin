///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2021/11/9 19:23
///
import 'package:flutter/material.dart';

import '../plugin/scan_plugin.dart';

@optionalTypeArgs
mixin ScanFocusListenerMixin<T extends StatefulWidget> on State<T> {
  int get focusPointers => _pointers;
  int _pointers = 0;

  bool get shouldReFocus => _pointers == 0;

  @override
  void dispose() {
    _pointers = 0;
    super.dispose();
  }

  /// 触摸点移除
  void _removePointer(PointerUpEvent event) {
    if (_pointers == 0) {
      return;
    }
    _pointers--;
    if (shouldReFocus) {
      Future<void>(() {
        ScanPlugin.reFocus(event.position);
      });
    }
  }

  Widget focusWrapper({required Widget child}) {
    return Listener(
      onPointerDown: (_) => _pointers++,
      onPointerUp: _removePointer,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}
