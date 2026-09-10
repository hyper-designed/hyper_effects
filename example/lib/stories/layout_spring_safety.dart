import 'package:hyper_effects/hyper_effects.dart';
import 'package:material_ui/material_ui.dart';

import 'story_scaffold.dart';

class LayoutSpringSafetyStory extends StatefulWidget {
  const LayoutSpringSafetyStory({super.key});

  @override
  State<LayoutSpringSafetyStory> createState() =>
      _LayoutSpringSafetyStoryState();
}

class _LayoutSpringSafetyStoryState extends State<LayoutSpringSafetyStory> {
  int trigger = 0;
  bool expanded = false;

  void _setExpanded(bool value) {
    setState(() {
      expanded = value;
      trigger++;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    const motion = CupertinoMotion.bouncy(extraBounce: 0.12);

    Widget lane(String label, Widget demo, String note) => Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      )),
              const SizedBox(height: 12),
              SizedBox(height: 92, child: Center(child: demo)),
              const SizedBox(height: 10),
              Text(note, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        );

    return StoryScaffold(
      title: 'Layout Spring Safety',
      description: 'Real layout values may overshoot. Positive bounce stays '
          'visible; unsafe negative dimensions and factors stop at zero.',
      maxWidth: 820,
      children: [
        const SizedBox(height: 28),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 3 : 1;
            final width = columns == 3
                ? (constraints.maxWidth - 24) / 3
                : constraints.maxWidth;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: width,
                  child: lane(
                    'SIZE',
                    Container(
                      key: const Key('safety-size-box'),
                      height: 42,
                      decoration: BoxDecoration(
                        color: colors.primary,
                        borderRadius: BorderRadius.circular(12),
                      ),
                    )
                        .widthTo(expanded ? 150 : 0, from: 0)
                        .animate(trigger: trigger, motion: motion),
                    'Width bounces beyond target, but never below 0.',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: lane(
                    'PADDING',
                    // The decorated frame hugs the animated Padding, so
                    // the growing insets paint as a visible halo. Bare
                    // padding around a centered box would be invisible.
                    Container(
                      key: const Key('safety-padding-frame'),
                      decoration: BoxDecoration(
                        color: colors.tertiaryContainer,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Container(
                        key: const Key('safety-padding-box'),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: colors.tertiary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      )
                          .padAll(expanded ? 24 : 0)
                          .animate(trigger: trigger, motion: motion),
                    ),
                    'Insets keep outward overshoot and floor undershoot.',
                  ),
                ),
                SizedBox(
                  width: width,
                  child: lane(
                    'ALIGN FACTOR',
                    // The decorated frame hugs the animated Align, so
                    // the width factor paints as a visible strip
                    // stretching around the circle.
                    Container(
                      key: const Key('safety-align-frame'),
                      decoration: BoxDecoration(
                        color: colors.secondaryContainer,
                        borderRadius: BorderRadius.circular(21),
                      ),
                      child: Container(
                        key: const Key('safety-align-box'),
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: colors.secondary,
                          shape: BoxShape.circle,
                        ),
                      )
                          .align(
                            Alignment.center,
                            widthFactor: expanded ? 2.2 : 0,
                            fromWidthFactor: 0,
                          )
                          .animate(trigger: trigger, motion: motion),
                    ),
                    'Width factor can bounce, while layout sees ≥ 0.',
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 26),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            FilledButton.icon(
              onPressed: () => _setExpanded(true),
              icon: const Icon(Icons.open_in_full_rounded),
              label: const Text('Overshoot outward'),
            ),
            OutlinedButton.icon(
              onPressed: () => _setExpanded(false),
              icon: const Icon(Icons.close_fullscreen_rounded),
              label: const Text('Shrink through floor'),
            ),
          ],
        ),
      ],
    );
  }
}
