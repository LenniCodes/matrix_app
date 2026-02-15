import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_wearable/apps/pixelated_games/model/game_posture_tracker.dart';
import 'package:open_wearable/apps/pixelated_games/model/pixelated_game_model.dart';
import 'package:open_wearable/apps/pixelated_games/view/matrix_view.dart';

/// Snake game implementation for the pixelated matrix
/// Player controls a snake to eat apples while avoiding walls and the snake's own body
class SnakeGame extends PixelatedGameModel {
  SnakeGame();

  /// Map of snake length to game speed in milliseconds
  final Map<int, int> speedSteps = {0: 350, 10: 320, 20: 290, 28: 260};

  /// Current game speed
  late int currSpeed;

  /// Current position of the apple
  late Offset applePos;

  /// Last update timestamp
  late int lastUpdate;

  /// Previous game control input
  GameControl lastControl = GameControl.neutral;

  /// Current direction the snake is moving
  Offset currDirection = Offset(1, 0);

  /// List of segments making up the snake body
  List<Offset> snakeBody = [];

  /// List of available empty positions on the matrix
  List<Offset> free = [];

  /// The tail position of the snake
  Offset tail = Offset(0, 0);

  @override
  void initGame() {
    lastUpdate = DateTime.now().millisecondsSinceEpoch;
    currSpeed = getSpeed();
    free.addAll(List.generate(
            matrixWidth,
            (x) => List.generate(
                matrixWidth, (y) => Offset(x.toDouble(), y.toDouble())))
        .expand((e) => e));
    generateApple();

    snakeBody.add(Offset(matrixWidth / 2, matrixWidth / 2));
    free.remove(snakeBody.first);

    tail = snakeBody.first;
  }

  @override
  void previewRender(GameControl currentControl, MatrixViewState matrixState) {
    for (Offset pos in snakeBody) {
      matrixState.drawPixelFromOffset(pos, Colors.green);
    }

    matrixState.drawPixelFromOffset(applePos, Colors.red);

    matrixState.repaint();
  }

  @override
  void render(
    GameControl currentControl,
    MatrixViewState matrixState,
    Function() onStop,
  ) {
    // Check if player input has changed and update direction
    if (currentControl != lastControl) {
      lastControl = currentControl;
      changeDirection(currentControl);
      HapticFeedback.lightImpact();
    }

    // Check if enough time has passed based on current game speed
    if (DateTime.now().millisecondsSinceEpoch - lastUpdate < currSpeed) {
      return;
    }
    lastUpdate = DateTime.now().millisecondsSinceEpoch;

    // Check for collisions with walls or the snake's own body
    if (snakeBody.first.dx + currDirection.dx < 0 ||
        snakeBody.first.dx + currDirection.dx >= matrixWidth ||
        snakeBody.first.dy + currDirection.dy < 0 ||
        snakeBody.first.dy + currDirection.dy >= matrixWidth ||
        snakeBody.contains(snakeBody.first + currDirection)) {
      onStop();
      HapticFeedback.vibrate();
      return;
    }

    // Check if the snake ate the apple
    if (snakeBody.first + currDirection == applePos) {
      // Add the tail back and generate a new apple
      snakeBody.add(tail);
      free.remove(tail);

      currSpeed = getSpeed();
      generateApple();
    }

    // Move the snake forward by adding a new head and removing the tail
    snakeBody.insert(0, snakeBody.first + currDirection);
    free.remove(snakeBody.first);
    tail = snakeBody.removeLast();
    free.add(tail);

    // Draw all snake segments
    for (Offset pos in snakeBody) {
      matrixState.drawPixelFromOffset(pos, Colors.green);
    }
    // Highlight the head with a lighter color
    matrixState.drawPixelFromOffset(snakeBody.first, Colors.lightGreen);

    // Draw the apple
    matrixState.drawPixelFromOffset(applePos, Colors.red);

    matrixState.repaint();
  }

  /// Generates a new apple at a random free position
  void generateApple() {
    Offset newApplePos = free[Random().nextInt(free.length)];
    applePos = newApplePos;
  }

  /// Calculates the current game speed based on snake length
  int getSpeed() {
    int length = snakeBody.length;
    int speed = 0;
    for (int step in speedSteps.keys) {
      if (length >= step) {
        speed = speedSteps[step]!;
      }
    }
    return speed;
  }

  /// Changes the snake direction based on control input
  /// Prevents the snake from reversing into itself
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

  /// Rotates a vector 90 degrees counterclockwise
  Offset rotate90Left(Offset v) {
    return Offset(-v.dy, v.dx);
  }

  /// Rotates a vector 90 degrees clockwise
  Offset rotate90Right(Offset v) {
    return Offset(v.dy, -v.dx);
  }
}
