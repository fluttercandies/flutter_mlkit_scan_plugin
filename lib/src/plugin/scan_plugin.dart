///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 12/11/20 4:40 PM
///
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import 'enums.dart';
import 'log_util.dart';
import 'scan_result.dart';

/// 固定的 channel 前缀
const String _channelPrefix = 'MLKitScanPlugin';

/// 定义扫描结果处理函数回调为类型
typedef ScanResultCallback = void Function(ScanResult result);

class ScanPlugin {
  const ScanPlugin._();

  /// 是否打印 LOG
  static bool isLogging = true;

  static const MethodChannel _scanChannel = MethodChannel(
    '$_channelPrefix/scanChannel',
    JSONMethodCodec(),
  );

  static const EventChannel _resultChannel = EventChannel(
    '$_channelPrefix/resultChannel',
  );

  static const String platformViewType = '$_channelPrefix/ScanViewFactory';

  ////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////

  static const String _METHOD_LOAD_SCAN_VIEW = 'loadScanView';
  static const String _METHOD_PAUSE_SCAN = 'pauseScan';
  static const String _METHOD_RESUME_SCAN = 'resumeScan';
  static const String _METHOD_STOP_SCAN = 'stopScan';
  static const String _METHOD_SWITCH_SCAN_TYPE = 'switchScanType';
  static const String _METHOD_RE_FOCUS = 'reFocus';
  static const String _METHOD_OPEN_FLASHLIGHT = 'openFlashlight';
  static const String _METHOD_CLOSE_FLASHLIGHT = 'closeFlashlight';
  static const String _METHOD_REQUEST_WAKE_LOCK = 'requestWakeLock';
  static const String _METHOD_ANALYZING_IMAGE_FILE = 'analyzingImageFile';

  ////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////

  static final Stream<Map<dynamic, dynamic>> _resultStream =
      _resultChannel.receiveBroadcastStream().cast<Map<dynamic, dynamic>>();

  static StreamSubscription<Map<dynamic, dynamic>>? _resultSubscription;

  /// 结果回调的监听器列表
  ///
  /// 在监听列表内的所有监听器，可以在调用时收到内容，从而进行调用。
  static ObserverList<ScanResultCallback> _resultListeners =
      ObserverList<ScanResultCallback>();

  ////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////
  ////////////////////////////////////////////////////////////////////////////

  /// 当前的扫描模式
  static ScanType get scanningType => _scanningType ?? ScanType.wait;
  static ScanType? _scanningType;

  /// 是否正在调用耗时方法
  static final ValueNotifier<bool> isDispatching = ValueNotifier<bool>(false);

  /// 当前的区域
  static Rect? _scanningRect;

  /// 是否已暂停解析
  static bool get isDecodingPaused => scanningType == ScanType.wait;

  /// 是否已暂停扫描
  static bool get isScanningPaused => _isScanningPaused;
  static bool _isScanningPaused = false;

  /// 注册扫描结果的监听基建
  ///
  /// 必须在初始化扫描前调用，且应只调用一次
  static void init() {
    assert(_resultSubscription == null);
    LogUtil.d('Initializing scan result subscription...');
    _resultSubscription = _resultStream.listen(
      (Map<dynamic, dynamic> event) {
        for (final ScanResultCallback listener in _resultListeners) {
          listener(ScanResult.fromJson(event));
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        LogUtil.e('Error in scan result subscription: $error, $stackTrace');
      },
      cancelOnError: false,
    );
  }

  /// 将当前的订阅取消
  static void destroy() {
    LogUtil.d('Destroying scan subscriptions...');
    _resultListeners = ObserverList<ScanResultCallback>();
    _resultSubscription?.cancel();
    _resultSubscription = null;
    _isScanningPaused = false;
    _scanningType = null;
    _scanningRect = null;
    isDispatching.value = false;
  }

  /// 添加监听器实例
  static void addListener(ScanResultCallback listener) {
    _resultListeners.add(listener);
  }

  /// 移除监听器实例
  static void removeListener(ScanResultCallback listener) {
    _resultListeners.remove(listener);
  }

  /// 初始化扫描
  ///
  /// 扫描初始化在 iOS 有两步：
  ///  * 1. 加载扫描 View。
  ///  * 2. 切换扫描模式至 **自定义状态** 或 [ScanType.all]，并传入对应的扫描区域。
  static Future<void> initializeScanning(
    Rect rect, {
    ScanType scanType = ScanType.barcodeAndMobile,
  }) async {
    LogUtil.d('Scanning initialize.');
    try {
      await _scanChannel.invokeMethod<void>(_METHOD_LOAD_SCAN_VIEW);
      await switchScanType(scanType, rect: rect);
    } catch (e) {
      LogUtil.e(e);
    }
  }

  /// 暂停解析
  static Future<void> pauseDecode() {
    return switchScanType(ScanType.wait, rect: null, updateVariable: false);
  }

  /// 恢复解析
  static Future<void> resumeDecode() async {
    if (_scanningType == null && _resultSubscription == null) {
      if (!kDebugMode) {
        return;
      }
      throw StateError('Scanner has already been destroyed.');
    }
    return switchScanType(
      _scanningType!,
      rect: _scanningRect,
      updateVariable: false,
    );
  }

  /// 暂停扫描
  static Future<void> pauseScan() async {
    if (_isScanningPaused) {
      return;
    }
    _isScanningPaused = true;
    LogUtil.d('Scanning pause.');
    return _invokeMethod(_METHOD_PAUSE_SCAN);
  }

  /// 恢复扫描
  static Future<void> resumeScan() async {
    if (!_isScanningPaused) {
      return;
    }
    _isScanningPaused = false;
    LogUtil.d('Scanning resume.');
    return _invokeMethod(_METHOD_RESUME_SCAN);
  }

  /// 停止扫描
  static Future<void> stopScan() {
    assert(_resultSubscription == null, 'Call destroy() first.');
    LogUtil.d('Scanning stop.');
    if (_resultSubscription != null) {
      destroy();
    }
    return _invokeMethod(_METHOD_STOP_SCAN);
  }

  /// 以操作点进行重新聚焦
  static Future<void> reFocus(Offset point) async {
    if (_resultSubscription == null) {
      return;
    }
    assert(point.dx >= 0 && point.dy >= 0);
    LogUtil.d('Re-focus with point: $point');
    return _invokeMethod<void>(_METHOD_RE_FOCUS, <double>[point.dx, point.dy]);
  }

  /// 切换扫描模式
  ///
  /// [type] 扫描模式
  /// [rect] 传入扫描的区域。宽和高必须大于 65。
  /// [updateVariable] 是否更新变量
  static Future<void> switchScanType(
    ScanType type, {
    required Rect? rect,
    bool updateVariable = true,
  }) async {
    if (_resultSubscription == null) {
      return;
    }
    assert(
      type == ScanType.wait ||
          rect != null && !rect.isEmpty && rect.width > 65 && rect.height > 65,
    );
    if (updateVariable) {
      _scanningType = type;
      _scanningRect = rect!;
    }
    // 正常模式扫描，谁不是 4 个元素谁砍头。
    final List<double>? rectFromLTWH = rect != null
        ? <double>[rect.left, rect.top, rect.width, rect.height]
        : null;
    String _log = 'Switch scan type to $type';
    if (rect != null) {
      _log += ' with Rect: $rect';
    }
    _log += '.';
    LogUtil.d(_log);
    return _invokeMethod(
      _METHOD_SWITCH_SCAN_TYPE,
      <String, dynamic>{
        'type': type.value,
        if (rectFromLTWH != null) 'rect': rectFromLTWH,
      },
    );
  }

  /// 手动调用扫描成功
  ///
  /// 该方法用于在扫描手机号时，手动输入手机号，调用运单扫描成功的回调
  static void manuallyAddResult(ScanResult result) {
    LogUtil.d('Manually adding result: $result');
    for (final ScanResultCallback listener in _resultListeners) {
      listener(result);
    }
  }

  static Future<void> openFlashlight() async {
    if (_resultSubscription == null) {
      return;
    }
    return _invokeMethod(_METHOD_OPEN_FLASHLIGHT);
  }

  static Future<void> closeFlashlight() async {
    if (_resultSubscription == null) {
      return;
    }
    return _invokeMethod(_METHOD_CLOSE_FLASHLIGHT);
  }

  static Future<void> requestWakeLock(bool value) async {
    if (_resultSubscription == null) {
      return;
    }
    return _invokeMethod(_METHOD_REQUEST_WAKE_LOCK, value);
  }

  static Future<List<Barcode>> analyzingImageFile(
    String path, [
    List<BarcodeFormat>? formats,
  ]) async {
    final List<dynamic>? list = await _invokeMethod<List<dynamic>>(
      _METHOD_ANALYZING_IMAGE_FILE,
      <String, dynamic>{
        'path': path,
        'formats':
            formats?.map((BarcodeFormat e) => e.code).toList(growable: false),
      },
    );
    if (list == null) {
      return <Barcode>[];
    }
    return list
        .cast<Map<String, dynamic>>()
        .map((Map<String, dynamic> e) => Barcode.fromJson(e))
        .toList(growable: false);
  }

  @optionalTypeArgs
  static Future<T?> _invokeMethod<T>(String method, [Object? arguments]) async {
    isDispatching.value = true;
    try {
      final T? t = await _scanChannel.invokeMethod<T>(method, arguments);
      return t;
    } catch (e) {
      LogUtil.e('Error when invoking method ($method): $e');
      return null;
    } finally {
      isDispatching.value = false;
    }
  }
}
