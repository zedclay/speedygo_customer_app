import 'package:speedygo_customer_app/features/auth/data/auth_api.dart';
import 'package:speedygo_customer_app/features/auth/data/customer_api.dart';
import 'package:speedygo_customer_app/features/auth/data/models.dart';

class FakeAuthClient implements AuthClient {
  FakeAuthClient();

  TokenPair pair = const TokenPair(
    accessToken: 'access-1',
    refreshToken: 'refresh-1-token-value',
    expiresIn: 900,
    tokenType: 'Bearer',
  );

  TokenPair rotated = const TokenPair(
    accessToken: 'access-2',
    refreshToken: 'refresh-2-token-value',
    expiresIn: 900,
    tokenType: 'Bearer',
  );

  int requestCount = 0;
  int verifyCount = 0;
  int refreshCount = 0;
  int logoutCount = 0;
  int meCount = 0;
  String? lastIdentifier;
  String? lastCode;
  Object? requestError;
  Object? verifyError;
  Object? refreshError;
  Object? logoutError;
  Object? meError;
  Duration? refreshDelay;
  AuthMe meResult = const AuthMe(
    accountId: 'acc-1',
    phone: '+213550123456',
    status: 'ACTIVE',
    hasCustomerProfile: false,
  );

  @override
  Future<void> requestOtp(String identifier) async {
    requestCount += 1;
    lastIdentifier = identifier;
    if (requestError != null) {
      throw requestError!;
    }
  }

  @override
  Future<TokenPair> verifyOtp(OtpVerifyBody body) async {
    verifyCount += 1;
    lastIdentifier = body.identifier;
    lastCode = body.code;
    if (verifyError != null) {
      throw verifyError!;
    }
    return pair;
  }

  @override
  Future<TokenPair> refresh(String refreshToken) async {
    refreshCount += 1;
    if (refreshDelay != null) {
      await Future<void>.delayed(refreshDelay!);
    }
    if (refreshError != null) {
      throw refreshError!;
    }
    return rotated;
  }

  @override
  Future<void> logout() async {
    logoutCount += 1;
    if (logoutError != null) {
      throw logoutError!;
    }
  }

  @override
  Future<void> logoutWithAccessToken(String accessToken) async {
    logoutCount += 1;
    if (logoutError != null) {
      throw logoutError!;
    }
  }

  @override
  Future<AuthMe> me() async {
    meCount += 1;
    if (meError != null) {
      throw meError!;
    }
    return meResult;
  }
}

class FakeCustomerClient implements CustomerClient {
  int meCount = 0;
  int createCount = 0;
  String? lastFullName;
  Object? meError;
  Object? createError;
  CustomerMe meResult = const CustomerMe(
    customerProfileExists: false,
    profileComplete: false,
    addressReady: false,
  );

  @override
  Future<CustomerMe> me() async {
    meCount += 1;
    if (meError != null) {
      throw meError!;
    }
    return meResult;
  }

  @override
  Future<CustomerProfile> createProfile({required String fullName}) async {
    createCount += 1;
    lastFullName = fullName;
    if (createError != null) {
      throw createError!;
    }
    meResult = CustomerMe(
      customerProfileExists: true,
      profileComplete: true,
      addressReady: false,
      profile: CustomerProfile(id: 'p1', fullName: fullName),
    );
    return CustomerProfile(id: 'p1', fullName: fullName);
  }
}
