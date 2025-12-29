import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:circom_witnesscalc/circom_witnesscalc.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
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
  late String _zkeyPath;
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

  final _flutterRapidsnarkPlugin = Rapidsnark();

  @override
  void initState() {
    super.initState();
    inputs.then((inputs) => _inputs = inputs);
    _copyZkeyToFs();
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
                  withData: true,
                  onFileSelected: (file) {
                    setState(() {
                      _inputsName = file.name;
                      _inputs = utf8.decode(file.bytes!);
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
                  // Not supported for some reason now
                  // allowedExtension: 'zkey',
                  onFileSelected: (file) async {
                    final tempDir = await getTemporaryDirectory();

                    final tempFile = File('${tempDir.path}/${file.xFile.name}');

                    await file.xFile.saveTo(tempFile.path);
                    setState(() {
                      _zkeyName = file.xFile.name;
                      _zkeyPath = tempFile.path;
                    });
                  },
                  onReset: () async {
                    setState(() {
                      _zkeyName = 'authV2.zkey';
                    });
                  },
                ),

                /// Witness graph data
                _FileSelectionSection(
                  fileTypeName: 'witness graph',
                  fileName: _witnessGraphDataName,
                  withReadStream: true,
                  // Not supported for some reason now
                  // allowedExtension: 'wcd',
                  onFileSelected: (file) async {
                    file.xFile.readAsBytes().then((bytes) {
                      setState(() {
                        _witnessGraphDataName = file.name;
                        _witnessGraphData = bytes;
                      });
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
                  withData: true,
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
                  withData: true,
                  fileName: _witnessName ?? 'Generated during execution',
                  // Not supported for some reason now
                  // allowedExtension: 'wtns',
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
                ElevatedButton(
                  onPressed: () => _runProver(concurrent: true),
                  child: const Text('Run prover concurrently (5x)'),
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

    _zkeyPath = file.path;

    return data.buffer.asUint8List();
  }

  Future<Uint8List> get zkey async {
    final zkey =
        await DefaultAssetBundle.of(context).load('assets/authV2.zkey');
    return zkey.buffer.asUint8List();
  }

  Future<String> get zkeyPath async {
    final appDocDir = await getTemporaryDirectory();
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

  Future<void> _runProver({bool concurrent = false}) async {
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
        Uint8List? generatedWitness;

        try {
          generatedWitness = await CircomWitnesscalc().calculateWitness(
            inputs: _inputs,
            graphData: _witnessGraphData,
          );
        } catch (e) {
          print(e);
        }

        if (generatedWitness == null) {
          setState(() {
            _error = 'Failed to calculate witness.';
          });
          return;
        }
        witness = generatedWitness;
      }

      final stopwatch = Stopwatch()..start();

      ProveResult proof;
      if (!concurrent) {
        proof = await _flutterRapidsnarkPlugin.groth16Prove(
          zkeyPath: _zkeyPath,
          witness: witness,
        );
      } else {
        final futures = <Future>[
          for (int i = 0; i < 5; i++)
            Future(() async {
              print(
                  'Starting proof generation $i at ${stopwatch.elapsedMilliseconds}');

              final proof = await _flutterRapidsnarkPlugin.groth16Prove(
                zkeyPath: _zkeyPath,
                witness: witness,
              );
              print(
                  'Proof generation $i completed at ${stopwatch.elapsedMilliseconds}');
              return proof;
            }).catchError((error) {
              print('Error in proof generation $i: $error');
              throw error;
            }),
        ];

        final results = await Future.wait(futures);
        proof = results[0];
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
  final String? allowedExtension;
  final bool withData;
  final bool withReadStream;

  const _FileSelectionSection({
    required this.fileTypeName,
    required this.fileName,
    required this.onFileSelected,
    required this.onReset,
    this.allowedExtension,
    this.withData = false,
    this.withReadStream = false,
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
                FilePicker.platform
                    .pickFiles(
                  type:
                      allowedExtension != null ? FileType.custom : FileType.any,
                  allowedExtensions:
                      allowedExtension != null ? [allowedExtension!] : null,
                  withData: withData,
                  withReadStream: withReadStream,
                )
                    .then((result) {
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
