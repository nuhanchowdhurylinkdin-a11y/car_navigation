import 'dart:io';

import 'package:car_navigation/core/network/reporting_http_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late List<String> events;

  ReportingHttpClient clientWith(Future<http.Response> Function(http.Request) handler) => ReportingHttpClient(
        MockClient(handler),
        onReachable: () => events.add('reachable'),
        onUnreachable: () => events.add('unreachable'),
      );

  setUp(() => events = []);

  test('a response (even an error status) means the server is reachable', () async {
    await clientWith((_) async => http.Response('', 404)).get(Uri.parse('https://tile.test/1.png'));
    expect(events, ['reachable']);
  });

  test('DNS / socket failure means unreachable and is rethrown', () async {
    final client = clientWith((_) async => throw const SocketException('Failed host lookup'));
    await expectLater(client.get(Uri.parse('https://tile.test/1.png')), throwsA(anything));
    expect(events, ['unreachable']);
  });

  test('a cancelled tile request is not treated as offline', () async {
    final client = clientWith((_) async => throw http.ClientException('Connection closed before full header'));
    await expectLater(client.get(Uri.parse('https://tile.test/1.png')), throwsA(anything));
    expect(events, isEmpty);
  });
}
