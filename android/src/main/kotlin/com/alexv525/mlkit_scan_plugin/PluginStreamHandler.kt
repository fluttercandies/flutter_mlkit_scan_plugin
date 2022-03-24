/*
 * Author: Alex (https://github.com/AlexV525)
 * Date: 1/18/21 8:49 PM
 */

package com.alexv525.mlkit_scan_plugin

import io.flutter.plugin.common.EventChannel

class PluginStreamHandler : EventChannel.StreamHandler {
    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        Shared.eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        Shared.eventSink = null
    }
}
