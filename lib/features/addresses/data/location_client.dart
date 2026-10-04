import 'dart:async';

import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:speedygo_customer_app/core/errors/app_exception.dart';

enum LocationAccess { granted, denied, deniedForever, servicesDisabled }

class DeviceLocation {
  const DeviceLocation({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class LocationUnavailableException extends UnexpectedException {
  const LocationUnavailableException()
    : super(
        'La position n’est pas disponible pour le moment. Saisissez les coordonnées manuellement.',
        code: 'LOCATION_UNAVAILABLE',
      );
}

abstract class LocationClient {
  /// Must be called only after an explicit user action.
  Future<LocationAccess> requestAccess();

  Future<DeviceLocation> readCurrent();
}

class GeolocatorLocationClient implements LocationClient {
  @override
  Future<LocationAccess> requestAccess() async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        return LocationAccess.servicesDisabled;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      switch (permission) {
        case LocationPermission.denied:
          return LocationAccess.denied;
        case LocationPermission.deniedForever:
          return LocationAccess.deniedForever;
        case LocationPermission.always:
        case LocationPermission.whileInUse:
          return LocationAccess.granted;
        case LocationPermission.unableToDetermine:
          return LocationAccess.denied;
      }
    } on MissingPluginException {
      // Hot restart does not rebind native plugins; treat as unavailable.
      throw const LocationUnavailableException();
    }
  }

  @override
  Future<DeviceLocation> readCurrent() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 15),
        ),
      );
      return DeviceLocation(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } on MissingPluginException {
      throw const LocationUnavailableException();
    } on TimeoutException {
      throw const LocationUnavailableException();
    } on LocationServiceDisabledException {
      throw const LocationUnavailableException();
    }
  }
}
