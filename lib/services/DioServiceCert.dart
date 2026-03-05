import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

// أنشئ Dio instance مع تجاهل SSL
Dio getDio() {
  final dio = Dio();
  (dio.httpClientAdapter as IOHttpClientAdapter).onHttpClientCreate = (client) {
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    return client;
  };
  return dio;
}
