import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

/// Thin HTTP client around the backend's `{data, error, code, details}`
/// envelope. Returns the decoded `data` payload or throws [ApiException].
///
/// Deliberately Flutter-free so it can run in plain Dart VM tooling
/// (see `tool/api_smoke.dart`); pass `ApiConfig.baseUrl` from app code.
class ApiClient {
  ApiClient({http.Client? httpClient, required String baseUrl})
      : _http = httpClient ?? http.Client(),
        _baseUrl = baseUrl;

  static const String apiPrefix = '/api/v1';

  final http.Client _http;
  final String _baseUrl;

  static const _timeout = Duration(seconds: 15);

  Uri _uri(String path) => Uri.parse('$_baseUrl$apiPrefix$path');

  Map<String, String> _headers(String? accessToken) => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

  Future<dynamic> post(
    String path, {
    Object? body,
    String? accessToken,
  }) async {
    final http.Response response;
    try {
      response = await _http
          .post(
            _uri(path),
            headers: _headers(accessToken),
            body: jsonEncode(body ?? const {}),
          )
          .timeout(_timeout);
    } on Exception {
      throw const ApiException.network();
    }
    return _unwrap(response);
  }

  Future<dynamic> put(
    String path, {
    Object? body,
    String? accessToken,
  }) async {
    final http.Response response;
    try {
      response = await _http
          .put(
            _uri(path),
            headers: _headers(accessToken),
            body: jsonEncode(body ?? const {}),
          )
          .timeout(_timeout);
    } on Exception {
      throw const ApiException.network();
    }
    return _unwrap(response);
  }

  Future<dynamic> get(String path, {String? accessToken}) async {
    final http.Response response;
    try {
      response = await _http
          .get(_uri(path), headers: _headers(accessToken))
          .timeout(_timeout);
    } on Exception {
      throw const ApiException.network();
    }
    return _unwrap(response);
  }

  dynamic _unwrap(http.Response response) {
    Map<String, dynamic> envelope;
    try {
      envelope =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } on Object {
      throw ApiException(
        message: 'Unexpected response from the server.',
        code: 'INVALID_RESPONSE',
        statusCode: response.statusCode,
      );
    }

    final error = envelope['error'];
    if (response.statusCode >= 200 &&
        response.statusCode < 300 &&
        error == null) {
      return envelope['data'];
    }

    throw ApiException(
      message: error is String && error.isNotEmpty
          ? error
          : 'Something went wrong. Please try again.',
      code: envelope['code'] is String ? envelope['code'] as String : 'UNKNOWN',
      statusCode: response.statusCode,
      fieldErrors: _fieldErrors(envelope['details']),
    );
  }

  static Map<String, String> _fieldErrors(dynamic details) {
    if (details is! Map<String, dynamic>) return const {};
    final issues = details['issues'];
    if (issues is! List) return const {};
    return {
      for (final issue in issues.whereType<Map<String, dynamic>>())
        if (issue['path'] is String && issue['message'] is String)
          issue['path'] as String: issue['message'] as String,
    };
  }

  void close() => _http.close();
}
