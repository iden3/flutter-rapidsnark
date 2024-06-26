import 'dart:typed_data';

import 'flutter_rapidsnark_platform_interface.dart';

const DEFAULT_PROOF_BUFFER_SIZE = 1024;
const DEFAULT_ERROR_BUFFER_SIZE = 256;

class Rapidsnark {
  Future<({String proof, String publicSignals})> groth16Prove({
    required Uint8List zkey,
    required Uint8List witness,
    int proofBufferSize = DEFAULT_PROOF_BUFFER_SIZE,
    int? publicBufferSize,
    int errorBufferSize = DEFAULT_ERROR_BUFFER_SIZE,
  }) {
    return FlutterRapidsnarkPlatform.instance.groth16Prove(
      zkey: zkey,
      witness: witness,
      proofBufferSize: proofBufferSize,
      publicBufferSize: publicBufferSize,
      errorBufferSize: errorBufferSize,
    );
  }

  Future<({String proof, String publicSignals})> groth16ProveWithZKeyFilePath({
    required String zkeyPath,
    required Uint8List witness,
    int proofBufferSize = DEFAULT_PROOF_BUFFER_SIZE,
    int? publicBufferSize,
    int errorBufferSize = DEFAULT_ERROR_BUFFER_SIZE,
  }) {
    return FlutterRapidsnarkPlatform.instance.groth16ProveWithZKeyFilePath(
      zkeyPath: zkeyPath,
      witness: witness,
      proofBufferSize: proofBufferSize,
      publicBufferSize: publicBufferSize,
      errorBufferSize: errorBufferSize,
    );
  }

  Future<bool> groth16Verify({
    required String proof,
    required String inputs,
    required String verificationKey,
    int errorBufferSize = DEFAULT_ERROR_BUFFER_SIZE,
  }) {
    return FlutterRapidsnarkPlatform.instance.groth16Verify(
      proof: proof,
      inputs: inputs,
      verificationKey: verificationKey,
      errorBufferSize: errorBufferSize,
    );
  }

  Future<int> groth16PublicSizeForZkeyBuf({
    required Uint8List zkey,
    int errorBufferSize = DEFAULT_ERROR_BUFFER_SIZE,
  }) {
    return FlutterRapidsnarkPlatform.instance.groth16PublicSizeForZkeyBuf(
      zkey: zkey,
      errorBufferSize: errorBufferSize,
    );
  }

  Future<int> groth16PublicSizeForZkeyFile({
    required String zkeyPath,
    int errorBufferSize = DEFAULT_ERROR_BUFFER_SIZE,
  }) {
    return FlutterRapidsnarkPlatform.instance.groth16PublicSizeForZkeyFile(
      zkeyPath: zkeyPath,
      errorBufferSize: errorBufferSize,
    );
  }
}
