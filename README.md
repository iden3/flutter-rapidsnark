# flutter_rapidsnark

---

This library is Flutter wrapper for the [Rapidsnark](https://github.com/iden3/rapidsnark). It enables the
generation of proofs for specified circuits within a Flutter environment.

## Platform Support

**iOS**: Compatible with any iOS device with 64 bit architecture.
> Version for emulator built without assembly optimizations, resulting in slower performance.

**Android**: Compatible with arm64-v8a, x86_64 architectures.

## Installation

```sh
flutter pub add flutter_rapidsnark
```

## Usage

#### groth16Prove

Function takes path to .zkey file and witness file as [Uint8List] and returns proof and public signals as record.

Reads .zkey file directly from filesystem.


```dart
import 'package:flutter_rapidsnark/flutter_rapidsnark.dart';

// ...

final zkeyPath = "path/to/zkey";
final witness = await File("path/to/wtns").readAsBytes();

final proof = await groth16Prove(zkeyPath, witness);
```

#### groth16Verify

Verifies proof and public signals against zkey.

```dart
import 'package:flutter_rapidsnark/flutter_rapidsnark.dart';

// ...

final zkey = await File("path/to/zkey").readAsBytes();
final witness = await File("path/to/wtns").readAsBytes();
final verificationKey = await File("path/to/verification_key").readAsBytes();

final proof = await groth16Prove(zkey, witness);

final proofValid = await groth16Verify(proof.proof, proof.publicSignals, verificationKey);
```

#### groth16PublicBufferSize

Calculates public buffer size for specified zkey.

```dart
import 'package:flutter_rapidsnark/flutter_rapidsnark.dart';

// ...

final publicBufferSize = await groth16PublicBufferSize("path/to/zkey");
```

### Public buffer size

`groth16Prove` has an optional `proofBufferSize`, `publicBufferSize` and `errorBufferSize` parameters. If publicBufferSize is too small it will be recalculated automatically by library.

These parameters are used to set the size of the buffers used to store the proof, public signals and error.

If you have embedded circuit in the app, it is recommended to calculate the size of the public buffer once and reuse it.
To calculate the size of public buffer call `groth16Prove`.

## Troubleshooting

### Errors

#### Invalid witness length.

If you're getting invalid witness length error - check that your witness file is not corrupted and is generated for the same circuit as zkey.

## Example App

Check out the [example app](./example) and [example README](./example/README.md) for a working example.

## License

The project is licensed under either of

- [Apache License, Version 2.0](https://www.apache.org/licenses/LICENSE-2.0) ([`LICENSE`](LICENSE))
- [MIT license](https://opensource.org/licenses/MIT) ([`LICENSE-MIT`](LICENSE-MIT))

at your option.

- **Rapidsnark**  is licensed under the [LGPL-3](https://github.com/iden3/rapidsnark/blob/main/COPYING)
