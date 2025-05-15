import Flutter
import UIKit

import rapidsnark

public class FlutterRapidsnarkPlugin: NSObject, FlutterPlugin {
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "flutter_rapidsnark", binaryMessenger: registrar.messenger())
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

    private func callGroth16Prove(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as! Dictionary<String, Any>

        let zkeyPath = args["zkeyPath"] as! String
        let witness = (args["witness"] as! FlutterStandardTypedData).data

        let proofBufferSize = (args["proofBufferSize"] as! NSNumber).intValue
        let publicBufferSize = (args["publicBufferSize"] as? NSNumber)?.intValue
        let errorBufferSize = (args["errorBufferSize"] as! NSNumber).intValue
        
        // Move the heavy computation to a background thread
        DispatchQueue.global(qos: .userInitiated).async {
            do {
                let proof = try groth16Prove(
                    zkeyPath: zkeyPath,
                    witness: witness,
                    proofBufferSize: proofBufferSize,
                    publicBufferSize: publicBufferSize,
                    errorBufferSize: errorBufferSize
                )
                
                // Return to main thread to deliver the result
                DispatchQueue.main.async {
                    result([
                        "proof": proof.proof,
                        "publicSignals": proof.publicSignals
                    ])
                }
            } catch let error as RapidsnarkProverError {
                // Return to main thread to deliver error
                DispatchQueue.main.async {
                    result(FlutterError(code: "groth16Prove", message: error.message, details: nil))
                }
            } catch let error {
                // Return to main thread to deliver error
                DispatchQueue.main.async {
                    result(FlutterError(code: "groth16Prove", message: "Unknown error", details: error.localizedDescription))
                }
            }
        }
    }

    private func callGroth16PublicBufferSize(call: FlutterMethodCall, result: FlutterResult) {
        let args = call.arguments as! Dictionary<String, Any>

        let zkeyPath = args["zkeyPath"] as! String

        let errorBufferSize = (args["errorBufferSize"] as! NSNumber).intValue

        do {
            let publicSize = try groth16PublicBufferSize(
                zkeyPath: zkeyPath,
                errorBufferSize: errorBufferSize
            )

            result(publicSize)
        } catch is RapidsnarkProverError {
            result(FlutterError(code: "groth16PublicSizeForZkeyFilePath", message: "Prover error", details: nil))
        } catch {
            result(FlutterError(code: "groth16PublicSizeForZkeyFilePath", message: "Unknown error", details: nil))
        }
    }

    private func callGroth16Verify(call: FlutterMethodCall, result: FlutterResult) {
        let args = call.arguments as! Dictionary<String, Any>

        let proof = args["proof"] as! String
        let inputs = args["inputs"] as! String
        let verificationKey = args["verificationKey"] as! String

        do {
            let isValid = try groth16Verify(
                proof: proof.data(using: .utf8)!,
                inputs: inputs.data(using: .utf8)!,
                verificationKey: verificationKey.data(using: .utf8)!
            )

            result(isValid)
        } catch {
            print("\(error)")
            result(FlutterError(code: "groth16Verify", message: "Unknown error", details: nil))
        }
    }
}
