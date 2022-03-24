///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 11/26/20 8:23 PM
///
import 'dart:developer';

DateTime get _currentTime => DateTime.now();

int get _currentTimeStamp => _currentTime.millisecondsSinceEpoch;

class LogUtil {
  const LogUtil._();

  static const String _TAG = 'SCAN PLUGIN - LOG';

  static void i(dynamic message, {String tag = _TAG, StackTrace? stackTrace}) {
    _printLog(message, tag, stackTrace);
  }

  static void d(dynamic message, {String tag = _TAG, StackTrace? stackTrace}) {
    _printLog(message, tag, stackTrace);
  }

  static void w(dynamic message, {String tag = _TAG, StackTrace? stackTrace}) {
    _printLog(message, tag, stackTrace);
  }

  static void e(dynamic message, {String tag = _TAG, StackTrace? stackTrace}) {
    _printLog(message, tag, stackTrace);
  }

  static void json(
    dynamic message, {
    String tag = _TAG,
    StackTrace? stackTrace,
  }) {
    _printLog(message, tag, stackTrace);
  }

  static void _printLog(dynamic message, String tag, StackTrace? stackTrace) {
    log(
      '$_currentTimeStamp - $message',
      name: tag,
      stackTrace: stackTrace,
    );
  }
}
