import 'package:material_ui/material_ui.dart';

/// The shared page chrome of an edge-case story: a centered, scrollable,
/// width-constrained column with a headline and a one-paragraph description,
/// followed by the story's own content.
class StoryScaffold extends StatelessWidget {
  /// The headline shown at the top of the page.
  final String title;

  /// One or two sentences describing what the story demonstrates.
  final String description;

  /// The maximum content width.
  final double maxWidth;

  /// The story's demo and controls, laid out below the description. Each
  /// child provides its own leading spacing.
  final List<Widget> children;

  /// Creates a [StoryScaffold].
  const StoryScaffold({
    super.key,
    required this.title,
    required this.description,
    this.maxWidth = 700,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              Text(description, textAlign: TextAlign.center),
              ...children,
            ],
          ),
        ),
      ),
    );
  }
}
