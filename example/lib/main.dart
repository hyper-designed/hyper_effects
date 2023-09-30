import 'dart:math';

import 'package:flutter/material.dart';
import 'package:scrolling_effects/scrolling_effects.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'MyApp Demo',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        // backgroundColor: Color(0xFFF0F1FA),
        body: Center(
          child: MyScreen(),
        ),
      ),
    );
  }
}

class MyScreen extends StatefulWidget {
  const MyScreen({super.key});

  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  Color randomColor(int index) {
    final r = Random(index * 100).nextInt(255);
    final g = Random(index * 200).nextInt(255);
    final b = Random(index * 300).nextInt(255);
    return Color.fromARGB(255, r, g, b);
  }

  bool toggle = true;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () => setState(() => toggle = !toggle),
          child: Container(
            width: 350,
            height: 350,
            // height: Random(index * 100).nextDouble().clamp(0.1, 0.5) * 1000,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: randomColor(index),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Item $index',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
              ),
            ),
          )
              .scale(toggle ? 1 : 0.8)
              .rotate(toggle ? 0 : 90 * pi / 180)
              .animate(
                toggle: toggle,
              )
              .scrollTransition(
                index,
                (context, widget, phase) =>
                    widget.scale(phase.isIdentity ? 1 : 0.7).translateX(
                          switch (phase) {
                            ScrollPhase.identity => 0,
                            ScrollPhase.topLeading => 200,
                            ScrollPhase.bottomTrailing => -200,
                          },
                        ),
              ),
        );
      },
    );
  }
}
