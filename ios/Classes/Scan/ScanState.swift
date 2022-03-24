import Foundation

/// 扫描的一些配置项
public struct ScanConfig {
    static let scanTimeOutDuration: TimeInterval = 1 // 扫描到条码后未扫描到手机号的超时时间，默认1s
}

/// 扫描模式的类型
public enum ScanningTaskMode {
    case wait // 暂停
    case barcodeAndMobile // 条码和手机号
    case mobile // 手机号
    case barcode // 条码
    case qrCode // 二维码
    case goodsCode // 商品条码
    
    static func toMode(_ value: Int) -> ScanningTaskMode {
        switch value {
        case -1:
            return .wait
        case 0:
            return .barcodeAndMobile
        case 1:
            return .mobile
        case 2:
            return .barcode
        case 3:
            return .qrCode
        case 4:
            return .goodsCode
        default:
            return .wait
        }
    }
}

/// 扫描任务的类型
public enum ScanningType {
    case wait // 暂停
    case barcodeAndMobile // 条码和手机号
    case mobile // 手机号
    case barcode // 条码
    case qrCode // 二维码
    case goodsCode // 商品条码
}

/// 扫描结果的状态
public enum ScanningResultState: Int {
    case success = 1 //扫描成功
    case failed = 0 //扫描失败
    case progress = -1 //任务尚未完成
}

/// 扫描结果数据映射
public struct ScanResult {
    var state: ScanningResultState = .failed // 状态码
    var code: String? // 条形码解析数值
    var phone: Array<String> = [] // 提取到的手机号
    
    public func toJSON() -> [String: Any] {
        var params: [String: Any] = ["state": state.rawValue]
        if let codeString = code {
            params["code"] = codeString
        }
        if (!phone.isEmpty) {
            params["phone"] = Array(Set(phone))
        }
        return params
    }
}
