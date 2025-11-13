package com.example.smart_saver

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.os.Build
import android.provider.DocumentsContract
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.documentfile.provider.DocumentFile
import java.io.File
import java.io.FileOutputStream

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.smart_saver/folderPicker"
    private val REQUEST_CODE = 1234
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "pickFolder" -> {
                    pendingResult = result
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE)
                    intent.addFlags(Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION)
                    intent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    
                    // Try to find and open WhatsApp Status folder directly
                    val statusFolderUri = findWhatsAppStatusFolder()
                    if (statusFolderUri != null && Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                        // Android 11+ (API 30+) supports EXTRA_INITIAL_URI
                        intent.putExtra(DocumentsContract.EXTRA_INITIAL_URI, statusFolderUri)
                    }
                    
                    startActivityForResult(intent, REQUEST_CODE)
                }
                "listFiles" -> {
                    val uriStr = call.argument<String>("uri")
                    if (uriStr != null) {
                        try {
                            val uri = Uri.parse(uriStr)
                            val documentFile = DocumentFile.fromTreeUri(this, uri)
                            val fileNames = documentFile?.listFiles()
                                ?.filter { it.isFile && (it.name?.endsWith(".mp4") == true || 
                                          it.name?.endsWith(".jpg") == true || 
                                          it.name?.endsWith(".jpeg") == true ||
                                          it.name?.endsWith(".png") == true ||
                                          it.name?.endsWith(".gif") == true) }
                                ?.map { it.name ?: "" }
                                ?.filter { it.isNotEmpty() } ?: emptyList()
                            result.success(fileNames)
                        } catch (e: Exception) {
                            result.error("ERROR", "Failed to list files: ${e.message}", null)
                        }
                    } else {
                        result.error("NO_URI", "No folder URI provided", null)
                    }
                }
                "getFileUri" -> {
                    val folderUriStr = call.argument<String>("folderUri")
                    val fileName = call.argument<String>("fileName")
                    if (folderUriStr != null && fileName != null) {
                        try {
                            val folderUri = Uri.parse(folderUriStr)
                            val documentFile = DocumentFile.fromTreeUri(this, folderUri)
                            val file = documentFile?.listFiles()?.find { it.name == fileName }
                            result.success(file?.uri?.toString())
                        } catch (e: Exception) {
                            result.error("ERROR", "Failed to get file URI: ${e.message}", null)
                        }
                    } else {
                        result.error("INVALID_ARGS", "Invalid arguments", null)
                    }
                }
                "copyFileToTemp" -> {
                    val fileUriStr = call.argument<String>("fileUri")
                    if (fileUriStr != null) {
                        try {
                            val fileUri = Uri.parse(fileUriStr)
                            val documentFile = DocumentFile.fromSingleUri(this, fileUri)
                            val fileName = documentFile?.name ?: "temp_file"
                            
                            val tempFile = File(cacheDir, fileName)
                            contentResolver.openInputStream(fileUri)?.use { input ->
                                FileOutputStream(tempFile).use { output ->
                                    input.copyTo(output)
                                }
                            }
                            result.success(tempFile.absolutePath)
                        } catch (e: Exception) {
                            result.error("ERROR", "Failed to copy file: ${e.message}", null)
                        }
                    } else {
                        result.error("NO_URI", "No file URI provided", null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_CODE && resultCode == Activity.RESULT_OK) {
            val uri = data?.data
            if (uri != null) {
                try {
                    contentResolver.takePersistableUriPermission(
                        uri,
                        Intent.FLAG_GRANT_READ_URI_PERMISSION
                    )
                    pendingResult?.success(uri.toString())
                } catch (e: Exception) {
                    pendingResult?.error("ERROR", "Failed to persist permission: ${e.message}", null)
                }
                pendingResult = null
            } else {
                pendingResult?.error("NO_URI", "Folder not selected", null)
                pendingResult = null
            }
        } else if (requestCode == REQUEST_CODE) {
            pendingResult?.error("CANCELLED", "Folder selection cancelled", null)
            pendingResult = null
        }
    }

    /**
     * Finds the WhatsApp Status folder and returns its tree URI
     * Tries multiple common paths where WhatsApp stores statuses
     */
    private fun findWhatsAppStatusFolder(): Uri? {
        // Common WhatsApp status folder paths
        val possiblePaths = listOf(
            "/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses",
            "/storage/emulated/0/WhatsApp/Media/.Statuses",
            "/sdcard/Android/media/com.whatsapp/WhatsApp/Media/.Statuses",
            "/sdcard/WhatsApp/Media/.Statuses",
            "/storage/emulated/0/Android/data/com.whatsapp/files/WhatsApp/Media/.Statuses",
            // WhatsApp Business paths
            "/storage/emulated/0/Android/media/com.whatsapp.w4b/WhatsApp Business/Media/.Statuses",
            "/storage/emulated/0/WhatsApp Business/Media/.Statuses",
        )

        for (path in possiblePaths) {
            val folder = File(path)
            if (folder.exists() && folder.isDirectory) {
                try {
                    // Convert file path to content URI for Android 11+
                    val uri = getTreeUriFromPath(path)
                    if (uri != null) {
                        return uri
                    }
                } catch (e: Exception) {
                    // Continue to next path
                }
            }
        }
        return null
    }

    /**
     * Converts a file path to a content tree URI
     * This works on Android 11+ (API 30+) using EXTRA_INITIAL_URI
     */
    private fun getTreeUriFromPath(path: String): Uri? {
        return try {
            // For Android 11+ (API 30+), we can use EXTRA_INITIAL_URI
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
                // Build the proper content URI format
                // Format: content://com.android.externalstorage.documents/tree/primary%3AAndroid%2Fmedia%2Fcom.whatsapp%2FWhatsApp%2FMedia%2F.Statuses
                val relativePath = path
                    .replace("/storage/emulated/0/", "")
                    .replace("/sdcard/", "")
                    .replace("/", "%2F")
                
                Uri.parse("content://com.android.externalstorage.documents/tree/primary%3A$relativePath")
            } else {
                null
            }
        } catch (e: Exception) {
            null
        }
    }
}
