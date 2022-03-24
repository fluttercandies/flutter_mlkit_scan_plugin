import UIKit

struct ChannelMethod {
    static let host = "MLKitScanPlugin"
    static let scanChannel = "\(host)/scanChannel"
    static let resultChannel = "\(host)/resultChannel"
    static let factoryId = "\(host)/ScanViewFactory"
    
    static let loadScanView = "loadScanView"
    static let switchScanType = "switchScanType"
    static let pauseScan = "pauseScan"
    static let resumeScan = "resumeScan"
    static let reFocus = "reFocus"
    static let stopScan = "stopScan"
    static let openFlashlight = "openFlashlight"
    static let closeFlashlight = "closeFlashlight"
    static let requestWakeLock = "requestWakeLock"
}

class ChannelManager: NSObject {
    var scanViewChannel: FlutterMethodChannel?
    var eventSink: FlutterEventSink?
    
    static let shared = ChannelManager()
    
    // MARK: - Bind all channel.
    public static func initFlutterMethodChannel(_ messenger: FlutterBinaryMessenger) {
        ChannelManager.shared.scanViewChannel = FlutterMethodChannel(
            name: ChannelMethod.scanChannel,
            binaryMessenger: messenger
        )
        FlutterEventChannel(
            name: ChannelMethod.resultChannel,
            binaryMessenger: messenger
        ).setStreamHandler(EventStreamHandler() as? FlutterStreamHandler & NSObjectProtocol)
    }
    
    // MARK: - Handle flutter channel calls.
    public static func handleFlutterChannel(
        _ call: FlutterMethodCall,
        factory: ScanViewFactory,
        result: @escaping FlutterResult
    ) {
        guard let scanView = factory.platformView?.scanView as? ScanView else {
            debugPrint("ScanView is null.")
            result(
                FlutterError(
                    code: "ScanView",
                    message: "0",
                    details: "ScanView is null."
                )
            )
            return
        }
        switch call.method {
        case ChannelMethod.loadScanView:
            scanView.createDeviceCapture()
            result(true)
        case ChannelMethod.switchScanType:
            switchScanType(call, scanView: scanView, result: result)
        case ChannelMethod.pauseScan:
            requestWakeLock(false)
            scanView.sessionPause()
            result(true)
        case ChannelMethod.resumeScan:
            requestWakeLock(true)
            scanView.sessionResume()
            result(true)
        case ChannelMethod.reFocus:
            reFocus(call, scanView: scanView, result: result)
        case ChannelMethod.stopScan:
            requestWakeLock(false)
            scanView.closeScanView()
            factory.platformView?.scanView?.removeFromSuperview()
            factory.platformView?.scanView = nil
            result(true)
        case ChannelMethod.openFlashlight:
            let _err = scanView.toggleFlashlight(enable: true)
            if (_err == nil) {
                result(nil)
            } else {
                result(FlutterError(code: "ScanView", message: _err, details: nil))
            }
        case ChannelMethod.closeFlashlight:
            let _err = scanView.toggleFlashlight(enable: false)
            if (_err == nil) {
                result(nil)
            } else {
                result(FlutterError(code: "ScanView", message: _err, details: nil))
            }
        case ChannelMethod.requestWakeLock:
            requestWakeLock(call)
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Switch the new scan type with the given rect.
    private static func switchScanType(
        _ call: FlutterMethodCall,
        scanView: ScanView,
        result: @escaping FlutterResult
    ) {
        if let argument = call.arguments as? [String: Any], let type = argument["type"] as? Int {
            var rect = CGRect.zero
            let taskMode = ScanningTaskMode.toMode(type)
            if taskMode != .wait {
                if let rectList = argument["rect"] as? Array<Double>, rectList.count == 4 {
                    rect = CGRect(
                        x: rectList[0],
                        y: rectList[1] - UIApplication.shared.statusBarFrame.height,
                        width: rectList[2],
                        height: rectList[3]
                    )
                }
            }
            scanView.changeScanState(with: taskMode, rect)
            debugPrint("Switching the scan type to: \(type)")
        }
        result(true)
    }
    
    // MARK: - Adjust focus with the given point.
    private static func reFocus(
        _ call: FlutterMethodCall,
        scanView: ScanView,
        result: @escaping FlutterResult
    ) {
        if let argument = call.arguments as? [Double], argument.count == 2 {
            let screenCenterPoint = CGPoint(
                x: UIScreen.main.bounds.width / 2,
                y: UIScreen.main.bounds.height / 2
            )
            let flutterX = argument.first ?? Double(screenCenterPoint.x)
            let flutterY = argument.last ?? Double(screenCenterPoint.y)
            scanView.adjustFocus(CGPoint(x: flutterX, y: flutterY))
        }
        result(true)
    }
    
    private static func requestWakeLock(_ call: FlutterMethodCall) {
        if let enable = call.arguments as? Bool {
            requestWakeLock(enable)
        }
    }
    
    private static func requestWakeLock(_ value: Bool) {
        debugPrint("Requesting wake lock: \(value)")
        UIApplication.shared.isIdleTimerDisabled = value
    }
}

class EventStreamHandler: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        ChannelManager.shared.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        ChannelManager.shared.eventSink = nil
        return nil
    }
}
