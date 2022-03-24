///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2021/11/9 20:03
///
import 'package:flutter/material.dart';

import '../plugin/constants.dart';
import '../plugin/scan_plugin.dart';
import '../resources.dart';

@optionalTypeArgs
mixin ScanFlashlightMixin<T extends StatefulWidget> on State<T> {
  /// 是否开启了闪光灯
  final ValueNotifier<bool> _flashlightActive = ValueNotifier<bool>(false);

  Future<void> toggleFlashlight() async {
    if (_flashlightActive.value) {
      await ScanPlugin.closeFlashlight();
      _flashlightActive.value = false;
    } else {
      await ScanPlugin.openFlashlight();
      _flashlightActive.value = true;
    }
  }

  @override
  void dispose() {
    _flashlightActive.dispose();
    super.dispose();
  }

  Widget flashlightButton(BuildContext context, {double size = 45}) {
    return GestureDetector(
      onTap: toggleFlashlight,
      child: ValueListenableBuilder<bool>(
        valueListenable: _flashlightActive,
        builder: (_, bool value, __) => Image.asset(
          value
              ? ScanPluginR.ASSETS_TORCH_ACTIVE_PNG
              : ScanPluginR.ASSETS_TORCH_PNG,
          package: ScanPluginPackage,
          width: size,
        ),
      ),
    );
  }
}
