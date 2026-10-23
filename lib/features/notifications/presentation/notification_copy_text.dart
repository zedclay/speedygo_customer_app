import 'package:flutter/material.dart';
import 'package:speedygo_customer_app/core/widgets/bidi_ltr.dart';
import 'package:speedygo_customer_app/features/notifications/application/notification_copy.dart';

/// Title/body whose direction follows the text, not the surrounding layout.
class NotificationCopyText extends StatelessWidget {
  const NotificationCopyText({
    super.key,
    required this.copy,
    required this.style,
    this.maxLines = 8,
    this.isTitle = false,
  });

  final NotificationCopy copy;
  final TextStyle? style;
  final int maxLines;
  final bool isTitle;

  @override
  Widget build(BuildContext context) {
    final raw = isTitle ? copy.title : copy.body;
    if (raw.isEmpty) {
      return const SizedBox.shrink();
    }
    final layoutDirection = Directionality.of(context);
    final guess = guessTextDirection(raw);
    final direction = switch (guess) {
      TextDirectionGuess.rtl => TextDirection.rtl,
      TextDirectionGuess.ltr => TextDirection.ltr,
      TextDirectionGuess.neutral => layoutDirection,
    };
    final token = copy.publicReference;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          raw,
          style: style,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          textDirection: direction,
          textAlign: TextAlign.start,
        ),
        if (!isTitle &&
            token != null &&
            token.isNotEmpty &&
            !raw.contains(token)) ...[
          const SizedBox(height: 4),
          BidiLtr(
            child: Text(token, style: style),
          ),
        ],
      ],
    );
  }
}
