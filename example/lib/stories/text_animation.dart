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
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'hello, this is a very boring text.',
              textAlign: TextAlign.start,
              style: GoogleFonts.robotoMonoTextTheme()
                  .bodyMedium!
                  .copyWith(color: Colors.white),
            ).roll('hello everyone, this is a very sexy text.').animate(
                  toggle: selected,
                  reverse: true,
                  duration: const Duration(milliseconds: 1000),
                ),
            const SizedBox(height: 16),
            Text(
              '103 views',
              textAlign: TextAlign.start,
              style: GoogleFonts.robotoMonoTextTheme()
                  .bodyMedium!
                  .copyWith(color: Colors.white),
            ).roll('420 views').animate(
                  toggle: selected,
                  reverse: true,
                  duration: const Duration(milliseconds: 1000),
                ),
          ],
        ),
      ),
    );
  }
}
