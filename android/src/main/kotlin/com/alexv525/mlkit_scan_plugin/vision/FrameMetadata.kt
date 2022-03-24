/*
 * Author: Alex (https://github.com/AlexV525)
 * Date: 2022/1/10 17:32
 */

package com.alexv525.mlkit_scan_plugin.vision

import android.util.Size

/** Describing a frame info. */
class FrameMetadata(val width: Int = 0, val height: Int = 0, val rotation: Int = 0) {
    constructor(size: Size, rotation: Int = 0) : this(size.width, size.height, rotation)

    /** Builder of [FrameMetadata]. */
    class Builder {
        private var width = 0
        private var height = 0
        private var rotation = 0

        fun setWidth(width: Int): Builder {
            this.width = width
            return this
        }

        fun setHeight(height: Int): Builder {
            this.height = height
            return this
        }

        fun setRotation(rotation: Int): Builder {
            this.rotation = rotation
            return this
        }

        fun build(): FrameMetadata {
            return FrameMetadata(width, height)
        }
    }
}