class AddressPolicy {
  AddressPolicy._();

  static const labelMaxLength = 64;
  static const addressTextMaxLength = 500;
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
    return value >= minLatitude && value <= maxLatitude;
  }

  static bool isValidLongitude(double value) {
    return value >= minLongitude && value <= maxLongitude;
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
  }) {
    if (otherLatitude == null || otherLongitude == null) {
      return false;
    }
    return label.trim() == otherLabel.trim() &&
        addressText.trim() == otherAddressText.trim() &&
        (latitude - otherLatitude).abs() < 0.000001 &&
        (longitude - otherLongitude).abs() < 0.000001;
  }
}
