import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_wearable/apps/pixelated_games/model/game_posture_tracker.dart';
import 'package:open_wearable/apps/pixelated_games/model/pixelated_game_model.dart';
import 'package:open_wearable/apps/pixelated_games/view/matrix_view.dart';

class PongGame extends PixelatedGameModel {
  PongGame();

  late int lastUpdate;
  late int lastBallUpdate;

  int topPaddleX = 0;
  int bottomPaddleX = 0;
  int paddleWidth = 4;

  bool lastHitTop = false;

  Offset ballPos = Offset(0, 0);
  List<Offset> ballTrail = [];

  Offset ballDirection = Offset(1, 1);

  final Map<int, int> speedSteps = {
    0: 350,
    3: 320,
    7: 290,
    10: 230,
    15: 200,
    20: 150,
  };
  late int currSpeed;
  int hits = 0;

  final int trailLength = 4;

  @override
  void render(
    GameControl currentControl,
    MatrixViewState matrixState,
    Function() onStop,
  ) {
    if (DateTime.now().millisecondsSinceEpoch - lastUpdate >= 150) {
      lastUpdate = DateTime.now().millisecondsSinceEpoch;

      if (DateTime.now().millisecondsSinceEpoch - lastBallUpdate >= currSpeed) {
        lastBallUpdate = DateTime.now().millisecondsSinceEpoch;
        ballPos += ballDirection;
      }

      // Check for wall collisions
      if (ballPos.dx < 0) {
        ballPos = Offset(0, ballPos.dy);
        ballDirection = Offset(-ballDirection.dx, ballDirection.dy);
      } else if (ballPos.dx > matrixWidth - 1) {
        ballPos = Offset(matrixWidth - 1, ballPos.dy);
        ballDirection = Offset(-ballDirection.dx, ballDirection.dy);
      }

      // Check for paddle collisions
      if (ballPos.dy < 1) {
        if (ballPos.dx >= topPaddleX &&
            ballPos.dx <= topPaddleX + paddleWidth) {
          ballPos = Offset(ballPos.dx, 1);
          lastHitTop = true;

          triggerHit();
        } else {
          onStop();
          return;
        }
      } else if (ballPos.dy > matrixWidth - 2) {
        if (ballPos.dx >= bottomPaddleX &&
            ballPos.dx <= bottomPaddleX + paddleWidth) {
          ballPos = Offset(ballPos.dx, matrixWidth - 2);
          lastHitTop = false;

          triggerHit();
        } else {
          onStop();
          return;
        }
      }

      if(ballPos != (ballTrail.isNotEmpty ? ballTrail.last : null)) {
        ballTrail.add(ballPos);
        if (ballTrail.length > trailLength) {
          ballTrail.removeAt(0);
        }
      }

      // Move paddles
      if (lastHitTop) {
        bottomPaddleX = movePlatform(currentControl, bottomPaddleX);
      } else {
        topPaddleX = movePlatform(currentControl, topPaddleX);
      }

      drawPaddles(matrixState);
      drawBall(matrixState);
      drawTrace(matrixState);

      matrixState.repaint();
    }
  }

  int getSpeed() {
    int speed = 0;
    for (int step in speedSteps.keys) {
      if (hits >= step) {
        speed = speedSteps[step]!;
      }
    }
    return speed;
  }

  int movePlatform(GameControl currentControl, int platform) {
    if (currentControl == GameControl.left) {
      if (platform > 0) {
        return platform - 1;
      }
    } else if (currentControl == GameControl.right) {
      if (platform < matrixWidth - paddleWidth) {
        return platform + 1;
      }
    }
    return platform;
  }

  Offset randomDirection() {
    int x = ([-1, 1]..shuffle()).first;
    int y = ([-1, 1]..shuffle()).first;
    return Offset(x.toDouble(), y.toDouble());
  }

  @override
  void previewRender(GameControl currentControl, MatrixViewState matrixState) {
    drawPaddles(matrixState);
    drawBall(matrixState);
    matrixState.repaint();
  }

  void triggerHit() {
    hits++;
    currSpeed = getSpeed();
    ballDirection = Offset(ballDirection.dx, -ballDirection.dy);
    HapticFeedback.lightImpact();
  }

  void drawTrace(MatrixViewState matrixState) {
    for (int i = 0; i < ballTrail.length - 1; i++) {
      double opacity = (i + 1) / ballTrail.length;
      matrixState.drawPixelFromOffset(
          ballTrail[i], Colors.white.withAlpha((opacity * 100).toInt()),);
    }
  }

  void drawBall(MatrixViewState matrixState) {
    matrixState.drawPixelFromOffset(ballPos, Colors.white.withAlpha(170));
  }

  void drawPaddles(MatrixViewState matrixState) {
    for (int x = topPaddleX; x < topPaddleX + paddleWidth; x++) {
      matrixState.drawPixel(x, 0, Colors.white);
    }

    for (int x = bottomPaddleX; x < bottomPaddleX + paddleWidth; x++) {
      matrixState.drawPixel(x, matrixWidth - 1, Colors.white);
    }
  }

  @override
  void initGame() {
    topPaddleX = (matrixWidth - paddleWidth) ~/ 2;
    bottomPaddleX = (matrixWidth - paddleWidth) ~/ 2;

    int mills = DateTime.now().millisecondsSinceEpoch;
    lastBallUpdate = mills;
    lastUpdate = mills;

    ballPos = Offset(matrixWidth / 2, matrixWidth / 2);
    ballDirection = randomDirection();

    currSpeed = getSpeed();
    hits = 0;

    if (ballDirection.dy < 0) {
      lastHitTop = false;
    } else {
      lastHitTop = true;
    }
  }
}
