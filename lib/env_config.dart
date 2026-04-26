class EnvConfig {
  static const backendUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://tatva-api-859841471446.us-central1.run.app',
  );
}
