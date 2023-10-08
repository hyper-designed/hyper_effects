import 'package:flutter/material.dart';

/// A widget that doesn't render first frame. This is useful for widgets that
/// need to be rendered after the first frame
class PostFrameWidget extends StatefulWidget {
  /// The widget below this widget in the tree.
  final Widget child;

  /// The callback to be called after the first frame is rendered.
  final VoidCallback? onPostFrame;

  /// Whether to render the first frame or not.
  final bool enabled;

  /// Creates a [PostFrameWidget] widget.
  const PostFrameWidget({
    super.key,
    required this.child,
    this.onPostFrame,
    this.enabled = true,
  });

  @override
  State<PostFrameWidget> createState() => _PostFrameWidgetState();
}

class _PostFrameWidgetState extends State<PostFrameWidget> {
  bool _isFirstFrame = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(onPostFrame);
  }

  void onPostFrame(Duration timeStamp) {
    _isFirstFrame = false;
    widget.onPostFrame?.call();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Visibility(
      visible: !widget.enabled || !_isFirstFrame,
      maintainSize: true,
      maintainState: true,
      maintainAnimation: true,
      child: widget.child,
    );
  }
}
