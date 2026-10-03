import 'package:latlong2/latlong.dart';

class PolylineDecoder {
  PolylineDecoder._();

  static List<LatLng> decode(String encoded, {int precision = 5}) {
    final factor = _pow10(precision);
    final points = <LatLng>[];
    var index = 0;
    var lat = 0;
    var lng = 0;

    while (index < encoded.length) {
      final dLat = _nextValue(encoded, index);
      if (dLat == null) break;
      index = dLat.$2;

      final dLng = _nextValue(encoded, index);
      if (dLng == null) break;
      index = dLng.$2;

      lat += dLat.$1;
      lng += dLng.$1;
      points.add(LatLng(lat / factor, lng / factor));
    }
    return points;
  }

  static (int, int)? _nextValue(String encoded, int start) {
    var index = start;
    var result = 0;
    var shift = 0;
    int byte;
    do {
      if (index >= encoded.length) return null;
      byte = encoded.codeUnitAt(index++) - 63;
      result |= (byte & 0x1f) << shift;
      shift += 5;
    } while (byte >= 0x20);
    final value = (result & 1) != 0 ? ~(result >> 1) : result >> 1;
    return (value, index);
  }

  static double _pow10(int exponent) {
    var value = 1.0;
    for (var i = 0; i < exponent; i++) {
      value *= 10;
    }
    return value;
  }
}
