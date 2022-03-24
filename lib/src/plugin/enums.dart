///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2021/11/4 10:57
///
/// 扫描的类别
///
/// -1 暂停扫描
/// 0  邮政条码和手机号扫描
/// 1  手机号扫描
/// 2  邮政条码扫描
/// 3  二维码扫描
/// 4  商品条码扫描
class ScanType extends _EnumClass {
  const ScanType._(int value) : super(value);

  static const ScanType wait = ScanType._(-1);
  static const ScanType barcodeAndMobile = ScanType._(0);
  static const ScanType mobile = ScanType._(1);
  static const ScanType barcode = ScanType._(2);
  static const ScanType qrCode = ScanType._(3);
  static const ScanType goodsCode = ScanType._(4);

  static ScanType from(int value) {
    return values.firstWhere((ScanType e) => e.value == value);
  }

  static const List<ScanType> values = <ScanType>[
    wait,
    barcodeAndMobile,
    mobile,
    barcode,
    qrCode,
    goodsCode,
  ];
}

/// 扫描结果的状态
///
/// -1 仅有条形码
/// 0  扫描失败
/// 1  扫描成功
class ScanResultStatus extends _EnumClass {
  const ScanResultStatus._(int value) : super(value);

  static const ScanResultStatus codeOnly = ScanResultStatus._(-1);
  static const ScanResultStatus failed = ScanResultStatus._(0);

  /// 注意：Android 下仍有可能返回 0 个电话号码，仍然需要作为 [codeOnly] 处理。
  static const ScanResultStatus succeed = ScanResultStatus._(1);

  static ScanResultStatus from(int value) {
    return values.firstWhere((ScanResultStatus e) => e.value == value);
  }

  static const List<ScanResultStatus> values = <ScanResultStatus>[
    codeOnly,
    failed,
    succeed,
  ];
}

class _EnumClass {
  const _EnumClass(this.value);

  final int value;

  bool operator <(_EnumClass other) => value < other.value;

  bool operator <=(_EnumClass other) => value <= other.value;

  bool operator >(_EnumClass other) => value > other.value;

  bool operator >=(_EnumClass other) => value >= other.value;

  @override
  String toString() => '$runtimeType._($value)';
}
