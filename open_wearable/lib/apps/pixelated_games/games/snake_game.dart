import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_wearable/apps/pixelated_games/model/game_posture_tracker.dart';
import 'package:open_wearable/apps/pixelated_games/model/pixelated_game_model.dart';
import 'package:open_wearable/apps/pixelated_games/view/matrix_view.dart';

class SnakeGame extends PixelatedGameModel {
  SnakeGame();

  final Map<int,int> speedSteps = {0: 350,10: 320, 20: 290, 28: 260};
  late int currSpeed;

  late Offset applePos;
  late int lastUpdate;

  GameControl lastControl = GameControl.neutral;
  Offset currDirection = Offset(1, 0);
  List<Offset> snakeBody = [];
  List<Offset> free = [];

  Offset tail = Offset(0, 0);


  Offset rotate90Left(Offset v) {
    return Offset(-v.dy, v.dx);
  }

  Offset rotate90Right(Offset v) {
    return Offset(v.dy, -v.dx);
  }

  @override
  void initGame() {
    lastUpdate = DateTime.now().millisecondsSinceEpoch;
    currSpeed = getSpeed();
    free.addAll(List.generate(matrixWidth, (x) => List.generate(matrixWidth, (y) => Offset(x.toDouble(), y.toDouble()))).expand((e) => e));
    generateApple();

    snakeBody.add(Offset(matrixWidth / 2, matrixWidth / 2));
    free.remove(snakeBody.first);

    tail = snakeBody.first;
  }

  void generateApple() {
    Offset newApplePos = free[Random().nextInt(free.length)];
    applePos = newApplePos;
  }

  @override
  void render(GameControl currentControl, MatrixViewState matrixState,
      Function() onStop,) {
    if (currentControl != lastControl) {
      lastControl = currentControl;
      changeDirection(currentControl);
      HapticFeedback.lightImpact();
    }

    if (DateTime.now().millisecondsSinceEpoch - lastUpdate < currSpeed) {
      return;
    }
    lastUpdate = DateTime.now().millisecondsSinceEpoch;

    if (snakeBody.first.dx + currDirection.dx < 0 ||
        snakeBody.first.dx + currDirection.dx >= matrixWidth ||
        snakeBody.first.dy + currDirection.dy < 0 ||
        snakeBody.first.dy + currDirection.dy >= matrixWidth ||
        snakeBody.contains(snakeBody.first + currDirection)) {
      onStop();
      HapticFeedback.vibrate();
      return;
    }

    if (snakeBody.first + currDirection == applePos) {
      
      snakeBody.add(tail);
      free.remove(tail);

      currSpeed = getSpeed();
      generateApple();
    }

    snakeBody.insert(0, snakeBody.first + currDirection);
    free.remove(snakeBody.first);
    tail = snakeBody.removeLast();
    free.add(tail);

    for (Offset pos in snakeBody) {
      matrixState.drawPixelFromOffset(pos, Colors.green);
    }
    matrixState.drawPixelFromOffset(snakeBody.first, Colors.lightGreen);

    matrixState.drawPixelFromOffset(applePos, Colors.red);

    matrixState.repaint();
  }

  @override
  void previewRender(GameControl currentControl, MatrixViewState matrixState) {
    for (Offset pos in snakeBody) {
      matrixState.drawPixelFromOffset(pos, Colors.green);
    }

    matrixState.drawPixelFromOffset(applePos, Colors.red);

    matrixState.repaint();
  }

  int getSpeed() {
    int length = snakeBody.length;
    int speed = 0;
    for (int step in speedSteps.keys) {
      if(length >= step) {
        speed = speedSteps[step]!;
      }
    }
    return speed;
  }

  void changeDirection(GameControl control) {
    switch (control) {
        case GameControl.neutral:
          break;
        case GameControl.left:
          if (currDirection.dx != 1) {
            currDirection = Offset(-1, 0);
          }
          break;
        case GameControl.right:
          if (currDirection.dx != -1) {
            currDirection = Offset(1, 0);
          }
          break;
        case GameControl.up:
          if (currDirection.dy != 1) {
            currDirection = Offset(0, -1);
          }
          break;
        case GameControl.down:
          if (currDirection.dy != -1) {
            currDirection = Offset(0, 1);
          }
          break;
      }
  }
}
