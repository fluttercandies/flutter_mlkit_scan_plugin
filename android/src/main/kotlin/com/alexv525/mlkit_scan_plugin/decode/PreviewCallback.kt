/*
 * Author: Alex (https://github.com/AlexV525)
 * Date: 2022/1/11 13:32
 */

package com.alexv525.mlkit_scan_plugin.decode

import android.hardware.Camera
import android.util.Size
import com.alexv525.mlkit_scan_plugin.camera.CameraConfigurationManager
import com.alexv525.mlkit_scan_plugin.vision.FrameMetadata

internal class PreviewCallback(
    private val mConfigManager: CameraConfigurationManager,
    private val onPreviewFrame: ((data: ByteArray, frameMetadata: FrameMetadata) -> Unit)? = null
) : Camera.PreviewCallback {
    private var cameraRotation: Int = 90

    override fun onPreviewFrame(data: ByteArray, camera: Camera) {
        val size: Size = mConfigManager.cameraResolution ?: return
        onPreviewFrame?.invoke(data, FrameMetadata(size, cameraRotation))
    }

    fun setRotation(rotation: Int) {
        this.cameraRotation = rotation
    }
}