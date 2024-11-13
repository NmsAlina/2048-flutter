import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_swipe_detector/flutter_swipe_detector.dart';

import 'package:twenty_forty_eight/components/button.dart';
import 'package:twenty_forty_eight/components/empty_board.dart';
import 'package:twenty_forty_eight/components/score_board.dart';
import 'package:twenty_forty_eight/components/tile_board.dart';
import 'package:twenty_forty_eight/constants/colors.dart';
import 'package:twenty_forty_eight/helpers/board_helper.dart';

import 'package:twenty_forty_eight/constants/colors.dart' as Colors;

class Game extends ConsumerStatefulWidget {
  const Game({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _GameState();
}

class _GameState extends ConsumerState<Game>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  //The contoller used to move the the tiles
  late final AnimationController _moveController = AnimationController(
    duration: const Duration(milliseconds: 100),
    vsync: this,
  )..addStatusListener((status) {
      //When the movement finishes merge the tiles and start the scale animation which gives the pop effect.
      if (status == AnimationStatus.completed) {
        ref.read(boardManager.notifier).merge();
        _scaleController.forward(from: 0.0);
      }
    });

  //The curve animation for the move animation controller.
  late final CurvedAnimation _moveAnimation = CurvedAnimation(
    parent: _moveController,
    curve: Curves.easeInOut,
  );

  //The contoller used to show a popup effect when the tiles get merged
  late final AnimationController _scaleController = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  )..addStatusListener((status) {
      //When the scale animation finishes end the round and if there is a queued movement start the move controller again for the next direction.
      if (status == AnimationStatus.completed) {
        if (ref.read(boardManager.notifier).endRound()) {
          _moveController.forward(from: 0.0);
        }
      }
    });

  //The curve animation for the scale animation controller.
  late final CurvedAnimation _scaleAnimation = CurvedAnimation(
    parent: _scaleController,
    curve: Curves.easeInOut,
  );

  @override
  void initState() {
    //Add an Observer for the Lifecycles of the App
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }
  // Add a variable to track the current mode (true for light, false for dark)
    bool isLightMode = true;

  // Function to toggle between light and dark mode
  void toggleMode() {
    setState(() {
      isLightMode = !isLightMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine colors based on the current mode
    final backgroundColor = isLightMode ? Colors.backgroundColor : Colors.backgroundColorDark;
    final textColor = isLightMode ? Colors.textColor : Colors.textColorDark;
    final buttonColor = isLightMode ? Colors.buttonColor : Colors.buttonColorDark;


return KeyboardListener(
      autofocus: true,
      focusNode: FocusNode(),
      onKeyEvent: (event) {
        if (ref.read(boardManager.notifier).onKey(event)) {
          _moveController.forward(from: 0.0);
        }
      },

      child: SwipeDetector(
        onSwipe: (direction, offset) {
          if (ref.read(boardManager.notifier).move(direction)) {
            _moveController.forward(from: 0.0);
          }
        },
        child: Scaffold(
          backgroundColor: backgroundColor,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '2048',
                      style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 52.0),
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Row(
                          children: [
                            ButtonWidget(
                              icon: Icons.restart_alt,
                              backgroundColor: isLightMode ? buttonColor : buttonColorDark,
                              textColor: isLightMode ? backgroundColor : backgroundColorDark,
                              isLightMode: isLightMode,
                              onPressed: () {
                                //Restart the game
                                ref.read(boardManager.notifier).newGame();
                              },
                            ),
                            const SizedBox(
                              width: 16.0,
                            ),
                            ButtonWidget(
                              icon: isLightMode ? Icons.dark_mode : Icons.light_mode,
                              onPressed: toggleMode,
                              backgroundColor: isLightMode ? buttonColor : buttonColorDark,
                              textColor: isLightMode ? backgroundColor : backgroundColorDark,
                              isLightMode: isLightMode,
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 16,
                        ),
                        ScoreBoard(isLightMode: isLightMode),
                        const SizedBox(
                          height: 12.0,
                        ),
                      ],
                    )
                  ],
                ),
              ),
              const SizedBox(
                height: 32.0,
              ),
              Stack(
                children: [
                  EmptyBoardWidget(isLightMode: isLightMode),
                  TileBoardWidget(
                    isLightMode: isLightMode,
                      moveAnimation: _moveAnimation,
                      scaleAnimation: _scaleAnimation)
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    //Save current state when the app becomes inactive
    if (state == AppLifecycleState.inactive) {
      ref.read(boardManager.notifier).save();
    }
    super.didChangeAppLifecycleState(state);
  }

  @override
  void dispose() {
    //Remove the Observer for the Lifecycles of the App
    WidgetsBinding.instance.removeObserver(this);

    //Dispose the animations.
    _moveAnimation.dispose();
    _scaleAnimation.dispose();
    _moveController.dispose();
    _scaleController.dispose();
    super.dispose();
  }
}