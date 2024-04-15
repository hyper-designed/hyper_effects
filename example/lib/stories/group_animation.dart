import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

class GroupAnimation extends StatefulWidget {
  const GroupAnimation({super.key});

  @override
  State<GroupAnimation> createState() => _GroupAnimationState();
}

class _GroupAnimationState extends State<GroupAnimation> {
  int counter = 0;

  final List<String> tags1 = [
    'family',
    'friends',
    'work',
    'school',
    'sports',
    'hobbies',
  ];
  final List<String> tags2 = [
    'family',
    'friends',
    'sports',
    'work',
  ];

  @override
  Widget build(BuildContext context) {
    final tags = counter % 2 == 0 ? tags1 : tags2;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            // clipBehavior: Clip.antiAlias,
              child: AnimatedGroup(
              builder: (context, children) => Row(children: children),
              valueGetter: (child, i) => tags[i],
              children: [
                for (int i = 0; i < tags.length; i++)
                  Padding(
                    key: ValueKey(tags[i]),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: TagChip(
                      tag: tags[i],
                      selected: false,
                    ),
                  )
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                counter++;
              });
            },
            child: const Text('Switch'),
          ),
        ],
      ),
    );
  }
}

class TagChip extends StatefulWidget {
  final String tag;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;
  final Widget? suffix;

  const TagChip({
    super.key,
    required this.tag,
    required this.selected,
    this.onTap,
    this.compact = false,
    this.suffix,
  });

  @override
  State<TagChip> createState() => _TagChipState();
}

class _TagChipState extends State<TagChip> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.selected
            ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
            : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      clipBehavior: Clip.none,
      child: InkWell(
        borderRadius: BorderRadius.circular(6),
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.only(left: 6, right: 8, top: 4, bottom: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.selected ? Icons.check_circle : Icons.tag,
                size: 16,
                color: widget.selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
              ),
              const SizedBox(width: 6),
              Text(
                widget.tag,
                style: TextStyle(
                  color: widget.selected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              if (widget.suffix case Widget suffix) ...[
                const SizedBox(width: 4),
                suffix,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
