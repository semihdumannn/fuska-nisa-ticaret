import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:nisa_ticaret/core/theme/app_theme.dart';

class MapPickerResult {
  final LatLng location;
  final String? fullAddress;
  final String? district;
  final String? city;

  const MapPickerResult({
    required this.location,
    this.fullAddress,
    this.district,
    this.city,
  });
}

class MapPickerScreen extends StatefulWidget {
  final LatLng? initialLocation;
  const MapPickerScreen({super.key, this.initialLocation});

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  static const _defaultLocation = LatLng(39.6484, 27.8826); // Balıkesir

  GoogleMapController? _mapController;
  late LatLng _selectedLocation;
  bool _locating = false;
  bool _confirming = false;

  @override
  void initState() {
    super.initState();
    _selectedLocation = widget.initialLocation ?? _defaultLocation;
    // initialLocation verilmemişse ekran açılınca kullanıcının konumuna git
    if (widget.initialLocation == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _goToCurrentLocation();
      });
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    setState(() => _confirming = true);
    try {
      final placemarks = await placemarkFromCoordinates(
        _selectedLocation.latitude,
        _selectedLocation.longitude,
      );

      MapPickerResult result;
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;

        // Tam adres: sokak + bina no
        final parts = [
          if ((p.thoroughfare ?? '').isNotEmpty) p.thoroughfare!,
          if ((p.subThoroughfare ?? '').isNotEmpty) p.subThoroughfare!,
        ];
        final fullAddress = parts.join(' ').trim();

        // İlçe: subAdministrativeArea veya locality
        final district = (p.subAdministrativeArea ?? p.locality ?? '').trim();

        // Şehir: administrativeArea (il adı)
        final city = (p.administrativeArea ?? '').trim();

        result = MapPickerResult(
          location: _selectedLocation,
          fullAddress: fullAddress.isNotEmpty ? fullAddress : null,
          district: district.isNotEmpty ? district : null,
          city: city.isNotEmpty ? city : null,
        );
      } else {
        result = MapPickerResult(location: _selectedLocation);
      }

      if (mounted) Navigator.of(context).pop(result);
    } catch (_) {
      // Geocoding başarısız olsa bile koordinatları döndür
      if (mounted) {
        Navigator.of(context).pop(MapPickerResult(location: _selectedLocation));
      }
    } finally {
      if (mounted) setState(() => _confirming = false);
    }
  }

  Future<void> _goToCurrentLocation() async {
    setState(() => _locating = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _showSnack('Konum servisi kapalı. Lütfen açın.');
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _showSnack('Konum izni reddedildi.');
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        _showSnack('Konum izni kalıcı reddedildi. Ayarlardan açın.');
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      final loc = LatLng(position.latitude, position.longitude);
      setState(() => _selectedLocation = loc);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(loc, 17));
    } catch (_) {
      _showSnack('Konum alınamadı. Tekrar deneyin.');
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        iconTheme: const IconThemeData(color: AppColors.secondary),
        title: const Text('Konum Seç',
            style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        actions: [
          TextButton(
            onPressed: (_confirming || _locating) ? null : _confirm,
            child: _confirming
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: AppColors.primary))
                : const Text('Onayla',
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
          ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLocation,
              zoom: 15,
            ),
            onMapCreated: (controller) => _mapController = controller,
            onCameraMove: (position) {
              _selectedLocation = position.target;
            },
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: true,
            mapToolbarEnabled: false,
          ),

          // Sabit merkez pin
          const IgnorePointer(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.location_pin,
                      color: AppColors.primary,
                      size: 52,
                      shadows: [Shadow(blurRadius: 8, color: Colors.black38)]),
                  SizedBox(height: 26),
                ],
              ),
            ),
          ),

          // Alt bilgi
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                boxShadow: [BoxShadow(blurRadius: 10, color: Colors.black12)],
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline,
                      color: AppColors.textHint, size: 16),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Haritayı kaydırarak pini doğru konuma getirin, sonra "Onayla"ya basın.',
                      style: TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // GPS butonu
          Positioned(
            right: 16,
            bottom: 90,
            child: FloatingActionButton.small(
              heroTag: 'map_location',
              backgroundColor: AppColors.surface,
              elevation: 4,
              onPressed: _locating ? null : _goToCurrentLocation,
              child: _locating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.primary))
                  : const Icon(Icons.my_location,
                      color: AppColors.primary, size: 22),
            ),
          ),

          // İlk açılışta konum alınırken gösterilen overlay
          if (_locating)
            Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(blurRadius: 8, color: Colors.black26)
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: AppColors.primary),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Konumunuz alınıyor...',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.textPrimary),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
