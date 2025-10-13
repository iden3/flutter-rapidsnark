import Flutter
import UIKit

import rapidsnark

let channelName = "com.rapidsnark.flutter_rapidsnark"

public class FlutterRapidsnarkPlugin: NSObject, FlutterPlugin {
    // Concurrent queue to allow multiple native proving operations to run in parallel
    private let workQueue = DispatchQueue(label: "com.rapidsnark.flutter_rapidsnark.proving", qos: .userInitiated, attributes: .concurrent)

    public static func register(with registrar: FlutterPluginRegistrar) {
        let messenger = registrar.messenger()
        let codec = FlutterStandardMethodCodec.sharedInstance()
        // We still provide a background task queue so initial message handling is off the main thread,
        // but heavy work is further dispatched onto our own concurrent queue to enable parallelism.
        let taskQueue = messenger.makeBackgroundTaskQueue?()
        let channel = FlutterMethodChannel(name: channelName, binaryMessenger: messenger, codec: codec, taskQueue: taskQueue)
        let instance = FlutterRapidsnarkPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "groth16Prove":
            callGroth16Prove(call: call, result: result)
        case "groth16PublicBufferSize":
            callGroth16PublicBufferSize(call: call, result: result)
        case "groth16Verify":
            callGroth16Verify(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func extractArguments(_ call: FlutterMethodCall) -> [String: Any]? {
        return call.arguments as? [String: Any]
    }

    private func callGroth16Prove(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = extractArguments(call) else {
            result(FlutterError(code: "groth16Prove", message: "Invalid arguments (not a map)", details: nil))
            return
        }
        guard let zkeyPath = args["zkeyPath"] as? String else {
            result(FlutterError(code: "groth16Prove", message: "Missing zkeyPath", details: nil))
            return
        }
        guard let witnessData = (args["witness"] as? FlutterStandardTypedData)?.data else {
            result(FlutterError(code: "groth16Prove", message: "Missing witness", details: nil))
            return
        }
        guard let proofBufferSize = (args["proofBufferSize"] as? NSNumber)?.intValue else {
            result(FlutterError(code: "groth16Prove", message: "Missing proofBufferSize", details: nil))
            return
        }
        let publicBufferSize = (args["publicBufferSize"] as? NSNumber)?.intValue // optional
        guard let errorBufferSize = (args["errorBufferSize"] as? NSNumber)?.intValue else {
            result(FlutterError(code: "groth16Prove", message: "Missing errorBufferSize", details: nil))
            return
        }

        // Dispatch onto concurrent queue so multiple calls can run in parallel when invoked from Flutter (e.g. Future.wait)
        workQueue.async {
            do {
                let proof = try groth16Prove(
                    zkeyPath: zkeyPath,
                    witness: witnessData,
                    proofBufferSize: proofBufferSize,
                    publicBufferSize: publicBufferSize,
                    errorBufferSize: errorBufferSize
                )

                // Return result (MethodChannel is thread-safe for calling the result closure from background threads)
                result([
                    "proof": proof.proof,
                    "publicSignals": proof.publicSignals
                ])
            } catch let error as RapidsnarkProverError {
                result(FlutterError(code: "groth16Prove", message: error.message, details: nil))
            } catch let error {
                result(FlutterError(code: "groth16Prove", message: "Unknown error", details: error.localizedDescription))
            }
        }
    }

    private func callGroth16PublicBufferSize(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = extractArguments(call) else {
            result(FlutterError(code: "groth16PublicSizeForZkeyFilePath", message: "Invalid arguments (not a map)", details: nil))
            return
        }
        guard let zkeyPath = args["zkeyPath"] as? String else {
            result(FlutterError(code: "groth16PublicSizeForZkeyFilePath", message: "Missing zkeyPath", details: nil))
            return
        }
        guard let errorBufferSize = (args["errorBufferSize"] as? NSNumber)?.intValue else {
            result(FlutterError(code: "groth16PublicSizeForZkeyFilePath", message: "Missing errorBufferSize", details: nil))
            return
        }

        workQueue.async {
            do {
                let publicSize = try groth16PublicBufferSize(
                    zkeyPath: zkeyPath,
                    errorBufferSize: errorBufferSize
                )
                result(publicSize)
            } catch let error as RapidsnarkProverError {
                result(FlutterError(code: "groth16PublicSizeForZkeyFilePath", message: error.message, details: nil))
            } catch {
                result(FlutterError(code: "groth16PublicSizeForZkeyFilePath", message: "Unknown error", details: nil))
            }
        }
    }

    private func callGroth16Verify(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = extractArguments(call) else {
            result(FlutterError(code: "groth16Verify", message: "Invalid arguments (not a map)", details: nil))
            return
        }
        guard
            let proof = args["proof"] as? String,
            let inputs = args["inputs"] as? String,
            let verificationKey = args["verificationKey"] as? String
        else {
            result(FlutterError(code: "groth16Verify", message: "Missing proof / inputs / verificationKey", details: nil))
            return
        }

        workQueue.async {
            do {
                let isValid = try groth16Verify(
                    proof: proof.data(using: .utf8)!,
                    inputs: inputs.data(using: .utf8)!,
                    verificationKey: verificationKey.data(using: .utf8)!
                )
                result(isValid)
            } catch let error as RapidsnarkVerifierError {
                result(FlutterError(code: "groth16Verify", message: error.message, details: nil))
            } catch {
                result(FlutterError(code: "groth16Verify", message: "Unknown error", details: nil))
            }
        }
    }
}
