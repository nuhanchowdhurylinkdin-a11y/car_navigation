import 'package:car_navigation/features/directions/model/osrm_model.dart';
import 'package:car_navigation/features/directions/model/route_exception.dart';
import 'package:http/http.dart' as http;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:latlong2/latlong.dart';

class OsrmApiService {
  OsrmApiService({required this.baseUrl, required this._client});

  final String baseUrl;
  final http.Client _client;

  static const _timeout = Duration(seconds: 10);
  static const _userAgent = 'NavTest/1.0 (com.nuhan.navtest)';

  Future<OsrmModel> fetchRoute({required LatLng start, required LatLng end}) async {
    final coords = '${start.longitude},${start.latitude};'
        '${end.longitude},${end.latitude}';
    final uri = Uri.parse('$baseUrl/route/v1/driving/$coords')
        .replace(queryParameters: {'overview': 'full', 'geometries': 'polyline'});

    final http.Response response;

    try {
      response = await _client.get(uri, headers: {'User-Agent': _userAgent}).timeout(_timeout);
    } on TimeoutException {
      throw const RouteTimeoutException();
    } on SocketException {
      throw const RouteNetworkException();
    } on http.ClientException {
      throw const RouteNetworkException();
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } on FormatException {
      throw RouteServerException('Bad response (${response.statusCode})');
    }

    final code = json['code'] as String?;
    if (code == 'NoRoute' || code == 'NoSegment') throw const NoRouteException();
    if (response.statusCode != 200 || code != 'Ok') {
      throw RouteServerException(json['message'] as String? ?? 'Routing error: $code');
    }

    final model = OsrmModel.fromJson(json);
    if (model.routes.isEmpty || model.routes.first.geometry.isEmpty) {
      throw const NoRouteException();
    }
    return model;
  }

  void dispose() => _client.close();
}
