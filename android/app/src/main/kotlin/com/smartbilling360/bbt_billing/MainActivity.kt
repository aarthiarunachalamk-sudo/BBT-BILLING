package com.smartbilling360.bbt_billing

import android.content.ContentValues
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val invoiceChannel = "com.smartbilling360.bbt_billing/invoices"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, invoiceChannel)
            .setMethodCallHandler { call, result ->
                if (call.method != "saveInvoicePdf") {
                    result.notImplemented()
                    return@setMethodCallHandler
                }
                val bytes = call.argument<ByteArray>("bytes")
                val fileName = call.argument<String>("fileName")
                if (bytes == null || fileName.isNullOrBlank()) {
                    result.error("invalid_arguments", "PDF bytes and a filename are required.", null)
                    return@setMethodCallHandler
                }
                try {
                    val savedPath = savePdfToDownloads(fileName, bytes)
                    result.success(savedPath)
                } catch (error: Exception) {
                    result.error("save_failed", error.message, null)
                }
            }
    }

    private fun savePdfToDownloads(fileName: String, bytes: ByteArray): String {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, "application/pdf")
                put(MediaStore.Downloads.RELATIVE_PATH, "${Environment.DIRECTORY_DOWNLOADS}/BBT Billing")
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val resolver = contentResolver
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: error("Unable to create the invoice download.")
            resolver.openOutputStream(uri)?.use { it.write(bytes) }
                ?: error("Unable to write the invoice PDF.")
            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return "Downloads/BBT Billing/$fileName"
        }

        val directory = File(Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS), "BBT Billing")
        if (!directory.exists() && !directory.mkdirs()) error("Unable to create the downloads folder.")
        val file = File(directory, fileName)
        FileOutputStream(file).use { it.write(bytes) }
        return file.absolutePath
    }
}
