///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 2021/8/20 14:08
///
const String ScanPluginPackage = 'mlkit_scan_plugin';

/// 扫描取景区域的高度
const double SCAN_RECT_HEIGHT_CODE_OR_MOBILE = 100; // 扫描单号或手机号
const double SCAN_RECT_HEIGHT_FULL = 400; // 扫描整个面单

const Duration SCAN_INTERVAL = Duration(milliseconds: 500); // 每次扫描的间隔
