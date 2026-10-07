import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// Shared HTTP client.
///
/// LiteSpeed on daltalifts.com returns 403 for JSON POSTs to `sql.php`.
/// Form-urlencoded bodies succeed, and PHP already merges `$_POST`.
Dio getDio() {
  final dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      contentType: Headers.formUrlEncodedContentType,
      headers: {
        HttpHeaders.userAgentHeader: 'DeltaElevators/1.3.7 (Flutter)',
        HttpHeaders.acceptHeader: 'application/json, text/plain, */*',
      },
    ),
  );
  (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate =
      (client) {
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return client;
  };
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final host = options.uri.host;
        final data = options.data;
        if (host.contains('daltalifts.com') && data is Map && data is! FormData) {
          options.contentType = Headers.formUrlEncodedContentType;
          options.headers[Headers.contentTypeHeader] =
              Headers.formUrlEncodedContentType;
        }
        handler.next(options);
      },
    ),
  );
  return dio;
}
