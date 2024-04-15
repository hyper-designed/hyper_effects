import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/widgets.dart';

import '../hyper_effects.dart';

typedef ChildrenBuilder = Widget Function(
  BuildContext context,
  List<Widget> children,
);

typedef RemovedChildBuilder = Widget Function(
  BuildContext context,
  Widget child,
);

typedef AddedChildBuilder = Widget Function(
  BuildContext context,
  Widget child,
);

typedef SwappedChildBuilder = Widget Function(
  BuildContext context,
  Widget child,
  Object? value,
);

typedef WidgetValueGetter = Object? Function(Widget child, int index);

Widget _defaultRemovedChildBuilder(BuildContext context, Widget child) {
  return child.fadeOut().slideOutToTop(value: -50).oneShot();
}

Widget _defaultAddedChildBuilder(BuildContext context, Widget child) {
  return child.fadeIn().slideInFromBottom(value: 50).oneShot();
}

Widget _defaultSwappedChildBuilder(
  BuildContext context,
  Widget child,
  Object? value,
) {
  return child
      .roll(multiplier: 1.5, useSnapshots: false)
      .animate(trigger: value);
}

class AnimatedGroup extends StatefulWidget {
  final List<Widget> children;
  final ChildrenBuilder builder;
  final RemovedChildBuilder removedChildBuilder;
  final AddedChildBuilder addedChildBuilder;
  final SwappedChildBuilder swappedChildBuilder;
  final WidgetValueGetter valueGetter;

  const AnimatedGroup({
    super.key,
    required this.children,
    required this.builder,
    required this.valueGetter,
    this.removedChildBuilder = _defaultRemovedChildBuilder,
    this.addedChildBuilder = _defaultAddedChildBuilder,
    this.swappedChildBuilder = _defaultSwappedChildBuilder,
  });

  @override
  State<AnimatedGroup> createState() => _AnimatedGroupState();
}

class _AnimatedGroupState extends State<AnimatedGroup> {
  final SnapshotController controller =
      SnapshotController(allowSnapshotting: true);

  List<Widget> prevChildren = [];
  late int longestChildCount = widget.children.length;

  @override
  void didUpdateWidget(covariant AnimatedGroup oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (const ListEquality().equals(
            oldWidget.children.map((child) => child.key).toList(),
            widget.children.map((child) => child.key).toList()) ==
        false) {
      prevChildren = oldWidget.children
          // .map((child) => SnapshotWidget(controller: controller, child: child))
          .toList();
      longestChildCount = max(prevChildren.length, widget.children.length);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.builder(
      context,
      List.generate(
        longestChildCount,
        (index) {
          final prevChild =
              prevChildren.length > index ? prevChildren[index] : null;
          final child =
              widget.children.length > index ? widget.children[index] : null;

          if (child != null) {
            return widget.addedChildBuilder(
              context,
              widget.swappedChildBuilder(
                context,
                child,
                widget.valueGetter(child, index),
              ),
            );
          }

          return Stack(
            clipBehavior: Clip.none,
            children: [
              if (prevChild != null)
                child == null
                    ? widget.removedChildBuilder(context, prevChild)
                    : Positioned.fill(
                        child: widget.removedChildBuilder(context, prevChild),
                      ),
              if (child != null) child,
            ],
          );
        },
      ),
    );
  }
}
