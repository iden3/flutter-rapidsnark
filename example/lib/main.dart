import 'dart:io';

import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_rapidsnark/flutter_rapidsnark.dart';
import 'package:path_provider/path_provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? _proof;
  String? _publicSignals;
  String _proveResult = '';
  String _verificationResult = '';
  bool _bufferProverEnabled = false;

  final _flutterRapidsnarkPlugin = Rapidsnark();

  @override
  void initState() {
    super.initState();
    _copyZkey();
  }

  void _copyZkey() async {
    final file = File(await zkeyPath);
    if (file.existsSync()) {
      return;
    }

    ByteData data = await rootBundle.load("assets/circuit_final.zkey");
    final bytes = data.buffer.asInt8List();

    await file.create();
    await file.writeAsBytes(bytes);
  }

  Future<Uint8List> get zkey async {
    final zkey =
        await DefaultAssetBundle.of(context).load('assets/circuit_final.zkey');
    return zkey.buffer.asUint8List();
  }

  Future<String> get zkeyPath async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return "${appDocDir.path}/circuit_final.zkey";
  }

  Future<Uint8List> get witness async {
    final witness =
        await DefaultAssetBundle.of(context).load('assets/witness.wtns');
    return witness.buffer.asUint8List();
  }

  Future<String> get verificationKey async {
    final verificationKey = await DefaultAssetBundle.of(context)
        .loadString('assets/verification_key.json');
    return verificationKey;
  }

  Future<void> _runProver() async {
    String result = "";
    try {
      final zkey = await this.zkey;
      final witness = await this.witness;

      final stopwatch = Stopwatch()..start();

      final ({String proof, String publicSignals}) proof;

      if (_bufferProverEnabled) {
        proof = await _flutterRapidsnarkPlugin.groth16Prove(
          zkey: zkey,
          witness: witness,
        );
      } else {
        final zkeyPath = await this.zkeyPath;
        proof = await _flutterRapidsnarkPlugin.groth16ProveWithZKeyFilePath(
          zkeyPath: zkeyPath,
          witness: witness,
        );
      }

      stopwatch.stop();

      _proof = proof.proof;
      _publicSignals = proof.publicSignals;

      result +=
          'Proof: ${proof.proof}\nPublic signals: ${proof.publicSignals}\nGenerated in: ${stopwatch.elapsedMilliseconds}ms';
    } on Exception catch (e) {
      result += 'Failed to get proof.\n $e';
    }

    if (!mounted) return;

    setState(() {
      _proveResult = result;
    });
  }

  Future<void> _runVerifier() async {
    String result = "";
    try {
      final proof = _proof;
      final publicSignals = _publicSignals;
      if (proof == null || publicSignals == null) {
        result += 'Proof is not generated yet.';
        return;
      }

      final verificationKey = await this.verificationKey;

      final proofValid = await _flutterRapidsnarkPlugin.groth16Verify(
        proof: proof,
        inputs: publicSignals,
        verificationKey: verificationKey,
      );

      result += 'Proof is valid: $proofValid\n';
    } on Exception catch (e) {
      result += 'Failed to get proof.\n $e';
    }

    if (!mounted) return;

    setState(() {
      _verificationResult = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 24),
                Row(
                  children: [
                    Switch(
                      value: _bufferProverEnabled,
                      onChanged: (value) {
                        setState(() {
                          _bufferProverEnabled = value;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    const Text('Enable buffer prover'),
                  ],
                ),
                SelectableText(_proveResult),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _runProver,
                  child: const Text('Run prover'),
                ),
                const SizedBox(height: 8),
                Text(_verificationResult),
                ElevatedButton(
                  onPressed: _runVerifier,
                  child: const Text('Run verifier'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
