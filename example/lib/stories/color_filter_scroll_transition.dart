import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

class FashionScrollTransition extends StatefulWidget {
  const FashionScrollTransition({super.key});

  @override
  State<FashionScrollTransition> createState() =>
      _FashionScrollTransitionState();
}

class _FashionScrollTransitionState extends State<FashionScrollTransition> {
  final filterA = ColorFilterEffect(
    matrix: ColorFilterMatrix.sepia,
    mode: BlendMode.overlay,
  );

  final filterB = ColorFilterEffect(
    matrix: ColorFilterMatrix.identity,
    mode: BlendMode.overlay,
  );

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemExtent: 300,
      cacheExtent: 300,
      itemBuilder: (context, index) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          alignment: Alignment.center,
          child: Container(
            width: 500,
            height: 300,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/fashion/fashion_${index % 8}.jpg'),
                fit: BoxFit.fitWidth,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
          ).scrollTransition(
            (context, widget, event) => filterB
                .lerp(filterA, event.screenOffsetFraction.abs())
                .apply(context, widget)
                .clipRRect(BorderRadius.circular(16))
                .scale(event.phase.isIdentity ? 1 : 0.7),
          ),
        );
      },
    );
  }
}
