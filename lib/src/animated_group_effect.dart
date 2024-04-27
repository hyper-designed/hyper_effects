import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

import '../hyper_effects.dart';

/// A builder that wraps the given [children] list in some
/// [MultiChildRenderObjectWidget] such as a [Stack], [Row], [Column], [Wrap],
/// etc.
///
/// The point of this builder is to enable the [AnimatedGroup] to re-wrap
/// each child of the [children] list with an [AnimatedChild] widget.
typedef ChildrenBuilder = Widget Function(
  BuildContext context,
  List<Widget> children,
);

/// A builder that wraps the given [child] in a widget that animates the
/// removal of the child out of the widget tree.
///
/// The reference to the [child] that has been removed is passed to the
/// [RemovedChildBuilder] so that it can be animated out.
typedef RemovedChildBuilder = Widget Function(
  BuildContext context,
  Widget child,
);

/// A builder that wraps the given [child] in a widget that animates the
/// addition or insertion of the child into the widget tree.
///
/// The [skipIf] callback can be used to determine whether the animation
/// should be skipped to the end or not, so as to avoid "initial" animations
/// when the widget is first built. For example, you may want a row of widgets
/// to appear as normal without animating when your screen renders for the first
/// time, but subsequent insertions should animate.
typedef AddedChildBuilder = Widget Function(
  BuildContext context,
  Widget child,
  BooleanCallback skipIf,
);

/// A builder that wraps the given [child] in a widget that animates the
/// swapping of the child with another child in the widget tree.
typedef SwappedChildBuilder = Widget Function(
  BuildContext context,
  Widget child,
);

Widget _defaultRemovedChildBuilder(BuildContext context, Widget child) => child
    .fadeOut()
    .align(
      Alignment.center,
      heightFactor: 0,
      widthFactor: 0,
      fromHeightFactor: 1,
      fromWidthFactor: 1,
    )
    .oneShot(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutQuart,
    );

Widget _defaultAddedChildBuilder(
        BuildContext context, Widget child, BooleanCallback skipIf) =>
    child.slideInFromTop(value: -50).fadeIn().oneShot(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutQuart,
          skipIf: skipIf,
        );

Widget _defaultSwappedChildBuilder(
  BuildContext context,
  Widget child,
) =>
    child.roll(multiplier: 2).clip(0).animate(
          trigger: child.key,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOutQuart,
        );

/// A widget that animates the addition, removal, or swapping of a group of
/// widgets automatically.
class AnimatedGroup extends StatefulWidget {
  /// The list of children to animate.
  final List<Widget> children;

  /// The builder that wraps the [children] list in a
  /// [MultiChildRenderObjectWidget] such as a [Stack], [Row], [Column], [Wrap],
  /// etc.
  final ChildrenBuilder builder;

  /// The builder that wraps the given [child] in a widget that animates the
  /// removal of the child out of the widget tree.
  final RemovedChildBuilder removeBuilder;

  /// The builder that wraps the given [child] in a widget that animates the
  /// addition or insertion of the child into the widget tree.
  final AddedChildBuilder addBuilder;

  /// The builder that wraps the given [child] in a widget that animates the
  /// swapping of the child with another child in the widget tree.
  final SwappedChildBuilder swapBuilder;

  /// Whether to trigger the addition of the children immediately when the
  /// widget is built for the first time, or only for subsequent insertions
  /// of children. For example, you may want a row of widgets
  /// to appear as normal without animating when your screen renders for the
  /// first time, but subsequent insertions should animate.
  final bool triggerAddImmediately;

  /// Whether to use the swap animation when possible. If set to `false`, the
  /// swap animation will be skipped and the new child will have the
  /// [addBuilder] applied to it and the old child will have the
  /// [removeBuilder] applied to it.
  final bool useSwapWhenPossible;

  /// Creates an [AnimatedGroup] with the given parameters.
  const AnimatedGroup({
    super.key,
    required this.children,
    required this.builder,
    this.removeBuilder = _defaultRemovedChildBuilder,
    this.addBuilder = _defaultAddedChildBuilder,
    this.swapBuilder = _defaultSwappedChildBuilder,
    this.triggerAddImmediately = false,
    this.useSwapWhenPossible = true,
  });

  @override
  State<AnimatedGroup> createState() => _AnimatedGroupState();
}

class _AnimatedGroupState extends State<AnimatedGroup> {
  late int longestChildCount = widget.children.length;

  late bool triggerAdd = widget.triggerAddImmediately;

  @override
  void didUpdateWidget(covariant AnimatedGroup oldWidget) {
    super.didUpdateWidget(oldWidget);

    triggerAdd = true;
    if (const ListEquality().equals(
            oldWidget.children.map((child) => child.key).toList(),
            widget.children.map((child) => child.key).toList()) ==
        false) {
      final prevChildren = oldWidget.children.toList();
      longestChildCount = max(prevChildren.length, widget.children.length);
    }
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      List.generate(
        longestChildCount,
        (index) {
          return AnimatedChild(
            triggerAdd: triggerAdd,
            removeBuilder: widget.removeBuilder,
            addBuilder: widget.addBuilder,
            swapBuilder: widget.swapBuilder,
            child:
                widget.children.length > index ? widget.children[index] : null,
          );
        },
      ),
    );
  }
}

/// A widget that animates the addition, removal, or swapping of a single child
/// widget automatically.
class AnimatedChild extends StatefulWidget {
  /// The child widget to animate.
  final Widget? child;

  /// Whether to trigger the addition of the child immediately when the
  /// widget is built for the first time, or only for subsequent insertions
  /// of children. For example, you may want a row of widgets to appear as
  /// normal without animating when your screen renders for the first
  /// time, but subsequent insertions should animate.
  final bool triggerAdd;

  /// Whether to use snapshots when animating the child. If set to `true`, the
  /// child will be wrapped in a [SnapshotWidget] to animate the child. If set
  /// to `false`, the child will be animated using the direct reference to the
  /// child.
  final bool useSnapshots;

  /// The builder that wraps the given [child] in a widget that animates the
  /// removal of the child out of the widget tree.
  final RemovedChildBuilder removeBuilder;

  /// The builder that wraps the given [child] in a widget that animates the
  /// addition or insertion of the child into the widget tree.
  final AddedChildBuilder addBuilder;

  /// The builder that wraps the given [child] in a widget that animates the
  /// swapping of the child with another child in the widget tree.
  final SwappedChildBuilder swapBuilder;

  /// Creates an [AnimatedChild] with the given parameters.
  const AnimatedChild({
    super.key,
    required this.child,
    this.triggerAdd = true,
    this.useSnapshots = true,
    this.removeBuilder = _defaultRemovedChildBuilder,
    this.addBuilder = _defaultAddedChildBuilder,
    this.swapBuilder = _defaultSwappedChildBuilder,
  });

  @override
  State<AnimatedChild> createState() => _AnimatedChildState();
}

class _AnimatedChildState extends State<AnimatedChild> {
  final SnapshotController controller =
      SnapshotController(allowSnapshotting: true);
  Widget? prevChild;
  GlobalKey removedKey = GlobalKey();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant AnimatedChild oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.child != widget.child) {
      removedKey = GlobalKey();
      if (widget.useSnapshots) {
        prevChild = oldWidget.child == null
            ? null
            : SnapshotWidget(
                mode: SnapshotMode.forced,
                controller: controller,
                child: oldWidget.child!,
              );
      } else {
        prevChild = oldWidget.child;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        if (widget.child == null)
          if (prevChild case Widget prev)
            KeyedSubtree(
              key: removedKey,
              child: widget.removeBuilder(context, prev),
            ),
        if (widget.child case Widget child)
          widget.addBuilder(
            context,
            widget.swapBuilder(
              context,
              child,
            ),
            () => !widget.triggerAdd,
          ),
      ],
    );
  }
}
