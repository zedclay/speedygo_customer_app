import 'package:flutter/widgets.dart';
import 'package:speedygo_customer_app/core/money/money_format.dart';
import 'package:speedygo_customer_app/core/widgets/bidi_ltr.dart';

/// Displays [MoneyFormat.dzd] in LTR so DZD amounts stay readable in Arabic.
///
/// Formatting itself is locale-invariant: never change [MoneyFormat].
class MoneyText extends StatelessWidget {
  const MoneyText(
    this.minor, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.textAlign,
  });

  final String minor;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return BidiLtr(
      child: Text(
        MoneyFormat.dzd(minor),
        style: style,
        maxLines: maxLines,
        overflow: overflow,
        textAlign: textAlign,
      ),
    );
  }
}
