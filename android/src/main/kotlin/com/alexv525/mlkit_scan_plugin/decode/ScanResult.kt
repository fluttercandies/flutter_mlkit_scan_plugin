/*
 * Author: Alex (https://github.com/AlexV525)
 * Date: 2022/1/10 17:34
 */

package com.alexv525.mlkit_scan_plugin.decode

import com.alexv525.mlkit_scan_plugin.Constant

class ScanResult(var code: String? = null, var phone: LinkedHashSet<String> = linkedSetOf()) {
    private val isValid get() = !code.isNullOrBlank() || phone.isNotEmpty()
    val isCodeOnly get() = !code.isNullOrBlank() && phone.isEmpty()
    val isFullFilled get() = !code.isNullOrBlank() && phone.isNotEmpty()

    private fun obtainStateInt(scanType: Int): Int {
        return when {
            isCodeOnly && scanType == Constant.SCAN_TYPE_BARCODE_AND_MOBILE -> Constant.SCAN_RESULT_CODE_ONLY
            isValid -> Constant.SCAN_RESULT_SUCCEED
            else -> Constant.SCAN_RESULT_FAILED
        }
    }

    fun reset() {
        code = null
        phone.clear()
    }

    fun toMap(scanType: Int): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>("state" to obtainStateInt(scanType))
        if (!code.isNullOrEmpty()) {
            map["code"] = code
        }
        if (phone.isNotEmpty()) {
            map["phone"] = ArrayList<String>(phone)
        }
        return map
    }
}