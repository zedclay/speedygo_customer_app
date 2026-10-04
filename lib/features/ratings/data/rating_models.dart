class RatingParseException implements Exception {
  const RatingParseException([this.message = 'Invalid rating payload']);

  final String message;

  @override
  String toString() => message;
}

const ratingScoreMin = 1;
const ratingScoreMax = 5;
const ratingCommentMaxLength = 2000;

class RatingSummary {
  const RatingSummary({
    required this.targetType,
    required this.targetId,
    required this.count,
    this.average,
  });

  final String targetType;
  final String targetId;
  final int count;
  final double? average;

  bool get hasDisplayableRating => count > 0 && average != null;

  String get displayAverage {
    final value = average;
    if (value == null) {
      return '';
    }
    final two = value.toStringAsFixed(2);
    if (two.endsWith('0')) {
      return value.toStringAsFixed(1);
    }
    return two;
  }

  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    final countRaw = json['count'];
    final count = countRaw is int
        ? countRaw
        : int.tryParse(countRaw?.toString() ?? '');
    if (count == null) {
      throw const RatingParseException('count is required');
    }
    final averageRaw = json['average'];
    double? average;
    if (averageRaw is num) {
      average = averageRaw.toDouble();
    }
    final targetId = json['targetId']?.toString() ?? '';
    if (targetId.isEmpty) {
      throw const RatingParseException('targetId is required');
    }
    return RatingSummary(
      targetType: json['targetType']?.toString() ?? '',
      targetId: targetId,
      count: count,
      average: average,
    );
  }
}

/// Author-own merchant or driver rating (no reviewer identity fields).
class OrderRating {
  const OrderRating({
    required this.id,
    required this.orderId,
    required this.targetType,
    required this.targetId,
    required this.score,
    required this.comment,
    required this.createdAt,
  });

  final String id;
  final String orderId;
  final String targetType;
  final String targetId;
  final int score;
  final String? comment;
  final String createdAt;

  bool get isMerchant => targetType == 'MERCHANT';
  bool get isDriver => targetType == 'DRIVER';

  factory OrderRating.fromJson(Map<String, dynamic> json) {
    final targetType = json['targetType']?.toString() ?? '';
    final targetId = targetType == 'DRIVER'
        ? (json['driverId']?.toString() ?? '')
        : (json['merchantId']?.toString() ?? '');
    final scoreRaw = json['score'];
    final score = scoreRaw is int
        ? scoreRaw
        : int.tryParse(scoreRaw?.toString() ?? '');
    if (score == null) {
      throw const RatingParseException('score is required');
    }
    final id = json['id']?.toString() ?? '';
    final orderId = json['orderId']?.toString() ?? '';
    final createdAt = json['createdAt']?.toString() ?? '';
    if (id.isEmpty || orderId.isEmpty || targetId.isEmpty || createdAt.isEmpty) {
      throw const RatingParseException('rating identity fields missing');
    }
    final commentRaw = json['comment']?.toString();
    return OrderRating(
      id: id,
      orderId: orderId,
      targetType: targetType,
      targetId: targetId,
      score: score,
      comment: (commentRaw == null || commentRaw.isEmpty) ? null : commentRaw,
      createdAt: createdAt,
    );
  }
}

class CreateRatingRequest {
  const CreateRatingRequest({required this.score, this.comment});

  final int score;
  final String? comment;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'score': score};
    final trimmed = comment?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      json['comment'] = trimmed;
    }
    return json;
  }
}

bool isValidRatingScore(int? score) =>
    score != null && score >= ratingScoreMin && score <= ratingScoreMax;

bool isValidRatingComment(String? comment) {
  final trimmed = comment?.trim() ?? '';
  return trimmed.length <= ratingCommentMaxLength;
}
