import 'dart:io';

import 'package:circom_witnesscalc/circom_witnesscalc.dart';
import 'package:file_picker/file_picker.dart';
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
  String _inputsName = 'authV2_inputs.json';
  late String _inputs;
  String _zkeyName = 'authV2.zkey';
  late Uint8List _zkey;
  String _witnessGraphDataName = 'authV2.wcd';
  late Uint8List _witnessGraphData;
  String _verificationKeyName = 'authV2_verification_key.json';
  late String _verificationKey;
  String? _witnessName;
  Uint8List? _witness;

  ProveResult? _proof;
  String? _error;
  String? _verificationResult;
  int _timestamp = 0;

  bool _bufferProverEnabled = false;

  final _flutterRapidsnarkPlugin = Rapidsnark();

  @override
  void initState() {
    super.initState();
    inputs.then((inputs) => _inputs = inputs);
    _copyZkeyToFs().then((zkey) => _zkey = zkey);
    witnessGraphData
        .then((witnessGraphData) => _witnessGraphData = witnessGraphData);
    verificationKey
        .then((verificationKey) => _verificationKey = verificationKey);
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
                /// Inputs
                _FileSelectionSection(
                  fileTypeName: 'inputs',
                  fileName: _inputsName,
                  allowedExtension: 'json',
                  onFileSelected: (file) {
                    setState(() {
                      _inputsName = file.name;
                      _inputs = file.bytes.toString();
                    });
                  },
                  onReset: () async {
                    _inputs = await inputs;
                    setState(() {
                      _inputsName = 'authV2_inputs.json';
                    });
                  },
                ),

                /// Circuit
                _FileSelectionSection(
                  fileTypeName: 'circuit',
                  fileName: _zkeyName,
                  allowedExtension: 'zkey',
                  onFileSelected: (file) {
                    setState(() {
                      _zkeyName = file.name;
                      _zkey = file.bytes!;
                    });
                  },
                  onReset: () async {
                    _zkey = await zkey;
                    setState(() {
                      _zkeyName = 'authV2.zkey';
                    });
                  },
                ),

                /// Witness graph data
                _FileSelectionSection(
                  fileTypeName: 'witness graph',
                  fileName: _witnessGraphDataName,
                  allowedExtension: 'wcd',
                  onFileSelected: (file) {
                    setState(() {
                      _witnessGraphDataName = file.name;
                      _witnessGraphData = file.bytes!;
                    });
                  },
                  onReset: () async {
                    _witnessGraphData = await witnessGraphData;
                    setState(() {
                      _witnessGraphDataName = 'authV2.wcd';
                    });
                  },
                ),

                /// Verification key
                _FileSelectionSection(
                  fileTypeName: 'verif key',
                  fileName: _verificationKeyName,
                  allowedExtension: 'json',
                  onFileSelected: (file) {
                    setState(() {
                      _verificationKeyName = file.name;
                      _verificationKey = file.bytes.toString();
                    });
                  },
                  onReset: () async {
                    _verificationKey = await verificationKey;
                    setState(() {
                      _verificationKeyName = 'authV2_verification_key.json';
                    });
                  },
                ),

                /// Witness
                _FileSelectionSection(
                  fileTypeName: 'witness',
                  fileName: _witnessName ?? 'Generated',
                  allowedExtension: 'wtns',
                  onFileSelected: (file) {
                    setState(() {
                      _witnessName = file.name;
                      _witness = file.bytes;
                    });
                  },
                  onReset: () async {
                    setState(() {
                      _witness = null;
                      _witnessName = null;
                    });
                  },
                ),

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
                Builder(
                  builder: (context) {
                    final proof = _proof;

                    final String displayText;

                    if (_error != null) {
                      displayText = 'Error: $_error';
                    } else if (proof != null) {
                      displayText =
                          'Proof: ${proof.proof}\nPublic signals: ${proof.publicSignals}\nGenerated in: ${_timestamp}ms';
                    } else {
                      displayText = '';
                    }

                    return SelectableText(
                      displayText,
                    );
                  },
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: _runProver,
                  child: const Text('Run prover'),
                ),
                const SizedBox(height: 8),
                Text(_verificationResult ?? ''),
                ElevatedButton(
                  onPressed: _runVerifier,
                  child: const Text('Run verifier'),
                ),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<Uint8List> _copyZkeyToFs() async {
    final file = File(await zkeyPath);
    ByteData data = await rootBundle.load("assets/authV2.zkey");

    if (!file.existsSync()) {
      await file.create();
      await file.writeAsBytes(data.buffer.asInt8List());
    }

    return data.buffer.asUint8List();
  }

  Future<Uint8List> get zkey async {
    final zkey =
        await DefaultAssetBundle.of(context).load('assets/authV2.zkey');
    return zkey.buffer.asUint8List();
  }

  Future<String> get zkeyPath async {
    final appDocDir = await getApplicationDocumentsDirectory();
    return "${appDocDir.path}/$_zkeyName";
  }

  Future<String> get inputs async {
    final verificationKey = await DefaultAssetBundle.of(context)
        .loadString('assets/authV2_inputs.json');
    return verificationKey;
  }

  Future<Uint8List> get witnessGraphData async {
    final witness =
        await DefaultAssetBundle.of(context).load('assets/authV2.wcd');
    return witness.buffer.asUint8List();
  }

  Future<String> get verificationKey async {
    final verificationKey = await DefaultAssetBundle.of(context)
        .loadString('assets/authV2_verification_key.json');
    return verificationKey;
  }

  Future<void> _runProver() async {
    setState(() {
      _error = null;
      _proof = null;
      _verificationResult = null;
    });

    try {
      final customWitness = _witness;

      final Uint8List witness;
      if (customWitness != null) {
        witness = customWitness;
      } else {
        final generatedWitness = await CircomWitnesscalc().calculateWitness(
          inputs: _inputs,
          graphData: _witnessGraphData,
        );

        if (generatedWitness == null) {
          setState(() {
            _error = 'Failed to calculate witness.';
          });
          return;
        }
        witness = generatedWitness;
      }

      final stopwatch = Stopwatch()..start();

      final ProveResult proof;

      if (_bufferProverEnabled) {
        proof = await _flutterRapidsnarkPlugin.groth16Prove(
          zkey: _zkey,
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

      setState(() {
        _proof = proof;
        _timestamp = stopwatch.elapsedMilliseconds;
      });
    } on Exception catch (e) {
      setState(() {
        _error = 'Failed to get proof.\n $e';
      });
    }

    if (!mounted) return;
  }

  Future<void> _runVerifier() async {
    try {
      final proof = _proof?.proof;
      final publicSignals = _proof?.publicSignals;
      if (proof == null || publicSignals == null) {
        setState(() {
          _error = 'Proof or public signals are null.';
        });
        return;
      }

      final proofValid = await _flutterRapidsnarkPlugin.groth16Verify(
        proof: proof,
        inputs: publicSignals,
        verificationKey: _verificationKey,
      );

      if (!mounted) return;

      setState(() {
        _verificationResult = 'Proof is valid: $proofValid\n';
      });
    } on Exception catch (e) {
      setState(() {
        _error = 'Failed to generate proof.\n $e';
      });
      return;
    }
  }
}

class _FileSelectionSection extends StatelessWidget {
  final String fileTypeName;
  final String fileName;
  final void Function(PlatformFile) onFileSelected;
  final void Function() onReset;
  final String allowedExtension;

  const _FileSelectionSection({
    required this.fileTypeName,
    required this.fileName,
    required this.onFileSelected,
    required this.onReset,
    required this.allowedExtension,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "${fileTypeName.capitalize()}: $fileName",
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            OutlinedButton(
              onPressed: () {
                FilePicker.platform.pickFiles(
                  type: FileType.custom,
                  allowedExtensions: [allowedExtension],
                ).then((result) {
                  if (result != null) {
                    onFileSelected(result.files.single);
                  }
                });
              },
              child: Text(
                'Select $fileTypeName',
              ),
            ),
            OutlinedButton(
              onPressed: () {
                onReset();
              },
              child: Text(
                'Reset $fileTypeName',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

extension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
