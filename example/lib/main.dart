import 'dart:math';

import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_box_transform/flutter_box_transform.dart';
import 'package:hyper_effects_demo/stories/color_filter_scroll_transition.dart';
import 'package:hyper_effects_demo/stories/counter_app.dart';
import 'package:hyper_effects_demo/stories/group_animation.dart';
import 'package:hyper_effects_demo/stories/one_shot_reset_animation.dart';
import 'package:hyper_effects_demo/stories/rolling_app_bar_animation.dart';
import 'package:hyper_effects_demo/stories/rolling_pictures_animation.dart';
import 'package:hyper_effects_demo/stories/scroll_phase_slide.dart';
import 'package:hyper_effects_demo/stories/scroll_phase_blur.dart';
import 'package:hyper_effects_demo/stories/scroll_wheel_transition.dart';
import 'package:hyper_effects_demo/stories/shake_and_spring_animation.dart';
import 'package:hyper_effects_demo/stories/success_card_animation.dart';
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
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: Colors.blue,
          surface: const Color(0xFFF0F0F0),
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
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: Colors.blue,
          surface: const Color(0xFF0F0F0F),
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

class _StoryboardState extends State<Storyboard> with WidgetsBindingObserver {
  final List<Story> animationStories = [
    const Story(
      title: 'Success Card Animation',
      child: SuccessCardAnimation()
    ),
    const Story(
      title: 'Group Animation',
      child: GroupAnimation(),
    ),
    const Story(
      title: 'Text Rolling Animations',
      child: TextAnimation(),
    ),
    const Story(
      title: 'Rolling Counter App',
      child: CounterApp(),
    ),
    const Story(
      title: 'One-Shot Reset Animation',
      child: OneShotResetAnimation(),
    ),
    const Story(
      title: 'Spring Animation',
      child: SpringAnimation(),
    ),
    const Story(
      title: 'Rolling Pictures Animation',
      child: RollingWidgetAnimation(),
    ),
    const Story(
      title: 'Rolling App Bar Animation',
      child: RollingAppBarAnimation(),
    ),
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

  bool openDrawer = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final screen = MediaQuery.sizeOf(context);

    if (screen.width > 800) {
      openDrawer = true;
    }
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();

    final screen = MediaQuery.sizeOf(context);
    openDrawer = screen.width > 800;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text(
          'Hyper Effects Storyboard',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            setState(() {
              openDrawer = !openDrawer;
            });
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.brightness_4),
            onPressed: () {
              AdaptiveTheme.of(context).toggleThemeMode();
            },
          ),
        ],
      ),
      body: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutQuart,
            width: openDrawer ? 350 : 0,
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  bottom: 0,
                  left: 0,
                  width: 350,
                  child: SizedBox(
                    width: 350,
                    child: ListView(
                      children: [
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            top: 0,
                          ),
                          child: Text('Animations',
                              style: Theme.of(context).textTheme.titleLarge),
                        ),
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
                                  selectedAnimation =
                                      animationStories.indexOf(story);
                                  selectedTransition = null;
                                });
                              },
                              selected: animationStories.indexOf(story) ==
                                  selectedAnimation,
                            ),
                          ),
                        const Divider(height: 32, indent: 16, endIndent: 16),
                        Padding(
                          padding: const EdgeInsets.only(
                            left: 16,
                            right: 16,
                            bottom: 16,
                            top: 0,
                          ),
                          child: Text('Transitions',
                              style: Theme.of(context).textTheme.titleLarge),
                        ),
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
                                  selectedTransition =
                                      transitionStories.indexOf(story);
                                  selectedAnimation = null;
                                });
                              },
                              selected: transitionStories.indexOf(story) ==
                                  selectedTransition,
                            ),
                          ),
                        const Divider(height: 16),
                      ],
                    ),
                  ),
                ),
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
              child: Center(child: ClipRect(child: widget.child)),
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
