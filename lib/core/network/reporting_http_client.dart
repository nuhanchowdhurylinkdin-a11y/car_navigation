import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;

// flutter_map hides tile errors when silenced, so this tells us if tiles can't load.
class ReportingHttpClient extends http.BaseClient {
  ReportingHttpClient(
    this._inner, {
    required this.onReachable,
    required this.onUnreachable,
  });

  final http.Client _inner;
  final void Function() onReachable;
  final void Function() onUnreachable;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    try {
      final response = await _inner.send(request);
      onReachable();
      return response;
    } on http.RequestAbortedException {
      rethrow;
    } on http.ClientException catch (e) {
      if (!_isCancellation(e)) onUnreachable();
      rethrow;
    } on SocketException {
      onUnreachable();
      rethrow;
    } on TimeoutException {
      onUnreachable();
      rethrow;
    }
  }

  @override
  void close() => _inner.close();

  static bool _isCancellation(http.ClientException e) {
    final message = e.message.toLowerCase();
    return message.contains('closed') || message.contains('cancel') || message.contains('abort');
  }
}
