/*
 * Author: Alex (https://github.com/AlexV525)
 * Date: 2022/1/10 17:32
 */

package com.alexv525.mlkit_scan_plugin.vision.processor

import android.graphics.Bitmap
import android.os.SystemClock
import android.util.Log
import android.util.Pair
import androidx.annotation.CallSuper
import androidx.annotation.GuardedBy
import com.google.android.gms.tasks.Task
import com.google.android.gms.tasks.Tasks
import com.google.android.odml.image.MlImage
import com.google.mlkit.common.MlKitException
import com.google.mlkit.vision.common.InputImage
import com.alexv525.mlkit_scan_plugin.Shared
import com.alexv525.mlkit_scan_plugin.vision.FrameMetadata
import com.alexv525.mlkit_scan_plugin.vision.ScopedExecutor
import java.nio.ByteBuffer
import java.util.Timer
import java.util.TimerTask

/*
 * Abstract base class for ML Kit frame processors. Subclasses need to implement {@link
 * #onSuccess(T, FrameMetadata, GraphicOverlay)} to define what they want to with the detection
 * results and {@link #detectInImage(VisionImage)} to specify the detector object.
 *
 * @param <T> The type of the detected feature.
 */
abstract class VisionProcessorBase<T>(
    private val onSuccessUnit: ((results: T) -> Unit)? = null,
    private val onFailureUnit: ((e: Exception) -> Unit)? = null,
    private var imageMaxWidth: Int = 0,
    private var imageMaxHeight: Int = 0
) : VisionImageProcessor {
    companion object {
        private const val TAG = "VisionProcessorBase"
    }

    private val fpsTimer = Timer()
    private val executor = ScopedExecutor { command -> Shared.threadPool.execute(command) }

    // Whether this processor is already shut down
    private var isShutdown = false

    // Used to calculate latency, running in the same thread, no sync needed.
    private var numRuns = 0
    private var totalFrameMs = 0L
    private var maxFrameMs = 0L
    private var minFrameMs = Long.MAX_VALUE
    private var totalDetectorMs = 0L
    private var maxDetectorMs = 0L
    private var minDetectorMs = Long.MAX_VALUE

    // Frame count that have been processed so far in an one second interval to calculate FPS.
    private var frameProcessedInOneSecondInterval = 0
    private var framesPerSecond = 0

    // To keep the latest images and its metadata.
    @GuardedBy("this")
    private var latestImage: ByteBuffer? = null

    @GuardedBy("this")
    private var latestImageMetaData: FrameMetadata? = null

    // To keep the images and metadata in process.
    @GuardedBy("this")
    private var processingImage: ByteBuffer? = null

    @GuardedBy("this")
    private var processingMetaData: FrameMetadata? = null

    init {
        fpsTimer.scheduleAtFixedRate(
            object : TimerTask() {
                override fun run() {
                    framesPerSecond = frameProcessedInOneSecondInterval
                    frameProcessedInOneSecondInterval = 0
                }
            },
            0,
            1000
        )
    }

    // Code for processing single still image
    override fun processBitmap(bitmap: Bitmap?, rotation: Int) {
        bitmap!!
        val frameStartMs = SystemClock.elapsedRealtime()

        val resizedBitmap = if (imageMaxWidth != 0 && imageMaxHeight != 0) {
            if (bitmap.width <= imageMaxWidth && bitmap.height <= imageMaxHeight) bitmap else {
                // Get the dimensions of the image view.
                val targetedSize: Pair<Int, Int> = Pair(imageMaxWidth, imageMaxHeight)
                // Determine how much to scale down the image.
                val scaleFactor = (bitmap.width.toFloat() / targetedSize.first.toFloat()).coerceAtLeast(
                    bitmap.height.toFloat() / targetedSize.second.toFloat()
                )
                Bitmap.createScaledBitmap(
                    bitmap,
                    (bitmap.width / scaleFactor).toInt(),
                    (bitmap.height / scaleFactor).toInt(),
                    true
                )
            }
        } else bitmap
        requestDetectInImage(
            InputImage.fromBitmap(resizedBitmap!!, rotation),
            frameStartMs
        )
    }

    // Code for processing live preview frame from Camera1 API
    @Synchronized
    override fun processByteBuffer(data: ByteBuffer?, frameMetadata: FrameMetadata?) {
        latestImage = data
        latestImageMetaData = frameMetadata
        if (processingImage == null && processingMetaData == null) {
            processLatestImage()
        }
    }

    @Synchronized
    private fun processLatestImage() {
        processingImage = latestImage
        processingMetaData = latestImageMetaData
        latestImage = null
        latestImageMetaData = null
        if (processingImage != null && processingMetaData != null && !isShutdown) {
            processImage(processingImage!!, processingMetaData!!)
        }
    }

    private fun processImage(data: ByteBuffer, frameMetadata: FrameMetadata) {
        val frameStartMs = SystemClock.elapsedRealtime()

        requestDetectInImage(
            InputImage.fromByteBuffer(
                data,
                frameMetadata.width,
                frameMetadata.height,
                frameMetadata.rotation,
                InputImage.IMAGE_FORMAT_NV21
            ),
            frameStartMs
        ).addOnSuccessListener(executor) { processLatestImage() }
    }

    // Common processing logic
    private fun requestDetectInImage(image: InputImage, frameStartMs: Long): Task<T> {
        return setUpListener(detectInImage(image), frameStartMs)
    }

    private fun requestDetectInImage(image: MlImage, frameStartMs: Long): Task<T> {
        return setUpListener(
            detectInImage(image),
            frameStartMs
        )
    }

    private fun setUpListener(task: Task<T>, frameStartMs: Long): Task<T> {
        val detectorStartMs = SystemClock.elapsedRealtime()
        return task.addOnSuccessListener(executor) { results: T ->
            val endMs = SystemClock.elapsedRealtime()
            val currentFrameLatencyMs = endMs - frameStartMs
            val currentDetectorLatencyMs = endMs - detectorStartMs
            if (numRuns >= 500) {
                resetLatencyStats()
            }
            numRuns++
            frameProcessedInOneSecondInterval++
            totalFrameMs += currentFrameLatencyMs
            maxFrameMs = currentFrameLatencyMs.coerceAtLeast(maxFrameMs)
            minFrameMs = currentFrameLatencyMs.coerceAtMost(minFrameMs)
            totalDetectorMs += currentDetectorLatencyMs
            maxDetectorMs = currentDetectorLatencyMs.coerceAtLeast(maxDetectorMs)
            minDetectorMs = currentDetectorLatencyMs.coerceAtMost(minDetectorMs)

            // Only log inference info once per second. When frameProcessedInOneSecondInterval is
            // equal to 1, it means this is the first frame processed during the current second.
//            if (frameProcessedInOneSecondInterval == 1) {
//                Log.d(TAG, "Num of Runs: $numRuns")
//                Log.d(
//                    TAG,
//                    "Frame latency: max=" +
//                            maxFrameMs +
//                            ", min=" +
//                            minFrameMs +
//                            ", avg=" +
//                            totalFrameMs / numRuns
//                )
//                Log.d(
//                    TAG,
//                    "Detector latency: max=" +
//                            maxDetectorMs +
//                            ", min=" +
//                            minDetectorMs +
//                            ", avg=" +
//                            totalDetectorMs / numRuns
//                )
//            }
            this@VisionProcessorBase.onSuccess(results)
        }.addOnFailureListener(executor) { e: Exception ->
            val error = "Failed to process. Error: " + e.localizedMessage
            Log.e(TAG, error)
            e.printStackTrace()
            this@VisionProcessorBase.onFailure(e)
        }
    }

    override fun stop() {
        executor.shutdown()
        isShutdown = true
        resetLatencyStats()
        fpsTimer.cancel()
    }

    private fun resetLatencyStats() {
        numRuns = 0
        totalFrameMs = 0
        maxFrameMs = 0
        minFrameMs = Long.MAX_VALUE
        totalDetectorMs = 0
        maxDetectorMs = 0
        minDetectorMs = Long.MAX_VALUE
    }

    protected abstract fun detectInImage(image: InputImage): Task<T>

    protected open fun detectInImage(image: MlImage): Task<T> {
        return Tasks.forException(
            MlKitException(
                "MlImage is currently not demonstrated for this feature",
                MlKitException.INVALID_ARGUMENT
            )
        )
    }

    @CallSuper
    protected open fun onSuccess(results: T) {
        onSuccessUnit?.invoke(results)
    }

    @CallSuper
    protected open fun onFailure(e: Exception) {
        onFailureUnit?.invoke(e)
    }
}