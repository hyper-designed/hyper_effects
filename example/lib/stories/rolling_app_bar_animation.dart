import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

class RollingAppBarAnimation extends StatefulWidget {
  const RollingAppBarAnimation({super.key});

  @override
  State<RollingAppBarAnimation> createState() => _RollingAppBarAnimationState();
}

class _RollingAppBarAnimationState extends State<RollingAppBarAnimation> {
  final TextEditingController searchController = TextEditingController();
  bool showSearchView = false;

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(8),
        ),
        clipBehavior: Clip.hardEdge,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: const InputDecoration(hintText: 'Search'),
                onTap: () {
                  showSearchView = true;
                  setState(() {});
                },
              ),
            ),
            KeyedSubtree(
              key: ValueKey(showSearchView),
              child: showSearchView
                  ? TextButton(
                      child: const Text('Cancel'),
                      onPressed: () {
                        showSearchView = false;
                        setState(() {});
                      },
                    )
                  : const HomeButtonTools(),
            )
                .roll(
                  multiplier: 1.5,
                  slideInDirection:
                      showSearchView ? AxisDirection.right : AxisDirection.left,
                  slideOutDirection:
                      showSearchView ? AxisDirection.right : AxisDirection.left,
                  rollInBuilder: (context, child) => child.fadeIn(),
                  rollOutBuilder: (context, child) => child.fadeOut(),
                )
                .clip(0)
                .animate(
                  trigger: showSearchView,
                  duration: const Duration(milliseconds: 350),
                  curve: Curves.easeInOutQuart,
                )
          ],
        ),
      ),
    );
  }
}

class HomeButtonTools extends StatefulWidget {
  const HomeButtonTools({super.key});

  @override
  State<HomeButtonTools> createState() => _HomeButtonToolsState();
}

class _HomeButtonToolsState extends State<HomeButtonTools> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(onPressed: () {}, icon: const Icon(Icons.filter_alt)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.compare_arrows)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.add)),
        IconButton(onPressed: () {}, icon: const Icon(Icons.settings)),
      ],
    );
  }
}
