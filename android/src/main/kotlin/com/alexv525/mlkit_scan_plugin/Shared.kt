package com.alexv525.mlkit_scan_plugin

import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.JSONMethodCodec
import io.flutter.plugin.common.MethodChannel
import java.util.concurrent.ArrayBlockingQueue
import java.util.concurrent.ThreadPoolExecutor
import java.util.concurrent.TimeUnit

object Shared {
    var scanChannel: MethodChannel? = null
    var eventSink: EventChannel.EventSink? = null
    val threadPool: ThreadPoolExecutor = ThreadPoolExecutor(
        8 + 3,
        1000,
        10,
        TimeUnit.SECONDS,
        ArrayBlockingQueue(8 + 3)
    )

    fun initChannels(messenger: BinaryMessenger, plugin: MLKitScanPlugin): ScanFactory {
        scanChannel =
            MethodChannel(messenger, Constant.METHOD_CHANNEL_NAME, JSONMethodCodec.INSTANCE).apply {
                setMethodCallHandler(plugin)
            }
        EventChannel(messenger, Constant.EVENT_CHANNEL_NAME).setStreamHandler(PluginStreamHandler())
        return ScanFactory(plugin)
    }
}
