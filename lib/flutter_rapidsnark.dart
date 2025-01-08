import 'dart:typed_data';

import 'flutter_rapidsnark_platform_interface.dart';
import 'model.dart';

export 'model.dart';

const _defaultProofBufferSize = 1024;
const _defaultErrorBufferSize = 256;

class Rapidsnark {
  Future<ProveResult> groth16Prove({
    required String zkeyPath,
    required Uint8List witness,
    int proofBufferSize = _defaultProofBufferSize,
    int? publicBufferSize,
    int errorBufferSize = _defaultErrorBufferSize,
  }) {
    return FlutterRapidsnarkPlatform.instance.groth16Prove(
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
    int errorBufferSize = _defaultErrorBufferSize,
  }) {
    return FlutterRapidsnarkPlatform.instance.groth16Verify(
      proof: proof,
      inputs: inputs,
      verificationKey: verificationKey,
      errorBufferSize: errorBufferSize,
    );
  }

  Future<int> groth16PublicBufferSize({
    required String zkeyPath,
    int errorBufferSize = _defaultErrorBufferSize,
  }) {
    return FlutterRapidsnarkPlatform.instance.groth16PublicBufferSize(
      zkeyPath: zkeyPath,
      errorBufferSize: errorBufferSize,
    );
  }
}
