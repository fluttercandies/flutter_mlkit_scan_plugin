package com.alexv525.mlkit_scan_plugin

object Constant {
    private const val PACKAGE = "MLKitScanPlugin"

    /// 三端约定的方法
    const val METHOD_CHANNEL_NAME = "$PACKAGE/scanChannel"
    const val METHOD_LOAD_SCAN_VIEW = "loadScanView"
    const val METHOD_SWITCH_SCAN_TYPE = "switchScanType"
    const val METHOD_STOP_SCAN = "stopScan"
    const val METHOD_REFOCUS = "reFocus"
    const val METHOD_RESUME_SCAN = "resumeScan"
    const val METHOD_PAUSE_SCAN = "pauseScan"
    const val METHOD_SCAN_FROM_FILE = "scanFromFile"
    const val METHOD_OPEN_FLASHLIGHT = "openFlashlight"
    const val METHOD_CLOSE_FLASHLIGHT = "closeFlashlight"
    const val METHOD_REQUEST_WAKE_LOCK = "requestWakeLock"

    const val EVENT_CHANNEL_NAME = "$PACKAGE/resultChannel"
    const val VIEW_TYPE_ID = "$PACKAGE/ScanViewFactory"

    /// 扫描的四种类别
    const val SCAN_TYPE_BARCODE_AND_MOBILE = 0
    const val SCAN_TYPE_MOBILE = 1
    const val SCAN_TYPE_WAIT = -1
    const val SCAN_TYPE_BARCODE = 2
    const val SCAN_TYPE_QR_CODE = 3
    const val SCAN_TYPE_GOODS_CODE = 4

    /// 扫描结果
    const val SCAN_RESULT_CODE_ONLY = -1
    const val SCAN_RESULT_FAILED = 0
    const val SCAN_RESULT_SUCCEED = 1

    /// 循环间隔时长设定
    const val DECODE_INTERVAL = 300
    const val FOCUS_INTERVAL = 1200
}