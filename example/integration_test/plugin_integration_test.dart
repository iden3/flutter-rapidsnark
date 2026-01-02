import 'dart:io';

import 'package:circom_witnesscalc/circom_witnesscalc.dart';
import 'package:flutter/foundation.dart';
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

  // Setup artifacts before tests
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

  // Clean up temporary zkey file after tests
  tearDownAll(() async {
    final file = File(zkeyPath);
    if (file.existsSync()) {
      await file.delete();
    }
  });

  testWidgets('Prove and verify test', (tester) async {
    debugPrint('Prove and verify test -- start');
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
    debugPrint('Prove and verify test -- end\n');
  });

  testWidgets("Test public buffer size calc from file path", (tester) async {
    debugPrint("Test public buffer size calc from file path -- start");
    final Rapidsnark plugin = Rapidsnark();
    final publicSize =
        await plugin.groth16PublicBufferSize(zkeyPath: zkeyPath);

    expect(publicSize, isNot(0));
    debugPrint("Test public buffer size calc from file path -- end\n");
  });

  testWidgets('Generate 5 proofs sequentially', (tester) async {
    debugPrint("Generate 5 proofs sequentially -- start");
    final Rapidsnark plugin = Rapidsnark();

    final totalStopwatch = Stopwatch()..start();
    final proveTimes = <int>[];

    for (int i = 0; i < 5; i++) {
      final proveStopwatch = Stopwatch()..start();
      final proof = await plugin.groth16Prove(
        zkeyPath: zkeyPath,
        witness: witness,
      );
      proveStopwatch.stop();
      proveTimes.add(proveStopwatch.elapsedMilliseconds);

      expect(proof.proof, isNotEmpty);
      expect(proof.publicSignals, isNotEmpty);

      final isValid = await plugin.groth16Verify(
        proof: proof.proof,
        inputs: proof.publicSignals,
        verificationKey: verificationKey,
      );
      expect(isValid, isTrue);

      print('Proof ${i + 1}: ${proveStopwatch.elapsedMilliseconds}ms');
    }

    totalStopwatch.stop();
    print('Proof generation times: $proveTimes ms');
    print('Total time (with verification): ${totalStopwatch.elapsedMilliseconds}ms');
    debugPrint("Generate 5 proofs sequentially -- end\n");
  });

  testWidgets('Generate 5 proofs in parallel', (tester) async {
    debugPrint("Generate 5 proofs in parallel -- start");

    // Wait for CPU to cool down after sequentially test
    debugPrint("Waiting 10 seconds for CPU to cool down...");
    await Future.delayed(const Duration(seconds: 10));

    final Rapidsnark plugin = Rapidsnark();

    final stopwatch = Stopwatch()..start();

    final futures = List.generate(5, (i) async {
      final proof = await plugin.groth16Prove(
        zkeyPath: zkeyPath,
        witness: witness,
      );

      final isValid = await plugin.groth16Verify(
        proof: proof.proof,
        inputs: proof.publicSignals,
        verificationKey: verificationKey,
      );

      return (proof: proof, isValid: isValid);
    });

    final results = await Future.wait(futures);

    stopwatch.stop();

    for (int i = 0; i < results.length; i++) {
      expect(results[i].proof.proof, isNotEmpty);
      expect(results[i].proof.publicSignals, isNotEmpty);
      expect(results[i].isValid, isTrue);
    }

    final totalTime = stopwatch.elapsedMilliseconds;
    final avgTime = totalTime / 5;
    print('5 parallel proofs - Total: ${totalTime}ms, Average: ${avgTime.toStringAsFixed(1)}ms');
    debugPrint("Generate 5 proofs in parallel -- end\n");
  });

  testWidgets('Benchmark proof generation', (tester) async {
    debugPrint("Benchmark proof generation -- start");

    // Wait for CPU to cool down after parallel test
    debugPrint("Waiting 10 seconds for CPU to cool down...");
    await Future.delayed(const Duration(seconds: 10));

    final Rapidsnark plugin = Rapidsnark();

    const iterations = 10;

    print('=== Benchmark ($iterations iterations) ===');

    for (int i = 0; i < iterations; i++) {
      final stopwatch = Stopwatch()..start();
      final proof = await plugin.groth16Prove(
        zkeyPath: zkeyPath,
        witness: witness,
      );
      stopwatch.stop();

      final isValid = await plugin.groth16Verify(
        proof: proof.proof,
        inputs: proof.publicSignals,
        verificationKey: verificationKey,
      );
      expect(isValid, isTrue);

      print('Proof ${i + 1}: ${stopwatch.elapsedMilliseconds}ms');
    }
    debugPrint("Benchmark proof generation -- end \n");
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
