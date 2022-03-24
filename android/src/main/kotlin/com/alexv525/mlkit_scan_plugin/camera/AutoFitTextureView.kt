package com.alexv525.mlkit_scan_plugin.camera

import android.content.Context
import android.util.AttributeSet
import android.util.Size
import android.view.TextureView

/**
 * A [TextureView] that can be adjusted to a specified fitted size.
 */
open class AutoFitTextureView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyle: Int = 0,
    private val viewSize: Size?,
    private var resolution: Size?
) : TextureView(context, attrs, defStyle) {
    constructor(context: Context) : this(context, null, 0, null, null)

    companion object {
        private val zeroSize = Size(0, 0)
    }

    override fun getKeepScreenOn(): Boolean {
        return true
    }

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        super.onMeasure(widthMeasureSpec, heightMeasureSpec)
        val validSize = viewSize
            ?: getSize(
                MeasureSpec.getSize(widthMeasureSpec),
                MeasureSpec.getSize(heightMeasureSpec)
            )
        if (resolution == null || resolution == zeroSize) {
            setMeasuredDimension(validSize.width, validSize.height)
        } else {
            val fittedSize = coverFit(validSize, resolution!!)
            setMeasuredDimension(fittedSize.width, fittedSize.height)
        }
    }

    private fun getSize(width: Int, height: Int): Size {
        return Size(width, height)
    }

//    fun setOriginalResolution(size: Size) {
//        resolution = size
//        requestLayout()
//    }

    /**
     * Fit the size to cover the whole view according to the given size.
     *
     * @param inputSize The original size of the view.
     * @param outputSize The target size of the view.
     */
    private fun coverFit(inputSize: Size, outputSize: Size): Size {
        return if (outputSize.width / outputSize.height > inputSize.width / inputSize.height) {
            Size(inputSize.width, inputSize.width * outputSize.height / outputSize.width)
        } else {
            Size(inputSize.height * outputSize.width / outputSize.height, inputSize.height)
        }
    }
}
