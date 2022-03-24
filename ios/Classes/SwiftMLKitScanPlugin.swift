import Flutter
import UIKit

public class SwiftMLKitScanPlugin: NSObject, FlutterPlugin {
    var factory: ScanViewFactory?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        // 初始化 channel
        ChannelManager.initFlutterMethodChannel(registrar.messenger())
        
        let instance = SwiftMLKitScanPlugin()
        if let scanViewChannel = ChannelManager.shared.scanViewChannel {
            registrar.addMethodCallDelegate(instance, channel: scanViewChannel)
        }
        // 注册 ScanView 到 Factory
        let factory = ScanViewFactory(messenger: registrar.messenger())
        instance.factory = factory
        registrar.register(factory, withId: ChannelMethod.factoryId)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let viewFactory = factory else {
            debugPrint("ScanViewFactory is null.")
            result(
                FlutterError(
                    code: "ScanViewFactory",
                    message: "0",
                    details: "ScanViewFactory is null"
                )
            )
            return
        }
        ChannelManager.handleFlutterChannel(call, factory: viewFactory, result: result)
    }
}
