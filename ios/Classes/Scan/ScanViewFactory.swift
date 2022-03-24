import Foundation

class ScanViewFactory: NSObject, FlutterPlatformViewFactory {
    var platformView: ScanPlatformView?
    private weak var messenger: FlutterBinaryMessenger?

    init(messenger: FlutterBinaryMessenger) {
        super.init()
        self.messenger = messenger
        debugPrint("ScanViewFactory init.")
    }
    
    func create(withFrame frame: CGRect, viewIdentifier viewId: Int64, arguments args: Any?) -> FlutterPlatformView {
        debugPrint("Creating new platformView.")
        let viewRect: CGRect?
        if let argsMap = args as? Dictionary<NSString, Int> {
            viewRect = CGRect(x: 0, y: 0, width: argsMap["w"]!, height: argsMap["h"]!);
        } else {
            viewRect = nil
        }
        let scanPlatformView = ScanPlatformView(
            frame: frame,
            viewIdentifier: viewId,
            arguments: args,
            binaryMessenger: messenger,
            viewRect: viewRect
        )
        platformView = scanPlatformView
        return scanPlatformView
    }

    func createArgsCodec() -> FlutterMessageCodec & NSObjectProtocol {
        return FlutterStandardMessageCodec.sharedInstance()
    }
}

class ScanPlatformView: NSObject, FlutterPlatformView {
    var scanView: UIView?

    init(
        frame: CGRect,
        viewIdentifier viewId: Int64,
        arguments args: Any?,
        binaryMessenger messenger: FlutterBinaryMessenger?,
        viewRect: CGRect?
    ) {
        super.init()
        scanView = ScanView.init(frame: frame, viewRect: viewRect)
        debugPrint("ScanPlatformView init.")
    }

    func view() -> UIView {
        return scanView ?? UIView()
    }
}
