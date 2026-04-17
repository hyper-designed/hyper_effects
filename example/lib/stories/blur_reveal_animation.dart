import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hyper_effects/hyper_effects.dart';

class BlurRevealStory extends StatefulWidget {
  const BlurRevealStory({super.key});

  @override
  State<BlurRevealStory> createState() => _BlurRevealStoryState();
}

class _BlurRevealStoryState extends State<BlurRevealStory> {
  int _trigger = 0;

  void _replay() => setState(() => _trigger++);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const _Label('DEFAULT'),
            Text(
              'Hello, World!',
              style: GoogleFonts.inter(fontSize: 48),
            )
                .blurReveal()
                .animate(
                  trigger: _trigger,
                  duration: const Duration(milliseconds: 900),
                  startState: AnimationStartState.playImmediately,
                ),
            const SizedBox(height: 40),
            const _Label('FAST REVEAL, NO RISE'),
            Text(
              'Welcome back',
              style: GoogleFonts.inter(fontSize: 40),
            )
                .blurReveal(
                  speedReveal: 2.5,
                  riseFrom: Offset.zero,
                )
                .animate(
                  trigger: _trigger,
                  duration: const Duration(milliseconds: 900),
                  startState: AnimationStartState.playImmediately,
                ),
            const SizedBox(height: 40),
            const _Label('SLOW REVEAL, DEEPER BLUR'),
            Text(
              'ease into it',
              style: GoogleFonts.inter(fontSize: 36),
            )
                .blurReveal(
                  speedReveal: 0.75,
                  blurSigma: 16,
                )
                .animate(
                  trigger: _trigger,
                  duration: const Duration(milliseconds: 1400),
                  startState: AnimationStartState.playImmediately,
                ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: _replay,
              child: const Text('Replay'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            letterSpacing: 1.2,
          ),
        ),
      );
}
