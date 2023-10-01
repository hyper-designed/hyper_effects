import 'package:flutter/widgets.dart';

abstract class Effect {
  const Effect();

  Effect lerp(covariant Effect other, double value);

  Widget apply(BuildContext context, Widget child);
}
