import 'dart:math';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_box_transform/flutter_box_transform.dart';
import 'package:hyper_effects_demo/stories/chained_animation.dart';
import 'package:hyper_effects_demo/stories/color_filter_scroll_transition.dart';
import 'package:hyper_effects_demo/stories/counter_app.dart';
import 'package:hyper_effects_demo/stories/scroll_phase_transition.dart';
import 'package:hyper_effects_demo/stories/scroll_wheel_blur.dart';
import 'package:hyper_effects_demo/stories/scroll_wheel_transition.dart';
import 'package:hyper_effects_demo/stories/spring_animation.dart';
import 'package:hyper_effects_demo/stories/text_animation.dart';
import 'package:hyper_effects_demo/stories/windows_settings_transition.dart';

import 'story.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AdaptiveTheme(
      light: ThemeData(
        useMaterial3: true,
        // brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: Colors.blue,
          background: const Color(0xFF0F0F0F),
        ),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
      dark: ThemeData(
        useMaterial3: true,
        // brightness: Brightness.dark,
        // colorSchemeSeed: Colors.blue,
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: Colors.blue,
          background: const Color(0xFF0F0F0F),
        ),
        inputDecorationTheme: InputDecorationTheme(
          isDense: true,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
          ),
        ),
      ),
      initial: AdaptiveThemeMode.system,
      builder: (theme, darkTheme) => MaterialApp(
        title: 'Hyper Effects Storyboard',
        debugShowCheckedModeBanner: false,
        theme: theme,
        darkTheme: darkTheme,
        home: const Storyboard(),
      ),
    );
  }
}

class Storyboard extends StatefulWidget {
  const Storyboard({super.key});

  @override
  State<Storyboard> createState() => _StoryboardState();
}

class _StoryboardState extends State<Storyboard> {
  final List<Story> animationStories = [
    const Story(
      title: 'Spring Animation',
      child: SpringAnimation(),
    ),
    const Story(
      title: 'Text Animations',
      child: TextAnimation(),
    ),
    const Story(
      title: 'Chained Animation',
      child: ChainedAnimation(),
    ),
    const Story(
      title: 'Counter App',
      child: CounterApp(),
    ),
    // const Story(
    //   title: 'Chained Animation',
    //   child: ChainedAnimation(),
    // )
  ];
  final List<Story> transitionStories = [
    const Story(
      title: 'Scroll Phase Transition',
      child: ScrollPhaseTransition(),
    ),
    const Story(
      title: 'Scroll Wheel Blur Transition',
      child: ScrollWheelBlurTransition(),
    ),
    const Story(
      title: 'Scroll Wheel Transition',
      child: ScrollWheelTransition(),
    ),
    const Story(
      title: 'Windows Settings Effect',
      child: WindowsSettingsTransition(),
    ),
    const Story(
      title: 'Color Filter Scroll Transition',
      child: FashionScrollTransition(),
    ),
  ];

  int? selectedAnimation;
  int? selectedTransition;
  int? selectedCategory;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SizedBox(
            width: 300,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Hyper Effects Storyboard',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Divider(height: 0),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Animations',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                // CustomExpansionTile(
                //   title: const Text('Animations'),
                //   isExpanded: selectedCategory == 0,
                //   onExpansionChanged: () {
                //     setState(() {
                //       if (selectedCategory == 0) {
                //         selectedCategory = null;
                //       } else {
                //         selectedCategory = 0;
                //       }
                //     });
                //   },
                //   children: [
                for (final Story story in animationStories)
                  Material(
                    type: MaterialType.transparency,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      title: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(story.title),
                      ),
                      onTap: () {
                        setState(() {
                          selectedAnimation = animationStories.indexOf(story);
                          selectedTransition = null;
                        });
                      },
                      selected:
                          animationStories.indexOf(story) == selectedAnimation,
                    ),
                  ),
                // ],
                // ),
                const Divider(height: 0, indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text('Transitions',
                      style: Theme.of(context).textTheme.titleLarge),
                ),
                // CustomExpansionTile(
                //   title: const Text('Transitions'),
                //   isExpanded: selectedCategory == 1,
                //   onExpansionChanged: () {
                //     setState(() {
                //       if (selectedCategory == 1) {
                //         selectedCategory = null;
                //       } else {
                //         selectedCategory = 1;
                //       }
                //     });
                //   },
                //   children: [
                for (final Story story in transitionStories)
                  Material(
                    type: MaterialType.transparency,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(32),
                      bottomRight: Radius.circular(32),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListTile(
                      title: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Text(story.title),
                      ),
                      onTap: () {
                        setState(() {
                          selectedTransition = transitionStories.indexOf(story);
                          selectedAnimation = null;
                        });
                      },
                      selected: transitionStories.indexOf(story) ==
                          selectedTransition,
                    ),
                  ),
                // ],
                // ),
                const Divider(height: 0),
              ],
            ),
          ),
          // const VerticalDivider(width: 2),
          Expanded(
            flex: 3,
            child: ContentView(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: selectedAnimation != null
                    ? animationStories[selectedAnimation!].child
                    : selectedTransition != null
                        ? transitionStories[selectedTransition!].child
                        : const Center(
                            child: Text('Select a story to view.'),
                          ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ContentView extends StatefulWidget {
  final Widget child;

  const ContentView({super.key, required this.child});

  @override
  State<ContentView> createState() => _ContentViewState();
}

class _ContentViewState extends State<ContentView> with WidgetsBindingObserver {
  final GlobalKey _key = GlobalKey();

  final TransformableBoxController controller = TransformableBoxController(
    resizeModeResolver: () {
      final pressedKeys = WidgetsBinding.instance.keyboard.logicalKeysPressed;

      final isShiftPressed =
          pressedKeys.contains(LogicalKeyboardKey.shiftLeft) ||
              pressedKeys.contains(LogicalKeyboardKey.shiftRight);

      if (isShiftPressed) {
        return ResizeMode.symmetricScale;
      } else {
        return ResizeMode.symmetric;
      }
    },
    allowFlippingWhileResizing: false,
  );

  @override
  void initState() {
    super.initState();

    controller
        .setConstraints(const BoxConstraints(minHeight: 200, minWidth: 200));

    SchedulerBinding.instance.addPostFrameCallback((_) {
      controller.setClampingRect(getArea(), notify: false);
      controller.setRect(Rect.fromCenter(
        center: controller.clampingRect.center,
        width: min(1000, controller.clampingRect.width),
        height: controller.clampingRect.height,
      ));
      if (mounted) setState(() {});
    });

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    controller.setClampingRect(getArea());
    controller.setRect(getRect(), recalculate: true);

    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant ContentView oldWidget) {
    super.didUpdateWidget(oldWidget);

    controller.setRect(getRect(), recalculate: true);
  }

  Rect getArea() {
    final RenderBox renderBox =
        _key.currentContext?.findRenderObject() as RenderBox;
    final size = renderBox.size;
    return Rect.fromLTWH(0, 0, size.width, size.height).deflate(16);
  }

  Rect getRect() {
    Rect rect = controller.rect;
    rect = Rect.fromCenter(
      center: controller.clampingRect.center,
      width: min(controller.clampingRect.width, rect.width),
      height: min(controller.clampingRect.height, rect.height),
    );
    return rect;
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _key,
      children: [
        TransformableBox(
          controller: controller,
          draggable: false,
          allowContentFlipping: false,
          contentBuilder: (BuildContext context, Rect rect, Flip flip) {
            return DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignOutside,
                ),
              ),
              child: Center(child: widget.child),
            );
          },
        ),
      ],
    );
  }
}

class CustomExpansionTile extends StatefulWidget {
  final Widget title;
  final List<Widget> children;
  final bool isExpanded;
  final VoidCallback onExpansionChanged;

  const CustomExpansionTile({
    super.key,
    required this.title,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.children,
  });

  @override
  State<CustomExpansionTile> createState() => _CustomExpansionTileState();
}

class _CustomExpansionTileState extends State<CustomExpansionTile> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          title: widget.title,
          trailing: const Icon(Icons.expand_more),
          onTap: widget.onExpansionChanged,
        ),
        ClipRect(
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuart,
            heightFactor: widget.isExpanded ? 1 : 0,
            alignment: Alignment.topCenter,
            child: ColoredBox(
              color: Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withOpacity(0.05),
              child: Column(
                children: widget.children,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
