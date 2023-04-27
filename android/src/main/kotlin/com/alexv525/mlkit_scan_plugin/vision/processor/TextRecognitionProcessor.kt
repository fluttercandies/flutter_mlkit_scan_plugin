/*
 * Author: Alex (https://github.com/AlexV525)
 * Date: 2022/1/10 17:32
 */

package com.alexv525.mlkit_scan_plugin.vision.processor

import com.google.android.gms.tasks.Task
import com.google.mlkit.vision.common.InputImage
import com.google.mlkit.vision.text.Text
import com.google.mlkit.vision.text.TextRecognition
import com.google.mlkit.vision.text.latin.TextRecognizerOptions

/** Processor for the text detector. */
class TextRecognitionProcessor(
    onSuccessUnit: ((results: Text) -> Unit)? = null,
    onFailureUnit: ((e: Exception) -> Unit)? = null,
    imageMaxWidth: Int = 0,
    imageMaxHeight: Int = 0
) : VisionProcessorBase<Text>(onSuccessUnit, onFailureUnit, imageMaxWidth, imageMaxHeight) {
    private val textRecognizer = TextRecognition.getClient(TextRecognizerOptions.DEFAULT_OPTIONS)

    override fun stop() {
        super.stop()
        textRecognizer.close()
    }

    override fun detectInImage(image: InputImage): Task<Text> {
        return textRecognizer.process(image)
    }
}