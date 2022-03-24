/*
 * Author: Alex (https://github.com/AlexV525)
 * Date: 2022/1/10 17:32
 */

package com.alexv525.mlkit_scan_plugin.vision.processor

import com.google.android.gms.tasks.Task
import com.google.mlkit.vision.barcode.BarcodeScanner
import com.google.mlkit.vision.barcode.BarcodeScannerOptions
import com.google.mlkit.vision.barcode.BarcodeScanning
import com.google.mlkit.vision.barcode.common.Barcode
import com.google.mlkit.vision.common.InputImage

/** Processor for the barcode detector. */
class BarcodeScannerProcessor(
    formats: IntArray? = null,
    onSuccessUnit: ((results: List<Barcode>) -> Unit)? = null,
    onFailureUnit: ((e: Exception) -> Unit)? = null
) : VisionProcessorBase<List<Barcode>>(onSuccessUnit, onFailureUnit) {
    private val barcodeScanner: BarcodeScanner = when {
        formats == null || formats.isEmpty() -> BarcodeScanning.getClient()
        formats.size == 1 -> BarcodeScanning.getClient(
            BarcodeScannerOptions.Builder()
                .setBarcodeFormats(formats.first())
                .build()
        )
        else -> BarcodeScanning.getClient(
            BarcodeScannerOptions.Builder()
                .setBarcodeFormats(formats.first(), *formats)
                .build()
        )
    }

    override fun stop() {
        super.stop()
        barcodeScanner.close()
    }

    override fun detectInImage(image: InputImage): Task<List<Barcode>> {
        return barcodeScanner.process(image)
    }
}