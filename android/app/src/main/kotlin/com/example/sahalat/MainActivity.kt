package com.example.sahalat

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.example.sahalat/unity_nav",
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "startArNavigation" -> {
                    val start = call.argument<String>("startNodeId")
                    val goal = call.argument<String>("goalNodeId")
                    if (start.isNullOrBlank() || goal.isNullOrBlank()) {
                        result.error("bad_args", "startNodeId and goalNodeId required", null)
                        return@setMethodCallHandler
                    }
                    val sent = sendUnitySimplePath(start.trim(), goal.trim())
                    result.success(sent)
                }
                "renderFlutterPath" -> {
                    val pathJson = call.argument<String>("pathJson")
                    if (pathJson.isNullOrBlank()) {
                        result.error("bad_args", "pathJson required", null)
                        return@setMethodCallHandler
                    }
                    val sent = sendUnityPathJson(pathJson.trim())
                    result.success(sent)
                }
                "openUnityAr" -> {
                    if (ContextCompat.checkSelfPermission(
                            this,
                            Manifest.permission.CAMERA,
                        ) != PackageManager.PERMISSION_GRANTED
                    ) {
                        Log.w(TAG, "openUnityAr blocked: CAMERA not granted")
                        result.error(
                            "camera_permission",
                            "Camera permission is required for AR",
                            null,
                        )
                        return@setMethodCallHandler
                    }
                    val pathJson = call.argument<String>("pathJson")
                    val start = call.argument<String>("startNodeId")
                    val goal = call.argument<String>("goalNodeId")
                    val simple =
                        if (pathJson.isNullOrBlank() && !start.isNullOrBlank() && !goal.isNullOrBlank()) {
                            "${start.trim()}|${goal.trim()}"
                        } else {
                            null
                        }
                    try {
                        UnityNavPending.prepareNavigation(pathJson?.trim(), simple)
                        val intent =
                            Intent(this, Class.forName("com.unity3d.player.UnityPlayerActivity"))
                        intent.addFlags(Intent.FLAG_ACTIVITY_REORDER_TO_FRONT)
                        startActivity(intent)
                        result.success(true)
                    } catch (_: ClassNotFoundException) {
                        Log.i(TAG, "UnityPlayerActivity not found — openUnityAr skipped")
                        result.success(false)
                    } catch (t: Throwable) {
                        Log.w(TAG, "openUnityAr failed: ${t.message}")
                        result.error("unity_launch", t.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    /**
     * Forwards route to Unity when `com.unity3d.player.UnityPlayer` is on the classpath
     * (Unity exported as Android library). GameObject must be named **FlutterBridge**.
     */
    private fun sendUnitySimplePath(startNodeId: String, goalNodeId: String): Boolean {
        val payload = "$startNodeId|$goalNodeId"
        return try {
            val unityPlayer = Class.forName("com.unity3d.player.UnityPlayer")
            val sendMessage = unityPlayer.getMethod(
                "UnitySendMessage",
                String::class.java,
                String::class.java,
                String::class.java,
            )
            sendMessage.invoke(null, "FlutterBridge", "ReceiveSimplePathMessage", payload)
            Log.i(TAG, "UnitySendMessage FlutterBridge.ReceiveSimplePathMessage($payload)")
            true
        } catch (_: ClassNotFoundException) {
            Log.i(TAG, "Unity not embedded — startArNavigation ignored ($payload)")
            false
        } catch (t: Throwable) {
            Log.w(TAG, "UnitySendMessage failed: ${t.message}")
            false
        }
    }

    /** Forwards Flutter-computed path JSON to [FlutterBridge.ReceivePathFromFlutter]. */
    private fun sendUnityPathJson(pathJson: String): Boolean {
        return try {
            val unityPlayer = Class.forName("com.unity3d.player.UnityPlayer")
            val sendMessage = unityPlayer.getMethod(
                "UnitySendMessage",
                String::class.java,
                String::class.java,
                String::class.java,
            )
            sendMessage.invoke(null, "FlutterBridge", "ReceivePathFromFlutter", pathJson)
            Log.i(TAG, "UnitySendMessage FlutterBridge.ReceivePathFromFlutter(len=${pathJson.length})")
            true
        } catch (_: ClassNotFoundException) {
            Log.i(TAG, "Unity not embedded — renderFlutterPath ignored")
            false
        } catch (t: Throwable) {
            Log.w(TAG, "UnitySendMessage ReceivePathFromFlutter failed: ${t.message}")
            false
        }
    }

    companion object {
        private const val TAG = "SahalatUnity"
    }
}
