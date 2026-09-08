class ApiConfig {
  const ApiConfig({required this.apiBaseUrl});

  final String apiBaseUrl;

  Uri get apiRoot => Uri.parse(_trimTrailingSlash(apiBaseUrl));

  /// Origin for unprefixed `GET /health` — never `/api/v1/health`.
  Uri get origin {
    final uri = apiRoot;
    final path = uri.path;
    final stripped = path.endsWith('/api/v1')
        ? path.substring(0, path.length - '/api/v1'.length)
        : path.replaceFirst(RegExp(r'/api/v1/?$'), '');
    return uri.replace(path: stripped.isEmpty ? '' : stripped);
  }

  Uri get healthUri => origin.replace(
    path: '${origin.path.isEmpty ? '' : origin.path}/health'.replaceAll(
      '//',
      '/',
    ),
  );

  static String _trimTrailingSlash(String value) {
    if (value.endsWith('/')) {
      return value.substring(0, value.length - 1);
    }
    return value;
  }
}
