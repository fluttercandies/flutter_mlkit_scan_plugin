package com.alexv525.mlkit_scan_plugin

import android.content.pm.ApplicationInfo
import android.graphics.Color
import android.graphics.Rect
import android.graphics.SurfaceTexture
import android.util.Size
import android.view.Gravity
import android.view.TextureView
import android.view.View
import android.widget.FrameLayout
import android.widget.RelativeLayout
import com.alexv525.mlkit_scan_plugin.camera.AutoFitTextureView
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import java.io.IOException

class ScanView(
    private val mPlugin: MLKitScanPlugin,
    private val size: Size?
) : PlatformView, TextureView.SurfaceTextureListener {
    private val context get() = mPlugin.context!!
    private var mLayout: FrameLayout = FrameLayout(context).apply {
        setBackgroundColor(Color.TRANSPARENT)
        keepScreenOn = true
    }
    private var mTextureView: TextureView? = null
    private var mRectView: View? = null
    private var result: MethodChannel.Result? = null

    override fun getView(): FrameLayout {
        if (mLayout.parent != null) {
            mLayout = FrameLayout(context).apply {
                setBackgroundColor(Color.TRANSPARENT)
                keepScreenOn = true
            }
        }
        return mLayout
    }

    override fun dispose() {
        mTextureView?.surfaceTextureListener = null
        mLayout.removeAllViews()
        mTextureView = null
        mRectView = null
        result = null
        mPlugin.viewFactory?.view = null // Deallocate the view itself.
    }

    /// Called everytime when we initialize the view or resumed from the background.
    override fun onSurfaceTextureAvailable(surface: SurfaceTexture, width: Int, height: Int) {
        try {
            result?.success(null)
            mPlugin.mCamera?.setPreviewTexture(surface)
            mPlugin.restartPreviewAndDecode()
        } catch (_: IOException) {
            // Something bad happened
        } finally {
            result = null
        }
    }

    override fun onSurfaceTextureSizeChanged(surface: SurfaceTexture, width: Int, height: Int) {
    }

    override fun onSurfaceTextureUpdated(surface: SurfaceTexture) {
    }

    override fun onSurfaceTextureDestroyed(surface: SurfaceTexture): Boolean {
        mTextureView = null
        return true
    }

    fun createTexture(result: MethodChannel.Result, resolution: Size) {
        this.result = result
        mTextureView = AutoFitTextureView(
            context,
            viewSize = size,
            resolution = Size(resolution.height, resolution.width)
        ).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT,
                Gravity.CENTER
            )
        }
        mTextureView?.surfaceTextureListener = this
        mLayout.apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
            addView(mTextureView)
        }
    }

    fun updateRectView(rect: Rect) {
        // Only update in debug mode.
        if (context.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE == 0) {
            return
        }
        mRectView.apply {
            mLayout.removeView(this)
        }
        mRectView = View(context).apply {
            layoutParams = RelativeLayout.LayoutParams(rect.width(), rect.height())
            x = rect.left.toFloat()
            y = rect.top.toFloat()
            setBackgroundColor(Color.parseColor("#33f0f986"))
            mLayout.addView(this)
        }
    }
}