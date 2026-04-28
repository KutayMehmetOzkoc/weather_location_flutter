import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;

class Place {
  final String name;
  final String type;
  final String? cuisine;
  final String? address;
  final double? distanceMeters;
  final double? lat;
  final double? lon;
  final double score;

  Place({
    required this.name,
    required this.type,
    this.cuisine,
    this.address,
    this.distanceMeters,
    this.lat,
    this.lon,
    required this.score,
  });

  String get distanceLabel {
    if (distanceMeters == null) return '';
    return distanceMeters! < 1000
        ? '${distanceMeters!.round()}m'
        : '${(distanceMeters! / 1000).toStringAsFixed(1)}km';
  }
}

class PlaceService {
  Future<List<Place>> fetchNearby(double lat, double lon) async {
    final query = '[out:json][timeout:20];'
        '('
        'node["amenity"="restaurant"](around:2000,$lat,$lon);'
        'way["amenity"="restaurant"](around:2000,$lat,$lon);'
        'node["amenity"="cafe"](around:2000,$lat,$lon);'
        'way["amenity"="cafe"](around:2000,$lat,$lon);'
        ');'
        'out center 60;';

    final url = Uri.https(
      'overpass-api.de',
      '/api/interpreter',
      {'data': query},
    );
    final response = await http.get(url, headers: {
      'User-Agent': 'WeatherApp/1.0',
      'Accept': '*/*',
    });

    if (response.statusCode != 200) return [];

    final data = json.decode(response.body);
    final elements = (data['elements'] as List?) ?? [];

    final places = <Place>[];
    for (final el in elements) {
      final tags = (el['tags'] as Map?)?.cast<String, dynamic>();
      if (tags == null) continue;

      final name = (tags['name'] as String?)?.trim();
      if (name == null || name.isEmpty) continue;

      final type = tags['amenity'] as String? ?? 'restaurant';

      final rawCuisine = tags['cuisine'] as String?;
      final cuisine = rawCuisine?.split(';').first.trim();

      final street = tags['addr:street'] as String?;
      final number = tags['addr:housenumber'] as String?;
      String? address;
      if (street != null) {
        address = number != null ? '$street $number' : street;
      }

      double? elLat, elLon;
      if (el['type'] == 'node') {
        elLat = (el['lat'] as num?)?.toDouble();
        elLon = (el['lon'] as num?)?.toDouble();
      } else if (el['center'] != null) {
        elLat = (el['center']['lat'] as num?)?.toDouble();
        elLon = (el['center']['lon'] as num?)?.toDouble();
      }

      places.add(Place(
        name: name,
        type: type,
        cuisine: cuisine,
        address: address,
        distanceMeters: (elLat != null && elLon != null)
            ? _haversine(lat, lon, elLat, elLon)
            : null,
        lat: elLat,
        lon: elLon,
        score: _calcScore(tags, name),
      ));
    }

    places.sort((a, b) {
      if (a.distanceMeters == null) return 1;
      if (b.distanceMeters == null) return -1;
      return a.distanceMeters!.compareTo(b.distanceMeters!);
    });

    return places;
  }

  double _calcScore(Map<String, dynamic> tags, String name) {
    // Deterministic base from name hash: 3.0 – 4.8
    final base = 3.0 + (name.hashCode.abs() % 19) / 10.0;
    double bonus = 0;
    if (tags['cuisine'] != null) bonus += 0.1;
    if (tags['addr:street'] != null) bonus += 0.1;
    if (tags['phone'] != null) bonus += 0.1;
    if (tags['website'] != null) bonus += 0.1;
    if (tags['opening_hours'] != null) bonus += 0.1;
    return (base + bonus).clamp(1.0, 5.0);
  }

  double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final phi1 = lat1 * pi / 180;
    final phi2 = lat2 * pi / 180;
    final dphi = (lat2 - lat1) * pi / 180;
    final dlambda = (lon2 - lon1) * pi / 180;
    final a = sin(dphi / 2) * sin(dphi / 2) +
        cos(phi1) * cos(phi2) * sin(dlambda / 2) * sin(dlambda / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
