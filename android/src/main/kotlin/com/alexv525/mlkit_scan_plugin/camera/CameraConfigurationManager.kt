/*
 * Copyright (C) 2008 ZXing authors
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.alexv525.mlkit_scan_plugin.camera

import android.content.Context
import android.graphics.Rect
import android.hardware.Camera
import android.util.Log
import android.util.Size
import java.util.ArrayList

/**
 * 设置相机的参数信息，获取最佳的预览界面
 */
class CameraConfigurationManager {
    companion object {
        private const val TAG = "CameraConfiguration"
    }

    private var mContext: Context? = null
    private var mCameraResolution: Size? = null

    // 相机分辨率
    val cameraResolution: Size?
        get() = mCameraResolution

    fun setContext(context: Context?) {
        mContext = context
    }

    fun release() {
        mCameraResolution = null
        mContext = null
    }

    fun initFromCameraParameters(camera: Camera, screenResolution: Size) {
        // 需要判断摄像头是否支持缩放
        val parameters = camera.parameters
        if (parameters.maxNumFocusAreas > 0) {
            val focusAreas: MutableList<Camera.Area> = ArrayList()
            val focusRect = Rect(-900, -900, 900, 0)
            focusAreas.add(Camera.Area(focusRect, 1000))
            parameters.focusAreas = focusAreas
        }
        // 因为换成了竖屏显示，所以不替换屏幕宽高得出的预览图是变形的
        val screenResolutionForCamera = if (screenResolution.width < screenResolution.height) {
            Size(screenResolution.height, screenResolution.width)
        } else {
            Size(screenResolution.width, screenResolution.height)
        }
        mCameraResolution = CameraConfigurationUtils.findBestPreviewSizeValue(
            parameters,
            screenResolutionForCamera
        )
    }

    fun setDesiredCameraParameters(camera: Camera) {
        val parameters = camera.parameters
        if (parameters == null) {
            Log.w(
                TAG,
                "Device error: no camera parameters are available. " +
                        "Proceeding without configuration."
            )
            return
        }
        Log.i(TAG, "Initial camera parameters: " + parameters.flatten())
        parameters.setPreviewSize(mCameraResolution!!.width, mCameraResolution!!.height)
        camera.parameters = parameters
        val afterParameters = camera.parameters
        val afterSize = afterParameters.previewSize
        if (afterSize != null && (mCameraResolution?.width != afterSize.width || mCameraResolution?.height != afterSize.height)) {
            Log.w(
                TAG,
                "Camera said it supported preview size ${mCameraResolution?.width}x${mCameraResolution?.height}, " +
                        "but after setting it, preview size is ${afterSize.width}x${afterSize.height}"
            )
            mCameraResolution = Size(afterSize.width, afterSize.height)
        }

        /// 设置相机预览为竖屏
        camera.setDisplayOrientation(90)
    }

    fun toggleFlashlight(camera: Camera, enable: Boolean) {
        camera.parameters = camera.parameters?.apply {
            flashMode = if (enable) {
                Camera.Parameters.FLASH_MODE_TORCH
            } else {
                Camera.Parameters.FLASH_MODE_OFF
            }
        }
    }
}