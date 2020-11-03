import 'dart:math';

import 'package:flutter/material.dart';
import 'package:assets_audio_player/assets_audio_player.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'High Five',
      theme: ThemeData(
        visualDensity: VisualDensity.adaptivePlatformDensity,
        backgroundColor: Color(0xFF86C9CD),
      ),
      home: HighFiveScreen(),
    );
  }
}

class HighFiveScreen extends StatefulWidget {
  @override
  _HighFiveScreenState createState() => _HighFiveScreenState();
}

// might have to change the mixin for this.
class _HighFiveScreenState extends State<HighFiveScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  List<Image> cycleImages;
  List<Image> smackImages;

  final assetsAudioPlayer = AssetsAudioPlayer();
  bool appClosed = false;

  AnimationController controller;

  bool smack = false;
  final int numFrames = 15;
  int frame = 0;

  void loadImages() {
    cycleImages = new List<Image>();
    smackImages = new List<Image>();
    for (int i = 0; i < numFrames; i++) {
      String frameString = i.toString().padLeft(5, '0');
      cycleImages.add(Image.asset("images/cycle images/c$frameString.png"));
      smackImages.add(Image.asset("images/smack images/s$frameString.png"));
    }
  }

  void precacheImages() {
    // https://alex.domenici.net/archive/preload-images-in-a-stateful-widget-on-flutter#:~:text=The%20images%20will%20actually%20be,%2C%20file%2C%20etc.
    for (int i = 0; i < numFrames; i++) {
      precacheImage(cycleImages[i].image, context);
      precacheImage(smackImages[i].image, context);
    }
  }

  void playSmack() {
    int smack = Random().nextInt(6);
    int vo = Random().nextInt(27);
    AssetsAudioPlayer.newPlayer().open(Audio("audio/slaps/slap-$smack.m4a"));
    AssetsAudioPlayer.newPlayer().open(Audio("audio/voiceover/vo-$vo.m4a"));
  }

  // for detecting if the app is closed
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      assetsAudioPlayer.play();
      appClosed = false;
    } else {
      assetsAudioPlayer.stop();
      appClosed = true;
    }
    print(appClosed);
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // load in the asset images
    loadImages();

    // load in the background music and set it to loop
    assetsAudioPlayer.setVolume(0.5);
    assetsAudioPlayer.open(Audio('audio/background.m4a'));
    assetsAudioPlayer.playlistAudioFinished.listen((Playing playing) {
      if (!appClosed) {
        assetsAudioPlayer.open(Audio('audio/background.m4a'));
      }
    });

    // prepare the animation controller
    controller = AnimationController(
      duration: Duration(seconds: 1),
      vsync: this,
    );
    controller.forward();

    controller.addListener(() {
      setState(() {
        frame = (controller.value * (numFrames - 1)).toInt();
      });
    });

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (smack) {
          smack = false;
          controller.forward(from: 0.0);
        } else {
          controller.reverse(from: 1.0);
        }
      } else if (status == AnimationStatus.dismissed) {
        controller.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    assetsAudioPlayer.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // prechache the images
    precacheImages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF86C9CD),
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            GestureDetector(
              onTap: () {
                if (!smack) {
                  setState(() {
                    smack = true;
                    controller.forward(from: 0.0);
                    playSmack();
                  });
                }
              },
              child: Center(
                child: LayoutBuilder(builder: (context, constraints) {
                  if (smack) {
                    return smackImages[frame];
                  } else {
                    return cycleImages[frame];
                  }
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
