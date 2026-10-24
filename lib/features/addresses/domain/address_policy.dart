class AddressPolicy {
  AddressPolicy._();

  static const labelMaxLength = 64;
  static const addressTextMaxLength = 500;
  static const buildingMaxLength = 64;
  static const floorMaxLength = 32;
  static const entranceMaxLength = 64;
  static const landmarkMaxLength = 128;
  static const minLatitude = -90.0;
  static const maxLatitude = 90.0;
  static const minLongitude = -180.0;
  static const maxLongitude = 180.0;

  static String? validateLabel(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'empty';
    }
    if (trimmed.length > labelMaxLength) {
      return 'tooLong';
    }
    return null;
  }

  static String? validateAddressText(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      return 'empty';
    }
    if (trimmed.length > addressTextMaxLength) {
      return 'tooLong';
    }
    return null;
  }

  static double? parseCoordinate(String raw) {
    final trimmed = raw.trim().replaceAll(',', '.');
    if (trimmed.isEmpty) {
      return null;
    }
    return double.tryParse(trimmed);
  }

  static bool isValidLatitude(double value) {
    return value.isFinite && value >= minLatitude && value <= maxLatitude;
  }

  static bool isValidLongitude(double value) {
    return value.isFinite && value >= minLongitude && value <= maxLongitude;
  }

  static bool isUsablePoint(double latitude, double longitude) {
    if (!isValidLatitude(latitude) || !isValidLongitude(longitude)) {
      return false;
    }
    return latitude != 0 || longitude != 0;
  }

  static String composeAddressText({
    required String street,
    String building = '',
    String floor = '',
    String entrance = '',
    String landmark = '',
  }) {
    // Named extras are accepted for call-site compatibility and ignored.
    // Structured details persist in their own columns, not in addressText.
    final hasExtras =
        building.trim().isNotEmpty ||
        floor.trim().isNotEmpty ||
        entrance.trim().isNotEmpty ||
        landmark.trim().isNotEmpty;
    if (hasExtras) {
      return street.trim();
    }
    return street.trim();
  }

  static String? validateOptionalDetail(String raw, int maxLength) {
    if (raw.trim().length > maxLength) {
      return 'tooLong';
    }
    return null;
  }

  static String? validateLatitude(String raw) {
    final value = parseCoordinate(raw);
    if (value == null || !isValidLatitude(value)) {
      return 'invalid';
    }
    return null;
  }

  static String? validateLongitude(String raw) {
    final value = parseCoordinate(raw);
    if (value == null || !isValidLongitude(value)) {
      return 'invalid';
    }
    return null;
  }

  static bool sameDraft({
    required String label,
    required String addressText,
    required double latitude,
    required double longitude,
    required String otherLabel,
    required String otherAddressText,
    required double? otherLatitude,
    required double? otherLongitude,
    String building = '',
    String floor = '',
    String entrance = '',
    String landmark = '',
    String? otherBuilding,
    String? otherFloor,
    String? otherEntrance,
    String? otherLandmark,
  }) {
    if (otherLatitude == null || otherLongitude == null) {
      return false;
    }
    return label.trim() == otherLabel.trim() &&
        addressText.trim() == otherAddressText.trim() &&
        (latitude - otherLatitude).abs() < 0.000001 &&
        (longitude - otherLongitude).abs() < 0.000001 &&
        building.trim() == (otherBuilding ?? '').trim() &&
        floor.trim() == (otherFloor ?? '').trim() &&
        entrance.trim() == (otherEntrance ?? '').trim() &&
        landmark.trim() == (otherLandmark ?? '').trim();
  }
}
