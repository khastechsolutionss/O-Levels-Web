package com.oef.OLevel.papers

import android.os.Bundle
import android.webkit.WebView
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import com.google.android.gms.ads.MobileAds
import com.google.android.gms.ads.RequestConfiguration
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import android.util.Log
import java.util.concurrent.atomic.AtomicBoolean

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.olevel.ads/init"
    private val TAG = "MainActivity"
    private val isInitialized = AtomicBoolean(false)
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // CRITICAL: Pre-initialize WebView and MobileAds on background thread
        // This prevents the Flutter plugin from blocking the main thread
        CoroutineScope(Dispatchers.IO).launch {
            try {
                Log.d(TAG, "🚀 Starting background initialization...")
                
                // Step 1: Initialize WebView provider
                withContext(Dispatchers.Main) {
                    try {
                        val webView = WebView(applicationContext)
                        webView.destroy()
                        Log.d(TAG, "✅ WebView initialized")
                    } catch (e: Exception) {
                        Log.e(TAG, "⚠️ WebView init error: ${e.message}")
                    }
                }
                
                // Step 2: Initialize MobileAds SDK
                // This MUST happen before Flutter plugin tries to use it
                MobileAds.initialize(applicationContext) { status ->
                    Log.d(TAG, "✅ MobileAds initialized: ${status.adapterStatusMap}")
                    isInitialized.set(true)
                }
                
                // Step 3: Set request configuration on background thread
                // This prevents the plugin from calling it on main thread
                val requestConfig = RequestConfiguration.Builder()
                    .setTestDeviceIds(listOf("TEST_DEVICE_ID"))
                    .build()
                MobileAds.setRequestConfiguration(requestConfig)
                Log.d(TAG, "✅ Request configuration set")
                
            } catch (e: Exception) {
                Log.e(TAG, "❌ Background init error: ${e.message}", e)
            }
        }
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "initializeMobileAds" -> {
                    // Check if already initialized
                    if (isInitialized.get()) {
                        Log.d(TAG, "📱 MobileAds already initialized")
                        result.success(true)
                        return@setMethodCallHandler
                    }
                    
                    // Initialize on background thread if not done yet
                    CoroutineScope(Dispatchers.IO).launch {
                        try {
                            Log.d(TAG, "📱 Initializing MobileAds on background thread...")
                            MobileAds.initialize(applicationContext) { status ->
                                Log.d(TAG, "✅ MobileAds initialized: ${status.adapterStatusMap}")
                                isInitialized.set(true)
                                CoroutineScope(Dispatchers.Main).launch {
                                    result.success(true)
                                }
                            }
                        } catch (e: Exception) {
                            Log.e(TAG, "❌ MobileAds init error: ${e.message}")
                            withContext(Dispatchers.Main) {
                                result.error("INIT_ERROR", e.message, null)
                            }
                        }
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
}
