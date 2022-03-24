package com.alexv525.mlkit_scan_plugin

import android.content.Context
import android.util.DisplayMetrics
import android.util.Size
import android.util.TypedValue
import android.view.WindowManager

object Extension {
    fun getScreenSize(context: Context): Size {
        return Size(getScreenWidth(context), getScreenHeight(context))
    }

    private fun getDisplayMetrics(context: Context): DisplayMetrics {
        val displayMetrics = DisplayMetrics()
        (context.getSystemService(Context.WINDOW_SERVICE) as WindowManager)
                .defaultDisplay
                .getRealMetrics(displayMetrics)
        return displayMetrics
    }

    fun getScreenWidth(context: Context): Int {
        return getDisplayMetrics(context).widthPixels
    }

    fun getScreenHeight(context: Context): Int {
        return getDisplayMetrics(context).heightPixels
    }

    fun Int.dp2px(context: Context): Int {
        return TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, this.toFloat(), context.resources.displayMetrics).toInt()
    }

    fun Double.dp2px(context: Context): Int {
        return TypedValue.applyDimension(TypedValue.COMPLEX_UNIT_DIP, this.toFloat(), context.resources.displayMetrics).toInt()
    }

    fun Int.px2dp(context: Context): Int {
        return (this / (getDisplayMetrics(context).density + 0.5f)).toInt()
    }
}