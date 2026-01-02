import 'dart:io';

import 'package:circom_witnesscalc/circom_witnesscalc.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:flutter_rapidsnark/flutter_rapidsnark.dart';
import 'package:path_provider/path_provider.dart';

const zkeyAssetPath = 'assets/authV2.zkey';
const inputsAssetPath = 'assets/authV2_inputs.json';
const wcdAssetPath = 'assets/authV2.wcd';
const vkAssetPath = 'assets/authV2_verification_key.json';

void main() async {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late String zkeyPath;
  late String verificationKey;
  late Uint8List witness;

  setUpAll(() async {
    final zkey = (await rootBundle.load(zkeyAssetPath)).buffer.asUint8List();
    final inputs = await rootBundle.loadString(inputsAssetPath);
    final witnessGraph = (await rootBundle.load(wcdAssetPath)).buffer.asUint8List();
    verificationKey = await rootBundle.loadString(vkAssetPath);

    zkeyPath = await _copyZkeyToTempDir(zkey);

    witness = (await CircomWitnesscalc().calculateWitness(
      inputs: inputs,
      graphData: witnessGraph.buffer.asUint8List(),
    ))!;
  });

  tearDownAll(() async {
    final file = File(zkeyPath);
    if (file.existsSync()) {
      await file.delete();
    }
  });

  testWidgets('Prove and verify test', (tester) async {
    final Rapidsnark plugin = Rapidsnark();
    final proof = await plugin.groth16Prove(
      zkeyPath: zkeyPath,
      witness: witness,
    );

    expect(proof.proof, isNotEmpty);
    expect(proof.publicSignals, isNotEmpty);

    final verify = await plugin.groth16Verify(
      proof: proof.proof,
      inputs: proof.publicSignals,
      verificationKey: verificationKey,
    );

    expect(verify, isTrue);
  });

  testWidgets("Test public buffer size calc from file path", (tester) async {
    final Rapidsnark plugin = Rapidsnark();
    final publicSize =
        await plugin.groth16PublicBufferSize(zkeyPath: zkeyPath);

    expect(publicSize, isNot(0));
  });
}

Future<String> _copyZkeyToTempDir(Uint8List zkey) async {
  final tempDir = await getTemporaryDirectory();
  final zkeyPath = '${tempDir.path}/authV2.zkey';
  final file = File(zkeyPath);
  if (file.existsSync()) {
    await file.delete();
  }
  await file.writeAsBytes(zkey);
  return zkeyPath;
}
