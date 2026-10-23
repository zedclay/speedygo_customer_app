import 'package:flutter/widgets.dart';

/// Forces LTR for phones, order references, and other Latin tokens inside RTL.
class BidiLtr extends StatelessWidget {
  const BidiLtr({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: child,
    );
  }
}
