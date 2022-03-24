/*
 * Author: Alex (https://github.com/AlexV525)
 * Date: 2022/1/10 17:32
 */

package com.alexv525.mlkit_scan_plugin.vision.processor

import android.graphics.Bitmap
import com.google.mlkit.common.MlKitException
import com.alexv525.mlkit_scan_plugin.vision.FrameMetadata
import java.nio.ByteBuffer

/** An interface to process the images with different vision detectors and custom image models.  */
interface VisionImageProcessor {
    /** Processes a bitmap image.  */
    fun processBitmap(bitmap: Bitmap?, rotation: Int = 0)

    /** Processes ByteBuffer image data, e.g. used for Camera1 live preview case.  */
    @Throws(MlKitException::class)
    fun processByteBuffer(data: ByteBuffer?, frameMetadata: FrameMetadata?)

    /** Stops the underlying machine learning model and release resources.  */
    fun stop()
}