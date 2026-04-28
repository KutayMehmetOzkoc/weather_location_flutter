import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'place_service.dart';
import 'weather_effect.dart';
import 'weather_service.dart';

const _kBgDay = Color(0xFF0B1B2E);
const _kBgNight = Color(0xFF07070F);

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  final _weatherService = WeatherService();
  final _placeService = PlaceService();

  WeatherData? _weather;
  bool _isLoading = false;
  String? _error;
  List<Place> _places = [];
  bool _placesLoading = false;
  WeatherEffectType? _previewEffect;
  bool _easterEggFound = false;

  @override
  void initState() {
    super.initState();
    _fetchCity('Istanbul');
  }

  Future<void> _fetchCity(String city) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _places = [];
    });
    final data = await _weatherService.searchCity(city);
    setState(() {
      _isLoading = false;
      _weather = data;
      if (data == null) _error = '"$city" bulunamadı.';
    });
    if (data != null) _fetchPlaces(data.lat, data.lon);
  }

  Future<void> _fetchPlaces(double lat, double lon) async {
    setState(() => _placesLoading = true);
    final places = await _placeService.fetchNearby(lat, lon);
    setState(() {
      _places = places;
      _placesLoading = false;
    });
  }

  // ── Accent color (always dark theme) ──────────────────────────────

  Color _accentColor(bool isDay, int code) {
    if (code >= 95) return const Color(0xFF9b59b6);
    if (code >= 71 && code <= 86) return const Color(0xFF74b9ff);
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) {
      return const Color(0xFF3498db);
    }
    if (code == 45 || code == 48) return const Color(0xFF7f8c8d);
    if (!isDay) return const Color(0xFF1A4A8A);
    return const Color(0xFFFFB74D);
  }

  String _weatherIcon(int code, bool isDay) {
    if (code == 0) return isDay ? '☀️' : '🌙';
    if (code <= 2) return isDay ? '🌤️' : '🌙';
    if (code == 3) return '☁️';
    if (code <= 48) return '🌫️';
    if (code <= 57) return '🌦️';
    if (code <= 67) return '🌧️';
    if (code <= 77) return '❄️';
    if (code <= 82) return '🌧️';
    if (code <= 86) return '🌨️';
    return '⛈️';
  }

  String _weatherDesc(int code) {
    if (code == 0) return 'Açık Hava';
    if (code == 1) return 'Çoğunlukla Açık';
    if (code == 2) return 'Parçalı Bulutlu';
    if (code == 3) return 'Bulutlu';
    if (code <= 48) return 'Sisli';
    if (code <= 55) return 'Hafif Çiseleme';
    if (code <= 57) return 'Dondurucu Çiseleme';
    if (code <= 63) return 'Yağmurlu';
    if (code <= 65) return 'Şiddetli Yağmur';
    if (code <= 67) return 'Dondurucu Yağmur';
    if (code <= 73) return 'Karlı';
    if (code <= 75) return 'Yoğun Kar';
    if (code == 77) return 'Kar Taneleri';
    if (code <= 82) return 'Sağanak Yağmur';
    if (code <= 86) return 'Kar Fırtınası';
    return 'Gök Gürültülü Fırtına';
  }

  String _dateString() {
    final now = DateTime.now();
    const days = [
      'Pazartesi', 'Salı', 'Çarşamba', 'Perşembe',
      'Cuma', 'Cumartesi', 'Pazar',
    ];
    const months = [
      'Ocak', 'Şubat', 'Mart', 'Nisan', 'Mayıs', 'Haziran',
      'Temmuz', 'Ağustos', 'Eylül', 'Ekim', 'Kasım', 'Aralık',
    ];
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDay = _weather?.isDay ?? (DateTime.now().hour >= 6 && DateTime.now().hour < 20);
    final accent = _weather != null
        ? _accentColor(isDay, _weather!.weatherCode)
        : const Color(0xFF2980b9);
    final effectType = _previewEffect ??
        (_weather != null ? effectFromCode(_weather!.weatherCode) : WeatherEffectType.none);

    final bgColor = isDay ? _kBgDay : _kBgNight;

    return Scaffold(
      backgroundColor: bgColor,
      body: WeatherEffect(
        type: effectType,
        child: Stack(
          children: [
            Positioned.fill(child: _buildBackground(accent)),
            SafeArea(
              bottom: false,
              child: Column(
                children: [
                  _buildSearch(accent),
                  Expanded(
                    child: _isLoading
                        ? _buildLoading(accent)
                        : _error != null
                            ? _buildError()
                            : _weather != null
                                ? _buildWeatherContent(isDay, accent)
                                : const SizedBox(),
                  ),
                ],
              ),
            ),
            DraggableScrollableSheet(
              key: ValueKey(_weather?.city),
              initialChildSize: 0.10,
              minChildSize: 0.10,
              maxChildSize: 0.88,
              snap: true,
              snapSizes: const [0.10, 0.46, 0.88],
              builder: (ctx, sc) => _buildPlacesPanel(sc, accent),
            ),
          ],
        ),
      ),
    );
  }

  // ── Background orbs ────────────────────────────────────────────────

  Widget _buildBackground(Color accent) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned(
          left: -90,
          top: -90,
          child: _Orb(size: 300, color: accent, opacity: 0.28, blur: 65),
        ),
        Positioned(
          right: -110,
          bottom: 160,
          child: _Orb(size: 330, color: accent, opacity: 0.16, blur: 85),
        ),
        Positioned(
          left: 40,
          bottom: 80,
          child: _Orb(size: 180, color: accent, opacity: 0.1, blur: 55),
        ),
      ],
    );
  }

  // ── Search bar ─────────────────────────────────────────────────────

  Widget _buildSearch(Color accent) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.09)),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            hintText: 'Şehir ara...',
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
            prefixIcon: Icon(
              Icons.search_rounded,
              color: accent.withValues(alpha: 0.75),
              size: 20,
            ),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(
                      Icons.close_rounded,
                      color: Colors.white.withValues(alpha: 0.35),
                      size: 18,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (v) {
            if (v.trim().isNotEmpty) _fetchCity(v.trim());
          },
        ),
      ),
    );
  }

  // ── Loading / error ────────────────────────────────────────────────

  Widget _buildLoading(Color accent) {
    return Center(
      child: CircularProgressIndicator(color: accent, strokeWidth: 1.5),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          _error!,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  // ── Weather content ────────────────────────────────────────────────

  Widget _buildWeatherContent(bool isDay, Color accent) {
    final w = _weather!;
    final progress = ((w.temperature + 20) / 70).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 120),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // City name
          Text(
            w.city,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.3,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          // Location + date row
          Row(
            children: [
              if (w.country.isNotEmpty) ...[
                Icon(Icons.location_on_rounded, color: accent, size: 13),
                const SizedBox(width: 3),
                Text(
                  w.country,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.45),
                    fontSize: 13,
                  ),
                ),
                Text(
                  '   ·   ',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.18),
                    fontSize: 13,
                  ),
                ),
              ],
              Text(
                _dateString(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.35),
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),

          // Temp ring (centered)
          Center(
            child: SizedBox(
              width: 230,
              height: 230,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(230, 230),
                    painter: _TempRingPainter(color: accent, progress: progress),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      GestureDetector(
                        onLongPress: _cyclePreviewEffect,
                        child: Text(
                          _weatherIcon(w.weatherCode, isDay),
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                      const SizedBox(height: 6),
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${w.temperature.round()}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 76,
                                fontWeight: FontWeight.w200,
                                height: 1,
                                letterSpacing: -2,
                              ),
                            ),
                            TextSpan(
                              text: '°',
                              style: TextStyle(
                                color: accent,
                                fontSize: 38,
                                fontWeight: FontWeight.w300,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Description pill (centered)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: accent.withValues(alpha: 0.25)),
              ),
              child: Text(
                _weatherDesc(w.weatherCode),
                style: TextStyle(
                  color: accent.withValues(alpha: 0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 44),

          // Stat chips
          Row(
            children: [
              Expanded(
                child: _StatChip(
                  icon: Icons.water_drop_outlined,
                  value: '${w.humidity}%',
                  label: 'Nem',
                  accent: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatChip(
                  icon: Icons.air_rounded,
                  value: '${w.windSpeed.round()}',
                  label: 'km/s',
                  accent: accent,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatChip(
                  icon: Icons.thermostat_rounded,
                  value: '${w.temperature.round()}°',
                  label: 'Celsius',
                  accent: accent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Places panel ───────────────────────────────────────────────────

  Widget _buildPlacesPanel(ScrollController scrollCtrl, Color accent) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0d0d1c).withValues(alpha: 0.93),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
            ),
          ),
          child: ListView(
            controller: scrollCtrl,
            padding: EdgeInsets.zero,
            children: [
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  width: 34,
                  height: 3,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 16),
                child: Row(
                  children: [
                    Container(
                      width: 3,
                      height: 16,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Yakındaki Mekanlar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Spacer(),
                    if (_placesLoading)
                      SizedBox(
                        width: 15,
                        height: 15,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: accent.withValues(alpha: 0.5),
                        ),
                      )
                    else if (_places.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 3),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${_places.length}',
                          style: TextStyle(
                            color: accent.withValues(alpha: 0.9),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (!_placesLoading && _places.isEmpty && _weather != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Text(
                    'Bu bölgede kayıtlı mekan bulunamadı.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 14,
                    ),
                  ),
                )
              else if (_weather == null && !_placesLoading)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Text(
                    'Konum yükleniyor...',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 14,
                    ),
                  ),
                )
              else
                ..._places.map((p) => _PlaceCard(place: p, accent: accent)),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  void _cyclePreviewEffect() {
    if (!_easterEggFound) {
      _easterEggFound = true;
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.6),
        builder: (_) => _EasterEggDialog(
          onDismiss: () {
            Navigator.of(context).pop();
            setState(() => _previewEffect = WeatherEffectType.rain);
          },
        ),
      );
      return;
    }

    setState(() {
      _previewEffect = switch (_previewEffect) {
        null => WeatherEffectType.rain,
        WeatherEffectType.rain => WeatherEffectType.snow,
        _ => null,
      };
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}

// ── Orb ────────────────────────────────────────────────────────────────

class _Orb extends StatelessWidget {
  final double size;
  final Color color;
  final double opacity;
  final double blur;

  const _Orb({
    required this.size,
    required this.color,
    required this.opacity,
    required this.blur,
  });

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color.withValues(alpha: opacity),
        ),
      ),
    );
  }
}

// ── Stat chip ───────────────────────────────────────────────────────────

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color accent;

  const _StatChip({
    required this.icon,
    required this.value,
    required this.label,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent.withValues(alpha: 0.75), size: 18),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w400,
              height: 1,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 11,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Temperature ring painter ────────────────────────────────────────────

class _TempRingPainter extends CustomPainter {
  final Color color;
  final double progress;

  _TempRingPainter({required this.color, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 14;

    // Track
    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, trackPaint);

    // Outer dashed tick marks (12 marks around the ring)
    final tickPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 24; i++) {
      final angle = -pi / 2 + (2 * pi * i / 24);
      final inner = radius - 5;
      final outer = radius + 5;
      canvas.drawLine(
        Offset(center.dx + inner * cos(angle), center.dy + inner * sin(angle)),
        Offset(center.dx + outer * cos(angle), center.dy + outer * sin(angle)),
        tickPaint,
      );
    }

    if (progress <= 0) return;

    // Glow arc
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.28)
      ..strokeWidth = 12
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      glowPaint,
    );

    // Main arc
    final arcPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      arcPaint,
    );

    // End dot glow
    final endAngle = -pi / 2 + 2 * pi * progress;
    final dotX = center.dx + radius * cos(endAngle);
    final dotY = center.dy + radius * sin(endAngle);
    final dotGlowPaint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..style = PaintingStyle.fill
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7);
    canvas.drawCircle(Offset(dotX, dotY), 7, dotGlowPaint);
    final dotPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(dotX, dotY), 3.5, dotPaint);
  }

  @override
  bool shouldRepaint(_TempRingPainter old) =>
      old.color != color || old.progress != progress;
}

// ── Place card ──────────────────────────────────────────────────────────

class _PlaceCard extends StatefulWidget {
  final Place place;
  final Color accent;

  const _PlaceCard({required this.place, required this.accent});

  @override
  State<_PlaceCard> createState() => _PlaceCardState();
}

class _PlaceCardState extends State<_PlaceCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final accent = widget.accent;

    final label = [
      if (place.cuisine != null) _cuisineLabel(place.cuisine!),
      if (place.address != null) place.address!,
    ].join(' · ');

    final hasMap = place.lat != null && place.lon != null;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      place.type == 'restaurant' ? '🍽️' : '☕',
                      style: const TextStyle(fontSize: 20),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (label.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          label,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.38),
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 5),
                      _buildStars(place.score, accent),
                    ],
                  ),
                ),
                if (hasMap) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _expanded = !_expanded),
                    child: AnimatedRotation(
                      turns: _expanded ? 0.25 : 0,
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: accent.withValues(alpha: 0.75),
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _expanded && hasMap
                ? _buildMapView(accent)
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView(Color accent) {
    final place = widget.place;
    final point = LatLng(place.lat!, place.lon!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(height: 1, color: Colors.white.withValues(alpha: 0.06)),
        SizedBox(
          height: 280,
          child: FlutterMap(
            options: MapOptions(
              initialCenter: point,
              initialZoom: 17,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.pinchZoom | InteractiveFlag.drag,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.weather_app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 200,
                    height: 80,
                    alignment: Alignment.bottomCenter,
                    child: _PinMarker(label: place.name, accent: accent),
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
          child: TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              backgroundColor: accent.withValues(alpha: 0.08),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: accent.withValues(alpha: 0.2)),
              ),
            ),
            onPressed: () async {
              final url = Uri.parse(
                'https://www.google.com/maps/search/?api=1'
                '&query=${Uri.encodeComponent(place.name)}'
                '&center=${place.lat},${place.lon}',
              );
              if (await canLaunchUrl(url)) {
                await launchUrl(url, mode: LaunchMode.externalApplication);
              }
            },
            icon: Icon(
              Icons.map_outlined,
              size: 15,
              color: accent.withValues(alpha: 0.65),
            ),
            label: Text(
              'Google Haritalar\'da Aç',
              style: TextStyle(
                color: accent.withValues(alpha: 0.65),
                fontSize: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStars(double score, Color accent) {
    final filled = score.floor();
    final hasHalf = (score - filled) >= 0.25;

    return Row(
      children: [
        Text(
          score.toStringAsFixed(1),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 4),
        ...List.generate(5, (i) {
          IconData icon;
          Color color;
          if (i < filled) {
            icon = Icons.star_rounded;
            color = accent;
          } else if (i == filled && hasHalf) {
            icon = Icons.star_half_rounded;
            color = accent;
          } else {
            icon = Icons.star_rounded;
            color = Colors.white.withValues(alpha: 0.12);
          }
          return Icon(icon, size: 12, color: color);
        }),
      ],
    );
  }

  String _cuisineLabel(String cuisine) {
    const map = {
      'turkish': 'Türk Mutfağı',
      'pizza': 'Pizza',
      'burger': 'Burger',
      'kebab': 'Kebap',
      'coffee_shop': 'Kahve',
      'sandwich': 'Sandviç',
      'asian': 'Asya',
      'chinese': 'Çin',
      'italian': 'İtalyan',
      'fast_food': 'Fast Food',
      'seafood': 'Deniz Ürünleri',
      'vegetarian': 'Vejetaryen',
      'sushi': 'Sushi',
      'indian': 'Hint',
      'mexican': 'Meksika',
    };
    final lower = cuisine.toLowerCase();
    return map[lower] ?? cuisine[0].toUpperCase() + cuisine.substring(1);
  }
}

// ── Custom pin marker ───────────────────────────────────────────────────

class _PinMarker extends StatelessWidget {
  final String label;
  final Color accent;

  const _PinMarker({required this.label, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFF0d0d1c),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: accent.withValues(alpha: 0.45)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.5),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: accent,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            color: accent,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.55),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: const Icon(Icons.place_rounded, color: Colors.white, size: 14),
        ),
        CustomPaint(
          size: const Size(8, 6),
          painter: _PinTailPainter(color: accent),
        ),
      ],
    );
  }
}

class _PinTailPainter extends CustomPainter {
  final Color color;

  const _PinTailPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = ui.Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_PinTailPainter old) => old.color != color;
}

// ── Easter Egg Dialog ───────────────────────────────────────────────────

class _EasterEggDialog extends StatefulWidget {
  final VoidCallback onDismiss;

  const _EasterEggDialog({required this.onDismiss});

  @override
  State<_EasterEggDialog> createState() => _EasterEggDialogState();
}

class _EasterEggDialogState extends State<_EasterEggDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: ScaleTransition(
          scale: _scale,
          child: Container(
            padding: const EdgeInsets.fromLTRB(28, 32, 28, 24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1626),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFB74D).withValues(alpha: 0.18),
                  blurRadius: 40,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🥚', style: TextStyle(fontSize: 52)),
                const SizedBox(height: 16),
                const Text(
                  'Easter Egg\'i Buldun!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Tebrikler 🎉\nGizli hava efekti önizleme modunu keşfettin.\nİkona uzun basarak efektler arasında geçiş yapabilirsin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 28),
                GestureDetector(
                  onTap: widget.onDismiss,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB74D).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFFFB74D).withValues(alpha: 0.35),
                      ),
                    ),
                    child: const Text(
                      'Harika! Deneyelim ✨',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFFFFB74D),
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
