/// Customer Payment aggregate + initiate view (backend Payments Foundation).
class CustomerPayment {
  const CustomerPayment({
    required this.paymentId,
    required this.method,
    required this.status,
    required this.amountMinor,
    required this.currency,
    required this.provider,
    required this.createdAt,
    required this.updatedAt,
  });

  final String paymentId;
  final String method;
  final String status;
  final String amountMinor;
  final String currency;
  final String? provider;
  final String createdAt;
  final String updatedAt;

  bool get isElectronic => method == 'ELECTRONIC';

  bool get isTerminal =>
      status == 'SUCCEEDED' || status == 'CANCELLED' || status == 'FAILED';

  bool get isSucceeded => status == 'SUCCEEDED';

  bool get canInitiate =>
      isElectronic &&
      (status == 'PENDING' || status == 'PROCESSING' || status == 'FAILED');

  factory CustomerPayment.fromJson(Map<String, dynamic> json) {
    return CustomerPayment(
      paymentId: _req(json, 'paymentId'),
      method: _req(json, 'method'),
      status: _req(json, 'status'),
      amountMinor: _req(json, 'amountMinor'),
      currency: _req(json, 'currency'),
      provider: json['provider']?.toString(),
      createdAt: _req(json, 'createdAt'),
      updatedAt: _req(json, 'updatedAt'),
    );
  }
}

class CustomerPaymentInitiate extends CustomerPayment {
  const CustomerPaymentInitiate({
    required super.paymentId,
    required super.method,
    required super.status,
    required super.amountMinor,
    required super.currency,
    required super.provider,
    required super.createdAt,
    required super.updatedAt,
    required this.attemptId,
    required this.checkoutUrl,
  });

  final String attemptId;
  final String? checkoutUrl;

  bool get isTestCheckoutUrl {
    final url = checkoutUrl?.trim() ?? '';
    return url.startsWith('test://');
  }

  factory CustomerPaymentInitiate.fromJson(Map<String, dynamic> json) {
    return CustomerPaymentInitiate(
      paymentId: _req(json, 'paymentId'),
      method: _req(json, 'method'),
      status: _req(json, 'status'),
      amountMinor: _req(json, 'amountMinor'),
      currency: _req(json, 'currency'),
      provider: json['provider']?.toString(),
      createdAt: _req(json, 'createdAt'),
      updatedAt: _req(json, 'updatedAt'),
      attemptId: _req(json, 'attemptId'),
      checkoutUrl: json['checkoutUrl']?.toString(),
    );
  }

  CustomerPayment get asPayment => CustomerPayment(
    paymentId: paymentId,
    method: method,
    status: status,
    amountMinor: amountMinor,
    currency: currency,
    provider: provider,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );
}

String _req(Map<String, dynamic> json, String key) {
  final value = json[key]?.toString();
  if (value == null || value.isEmpty) {
    throw FormatException('Missing payment field $key');
  }
  return value;
}

bool paymentStatusIsTerminal(String status) {
  return status == 'SUCCEEDED' ||
      status == 'CANCELLED' ||
      status == 'FAILED';
}
