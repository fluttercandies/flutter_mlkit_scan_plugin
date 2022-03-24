///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2021/11/29 16:30
///
import 'dart:io' show Platform;
import 'dart:ui' show window;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../plugin/enums.dart';
import '../plugin/log_util.dart';
import '../plugin/scan_plugin.dart';
import '../plugin/scan_result.dart';

class ScanView extends StatefulWidget {
  const ScanView({
    Key? key,
    required this.scanType,
    required this.scanRect,
    this.onViewCreated,
    this.resultListener,
  }) : super(key: key);

  final ScanType scanType;
  final Rect scanRect;
  final PlatformViewCreatedCallback? onViewCreated;
  final ScanResultCallback? resultListener;

  @override
  _ScanViewState createState() => _ScanViewState();
}

class _ScanViewState extends State<ScanView> with WidgetsBindingObserver {
  late final Widget _scanView = createView();
  late ScanResultCallback? _innerResultListener = widget.resultListener;
  late ScanResultCallback? _resultListener;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance?.addObserver(this);
    if (_innerResultListener != null) {
      _resultListener = _resultListenerWrapper(_innerResultListener!);
    }
  }

  @override
  void didUpdateWidget(ScanView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scanRect != oldWidget.scanRect) {
      ScanPlugin.switchScanType(ScanPlugin.scanningType, rect: widget.scanRect);
    }
    if (widget.resultListener != oldWidget.resultListener) {
      if (oldWidget.resultListener != null) {
        ScanPlugin.removeListener(_innerResultListener!);
        _innerResultListener = null;
        _resultListener = null;
      }
      if (widget.resultListener != null) {
        _innerResultListener = widget.resultListener;
        _resultListener = _resultListenerWrapper(_innerResultListener!);
        ScanPlugin.addListener(_resultListener!);
      }
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance?.addPostFrameCallback((_) async {
        if (ScanPlugin.isScanningPaused) {
          ScanPlugin.resumeScan();
        }
      });
    } else if (!ScanPlugin.isScanningPaused) {
      ScanPlugin.pauseScan();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance?.removeObserver(this);
    if (_resultListener != null) {
      ScanPlugin.removeListener(_resultListener!);
    }
    ScanPlugin.destroy();
    ScanPlugin.stopScan().whenComplete(() => LogUtil.d('Scanning stopped.'));
    super.dispose();
  }

  Future<void> _onViewCreated(int id) async {
    widget.onViewCreated?.call(id);
    ScanPlugin.init();
    if (_innerResultListener != null) {
      ScanPlugin.addListener(_resultListenerWrapper(widget.resultListener!));
    }
    await ScanPlugin.initializeScanning(
      widget.scanRect,
      scanType: widget.scanType,
    );
  }

  ScanResultCallback _resultListenerWrapper(ScanResultCallback cb) {
    return (ScanResult result) {
      if (!mounted) {
        return;
      }
      cb(result);
    };
  }

  /// 根据平台获取原生 View
  Widget createView() {
    if (!Platform.isAndroid && !Platform.isIOS) {
      throw UnimplementedError(
        'Scan view is not implemented for '
        '${Platform.operatingSystem}.',
      );
    }

    Widget _buildView(BoxConstraints cs) {
      final double ratio = MediaQueryData.fromWindow(window).devicePixelRatio;
      final int w = (cs.maxWidth * ratio).toInt();
      final int h = (cs.maxHeight * ratio).toInt();

      if (Platform.isIOS) {
        return UiKitView(
          viewType: ScanPlugin.platformViewType,
          onPlatformViewCreated: (int id) {
            LogUtil.d('UiKitView $id created.');
            _onViewCreated(id);
          },
          creationParams: <String, int>{'w': w, 'h': h},
          creationParamsCodec: const StandardMessageCodec(),
        );
      }
      return AndroidView(
        viewType: ScanPlugin.platformViewType,
        onPlatformViewCreated: (int id) {
          LogUtil.d('AndroidView $id created.');
          _onViewCreated(id);
        },
        creationParams: <String, int>{'w': w, 'h': h},
        creationParamsCodec: const StandardMessageCodec(),
      );
    }

    return LayoutBuilder(builder: (_, BoxConstraints cs) => _buildView(cs));
  }

  @override
  Widget build(BuildContext context) => _scanView;
}
