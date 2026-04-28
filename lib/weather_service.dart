import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherData {
  final String city;
  final String country;
  final double temperature;
  final int weatherCode;
  final double windSpeed;
  final int humidity;
  final double lat;
  final double lon;
  final bool isDay;

  WeatherData({
    required this.city,
    required this.country,
    required this.temperature,
    required this.weatherCode,
    required this.windSpeed,
    required this.humidity,
    required this.lat,
    required this.lon,
    required this.isDay,
  });
}

class WeatherService {
  Future<WeatherData?> searchCity(String cityName) async {
    final geoUrl = Uri.parse(
      'https://geocoding-api.open-meteo.com/v1/search?name=${Uri.encodeComponent(cityName)}&count=1&language=tr&format=json',
    );
    final geoResponse = await http.get(geoUrl);
    if (geoResponse.statusCode != 200) return null;
    final geoData = json.decode(geoResponse.body);
    if (geoData['results'] == null || (geoData['results'] as List).isEmpty) {
      return null;
    }

    final result = geoData['results'][0];
    final lat = (result['latitude'] as num).toDouble();
    final lon = (result['longitude'] as num).toDouble();
    final name = result['name'] as String;
    final country = (result['country'] as String?) ?? '';

    return await _fetchWeather(lat, lon, name, country);
  }

  Future<WeatherData?> _fetchWeather(
    double lat,
    double lon,
    String city,
    String country,
  ) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,weather_code,wind_speed_10m,relative_humidity_2m,is_day',
    );
    final response = await http.get(url);
    if (response.statusCode != 200) return null;

    final data = json.decode(response.body);
    final current = data['current'] as Map<String, dynamic>;

    return WeatherData(
      city: city,
      country: country,
      temperature: (current['temperature_2m'] as num).toDouble(),
      weatherCode: (current['weather_code'] as num).toInt(),
      windSpeed: (current['wind_speed_10m'] as num).toDouble(),
      humidity: (current['relative_humidity_2m'] as num).toInt(),
      lat: lat,
      lon: lon,
      isDay: (current['is_day'] as num?)?.toInt() == 1,
    );
  }
}
