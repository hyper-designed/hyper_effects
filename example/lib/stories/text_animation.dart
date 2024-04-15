import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class TextAnimation extends StatefulWidget {
  const TextAnimation({super.key});

  @override
  State<TextAnimation> createState() => _TextAnimationState();
}

class _TextAnimationState extends State<TextAnimation> {
  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Translation(),
        SizedBox(height: 16),
        TagLine(),
        SizedBox(height: 16),
        EmojiLine(),
        SizedBox(height: 32),
        LikeButton(),
        SizedBox(height: 32),
        Flexible(flex: 10, child: IPhone()),
      ],
    );
  }
}

class IPhone extends StatelessWidget {
  const IPhone({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: SizedBox(
        width: 512,
        height: 512,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.all(16),
              width: 500,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(100)),
                border: Border.all(
                  color: Theme.of(context).colorScheme.onPrimary,
                  width: 2,
                ),
              ),
              clipBehavior: Clip.hardEdge,
              child: const ColorPalettePage(),
            ),
            Positioned(
              bottom: -530,
              child: IgnorePointer(
                child: Image.asset(
                  'assets/iphone15pro_1024x.png',
                  width: 512,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmojiLine extends StatefulWidget {
  const EmojiLine({super.key});

  @override
  State<EmojiLine> createState() => _EmojiLineState();
}

class _EmojiLineState extends State<EmojiLine> {
  bool trigger = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        setState(() {
          trigger = !trigger;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(32),
        ),
        child: Text(
          trigger
              ? 'World 🧳🌂☂️🧵🪡🪢🪭🧶👓🕶🥽🥼🦺👔👖🧣 Effect'
              : 'Hello 😀😃😄😁😆😅😂🤣🥲🥹️😊😇🙂🙃😉😌 Sexy',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        )
            .roll(
              tapeStrategy: const ConsistentSymbolTapeStrategy(4),
              tapeSlideDirection: TextTapeSlideDirection.alternating,
              staggerTapes: true,
              tapeCurve: Curves.easeInOutBack,
              widthCurve: Curves.easeOutQuart,
              symbolDistanceMultiplier: 2,
              staggerSoftness: 30,
              // clipBehavior: Clip.none,
            )
            .animate(
              trigger: trigger,
              duration: const Duration(milliseconds: 2000),
            ),
      ),
    );
  }
}

class TagLine extends StatefulWidget {
  const TagLine({super.key});

  @override
  State<TagLine> createState() => _TagLineState();
}

class _TagLineState extends State<TagLine> {
  List<String> tagLines = [
    'Connect',
    'Innovate',
    'Create',
    'Develop',
    'Grow',
    'Learn',
    'Share',
    'Create',
    'Design',
    'Build',
    'Code',
  ];
  int tagLine = 0;

  late Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(
        Duration(milliseconds: (1800 * timeDilation).toInt()), (timer) {
      setState(() {
        tagLine = (tagLine + 1) % tagLines.length;
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'We help you',
          style: GoogleFonts.robotoMono().copyWith(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 48,
          ),
          strutStyle: const StrutStyle(
            fontSize: 56,
            height: 1,
            forceStrutHeight: true,
            leading: 1,
          ),
        ),
        ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0),
              Colors.white,
              Colors.white,
              Colors.white,
              Colors.white,
              Colors.white.withOpacity(0),
              // Colors.white,
            ],
          ).createShader(rect),
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [
                Color(0xFFBFF098),
                Color(0xFF6FD6FF)
                // Colors.white,
              ],
            ).createShader(rect),
            child: Text(
              tagLines[tagLine],
              style: GoogleFonts.gloriaHallelujah().copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 56,
              ),
            )
                .roll(
                  symbolDistanceMultiplier: 2,
                  tapeSlideDirection: TextTapeSlideDirection.down,
                  tapeCurve: Curves.easeInOutCubic,
                  widthCurve: Curves.easeOutCubic,
                  widthDuration: const Duration(milliseconds: 1000),
                  padding: const EdgeInsets.only(left: 16),
                )
                .animate(
                  trigger: tagLine,
                  duration: const Duration(milliseconds: 1000),
                ),
          ),
        ),
      ],
    );
  }
}

class Translation extends StatefulWidget {
  const Translation({super.key});

  @override
  State<Translation> createState() => _TranslationState();
}

class _TranslationState extends State<Translation> {
  List<String> translations = [
    'Hello',
    'Bonjour',
    'Marhaba',
    'Hola',
    'Ciao',
    'Hallo',
    'Hej',
    'Ahoj',
    'Saluton',
    'Konnichiwa',
    'Annyeong',
    'Ni Hao',
    'Namaste',
    'Salaam',
  ];
  int translation = 0;

  late Timer timer;

  @override
  void initState() {
    super.initState();

    timer = Timer.periodic(
        Duration(milliseconds: (2000 * timeDilation).toInt()), (timer) {
      setState(() {
        translation = (translation + 1) % translations.length;
      });
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withOpacity(0),
              Colors.white,
              Colors.white,
              Colors.white,
              Colors.white,
              Colors.white.withOpacity(0),
              // Colors.white,
            ],
          ).createShader(rect),
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [
                Color(0xFFD4145A),
                Color(0xFFFBB03B)
                // Colors.white,
              ],
            ).createShader(rect),
            child: Text(
              translations[translation],
              style: GoogleFonts.sacramento().copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 56,
              ),
            )
                .roll(
                  symbolDistanceMultiplier: 2,
                  tapeCurve: Curves.easeInOutBack,
                  widthCurve: Curves.easeInOutQuart,
                  padding: const EdgeInsets.only(right: 3),
                )
                .animate(
                  trigger: translation,
                  duration: const Duration(milliseconds: 1000),
                ),
          ),
        ),
        Text(
          ', Stranger',
          style: GoogleFonts.sacramento().copyWith(
            color: Theme.of(context).colorScheme.onBackground,
            fontSize: 56,
          ),
          strutStyle: const StrutStyle(
            fontSize: 56,
            height: 1,
            forceStrutHeight: true,
            leading: 1,
          ),
        ),
      ],
    );
  }
}

class LikeButton extends StatefulWidget {
  const LikeButton({super.key});

  @override
  State<LikeButton> createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton> {
  int counter = 19;
  bool triggerShare = false;
  int downloadIteration = 1;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          clipBehavior: Clip.hardEdge,
          borderRadius: BorderRadius.circular(32),
          color: const Color(0xFF272727),
          child: InkWell(
            onTap: () {
              setState(() {
                counter++;
              });
            },
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.thumb_up_sharp,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${counter}K',
                    style: GoogleFonts.robotoTextTheme()
                        .bodyMedium!
                        .copyWith(color: Colors.white, fontSize: 16),
                  )
                      .roll(
                        tapeStrategy: const AllSymbolsTapeStrategy(false),
                        symbolDistanceMultiplier: 2,
                        clipBehavior: Clip.none,
                        tapeCurve: Curves.easeOutQuart,
                      )
                      .animate(
                        trigger: counter,
                        duration: const Duration(milliseconds: 1000),
                      ),
                  VerticalDivider(
                    color: Theme.of(context)
                        .colorScheme
                        .onPrimaryContainer
                        .withOpacity(0.5),
                    indent: 4,
                    endIndent: 4,
                  ),
                  const Icon(
                    Icons.thumb_down_sharp,
                    size: 18,
                    color: Colors.white,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          clipBehavior: Clip.hardEdge,
          borderRadius: BorderRadius.circular(32),
          color: const Color(0xFF272727),
          child: InkWell(
            onTap: () {
              setState(() {
                triggerShare = !triggerShare;
              });
            },
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.share,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    triggerShare ? 'Thanks!' : 'Share',
                    style: GoogleFonts.robotoTextTheme()
                        .bodyMedium!
                        .copyWith(color: Colors.white, fontSize: 16),
                  )
                      .roll(
                        tapeStrategy:
                            const ConsistentSymbolTapeStrategy(0, true),
                        symbolDistanceMultiplier: 2,
                        clipBehavior: Clip.none,
                        tapeCurve:
                            triggerShare ? Curves.bounceOut : Curves.bounceIn,
                        widthCurve: Curves.bounceOut,
                        staggerTapes: false,
                      )
                      .animate(
                        trigger: triggerShare,
                        reverse: true,
                        duration: const Duration(milliseconds: 800),
                      ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Material(
          clipBehavior: Clip.hardEdge,
          borderRadius: BorderRadius.circular(32),
          color: const Color(0xFF272727),
          child: InkWell(
            onTap: () {
              setState(() {
                downloadIteration = (downloadIteration + 1) % 3;
              });
            },
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.download,
                    size: 18,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    switch ((downloadIteration - 1) % 3) {
                      1 => 'Downloading',
                      2 => 'Downloaded',
                      _ => 'Download',
                    },
                    style: GoogleFonts.robotoTextTheme()
                        .bodyMedium!
                        .copyWith(color: Colors.white, fontSize: 16),
                  )
                      .roll(
                        tapeStrategy:
                            const ConsistentSymbolTapeStrategy(0, false),
                        symbolDistanceMultiplier: 2,
                        clipBehavior: Clip.none,
                        tapeCurve: Curves.easeOutBack,
                        widthCurve: Curves.easeOutQuart,
                        staggerSoftness: 100,
                      )
                      .animate(
                        trigger: downloadIteration,
                        duration: const Duration(milliseconds: 800),
                      ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ColorPalettePage extends StatefulWidget {
  const ColorPalettePage({super.key});

  @override
  State<ColorPalettePage> createState() => _ColorPalettePageState();
}

class _ColorPalettePageState extends State<ColorPalettePage> {
  final Map<String, List<Color>> palettes = const {
    'Cappuccino': [
      Color(0xFF4b3832),
      Color(0xFF854442),
      Color(0xFFfff4e6),
      Color(0xFF3c2f2f),
      Color(0xFFbe9b7b),
    ],
    'Beach': [
      Color(0xFF96ceb4),
      Color(0xFFffeead),
      Color(0xFFff6f69),
      Color(0xFFffcc5c),
      Color(0xFF88d8b0),
    ],
    'Kirkjufell': [
      Color(0xFF455982),
      Color(0xFF2c2521),
      Color(0xFF6078c6),
      Color(0xFFd7b98f),
      Color(0xFFcae3f0),
    ],
    'Volcarona': [
      Color(0xFF626262),
      Color(0xFFe6e6e6),
      Color(0xFFc54a41),
      Color(0xFFee7318),
      Color(0xFF94cdd5),
    ],
    'Ariana Grande': [
      Color(0xFFf4c5cb),
      Color(0xFF010101),
      Color(0xFFfdfefe),
      Color(0xFFbcbbbb),
      Color(0xFFeae4fd),
    ],
    'Grand Manan Sunset': [
      Color(0xFFd04b2f),
      Color(0xFFff6f61),
      Color(0xFFffb9ad),
      Color(0xFFfbeee6),
      Color(0xFFc8506f),
    ],
    'Nature Goddess': [
      Color(0xFF00909e),
      Color(0xFF6fb653),
      Color(0xFFffb9ad),
      Color(0xFFff6f61),
      Color(0xFFd04b2f),
    ],
    'Warm Steel': [
      Color(0xFFebb463),
      Color(0xFFdebe90),
      Color(0xFFc1ae90),
      Color(0xFF797062),
      Color(0xFF312e28),
    ],
    'Valorant Faux': [
      Color(0xFF8e8b82),
      Color(0xFFfdf3e3),
      Color(0xFFff0096),
      Color(0xFF3d3939),
      Color(0xFFb76e79),
    ],
    'Maliz Duskryr': [
      Color(0xFFdfd8ce),
      Color(0xFF56625d),
      Color(0xFF45434b),
      Color(0xFF633c39),
      Color(0xFF281214),
    ],
    'Eilith Shadownhorn': [
      Color(0xFF7a555c),
      Color(0xFF89644a),
      Color(0xFF54383e),
      Color(0xFF311011),
      Color(0xFF1d0407),
    ],
    'Reymoira Vidromis': [
      Color(0xFFb19f83),
      Color(0xFFbbd3d8),
      Color(0xFFe8d487),
      Color(0xFF5c3924),
      Color(0xFF235162),
    ],
    'Warm Sugar Cookies': [
      Color(0xFFfff8e5),
      Color(0xFFf8e4b2),
      Color(0xFFf2d9a4),
      Color(0xFFd1aa73),
      Color(0xFFbd9660),
    ]
  };

  int currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        brightness: Brightness.light,
        colorSchemeSeed: Colors.blue,
        // textTheme: GoogleFonts.robotoTextTheme(),
      ),
      debugShowCheckedModeBanner: false,
      home: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 64),
        child: Builder(builder: (context) {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                'Look And Feel',
                style: GoogleFonts.notoSerif().copyWith(fontSize: 28),
              ),
              titleSpacing: 0,
              centerTitle: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios),
                onPressed: () {},
              ),
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'Accent Colour',
                      style: GoogleFonts.inter()
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    ShaderMask(
                      shaderCallback: (rect) => LinearGradient(
                        colors: palettes.values.elementAt(currentPage),
                      ).createShader(rect),
                      child: Text(
                        palettes.keys.elementAt(currentPage).toUpperCase(),
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, color: Colors.white),
                      )
                          .roll(
                            staggerSoftness: 6,
                            reverseStaggerDirection: false,
                            tapeSlideDirection: TextTapeSlideDirection.down,
                            tapeCurve: Curves.easeOutBack,
                            widthCurve: Curves.easeOutQuart,
                            widthDuration: const Duration(milliseconds: 500),
                          )
                          .animate(
                            trigger: currentPage,
                            curve: Curves.linear,
                            duration: const Duration(milliseconds: 800),
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Stack(
                  alignment: Alignment.bottomCenter,
                  children: [
                    Container(
                      height: 128,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: PageView.builder(
                        controller: _pageController,
                        scrollDirection: Axis.horizontal,
                        itemCount: palettes.keys.length,
                        onPageChanged: (int page) {
                          setState(() {
                            currentPage = page;
                          });
                        },
                        itemBuilder: (context, index) {
                          final paletteName = palettes.keys.elementAt(index);
                          final paletteColors = palettes[paletteName]!;

                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final color in paletteColors)
                                Expanded(
                                  child: ColoredBox(color: color),
                                )
                            ],
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: SmoothPageIndicator(
                        controller: _pageController,
                        count: palettes.keys.length,
                        effect: WormEffect(
                          offset: 8,
                          dotWidth: 10,
                          dotHeight: 10,
                          spacing: 6,
                          radius: 12,
                          activeDotColor: Colors.white,
                          dotColor: Colors.white.withOpacity(0.25),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        }),
      ),
    );
  }
}
