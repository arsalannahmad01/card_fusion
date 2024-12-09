import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class LocationService {
  Future<Map<String, dynamic>> getCurrentLocation() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled');
        return {};
      }

      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied');
          return {};
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied');
        return {};
      }

      // Get position with high accuracy
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      );
      
      // Get place details with retries
      List<Placemark> placemarks = [];
      int retries = 3;
      
      while (retries > 0 && placemarks.isEmpty) {
        try {
          placemarks = await placemarkFromCoordinates(
            position.latitude,
            position.longitude,
            localeIdentifier: 'en'
          );
          break;
        } catch (e) {
          debugPrint('Error getting placemark, retries left: ${retries - 1}');
          retries--;
          if (retries > 0) {
            await Future.delayed(const Duration(seconds: 1));
          }
        }
      }

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality ?? 
                    place.subLocality ?? 
                    place.subAdministrativeArea;
        final country = place.country;
        
        debugPrint('Found location - City: $city, Country: $country');
        
        if (city == null || country == null) {
          debugPrint('Could not determine city or country');
          return {};
        }
        
        return {
          'city': city,
          'country': country,
          'coordinates': {
            'latitude': position.latitude,
            'longitude': position.longitude,
          }
        };
      }
      
      debugPrint('No placemarks found for location');
      return {};
    } catch (e) {
      debugPrint('Error getting location: $e');
      return {};
    }
  }
} 