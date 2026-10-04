class SessionParseException implements Exception {
  const SessionParseException();
}

class TokenPair {
  const TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;

  factory TokenPair.fromJson(Map<String, dynamic> json) {
    final access = json['accessToken']?.toString();
    final refresh = json['refreshToken']?.toString();
    final type = json['tokenType']?.toString() ?? 'Bearer';
    final expires = json['expiresIn'];
    if (access == null ||
        access.isEmpty ||
        refresh == null ||
        refresh.isEmpty) {
      throw const SessionParseException();
    }
    return TokenPair(
      accessToken: access,
      refreshToken: refresh,
      expiresIn: expires is int ? expires : int.tryParse('$expires') ?? 0,
      tokenType: type,
    );
  }

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresIn': expiresIn,
    'tokenType': tokenType,
  };
}

class AuthMe {
  const AuthMe({
    required this.accountId,
    required this.phone,
    required this.status,
    required this.hasCustomerProfile,
  });

  final String accountId;
  final String? phone;
  final String status;
  final bool hasCustomerProfile;

  factory AuthMe.fromJson(Map<String, dynamic> json) {
    final account = json['account'];
    final profiles = json['profiles'];
    if (account is! Map) {
      throw const SessionParseException();
    }
    return AuthMe(
      accountId: account['id']?.toString() ?? '',
      phone: account['phone']?.toString(),
      status: account['status']?.toString() ?? '',
      hasCustomerProfile: profiles is Map
          ? profiles['hasCustomerProfile'] == true
          : false,
    );
  }
}

class CustomerProfile {
  const CustomerProfile({
    required this.id,
    required this.fullName,
    this.avatarUrl,
  });

  final String id;
  final String fullName;
  final String? avatarUrl;

  factory CustomerProfile.fromJson(Map<String, dynamic> json) {
    return CustomerProfile(
      id: json['id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }
}

class CustomerAddress {
  const CustomerAddress({
    required this.id,
    required this.label,
    required this.addressText,
    required this.isDefault,
    this.latitude,
    this.longitude,
  });

  final String id;
  final String label;
  final String addressText;
  final bool isDefault;
  final double? latitude;
  final double? longitude;

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: json['id']?.toString() ?? '',
      label: json['label']?.toString() ?? '',
      addressText: json['addressText']?.toString() ?? '',
      isDefault: json['isDefault'] == true,
      latitude: _parseCoord(json['latitude']),
      longitude: _parseCoord(json['longitude']),
    );
  }

  CustomerAddress copyWith({
    String? id,
    String? label,
    String? addressText,
    bool? isDefault,
    double? latitude,
    double? longitude,
  }) {
    return CustomerAddress(
      id: id ?? this.id,
      label: label ?? this.label,
      addressText: addressText ?? this.addressText,
      isDefault: isDefault ?? this.isDefault,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  /// Contract `label`, or `addressText` when the label is empty.
  String get displayLabel {
    final trimmed = label.trim();
    if (trimmed.isNotEmpty) {
      return trimmed;
    }
    return addressText.trim();
  }
}

double? _parseCoord(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  if (value is String) {
    return double.tryParse(value.trim());
  }
  return null;
}

class CustomerMe {
  const CustomerMe({
    required this.customerProfileExists,
    required this.profileComplete,
    required this.addressReady,
    this.profile,
    this.addresses = const [],
    this.defaultAddressId,
  });

  final bool customerProfileExists;
  final bool profileComplete;
  final bool addressReady;
  final CustomerProfile? profile;
  final List<CustomerAddress> addresses;
  final String? defaultAddressId;

  factory CustomerMe.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profile'];
    final defaultId = json['defaultAddressId']?.toString();
    return CustomerMe(
      customerProfileExists: json['customerProfileExists'] == true,
      profileComplete: json['profileComplete'] == true,
      addressReady: json['addressReady'] == true,
      profile: profileJson is Map<String, dynamic>
          ? CustomerProfile.fromJson(profileJson)
          : profileJson is Map
          ? CustomerProfile.fromJson(Map<String, dynamic>.from(profileJson))
          : null,
      addresses: _parseAddresses(json['addresses']),
      defaultAddressId: defaultId == null || defaultId.isEmpty
          ? null
          : defaultId,
    );
  }

  String? get displayName {
    final name = profile?.fullName.trim();
    if (name == null || name.isEmpty) {
      return null;
    }
    return name;
  }

  /// Server default address only. Home may show a temporary selection separately.
  CustomerAddress? get deliveryAddress {
    if (addresses.isEmpty) {
      return null;
    }
    if (defaultAddressId != null) {
      for (final address in addresses) {
        if (address.id == defaultAddressId) {
          return address;
        }
      }
    }
    for (final address in addresses) {
      if (address.isDefault) {
        return address;
      }
    }
    return null;
  }

  /// Uses the contract `label`, or `addressText` when the label is empty.
  String? get deliverToLabel {
    final address = deliveryAddress;
    if (address == null) {
      return null;
    }
    final label = address.displayLabel;
    return label.isEmpty ? null : label;
  }
}

List<CustomerAddress> _parseAddresses(Object? raw) {
  if (raw is! List) {
    return const [];
  }
  final addresses = <CustomerAddress>[];
  for (final item in raw) {
    if (item is! Map) {
      continue;
    }
    final address = CustomerAddress.fromJson(Map<String, dynamic>.from(item));
    if (address.id.isEmpty) {
      continue;
    }
    addresses.add(address);
  }
  return addresses;
}

class OtpRequestBody {
  const OtpRequestBody({required this.identifier});

  final String identifier;

  Map<String, dynamic> toJson() => {
    'channel': 'PHONE',
    'identifier': identifier,
    'purpose': 'AUTHENTICATE',
  };
}

class OtpVerifyBody {
  const OtpVerifyBody({
    required this.identifier,
    required this.code,
    required this.platform,
    required this.appVersion,
    this.deviceId,
    this.deviceName,
  });

  final String identifier;
  final String code;
  final String platform;
  final String appVersion;
  final String? deviceId;
  final String? deviceName;

  Map<String, dynamic> toJson() {
    return {
      'channel': 'PHONE',
      'identifier': identifier,
      'purpose': 'AUTHENTICATE',
      'code': code,
      'platform': platform,
      'appVersion': appVersion,
      if (deviceId != null) 'deviceId': deviceId,
      if (deviceName != null) 'deviceName': deviceName,
    };
  }
}

/// Account-owned auth session row from `GET /auth/sessions`.
class AuthSession {
  const AuthSession({
    required this.id,
    required this.deviceId,
    required this.platform,
    required this.deviceName,
    required this.createdAt,
    required this.expiresAt,
    required this.revoked,
    required this.currentSession,
  });

  final String id;
  final String? deviceId;
  final String? platform;
  final String? deviceName;
  final String createdAt;
  final String expiresAt;
  final bool revoked;
  final bool currentSession;

  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString();
    if (id == null || id.isEmpty) {
      throw const SessionParseException();
    }
    return AuthSession(
      id: id,
      deviceId: json['deviceId']?.toString(),
      platform: json['platform']?.toString(),
      deviceName: json['deviceName']?.toString(),
      createdAt: json['createdAt']?.toString() ?? '',
      expiresAt: json['expiresAt']?.toString() ?? '',
      revoked: json['revoked'] == true,
      currentSession: json['currentSession'] == true,
    );
  }
}
