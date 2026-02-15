import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:open_wearable/apps/pixelated_games/model/game_posture_tracker.dart';
import 'package:open_wearable/apps/pixelated_games/model/pixelated_game_model.dart';
import 'package:open_wearable/apps/pixelated_games/view/matrix_view.dart';

/// Pong game implementation for the pixelated matrix
/// Player controls a paddle to keep a ball from going off screen
class PongGame extends PixelatedGameModel {
  PongGame();

  /// Timestamp of the last game update
  late int lastUpdate;
  /// Timestamp of the last ball position update
  late int lastBallUpdate;

  /// X position of the top paddle
  int topPaddleX = 0;
  /// X position of the bottom paddle
  int bottomPaddleX = 0;
  /// Width of the paddles
  int paddleWidth = 4;

  /// Whether the ball last hit the top paddle
  bool lastHitTop = false;

  /// Current position of the ball
  Offset ballPos = Offset(0, 0);
  /// Previous positions of the ball for trail effect
  List<Offset> ballTrail = [];

  /// Current direction the ball is moving
  Offset ballDirection = Offset(1, 1);

  /// Map of hits to game speed in milliseconds
  final Map<int, int> speedSteps = {
    0: 350,
    3: 320,
    7: 290,
    10: 230,
    15: 200,
    20: 150,
  };

  /// Current game speed
  late int currSpeed;
  /// Number of successful paddle hits
  int hits = 0;

  /// Length of the ball trail effect
  final int trailLength = 4;

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

  @override
  void previewRender(GameControl currentControl, MatrixViewState matrixState) {
    drawPaddles(matrixState);
    drawBall(matrixState);
    matrixState.repaint();
  }

  @override
  void render(
    GameControl currentControl,
    MatrixViewState matrixState,
    Function() onStop,
  ) {
    // Only update at 150ms intervals
    if (DateTime.now().millisecondsSinceEpoch - lastUpdate >= 150) {
      lastUpdate = DateTime.now().millisecondsSinceEpoch;

      // Update ball position at the current game speed
      if (DateTime.now().millisecondsSinceEpoch - lastBallUpdate >= currSpeed) {
        lastBallUpdate = DateTime.now().millisecondsSinceEpoch;
        ballPos += ballDirection;
      }

      // Check for wall collisions on left and right sides
      if (ballPos.dx < 0) {
        ballPos = Offset(0, ballPos.dy);
        ballDirection = Offset(-ballDirection.dx, ballDirection.dy);
      } else if (ballPos.dx > matrixWidth - 1) {
        ballPos = Offset(matrixWidth - 1, ballPos.dy);
        ballDirection = Offset(-ballDirection.dx, ballDirection.dy);
      }

      // Check for paddle collisions at the top
      if (ballPos.dy < 1) {
        if (ballPos.dx >= topPaddleX &&
            ballPos.dx <= topPaddleX + paddleWidth) {
          ballPos = Offset(ballPos.dx, 1);
          lastHitTop = true;

          triggerHit();
        } else {
          // Ball missed the paddle: game over
          onStop();
          return;
        }
      } else if (ballPos.dy > matrixWidth - 2) {
        // Check for paddle collisions at the bottom
        if (ballPos.dx >= bottomPaddleX &&
            ballPos.dx <= bottomPaddleX + paddleWidth) {
          ballPos = Offset(ballPos.dx, matrixWidth - 2);
          lastHitTop = false;

          triggerHit();
        } else {
          // Ball missed the paddle: game over
          onStop();
          return;
        }
      }

      // Update ball trail for the visual effect
      if(ballPos != (ballTrail.isNotEmpty ? ballTrail.last : null)) {
        ballTrail.add(ballPos);
        if (ballTrail.length > trailLength) {
          ballTrail.removeAt(0);
        }
      }

      // Move paddles based on control input
      // The paddle that moves depends on which side last hit the ball
      if (lastHitTop) {
        bottomPaddleX = movePlatform(currentControl, bottomPaddleX);
      } else {
        topPaddleX = movePlatform(currentControl, topPaddleX);
      }

      // Draw all game elements
      drawPaddles(matrixState);
      drawBall(matrixState);
      drawTrace(matrixState);

      matrixState.repaint();
    }
  }

  /// Calculates the current game speed based on hits
  int getSpeed() {
    int speed = 0;
    for (int step in speedSteps.keys) {
      if (hits >= step) {
        speed = speedSteps[step]!;
      }
    }
    return speed;
  }

  /// Moves a paddle based on control input, keeping it within bounds
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

  /// Generates a random direction for the ball
  Offset randomDirection() {
    int x = ([-1, 1]..shuffle()).first;
    int y = ([-1, 1]..shuffle()).first;
    return Offset(x.toDouble(), y.toDouble());
  }

  /// Handles a successful paddle hit
  /// Increases hit count and reverses ball direction
  void triggerHit() {
    hits++;
    currSpeed = getSpeed();
    ballDirection = Offset(ballDirection.dx, -ballDirection.dy);
    HapticFeedback.lightImpact();
  }

  /// Draws the ball trail effect
  void drawTrace(MatrixViewState matrixState) {
    for (int i = 0; i < ballTrail.length - 1; i++) {
      double opacity = (i + 1) / ballTrail.length;
      matrixState.drawPixelFromOffset(
          ballTrail[i], Colors.white.withAlpha((opacity * 100).toInt()),);
    }
  }

  /// Draws the ball on the matrix
  void drawBall(MatrixViewState matrixState) {
    matrixState.drawPixelFromOffset(ballPos, Colors.white.withAlpha(170));
  }

  /// Draws both paddles on the matrix
  void drawPaddles(MatrixViewState matrixState) {
    for (int x = topPaddleX; x < topPaddleX + paddleWidth; x++) {
      matrixState.drawPixel(x, 0, Colors.white);
    }

    for (int x = bottomPaddleX; x < bottomPaddleX + paddleWidth; x++) {
      matrixState.drawPixel(x, matrixWidth - 1, Colors.white);
    }
  }
}
