package com.alexv525.mlkit_scan_plugin

import android.app.Activity
import android.graphics.Rect
import android.hardware.Camera
import android.net.Uri
import android.util.Size
import com.alexv525.mlkit_scan_plugin.Extension.dp2px
import com.alexv525.mlkit_scan_plugin.camera.CameraConfigurationManager
import com.alexv525.mlkit_scan_plugin.decode.Decoder
import com.alexv525.mlkit_scan_plugin.decode.PreviewCallback
import com.google.mlkit.vision.common.InputImage
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.JSONUtil
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import org.json.JSONObject
import org.json.JSONTokener
import java.io.File

class MLKitScanPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private var mContext: Activity? = null
    val context: Activity? get() = mContext

    var mCamera: Camera? = null
    private var mDecoder: Decoder? = null

    private var mIsDecoding = true
    val isDecoding: Boolean get() = mIsDecoding

    var scanType = Constant.SCAN_TYPE_WAIT
    private var mPreviewing = false

    private var mLastFocusTime: Long = System.currentTimeMillis()
    private var useAutoFocus = false
    private val focusMode = arrayListOf(
        Camera.Parameters.FOCUS_MODE_AUTO, Camera.Parameters.FOCUS_MODE_MACRO
    )

    private var mConfigManager: CameraConfigurationManager? = null
    private var mInitialized = false
    private var mPreviewCallback: PreviewCallback? = null
    val cropRect: Rect get() = mRect
    private lateinit var mRect: Rect
    private lateinit var screenSize: Size
    var viewFactory: ScanFactory? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        viewFactory = Shared.initChannels(binding.binaryMessenger, this).apply {
            binding.platformViewRegistry.registerViewFactory(Constant.VIEW_TYPE_ID, this)
        }
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        mContext = binding.activity
        setScreenSize()
        initCamera()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        mContext = binding.activity
        setScreenSize()
        initCamera()
    }

    override fun onDetachedFromActivityForConfigChanges() {
        mContext = null
        destroyCamera()
    }

    override fun onDetachedFromActivity() {
        mContext = null
        destroyCamera()
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        viewFactory = null
        Shared.scanChannel?.setMethodCallHandler(null)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            Constant.METHOD_LOAD_SCAN_VIEW -> {
                loadScanView(result)
            }
            Constant.METHOD_SWITCH_SCAN_TYPE -> {
                val arguments = call.arguments as HashMap<*, *>
                switchScanType(arguments)
                result.success(null)
            }
            Constant.METHOD_STOP_SCAN -> {
                quitScan()
                result.success(null)
            }
            Constant.METHOD_REFOCUS -> { // 聚焦并重新识别
                mIsDecoding = true
                restartPreviewAndDecode()
                result.success(null)
            }
            Constant.METHOD_OPEN_FLASHLIGHT -> {
                if (mCamera == null || mConfigManager == null) {
                    result.error(
                        "STATE_ERROR", "Camera seems not being initialized.", null
                    )
                    return
                }
                mCamera?.apply {
                    mConfigManager?.toggleFlashlight(this, true)
                }
                result.success(null)
            }
            Constant.METHOD_CLOSE_FLASHLIGHT -> {
                if (mCamera == null || mConfigManager == null) {
                    result.error(
                        "STATE_ERROR", "Camera seems not being initialized.", null
                    )
                    return
                }
                mCamera?.apply {
                    mConfigManager?.toggleFlashlight(this, false)
                }
                result.success(null)
            }
            Constant.METHOD_REQUEST_WAKE_LOCK -> {
                requestWakeLock(call)
                result.success(null)
            }
            Constant.METHOD_RESUME_SCAN -> {
                resumeScan(result)
            }
            Constant.METHOD_PAUSE_SCAN -> {
                pauseScan()
                result.success(null)
            }
            Constant.METHOD_SCAN_FROM_FILE -> {
                context?.apply {
                    val path = call.argument<String>("path")
                    val formats = call.argument<List<Int>>("formats")
                    val client = formats?.run {
                        val length = this.size
                        val array = IntArray(length)
                        for (i in 0 until length) {
                            array[i] = this[i]
                        }
                        array
                    }.getBarcodeScanner()
                    val task =
                        client.process(InputImage.fromFilePath(this, Uri.fromFile(File(path))))
                    task.addOnSuccessListener {
                        client.close()
                        val list = it.fold(mutableListOf<Map<String, Any?>>()) { d, b ->
                            if (!b.displayValue.isNullOrBlank()) {
                                d.add(
                                    mapOf(
                                        "value" to b.displayValue,
                                        "boundingBox" to b.boundingBox?.run {
                                            mapOf(
                                                "left" to left,
                                                "top" to top,
                                                "width" to width(),
                                                "height" to height(),
                                            )
                                        },
                                    )
                                )
                            }
                            d
                        }
                        result.success(list)
                    }
                    task.addOnFailureListener {
                        client.close()
                        result.error("-1", it.message, it)
                    }
                } ?: result.error("-3", "unmounted", null)
            }
            else -> {
                result.notImplemented()
            }
        }

    }

    private fun initCamera() {
        mConfigManager = CameraConfigurationManager().apply {
            setContext(mContext)
            mPreviewCallback = PreviewCallback(this,
                onPreviewFrame = { data, frameMetadata -> mDecoder?.decode(data, frameMetadata) })
        }
    }

    private fun destroyCamera() {
        pauseScan()
        mCamera?.stopPreview()
        mCamera = null
        mConfigManager?.release()
        mConfigManager = null
        mInitialized = false
        mPreviewCallback = null
    }

    private fun openCamera(): Boolean {
        if (mCamera == null) {
            return try {
                mCamera = Camera.open()
                mCamera?.apply {
                    val cameraInfo = Camera.CameraInfo()
                    Camera.getCameraInfo(obtainCameraId(), cameraInfo)
                    mPreviewCallback?.setRotation(cameraInfo.orientation % 360)
                    // setParameters 是针对魅族 MX5 做的。
                    // MX5 通过 Camera.open() 拿到的 Camera 对象不为 null。
                    val mParameters = parameters
                    parameters = mParameters
                    useAutoFocus = focusMode.contains(parameters.focusMode)
                    if (!mInitialized) {
                        mInitialized = true
                        mConfigManager?.initFromCameraParameters(this, screenSize)
                    }
                    mConfigManager?.setDesiredCameraParameters(this)
                    setOneShotPreviewCallback(mPreviewCallback)
                    return true
                }
                false
            } catch (e: Exception) {
                e.printStackTrace()
                false
            }
        }
        return false
    }

    private fun obtainCameraId(): Int {
        val cameraInfo = Camera.CameraInfo()
        for (i in 0 until Camera.getNumberOfCameras()) {
            Camera.getCameraInfo(i, cameraInfo)
            if (cameraInfo.facing == Camera.CameraInfo.CAMERA_FACING_BACK) {
                return i
            }
        }
        return -1
    }

    private fun closeCamera(): Boolean {
        if (mCamera == null) {
            return false
        }
        return try {
            mCamera?.release()
            mInitialized = false
            mPreviewing = false
            mCamera = null
            true
        } catch (e: Exception) {
            e.printStackTrace()
            false
        }
    }

    // 手动暂停或者切换到后台
    private fun pauseScan() {
        mIsDecoding = false
        try {
            mCamera?.apply {
                mConfigManager?.toggleFlashlight(this, false)
            }
            mDecoder?.destroy()
            mDecoder = null
            stopPreview()
            closeCamera()
        } catch (e: Exception) {
            e.printStackTrace()
            // 关闭摄像头失败的情况下，最好退出该 Activity，否则下次初始化的时候会显示摄像头已占用。
        }
    }

    private fun resumeScan(result: MethodChannel.Result) {
        try {
            mIsDecoding = true
            openCamera()
            mDecoder = Decoder(this)
            mConfigManager?.cameraResolution?.apply {
                viewFactory?.view?.createTexture(result, this)
            }
            startPreview()
            requestWakeLock(true)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // 恢复扫描，切换到前台，或者点击聚焦
    fun restartPreviewAndDecode() {
        requestAutoFocus()
        requestPreviewFrame()
        requestWakeLock(true)
    }

    // 请求自动聚焦
    private fun requestAutoFocus() {
        mCamera?.apply {
            val currentTime = System.currentTimeMillis()
            if (currentTime - mLastFocusTime < Constant.FOCUS_INTERVAL) {
                return
            }
            mLastFocusTime = currentTime
            if (mPreviewing && useAutoFocus) {
                try {
                    autoFocus(null)
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
    }

    private fun startPreview(): Boolean {
        mCamera?.apply {
            if (!mPreviewing) {
                try {
                    startPreview()
                    mPreviewing = true
                    return true
                } catch (e: Exception) {
                    e.printStackTrace()
                }
            }
        }
        return false
    }

    private fun stopPreview(): Boolean {
        if (!mPreviewing) {
            return false
        }
        mCamera?.apply {
            return try {
                // 停止预览时把callback移除.
                setOneShotPreviewCallback(null)
                stopPreview()
                mPreviewing = false
                true
            } catch (e: Exception) {
                e.printStackTrace()
                false
            }
        }
        return false
    }

    private fun requestPreviewFrame() {
        mCamera?.apply {
            if (mPreviewing) {
                setOneShotPreviewCallback(mPreviewCallback)
            }
        }
    }

    private fun loadScanView(result: MethodChannel.Result) {
        resumeScan(result)
    }

    private fun switchScanType(map: HashMap<*, *>) {
        val type = map["type"] as Int
        val rect = map["rect"] as List<*>?
        when (type) {
            Constant.SCAN_TYPE_WAIT -> {
                mIsDecoding = false
            }
            else -> {
                mIsDecoding = true
                rect?.apply {
                    val l = (this[0] as Double).toInt().dp2px(mContext!!)
                    val t = (this[1] as Double).toInt().dp2px(mContext!!)
                    val r = l + (this[2] as Double).toInt().dp2px(mContext!!)
                    val b = t + (this[3] as Double).toInt().dp2px(mContext!!)
                    mRect = Rect(l, t, r, b)
                    viewFactory?.view?.updateRectView(mRect)
                }
                scanType = type
                restartPreviewAndDecode()
            }
        }
    }

    private fun quitScan() {
        Shared.eventSink?.endOfStream()
        pauseScan()
    }

    private fun requestWakeLock(call: MethodCall) {
        (call.arguments as Boolean?)?.let {
            requestWakeLock(it)
        }
    }

    private fun requestWakeLock(value: Boolean) {
        viewFactory?.view?.view?.keepScreenOn = value
    }

    private fun setScreenSize() {
        screenSize = Extension.getScreenSize(mContext!!)
        mRect = Rect(
            0,
            0,
            screenSize.width, screenSize.height,
        )
    }
}
