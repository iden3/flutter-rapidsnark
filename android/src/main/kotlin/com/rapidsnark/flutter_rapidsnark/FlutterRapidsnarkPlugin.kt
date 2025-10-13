package com.rapidsnark.flutter_rapidsnark

import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.StandardMethodCodec
import io.iden3.rapidsnark.*
import java.util.concurrent.Executors
import android.os.Handler
import android.os.Looper

/** FlutterRapidsnarkPlugin */
class FlutterRapidsnarkPlugin : FlutterPlugin, MethodCallHandler {
    /// The MethodChannel that will the communication between Flutter and native Android
    ///
    /// This local reference serves to register the plugin with the Flutter Engine and unregister it
    /// when the Flutter Engine is detached from the Activity
    private lateinit var channel: MethodChannel

    // Executor to allow multiple proving / verifying operations to run concurrently
    private val executor = Executors.newFixedThreadPool(
        Runtime.getRuntime().availableProcessors().coerceAtLeast(2)
    )
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun onAttachedToEngine(flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
        val taskQueue = flutterPluginBinding.binaryMessenger.makeBackgroundTaskQueue()
        channel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "com.rapidsnark.flutter_rapidsnark",
            StandardMethodCodec.INSTANCE,
            taskQueue
        )
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "groth16Prove" -> callGroth16Prove(call, result)
            "groth16PublicBufferSize" -> callGroth16PublicBufferSize(call, result)
            "groth16Verify" -> callGroth16Verify(call, result)
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
        executor.shutdown()
    }

    // Helper to finish results safely on main thread
    private fun complete(result: Result, block: () -> Unit) {
        if (Looper.myLooper() == Looper.getMainLooper()) {
            block()
        } else {
            mainHandler.post { block() }
        }
    }

    private fun callGroth16Prove(call: MethodCall, result: Result) {
        val arguments = try {
            @Suppress("UNCHECKED_CAST")
            call.arguments<Map<String, Any?>>() ?: run {
                result.error("groth16Prove", "Arguments must be a map", null)
                return
            }
        } catch (e: Exception) {
            result.error("groth16Prove", "Invalid arguments type: ${e.message}", null)
            return
        }

        val zkeyPath = arguments["zkeyPath"] as? String
        val witnessBytes = arguments["witness"] as? ByteArray
        val proofBufferSize = (arguments["proofBufferSize"] as? Int)
        val publicBufferSize = (arguments["publicBufferSize"] as? Int?)
        val errorBufferSize = (arguments["errorBufferSize"] as? Int)

        if (zkeyPath == null) { result.error("groth16Prove", "Missing zkeyPath", null); return }
        if (witnessBytes == null) { result.error("groth16Prove", "Missing witness", null); return }
        if (proofBufferSize == null) { result.error("groth16Prove", "Missing proofBufferSize", null); return }
        if (errorBufferSize == null) { result.error("groth16Prove", "Missing errorBufferSize", null); return }

        // Dispatch heavy native call asynchronously to allow concurrency
        executor.execute {
            try {
                val proof = groth16Prove(
                    zkeyPath,
                    witnessBytes,
                    proofBufferSize,
                    publicBufferSize,
                    errorBufferSize,
                )
                complete(result) {
                    result.success(
                        mapOf(
                            "proof" to proof.proof,
                            "publicSignals" to proof.publicSignals
                        )
                    )
                }
            } catch (e: RapidsnarkProverError) {
                complete(result) { result.error("groth16Prove", e.message, null) }
            } catch (e: Exception) {
                complete(result) { result.error("groth16Prove", e.message, null) }
            }
        }
    }

    private fun callGroth16PublicBufferSize(call: MethodCall, result: Result) {
        val arguments = try {
            @Suppress("UNCHECKED_CAST")
            call.arguments<Map<String, Any?>>() ?: run {
                result.error("groth16PublicBufferSize", "Arguments must be a map", null)
                return
            }
        } catch (e: Exception) {
            result.error("groth16PublicBufferSize", "Invalid arguments type: ${e.message}", null)
            return
        }

        val zkeyPath = arguments["zkeyPath"] as? String
        val errorBufferSize = arguments["errorBufferSize"] as? Int

        if (zkeyPath == null) { result.error("groth16PublicBufferSize", "Missing zkeyPath", null); return }
        if (errorBufferSize == null) { result.error("groth16PublicBufferSize", "Missing errorBufferSize", null); return }

        executor.execute {
            try {
                val publicSize = groth16PublicBufferSize(
                    zkeyPath,
                    errorBufferSize,
                )
                complete(result) { result.success(publicSize) }
            } catch (e: RapidsnarkProverError) {
                complete(result) { result.error("groth16PublicBufferSize", e.message, null) }
            } catch (e: Exception) {
                complete(result) { result.error("groth16PublicBufferSize", e.message, null) }
            }
        }
    }

    private fun callGroth16Verify(call: MethodCall, result: Result) {
        val arguments = try {
            @Suppress("UNCHECKED_CAST")
            call.arguments<Map<String, Any?>>() ?: run {
                result.error("groth16Verify", "Arguments must be a map", null)
                return
            }
        } catch (e: Exception) {
            result.error("groth16Verify", "Invalid arguments type: ${e.message}", null)
            return
        }

        val proof = arguments["proof"] as? String
        val inputs = arguments["inputs"] as? String
        val verificationKey = arguments["verificationKey"] as? String
        val errorBufferSize = arguments["errorBufferSize"] as? Int

        if (proof == null || inputs == null || verificationKey == null) {
            result.error("groth16Verify", "Missing proof / inputs / verificationKey", null); return
        }
        if (errorBufferSize == null) { result.error("groth16Verify", "Missing errorBufferSize", null); return }

        executor.execute {
            try {
                val isValid = groth16Verify(
                    proof,
                    inputs,
                    verificationKey,
                    errorBufferSize,
                )
                complete(result) { result.success(isValid) }
            } catch (e: RapidsnarkVerifierError) {
                complete(result) { result.error("groth16Verify", e.message, null) }
            } catch (e: Exception) {
                complete(result) { result.error("groth16Verify", e.message, null) }
            }
        }
    }
}
