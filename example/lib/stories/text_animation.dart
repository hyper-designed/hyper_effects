import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hyper_effects/hyper_effects.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:unicode_emojis/unicode_emojis.dart';

class TextAnimation extends StatefulWidget {
  const TextAnimation({super.key});

  @override
  State<TextAnimation> createState() => _TextAnimationState();
}

class _TextAnimationState extends State<TextAnimation> {
  TextRenderMode _mode = TextRenderMode.contextualCharacters;

  @override
  Widget build(BuildContext context) {
    return HyperEffectsScope(
      renderMode: _mode,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
          // Render mode toggle — lets the user compare legacy vs shaped path.
          SegmentedButton<TextRenderMode>(
            segments: const [
              ButtonSegment(
                // ignore: deprecated_member_use
                value: TextRenderMode.independentCharacters,
                label: Text('Legacy — deprecated'),
              ),
              ButtonSegment(
                value: TextRenderMode.contextualCharacters,
                label: Text('Shaped (default)'),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (s) => setState(() => _mode = s.first),
          ),
          const SizedBox(height: 16),
          const Translation(),
          const SizedBox(height: 16),
          const TagLine(),
          const SizedBox(height: 16),
          const EmojiLine(),
          const SizedBox(height: 16),
          // Side-by-side comparison: legacy vs shaped.
          const _CompareLabel(text: 'Same string, two render paths'),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ComparePane(
                label: 'LEGACY',
                // ignore: deprecated_member_use
                mode: TextRenderMode.independentCharacters,
              ),
              SizedBox(width: 48),
              _ComparePane(
                label: 'SHAPED',
                mode: TextRenderMode.contextualCharacters,
              ),
            ],
          ),
          const SizedBox(height: 48),
          // Arabic demo — shows BROKEN isolated forms in independent mode,
          // correct cursive joining in contextual mode.
          const ArabicRollingDemo(),
          const SizedBox(height: 48),
          const _CompareLabel(text: 'Japanese'),
          const SizedBox(height: 12),
          _PhraseDemo(
            phrases: const ['こんにちは', 'ありがとう', 'おはよう'],
            direction: TextDirection.ltr,
            font: GoogleFonts.notoSansJp(fontSize: 48),
          ),
          const SizedBox(height: 48),
          const _CompareLabel(text: 'Devanagari'),
          const SizedBox(height: 12),
          _PhraseDemo(
            phrases: const ['नमस्ते', 'शुभ', 'धन्यवाद'],
            direction: TextDirection.ltr,
            font: GoogleFonts.notoSansDevanagari(fontSize: 48),
          ),
          const SizedBox(height: 32),
          const LikeButton(),
          const SizedBox(height: 32),
          const IPhone(),
          const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

/// Showcases Arabic rolling between phrases.
///
/// In `TextRenderMode.independentCharacters` (legacy) mode the Arabic letters
/// render as BROKEN isolated forms.  Switch to
/// `TextRenderMode.contextualCharacters` to see correct cursive joining —
/// this is the selling point of the shaped-text path.
class ArabicRollingDemo extends StatefulWidget {
  const ArabicRollingDemo({super.key});

  @override
  State<ArabicRollingDemo> createState() => _ArabicRollingDemoState();
}

class _ArabicRollingDemoState extends State<ArabicRollingDemo> {
  static const _phrases = ['مرحبا', 'شكرا', 'سلام'];
  int _phraseIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Arabic demo (toggle mode above to compare)',
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            _phrases[_phraseIndex],
            style: GoogleFonts.notoNaskhArabic(
              fontSize: 48,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          )
              .roll(
                tapeSlideDirection: TextTapeSlideDirection.down,
                tapeCurve: Curves.easeInOutCubic,
                widthCurve: Curves.easeOutCubic,
              )
              .animate(
                trigger: _phraseIndex,
                duration: const Duration(milliseconds: 800),
              ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(
          onPressed: () =>
              setState(() => _phraseIndex = (_phraseIndex + 1) % _phrases.length),
          child: const Text('Next phrase'),
        ),
      ],
    );
  }
}

class IPhone extends StatelessWidget {
  const IPhone({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRect(
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

final String _allEmojis =
    UnicodeEmojis.allEmojis.map((emoji) => emoji.emoji).join('');

class EmojiTapeBuilder extends CharacterTapeBuilder {
  @override
  String get characters => _allEmojis;

  @override
  bool compare(String a, String b) =>
      _allEmojis.contains(a) && _allEmojis.contains(b);
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
              tapeStrategy:
                  ConsistentSymbolTapeStrategy(4, characterTapeBuilders: {
                EmojiTapeBuilder(),
              }),
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
      // Baseline alignment between the static "We help you" and the
      // rolled tagline. RenderShapedRolledRow exposes its row
      // baseline via `computeDistanceToActualBaseline`; ShaderMask
      // (and its `RenderProxyBox` base) forwards that through, so
      // the rolled child can baseline-anchor against the sibling
      // even through the gradient stack.
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'We help you',
          style: GoogleFonts.robotoMono().copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 48,
          ),
        ),
        ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white,
              Colors.white,
              Colors.white,
              Colors.white,
              Colors.white.withValues(alpha: 0),
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
      // Baseline alignment so the rolled translation lines up with
      // ", Stranger" against the typographic baseline (not the box
      // centre). ShaderMask forwards baseline queries from its
      // child, so this works even with the gradient stack wrapping
      // the rolled widget.
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0),
              Colors.white,
              Colors.white,
              Colors.white,
              Colors.white,
              Colors.white.withValues(alpha: 0),
            ],
          ).createShader(rect),
          child: ShaderMask(
            shaderCallback: (rect) => const LinearGradient(
              colors: [
                Color(0xFFD4145A),
                Color(0xFFFBB03B),
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
                  // Sacramento's capitals and terminal letters carry
                  // entry/exit swashes that extend past the glyph
                  // advance box. The renderer's outer-pad gating
                  // restores them at settled state and the seam-
                  // overlap blend keeps them whole at every interior
                  // join.
                  slotClipPadding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 4,
                  ),
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
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 56,
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
                        tapeStrategy: const AllSymbolsTapeStrategy(
                          repeatCharacters: false,
                        ),
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
                        .withValues(alpha: 0.5),
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
                        tapeStrategy: const ConsistentSymbolTapeStrategy(0,
                            repeatCharacters: true),
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
                        tapeStrategy: const ConsistentSymbolTapeStrategy(0,
                            repeatCharacters: false),
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
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
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
                      child: ScrollConfiguration(
                        behavior:
                            ScrollConfiguration.of(context).copyWith(
                          dragDevices: const {
                            PointerDeviceKind.touch,
                            PointerDeviceKind.mouse,
                            PointerDeviceKind.trackpad,
                            PointerDeviceKind.stylus,
                          },
                          scrollbars: false,
                        ),
                        child: Listener(
                          onPointerSignal: (event) {
                            if (event is PointerScrollEvent &&
                                _pageController.hasClients) {
                              _pageController.position
                                  .pointerScroll(event.scrollDelta.dy);
                            }
                          },
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
                              final paletteName =
                                  palettes.keys.elementAt(index);
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
                          dotColor: Colors.white.withValues(alpha: 0.25),
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

class _CompareLabel extends StatelessWidget {
  const _CompareLabel({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: 12,
          letterSpacing: 1.2,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      );
}

class _ComparePane extends StatefulWidget {
  const _ComparePane({required this.label, required this.mode});
  final String label;
  final TextRenderMode mode;

  @override
  State<_ComparePane> createState() => _ComparePaneState();
}

class _ComparePaneState extends State<_ComparePane> {
  static const _phrases = <String>['مرحبا', 'شكرا', 'سلام', 'أهلا'];
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(widget.label,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 2,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5),
            )),
        const SizedBox(height: 8),
        Directionality(
          textDirection: TextDirection.rtl,
          child: Text(
            _phrases[_index],
            style: GoogleFonts.notoNaskhArabic(fontSize: 48),
          )
              .roll(renderMode: widget.mode)
              .animate(
                trigger: _index,
                duration: const Duration(milliseconds: 700),
              ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () =>
              setState(() => _index = (_index + 1) % _phrases.length),
          child: const Text('Next'),
        ),
      ],
    );
  }
}

class _PhraseDemo extends StatefulWidget {
  const _PhraseDemo({
    required this.phrases,
    required this.direction,
    required this.font,
  });
  final List<String> phrases;
  final TextDirection direction;
  final TextStyle font;

  @override
  State<_PhraseDemo> createState() => _PhraseDemoState();
}

class _PhraseDemoState extends State<_PhraseDemo> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Directionality(
          textDirection: widget.direction,
          child: Text(widget.phrases[_index], style: widget.font)
              .roll()
              .animate(
                trigger: _index,
                duration: const Duration(milliseconds: 700),
              ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () =>
              setState(() => _index = (_index + 1) % widget.phrases.length),
          child: const Text('Next'),
        ),
      ],
    );
  }
}
