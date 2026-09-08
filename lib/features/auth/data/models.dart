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

class CustomerMe {
  const CustomerMe({
    required this.customerProfileExists,
    required this.profileComplete,
    required this.addressReady,
    this.profile,
  });

  final bool customerProfileExists;
  final bool profileComplete;
  final bool addressReady;
  final CustomerProfile? profile;

  factory CustomerMe.fromJson(Map<String, dynamic> json) {
    final profileJson = json['profile'];
    return CustomerMe(
      customerProfileExists: json['customerProfileExists'] == true,
      profileComplete: json['profileComplete'] == true,
      addressReady: json['addressReady'] == true,
      profile: profileJson is Map<String, dynamic>
          ? CustomerProfile.fromJson(profileJson)
          : profileJson is Map
          ? CustomerProfile.fromJson(Map<String, dynamic>.from(profileJson))
          : null,
    );
  }

  String? get displayName {
    final name = profile?.fullName.trim();
    if (name == null || name.isEmpty) {
      return null;
    }
    return name;
  }
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
