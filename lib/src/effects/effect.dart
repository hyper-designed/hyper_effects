import 'package:flutter/widgets.dart';

abstract class Effect {
  const Effect();

  Effect lerp(Effect other, double value);

  Widget apply(BuildContext context, Widget child);
}
