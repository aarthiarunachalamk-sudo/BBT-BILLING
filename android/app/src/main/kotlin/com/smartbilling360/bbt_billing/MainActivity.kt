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
                when (call.method) {
                    "saveInvoicePdf" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val fileName = call.argument<String>("fileName")
                        if (bytes == null || fileName.isNullOrBlank()) {
                            result.error("invalid_arguments", "PDF bytes and a filename are required.", null)
                            return@setMethodCallHandler
                        }
                        try {
                            result.success(savePublicFile(fileName, bytes, "application/pdf", false))
                        } catch (error: Exception) {
                            result.error("save_failed", error.message, null)
                        }
                    }
                    "saveReportFile" -> {
                        val bytes = call.argument<ByteArray>("bytes")
                        val fileName = call.argument<String>("fileName")
                        val mimeType = call.argument<String>("mimeType")
                        val gallery = call.argument<Boolean>("gallery") ?: false
                        if (bytes == null || fileName.isNullOrBlank() || mimeType.isNullOrBlank()) {
                            result.error("invalid_arguments", "Report bytes, filename and MIME type are required.", null)
                            return@setMethodCallHandler
                        }
                        try {
                            result.success(savePublicFile(fileName, bytes, mimeType, gallery))
                        } catch (error: Exception) {
                            result.error("save_failed", error.message, null)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    private fun savePublicFile(
        fileName: String,
        bytes: ByteArray,
        mimeType: String,
        gallery: Boolean
    ): String {
        val publicDirectory = if (gallery) Environment.DIRECTORY_PICTURES else Environment.DIRECTORY_DOWNLOADS
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.MediaColumns.MIME_TYPE, mimeType)
                put(MediaStore.MediaColumns.RELATIVE_PATH, "$publicDirectory/BBT Billing")
                put(MediaStore.MediaColumns.IS_PENDING, 1)
            }
            val resolver = contentResolver
            val collection = if (gallery) {
                MediaStore.Images.Media.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            } else {
                MediaStore.Downloads.getContentUri(MediaStore.VOLUME_EXTERNAL_PRIMARY)
            }
            val uri = resolver.insert(collection, values)
                ?: error("Unable to create the report file.")
            resolver.openOutputStream(uri)?.use { it.write(bytes) }
                ?: error("Unable to write the report file.")
            values.clear()
            values.put(MediaStore.MediaColumns.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return "$publicDirectory/BBT Billing/$fileName"
        }

        val directory = File(Environment.getExternalStoragePublicDirectory(publicDirectory), "BBT Billing")
        if (!directory.exists() && !directory.mkdirs()) error("Unable to create the report folder.")
        val file = File(directory, fileName)
        FileOutputStream(file).use { it.write(bytes) }
        return file.absolutePath
    }
}
