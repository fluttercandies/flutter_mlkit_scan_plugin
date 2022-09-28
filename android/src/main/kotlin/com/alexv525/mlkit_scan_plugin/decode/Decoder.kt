/*
 * Author: Alex (https://github.com/AlexV525)
 * Date: 2022/1/10 17:32
 */

package com.alexv525.mlkit_scan_plugin.decode

import android.graphics.Bitmap
import android.graphics.Matrix
import android.os.Handler
import android.os.Looper
import android.renderscript.*
import com.alexv525.mlkit_scan_plugin.Constant
import com.alexv525.mlkit_scan_plugin.MLKitScanPlugin
import com.alexv525.mlkit_scan_plugin.Shared
import com.alexv525.mlkit_scan_plugin.runInBackground
import com.alexv525.mlkit_scan_plugin.vision.FrameMetadata
import com.alexv525.mlkit_scan_plugin.vision.processor.BarcodeScannerProcessor
import com.alexv525.mlkit_scan_plugin.vision.processor.TextRecognitionProcessor
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.text.Text
import java.lang.ref.WeakReference

class Decoder(private val mScanPlugin: MLKitScanPlugin) {
    private val weakSelf = WeakReference(this)
    private val weakDecoder: Decoder? get() = weakSelf.get()

    private enum class State { PREVIEW, SUCCESS, DONE }

    private var mLastDecodeTime: Long = System.currentTimeMillis()
    private var mState: State = State.PREVIEW
    private var mScanResult = ScanResult()

    private val scanType get() = mScanPlugin.scanType
    private val isScanningMobile
        get() = scanType == Constant.SCAN_TYPE_BARCODE_AND_MOBILE
                || scanType == Constant.SCAN_TYPE_MOBILE

    private val barcodeFormats: IntArray?
        get() = when (scanType) {
            Constant.SCAN_TYPE_BARCODE, Constant.SCAN_TYPE_BARCODE_AND_MOBILE -> intArrayOf(
                Barcode.FORMAT_CODE_39,
                Barcode.FORMAT_CODE_93,
                Barcode.FORMAT_CODE_128
            )
            Constant.SCAN_TYPE_GOODS_CODE -> intArrayOf(
                Barcode.FORMAT_EAN_8,
                Barcode.FORMAT_EAN_13,
                Barcode.FORMAT_UPC_A,
                Barcode.FORMAT_UPC_E
            )
            Constant.SCAN_TYPE_QR_CODE -> intArrayOf(Barcode.FORMAT_QR_CODE)
            else -> null
        }

    private fun runInMainThread(runnable: Runnable) {
        Handler(Looper.getMainLooper()).post(runnable)
    }

    fun decode(data: ByteArray, frameMetadata: FrameMetadata) {
        if (weakDecoder == null || mState == State.DONE || !mScanPlugin.isDecoding) {
            return
        }
        // Skip decoding too rapidly.
        val currentTime = System.currentTimeMillis()
        if (currentTime - mLastDecodeTime < Constant.DECODE_INTERVAL) {
            validateResult()
            return
        }
        mLastDecodeTime = currentTime
        runInBackground {
            if (scanType == Constant.SCAN_TYPE_WAIT) {
                return@runInBackground
            }
            val firstBitmap = makeMatrixBitmap(data, frameMetadata)
            val rect = mScanPlugin.cropRect
            val croppedBitmap = Bitmap.createBitmap(
                firstBitmap,
                rect.left,
                rect.top,
                rect.width().coerceAtMost(firstBitmap.width),
                rect.height().coerceAtMost(firstBitmap.height),
                null,
                false
            )
            firstBitmap.apply { if (!isRecycled) recycle() }
            // Decode barcodes when formats are valid and the code in the result is empty.
            barcodeFormats?.apply {
                if (mScanResult.code.isNullOrBlank()) {
                    BarcodeScannerProcessor(
                        formats = this,
                        onSuccessUnit = { handleBarcodes(it) }
                    ).processBitmap(croppedBitmap)
                }
            }
            // Recognize texts when the scan type is valid and the phone in the result is empty.
            if (isScanningMobile && mScanResult.phone.isEmpty()
            ) {
                TextRecognitionProcessor(
                    onSuccessUnit = { handleText(it) }
                ).processBitmap(croppedBitmap)
            }
        }
    }

    private fun validateResult() {
        // Skip validating when the reference has been cleaned.
        if (weakDecoder == null) {
            return
        }
        val predicate: Boolean = when (scanType) {
            Constant.SCAN_TYPE_BARCODE_AND_MOBILE -> mScanResult.isFullFilled || mScanResult.isCodeOnly
            Constant.SCAN_TYPE_MOBILE -> mScanResult.phone.isNotEmpty()
            Constant.SCAN_TYPE_BARCODE,
            Constant.SCAN_TYPE_QR_CODE,
            Constant.SCAN_TYPE_GOODS_CODE -> mScanResult.isCodeOnly
            else -> false
        }
        // Post delayed validation when scanning with the hybrid mode.
        if (scanType == Constant.SCAN_TYPE_BARCODE_AND_MOBILE && mScanResult.isCodeOnly) {
            Handler(Looper.getMainLooper()).postDelayed({
                weakDecoder?.validateResult()
            }, Constant.DECODE_INTERVAL * 5L)
            return
        }
        if (predicate) {
            val resultMap = mScanResult.toMap(scanType)
            mState = State.SUCCESS
            runInMainThread { Shared.eventSink?.success(resultMap) }
            mScanResult.reset()
            return
        }
        mScanPlugin.restartPreviewAndDecode()
    }

    private fun handleBarcodes(list: List<Barcode>) {
        val codes = list.fold(LinkedHashSet<String>()) { set, e ->
            set.apply set@{ e.displayValue?.apply { this@set.add(this) } }
        }
        if (codes.isNotEmpty()) {
            mScanResult.code = codes.first()
        }
        validateResult()
    }

    private fun handleText(text: Text) {
        val texts = text.textBlocks.fold(mutableListOf<String>()) { set, e ->
            set.apply {
                addAll(e.lines.fold(mutableListOf()) { set, e ->
                    // Save only digits.
                    set.apply { add(e.text.filter { it.isDigit() }) }
                })
            }
        }.filter { it.isNotEmpty() && it.length > 10 }
        mScanResult.phone.addAll(texts)
        Handler(Looper.getMainLooper()).postDelayed({
            weakDecoder?.validateResult()
        }, Constant.DECODE_INTERVAL * 2L)
    }

    fun destroy() {
        mState = State.DONE
        mScanResult.reset()
    }

    private fun makeMatrixBitmap(data: ByteArray, frameMetadata: FrameMetadata): Bitmap {
        val mWidth = frameMetadata.width
        val mHeight = frameMetadata.height
        val mRotation = frameMetadata.rotation.toFloat()
        val bitmap = Bitmap.createBitmap(mWidth, mHeight, Bitmap.Config.ARGB_8888)
        renderScriptNV21ToRGBA8888(mWidth, mHeight, data).apply {
            copyTo(bitmap)
            destroy()
        }
        val matrix = Matrix().apply { postRotate(mRotation) }
        val rotatedBitmap = Bitmap.createBitmap(
            bitmap, 0, 0, mWidth, mHeight,
            matrix, true
        )
        bitmap.apply { if (!isRecycled) recycle() }
        return rotatedBitmap
    }

    private fun renderScriptNV21ToRGBA8888(width: Int, height: Int, nv21: ByteArray): Allocation {
        val rs: RenderScript = RenderScript.create(mScanPlugin.context!!)
        val inAllocation = Allocation.createTyped(
            rs,
            Type.Builder(rs, Element.U8(rs)).setX(nv21.size).create(),
            Allocation.USAGE_SCRIPT
        )
        val outAllocation = Allocation.createTyped(
            rs,
            Type.Builder(rs, Element.RGBA_8888(rs)).setX(width).setY(height).create(),
            Allocation.USAGE_SCRIPT
        )
        inAllocation.copyFrom(nv21)
        ScriptIntrinsicYuvToRGB.create(rs, Element.U8_4(rs)).apply {
            setInput(inAllocation)
            forEach(outAllocation)
            destroy()
        }
        inAllocation.destroy()
        return outAllocation
    }
}