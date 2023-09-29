import 'dart:math';

import 'package:flutter/material.dart';
import 'package:scrolling_effects/scroll_phase.dart';
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
        body: SizedBox.expand(
          child: MyScreen(),
        ),
      ),
    );
  }
}

class MyScreen extends StatelessWidget {
  const MyScreen({super.key});

  Color randomColor(int index) {
    final r = Random(index * 100).nextInt(255);
    final g = Random(index * 200).nextInt(255);
    final b = Random(index * 300).nextInt(255);
    return Color.fromARGB(255, r, g, b);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      primary: true,
      itemBuilder: (context, index) {
        return ScrollAnimation(
          key: ValueKey(index),
          index: index,
          effectsBuilder: (phase) => [
            ScaleEffect(scale: phase.isIdentity ? 1 : 0.5),
            OffsetEffect(
              x: switch (phase) {
                ScrollPhase.topLeading => 200,
                ScrollPhase.bottomTrailing => -200,
                ScrollPhase.identity => 0,
              },
            ),
          ],
          child: Container(
            height: 350,
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
          ),
        );
      },
    );
  }
}
