class ProveResult {
  final String proof;
  final String publicSignals;

  ProveResult({required this.proof, required this.publicSignals});

  // JSON serialization
  factory ProveResult.fromJson(Map<String, dynamic> json) {
    return ProveResult(
      proof: json['proof'],
      publicSignals: json['public'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'proof': proof,
      'public': publicSignals,
    };
  }

  // String representation
  @override
  String toString() {
    return 'ProveResult(proof: $proof, public: $publicSignals)';
  }
}
