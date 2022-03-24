package com.alexv525.mlkit_scan_plugin

import android.content.Context
import android.util.Size
import io.flutter.plugin.common.StandardMessageCodec
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.platform.PlatformViewFactory

class ScanFactory(
    private val plugin: MLKitScanPlugin
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {
    var view: ScanView? = null

    @Suppress("UNCHECKED_CAST")
    override fun create(context: Context, viewId: Int, args: Any?): PlatformView {
        if (view == null) {
            val sizeMap = args as HashMap<String, Int>?
            val size = if (sizeMap != null) Size(sizeMap["w"]!!, sizeMap["h"]!!) else null
            view = ScanView(plugin, size)
        }
        return view!!
    }
}
