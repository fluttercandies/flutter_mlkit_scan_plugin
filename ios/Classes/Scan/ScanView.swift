import Foundation
import AVFoundation
import CoreImage
import MLKitBarcodeScanning
import MLKitTextRecognition
import MLKitVision
import UIKit

class ScanView: UIView {
    private var viewRect: CGRect?
    private var scanningFrame: CGRect?
    private var captureDevice: AVCaptureDevice?
    private var session: AVCaptureSession?
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var scanningType: ScanningType = .wait
    private var timeOut: Bool = false
    private var createTimer: Bool = false
    private var codeSuccess: Bool = false
    private var phoneSuccess: Bool = false
    private var resultModel: ScanResult?
    private final var imageParser = ImageParser()
    private final var barcodeFormats = BarcodeFormat.init(arrayLiteral: [.code39, .code93, .code128])
    private final var qrCodeFormats = BarcodeFormat.qrCode
    private final var goodsCodeFormats = BarcodeFormat.init(arrayLiteral: [.EAN8, .EAN13, .UPCA, .UPCE])
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    init(frame: CGRect, viewRect: CGRect?) {
        if let rect = viewRect as CGRect? {
            let dpi = UIScreen.main.scale
            self.viewRect = CGRect(x: 0, y: 0, width: rect.width / dpi, height: rect.height / dpi)
        }
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Change scan state and update the scanning frame.
    public func changeScanState(with mode: ScanningTaskMode, _ frame: CGRect) {
        scanningFrame = frame
        restartScan()
        switch mode {
        case .wait:
            scanningType = .wait
        case .barcodeAndMobile:
            scanningType = .barcodeAndMobile
        case .mobile:
            scanningType = .mobile
        case .barcode:
            scanningType = .barcode
        case .qrCode:
            scanningType = .qrCode
        case .goodsCode:
            scanningType = .goodsCode
        }
    }
    
    // MARK: - Pause scanning.
    public func sessionPause() {
        session?.stopRunning()
        UIApplication.shared.isIdleTimerDisabled = false
    }
    
    // MARK: - Resume scanning.
    public func sessionResume() {
        session?.startRunning()
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    // MARK: - Adjust the focus.
    public func adjustFocus(_ point: CGPoint) {
        debugPrint("Adjusting focus at: \(point)")
        guard let device = captureDevice else {
            debugPrint("Find Error: Device adjust focus failed")
            return
        }
        // 转换 point 数据为焦点相对位置
        let focusPoint = CGPoint(
            x: point.y / UIScreen.main.bounds.size.height,
            y: 1 - point.x / UIScreen.main.bounds.size.width
        )
        if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(.autoFocus) {
            do {
                try device.lockForConfiguration()
                device.focusPointOfInterest = focusPoint
                device.focusMode = .autoFocus
                device.unlockForConfiguration()
            } catch let error {
                debugPrint("Find Error: Set device focus failed\n\(error)")
            }
        }
    }
    
    // MARK: - Toggle Flashlight during the capture session.
    public func toggleFlashlight(enable: Bool) -> String? {
        guard
            let device = captureDevice,
            device.hasTorch
        else { return "Device has no torch available." }
        
        do {
            try device.lockForConfiguration()
            device.torchMode = enable ? .on : .off
            device.unlockForConfiguration()
            return nil
        } catch {
            return "Torch could not be used."
        }
    }
    
    // MARK: - Run DeviceCapture
    public func createDeviceCapture() {
        // 创建 Device 对象
        let device = AVCaptureDevice.default(for: .video)
        session = AVCaptureSession()
        guard let currentDevice = device, let input = try? AVCaptureDeviceInput(device: currentDevice) else {
            debugPrint("Device input init failed.")
            return
        }
        // 设置参数
        session = AVCaptureSession()
        if session?.canAddInput(input) ?? false {
            session?.addInput(input)
        }
        if let currentSession = session {
            previewLayer = AVCaptureVideoPreviewLayer(session: currentSession)
        }
        // 设置预览图层
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = viewRect ?? UIScreen.main.bounds
        if let currentPreviewLayer = previewLayer {
            layer.insertSublayer(currentPreviewLayer, at: 0)
        }
        // 设置视频清晰度，非刘海屏一律使用最低清晰度
        if safeAreaInsets.top > 0 && session?.canSetSessionPreset(.high) ?? false {
            session?.canSetSessionPreset(.high)
        } else if (session?.canSetSessionPreset(.low) ?? false) {
            session?.canSetSessionPreset(.low)
        }
        // 设置输出格式
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: NSNumber(value: kCVPixelFormatType_32BGRA)]
        if session?.canAddOutput(videoOutput) ?? false {
            session?.addOutput(videoOutput)
            videoOutput.accessibilityFrame = UIScreen.main.bounds
        }
        // 设置分辨率
        let fps = 15
        if let device = captureDevice, let fpsRange = device.activeFormat.videoSupportedFrameRateRanges.first {
            if fps < Int(fpsRange.maxFrameRate) && fps > Int(fpsRange.minFrameRate) {
                do {
                    try device.lockForConfiguration()
                    device.activeVideoMinFrameDuration = CMTime(value: 1, timescale: CMTimeScale(fps))
                    device.activeVideoMaxFrameDuration = CMTime(value: 1, timescale: CMTimeScale(fps))
                    device.unlockForConfiguration()
                } catch let error {
                    debugPrint("Find Error: Set device fps failed\n\(error)")
                }
            }
        }
        videoOutput.setSampleBufferDelegate(self, queue: .main)
        captureDevice = device
        sessionResume()
    }
    
    // MARK: - Start scan, prepare for video output.
    private func restartScan() {
        resultModel = ScanResult()
        codeSuccess = false
        phoneSuccess = false
        timeOut = false
    }
    
    // MARK: - Check the output result.
    private func checkOutputState() {
        // 处理当前扫描结果
        var toFlutterResult = ScanResult()
        toFlutterResult.code = resultModel?.code
        toFlutterResult.phone = resultModel?.phone ?? []
        // 设置当前扫描结果的状态码
        switch scanningType {
        case .barcodeAndMobile:
            toFlutterResult.state = .progress
            if codeSuccess && phoneSuccess {
                toFlutterResult.state = .success
            }
        case .mobile:
            if phoneSuccess {
                toFlutterResult.state = .success
            }
        case .barcode, .qrCode, .goodsCode:
            if codeSuccess {
                toFlutterResult.state = .success
            }
        default:
            break
        }
        let result = toFlutterResult.toJSON()
        debugPrint(result)
        // 根据状态码回传扫描结果
        switch toFlutterResult.state {
        case .success:
            scanEnd()
            ChannelManager.shared.eventSink?(result)
        case .progress:
            if timeOut {
                resultModel?.phone.removeAll()
                scanningType = .wait
                createTimer = false
                timeOut = false
                ChannelManager.shared.eventSink?(result)
            }
        default:
            break
        }
    }
    
    // MARK: - Start the OCR decode task.
    private func startScanTask(_ buffer: CMSampleBuffer) {
        if (imageParser.isProcessing) {
            return
        }
        guard let scanImage = imageParser.sampleBufferToImage(buffer) else {
            debugPrint("SampleBuffer does not include UIImage.")
            return
        }
        guard let resultImage = imageParser.reSize(
            image: scanImage,
            rect: scanningFrame!
        ) else {
            debugPrint("Scan image cannot be cropped.")
            return
        }
        // 根据扫描模式和任务状态标识开启不同的任务
        switch scanningType {
        case .barcodeAndMobile: // 常规任务情况下根据状态进行识别任务节流
            if codeSuccess {
                startScanPhoneTask(resultImage)
            } else {
                startScanCodeTask(resultImage)
                if !phoneSuccess {
                    startScanPhoneTask(resultImage)
                }
            }
        case .barcode, .qrCode, .goodsCode:
            startScanCodeTask(resultImage)
        case .mobile:
            startScanPhoneTask(resultImage)
        default:
            break
        }
    }
    
    // MARK: - Start the barcode scanning task.
    private func startScanCodeTask(_ image: UIImage) {
        let visionImage = VisionImage(image: image)
        // Define the options for a barcode detector.
        let format: BarcodeFormat
        if (scanningType == .qrCode) {
            format = qrCodeFormats
        } else if (scanningType == .goodsCode) {
            format = goodsCodeFormats
        } else {
            format = barcodeFormats
        }
        // Create a barcode scanner.
        let barcodeScanner = BarcodeScanner.barcodeScanner(options: BarcodeScannerOptions(formats: format))
        var barcodes: [Barcode]
        weak var weakSelf = self
        do {
            barcodes = try barcodeScanner.results(in: visionImage)
        } catch let error {
            debugPrint("Failed to scan barcodes with error: \(error.localizedDescription).")
            return
        }
        guard let strongSelf = weakSelf else {
            debugPrint("Self is nil!")
            return
        }
        if let strScanned = checkCodeText(barcodes, scanningType) {
            debugPrint("Scanned code string = \(strScanned)")
            strongSelf.resultModel?.code = strScanned
            strongSelf.codeSuccess = true
            DispatchQueue.main.async {
                if strongSelf.scanningType == .barcodeAndMobile && !strongSelf.createTimer {
                    strongSelf.createTimer = true
                    strongSelf.setScanTimer()
                } else {
                    strongSelf.checkOutputState()
                }
            }
        }
    }
    
    // MARK: - Start the phone number scanning task.
    private func startScanPhoneTask(_ image: UIImage) {
        let visionImage = VisionImage(image: image)
        let recognizer = TextRecognizer.textRecognizer(options: TextRecognizerOptions.init())
        var text: Text?
        weak var weakSelf = self
        do {
            text = try recognizer.results(in: visionImage)
        } catch let error {
            debugPrint("Failed to scan texts with error: \(error.localizedDescription).")
            return
        }
        guard let strongSelf = weakSelf else {
            debugPrint("Self is nil!")
            return
        }
        if let text = text {
            var texts = Array<String>()
            for block in text.blocks {
                for line in block.lines {
                    let text = enhanceNumberText(line.text).filter(\.isNumber)
                    if (!text.isEmpty) {
                        texts.append(text)
                    }
                }
            }
            let phones = checkPhoneText(texts)
            if (!phones.isEmpty) {
                strongSelf.resultModel?.phone.append(contentsOf: phones)
                strongSelf.phoneSuccess = strongSelf.resultModel?.phone.isEmpty == false
                // Delayed check after 600ms.
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                    strongSelf.checkOutputState()
                }
            }
        }
    }
    
    // MARK: - Init the timeout timer and check the output result.
    private func setScanTimer() {
        DispatchQueue.main.asyncAfter(deadline: .now() + ScanConfig.scanTimeOutDuration) {
            self.timeOut = true
            self.checkOutputState()
        }
    }
    
    // MARK: - A scanning queue has finished.
    private func scanEnd() {
        scanningType = .wait
        resultModel = nil
        codeSuccess = false
        phoneSuccess = false
        timeOut = false
        createTimer = false
    }
    
    // MARK: - deinit
    // view 释放时关闭 session
    deinit {
        debugPrint("deinit")
        sessionPause()
        session = nil
    }
    
    // MARK: - Close scan device capture.
    public func closeScanView() {
        debugPrint("close")
        let _ = toggleFlashlight(enable: false)
        sessionPause()
        session = nil
    }
}

extension ScanView: AVCaptureVideoDataOutputSampleBufferDelegate {
    static var scanCountMargin = 0
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if scanningType == .wait {
            return
        }
        ScanView.scanCountMargin += 1
        if ScanView.scanCountMargin != 5 {
            return
        }
        ScanView.scanCountMargin = 0
        DispatchQueue.global().async {
            self.startScanTask(sampleBuffer)
        }
    }
}
