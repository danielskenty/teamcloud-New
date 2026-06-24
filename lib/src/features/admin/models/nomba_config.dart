class NombaConfig {
  const NombaConfig({
    required this.mode,
    required this.test,
    required this.live,
  });

  final String mode;
  final NombaKeySet test;
  final NombaKeySet live;

  factory NombaConfig.empty() {
    return const NombaConfig(
      mode: 'test',
      test: NombaKeySet(),
      live: NombaKeySet(),
    );
  }

  factory NombaConfig.fromMap(Map<String, dynamic> map) {
    return NombaConfig(
      mode: map['mode'] == 'live' ? 'live' : 'test',
      test: NombaKeySet.fromMap(map['test']),
      live: NombaKeySet.fromMap(map['live']),
    );
  }
}

class NombaKeySet {
  const NombaKeySet({
    this.publicKey = '',
    this.secretKeyMasked = '',
    this.secretKeyConfigured = false,
    this.webhookSecretMasked = '',
    this.webhookSecretConfigured = false,
  });

  final String publicKey;
  final String secretKeyMasked;
  final bool secretKeyConfigured;
  final String webhookSecretMasked;
  final bool webhookSecretConfigured;

  factory NombaKeySet.fromMap(dynamic value) {
    if (value is! Map<String, dynamic>) {
      return const NombaKeySet();
    }

    return NombaKeySet(
      publicKey: value['publicKey'] as String? ?? '',
      secretKeyMasked: value['secretKeyMasked'] as String? ?? '',
      secretKeyConfigured: value['secretKeyConfigured'] == true,
      webhookSecretMasked: value['webhookSecretMasked'] as String? ?? '',
      webhookSecretConfigured: value['webhookSecretConfigured'] == true,
    );
  }
}
