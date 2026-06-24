class BackendConfig {
  static const functionsUrl = String.fromEnvironment(
    'TEAMCLOUD_FUNCTIONS_URL',
    defaultValue: 'https://us-central1-teamcloud-94b3a.cloudfunctions.net/api',
  );
}
