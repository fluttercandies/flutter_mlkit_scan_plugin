import Foundation

class ImageParser {
    var isProcessing: Bool = false
    
    func reScale(image: UIImage, maxSize: CGSize) -> UIImage {
        let scaleFactor = max(
            image.size.width / maxSize.width,
            image.size.height / maxSize.height
        )
        let newSize = CGSize(
            width: image.size.width / scaleFactor,
            height: image.size.height / scaleFactor
        )
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRectMake(0, 0, newSize.width, newSize.height))
        let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return newImage
    }
    
    /// 裁剪图片
    /// rect需要裁剪的图片相对于原图的范围
    func crop(image: UIImage, rect: CGRect) -> UIImage? {
        isProcessing = true
        guard let orientatedImage = fixOrientation(image) else {
            isProcessing = false
            return nil
        }
        let imageViewScale = max(
            orientatedImage.size.width / UIScreen.main.bounds.width,
            orientatedImage.size.height / UIScreen.main.bounds.height
        )
        let newRect = CGRect(
            x: rect.origin.x * imageViewScale,
            y: rect.origin.y * imageViewScale,
            width: rect.size.width * imageViewScale,
            height: rect.size.height * imageViewScale
        )
        guard let cgImage = orientatedImage.cgImage?.cropping(to: newRect) else {
            isProcessing = false
            return nil
        }
        let resultImage = UIImage(cgImage: cgImage)
        isProcessing = false
        return resultImage
    }
    
    func sampleBufferToImage(_ sampleBuffer: CMSampleBuffer) -> UIImage? {
        isProcessing = true
        // 转为CVImageBuffer
        guard let imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            isProcessing = false
            return nil
        }
        // 地址空间上锁
        CVPixelBufferLockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0))
        // 获取图片的内存信息
        // 内存指针
        let baseAddress = CVPixelBufferGetBaseAddress(imageBuffer)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer)
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        // 位图的配置信息，如Alpha等
        let bitmapInfo = CGBitmapInfo(
            rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue
        )
        // 获取上下文环境
        guard let context = CGContext(
            data: baseAddress,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: bitmapInfo.rawValue
        )
        else {
            isProcessing = false
            return nil
        }
        // 上下文转存CGImage
        guard let cgImage = context.makeImage() else {
            isProcessing = false
            return nil
        }
        // 解锁
        CVPixelBufferUnlockBaseAddress(imageBuffer, CVPixelBufferLockFlags(rawValue: 0));
        isProcessing = false
        // 返回Image数据
        return UIImage(
            cgImage: cgImage,
            scale: UIScreen.main.scale,
            orientation: imageOrientation(fromDevicePosition: .back)
        )
    }
    
    private func fixOrientation(_ image: UIImage) -> UIImage? {
        if image.imageOrientation == .up {
            return image
        }
        guard let cgImage = image.cgImage, let colorSpace = cgImage.colorSpace else {
            return nil
        }
        let size = image.size
        var transform = CGAffineTransform.identity
        switch image.imageOrientation {
        case .down, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: size.height)
            transform = transform.rotated(by: .pi)
            break
        case .left, .leftMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.rotated(by: .pi / 2)
            break
        case .right, .rightMirrored:
            transform = transform.translatedBy(x: 0, y: size.height)
            transform = transform.rotated(by: -.pi / 2)
            break
        default:
            break
        }
        switch image.imageOrientation {
        case .upMirrored, .downMirrored:
            transform = transform.translatedBy(x: size.width, y: 0)
            transform = transform.scaledBy(x: -1, y: 1)
            break
        case .leftMirrored, .rightMirrored:
            transform = transform.translatedBy(x: size.height, y: 0);
            transform = transform.scaledBy(x: -1, y: 1)
            break
        default:
            break
        }
        let context = CGContext(
            data: nil,
            width: Int(size.width),
            height: Int(size.height),
            bitsPerComponent: cgImage.bitsPerComponent,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: cgImage.bitmapInfo.rawValue
        )
        context?.concatenate(transform)
        switch image.imageOrientation {
        case .left, .leftMirrored, .right, .rightMirrored:
            context?.draw(
                image.cgImage!,
                in: CGRect(
                    x: CGFloat(0),
                    y: CGFloat(0),
                    width: CGFloat(size.height),
                    height: CGFloat(size.width)
                )
            )
            break
        default:
            context?.draw(
                image.cgImage!,
                in: CGRect(
                    x: CGFloat(0),
                    y: CGFloat(0),
                    width: CGFloat(size.width),
                    height: CGFloat(size.height)
                )
            )
            break
        }
        guard let fixedCGImage = context?.makeImage() else { return nil }
        let resultImage = UIImage(cgImage: fixedCGImage)
        return resultImage
    }
}
