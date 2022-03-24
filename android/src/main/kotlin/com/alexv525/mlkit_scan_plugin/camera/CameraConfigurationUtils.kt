package com.alexv525.mlkit_scan_plugin.camera

import android.hardware.Camera
import android.util.Log
import android.util.Size
import java.lang.IllegalStateException
import java.lang.StringBuilder
import kotlin.math.abs

/**
 * Utility methods for configuring the Android camera.
 *
 * @author Sean Owen
 */
object CameraConfigurationUtils {
    private const val TAG = "CameraConfiguration"
    private const val MIN_PREVIEW_PIXELS = 480 * 320 // normal screen

    fun findBestPreviewSizeValue(parameters: Camera.Parameters, screenResolution: Size): Size {
        val rawSupportedSizes = parameters.supportedPreviewSizes
        if (rawSupportedSizes == null) {
            Log.w(TAG, "Device returned no supported preview sizes; using default")
            val defaultSize = parameters.previewSize
                ?: throw IllegalStateException("Parameters contained no preview size!")
            return Size(defaultSize.width, defaultSize.height)
        }
        if (Log.isLoggable(TAG, Log.INFO)) {
            val previewSizesString = StringBuilder()
            for (size in rawSupportedSizes) {
                previewSizesString.append(size.width).append('x').append(size.height).append(' ')
            }
            Log.i(
                TAG,
                "Supported preview sizes: $previewSizesString"
            )
        }

//        double screenAspectRatio = screenResolution.x / (double) screenResolution.y;

        // Find a suitable size, with max resolution
//        int maxResolution = 0;
        var maxResPreviewSize: Camera.Size? = null
        var diff = Int.MAX_VALUE
        for (size in rawSupportedSizes) {
            val realWidth = size.width
            val realHeight = size.height
            val resolution = realWidth * realHeight
            if (resolution < MIN_PREVIEW_PIXELS) {
                continue
            }
            val isCandidatePortrait = realWidth < realHeight
            val maybeFlippedWidth = if (isCandidatePortrait) realHeight else realWidth
            val maybeFlippedHeight = if (isCandidatePortrait) realWidth else realHeight
            if (maybeFlippedWidth == screenResolution.width && maybeFlippedHeight == screenResolution.height) {
                val exactPoint = Size(realWidth, realHeight)
                Log.i(
                    TAG,
                    "Found preview size exactly matching screen size: $exactPoint"
                )
                return exactPoint
            }
            val newDiff =
                abs(maybeFlippedWidth - screenResolution.width) + abs(maybeFlippedHeight - screenResolution.height)
            if (newDiff < diff) {
                maxResPreviewSize = size
                diff = newDiff
            }
        }

        // If no exact match, use largest preview size.
        // This was not a great idea on older devices because of the additional computation needed.
        // We're likely to get here on newer Android 4+ devices, where the CPU is much more powerful.
        if (maxResPreviewSize != null) {
            return Size(maxResPreviewSize.width, maxResPreviewSize.height)
        }

        // If there is nothing at all suitable, return current preview size
        val defaultPreview = parameters.previewSize
            ?: throw IllegalStateException("Parameters contained no preview size!")
        val defaultSize = Size(defaultPreview.width, defaultPreview.height)
        Log.i(TAG, "No suitable preview sizes, using default: $defaultSize")
        return defaultSize
    }
}