import 'package:flutter/material.dart';
import 'package:hyper_effects/hyper_effects.dart';

class ColorFilterScrollTransition extends StatefulWidget {
  const ColorFilterScrollTransition({super.key});

  @override
  State<ColorFilterScrollTransition> createState() =>
      _ColorFilterScrollTransitionState();
}

class _ColorFilterScrollTransitionState
    extends State<ColorFilterScrollTransition> {
  static const List<String> images = [
    'https://imgv3.fotor.com/images/slider-image/A-clear-image-of-a-woman-wearing-red-sharpened-by-Fotors-image-sharpener.jpg',
    'https://media.istockphoto.com/id/1281783803/photo/mountains-velliangiri-view-with-blue-sky-and-green-fores.jpg?s=612x612&w=0&k=20&c=25epzQEXtzNmGMtUoBa13SpHZ4rGz2HDLuHfWaUa51o=',
    'https://stimg.cardekho.com/images/carexteriorimages/630x420/Hyundai/Venue/10142/1684739946788/front-left-side-47.jpg?imwidth=420&impolicy=resize',
    'https://www.befunky.com/images/prismic/82e0e255-17f9-41e0-85f1-210163b0ea34_hero-blur-image-3.jpg?auto=avif,webp&format=jpg&width=896',
    'https://images.unsplash.com/photo-1682685797661-9e0c87f59c60',
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Container(
            width: 350,
            height: 200,
            alignment: Alignment.center,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              // color: randomColor(index),
              image: DecorationImage(
                image: NetworkImage(
                  images[index % images.length],
                ),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Item $index',
              style: const TextStyle(
                fontSize: 24,
                color: Colors.white,
              ),
            ),
          ).scrollTransition((context, widget, event) =>
                  widget /*.translateX(
                        switch (event.phase) {
                          ScrollPhase.identity => 0,
                          ScrollPhase.topLeading => 200,
                          ScrollPhase.bottomTrailing => -200,
                        },
                      )*/
                      /*.colorFilter(color:
                        switch (event.phase) {
                          ScrollPhase.identity =>
                            Colors.pink.withOpacity(0.5),
                          ScrollPhase.topLeading =>
                            Colors.blue.withOpacity(0.5),
                          ScrollPhase.bottomTrailing =>
                            Colors.blue.withOpacity(0.5),
                        },
                        mode: BlendMode.overlay,
                      )*/
                      .colorFilter(
                        matrix: switch (event.phase) {
                          ScrollPhase.identity => ColorFilterMatrix.greyscale,
                          ScrollPhase.topLeading => ColorFilterMatrix.sepia,
                          ScrollPhase.bottomTrailing => ColorFilterMatrix.sepia,
                        },
                        // color: switch (event.phase) {
                        //   ScrollPhase.identity =>
                        //       Colors.pink.withOpacity(0.5),
                        //   ScrollPhase.topLeading =>
                        //       Colors.blue.withOpacity(0.5),
                        //   ScrollPhase.bottomTrailing =>
                        //       Colors.blue.withOpacity(0.5),
                        // },
                        mode: BlendMode.overlay,
                      )
                      .clipRRect(BorderRadius.circular(16))
                      .scale(event.phase.isIdentity ? 1 : 0.7)
              /*.rotate(switch (event.phase) {
                      ScrollPhase.identity => 0,
                      ScrollPhase.topLeading => pi / 2,
                      ScrollPhase.bottomTrailing => -pi / 2,
                    }),*/
              ),
        );
      },
    );
  }
}
