import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hyper_effects/hyper_effects.dart';

class TextAnimation extends StatefulWidget {
  const TextAnimation({super.key});

  @override
  State<TextAnimation> createState() => _TextAnimationState();
}

class _TextAnimationState extends State<TextAnimation> {
  bool selected = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          selected = !selected;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(32),
        alignment: Alignment.center,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                // width: 500,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.onPrimary,
                    width: 2,
                  ),
                ),
                // clipBehavior: Clip.hardEdge,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Hello, ',
                      style: GoogleFonts.inter().copyWith(
                        color: Colors.white,
                        fontSize: 32,
                        fontFeatures: [const FontFeature.tabularFigures()],
                      ),
                      strutStyle: const StrutStyle(
                        fontSize: 32,
                        height: 1,
                        forceStrutHeight: true,
                      ),
                    ),
                    Text(
                      'Saad Ardati',
                      style: GoogleFonts.inter().copyWith(
                        color: Colors.white,
                        fontSize: 32,
                      ),
                      strutStyle: const StrutStyle(
                        fontSize: 32,
                        height: 1,
                        // leading: 2,
                        forceStrutHeight: true,
                      ),
                    )
                        .roll(
                          'Birju Vachhani',
                          symbolDistanceMultiplier: 2,
                          staggerSoftness: 10,
                          tapeStrategy: const ConsistentSymbolTapeStrategy(0, true),
                          // clipBehavior: Clip.none,
                        )
                        .animate(
                          toggle: selected,
                          reverse: true,
                          duration: const Duration(milliseconds: 500),
                          // curve: Curves.easeInOutQuart,
                        ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Container(
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
                clipBehavior: Clip.hardEdge,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Icon(Icons.thumb_up_sharp, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      '10.3',
                      style: GoogleFonts.robotoTextTheme()
                          .bodyMedium!
                          .copyWith(color: Colors.white, fontSize: 16),
                    )
                        .roll(
                          '21',
                          symbolDistanceMultiplier: 2,
                          clipBehavior: Clip.none,
                          widthDuration: const Duration(milliseconds: 350),
                        )
                        .animate(
                          toggle: selected,
                          reverse: true,
                          duration: const Duration(milliseconds: 1000),
                        ),
                    Text(
                      'K',
                      style: GoogleFonts.robotoTextTheme()
                          .bodyMedium!
                          .copyWith(color: Colors.white, fontSize: 16),
                      strutStyle: const StrutStyle(
                        fontSize: 16,
                        height: 1,
                        forceStrutHeight: true,
                        leading: 1,
                      ),
                    ),
                    VerticalDivider(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer
                          .withOpacity(0.5),
                      indent: 4,
                      endIndent: 4,
                    ),
                    const Icon(Icons.thumb_down_sharp, size: 18),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
