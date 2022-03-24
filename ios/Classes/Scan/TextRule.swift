import Foundation
import MLKitBarcodeScanning
import MLKitTextRecognition

// MARK: - Validate code text.
public func checkCodeText(_ barcodes: [Barcode], _ scanningType: ScanningType) -> String? {
    guard !barcodes.isEmpty else {
        return nil
    }
    var resultString: String?
    for barcode in barcodes {
        if (scanningType == .qrCode || scanningType == .goodsCode) {
            resultString = barcode.rawValue
            break
        }
        let reg = "^[0-9a-zA-Z\\-]{10,}"
        let predicate = NSPredicate(format: "SELF MATCHES %@", reg)
        if predicate.evaluate(with: barcode.rawValue) {
            resultString = barcode.rawValue
            break
        }
    }
    return resultString
}

// MARK: - Validate phone text.
public func checkPhoneText(_ texts: Array<String>) -> Array<String> {
    var results = [] as [String]
    for text in texts {
        let content = text.filter(\.isNumber)
        if (content.isEmpty || content.count < 11) {
            continue
        }
        results.append(content)
    }
    return Array(Set(results))
}

public func enhanceNumberText(_ text: String) -> String {
    return text.replacingOccurrences(of: "O", with: "0")
        .replacingOccurrences(of: "I", with: "1")
        .replacingOccurrences(of: "i", with: "1")
        .replacingOccurrences(of: "l", with: "1")
        .replacingOccurrences(of: "|", with: "1")
        .replacingOccurrences(of: "!", with: "1")
        .replacingOccurrences(of: "Z", with: "2")
        .replacingOccurrences(of: "z", with: "2")
}
