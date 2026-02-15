import "dart:async";

import "package:flutter/material.dart";
import "package:open_wearable/apps/pixelated_games/games/pong_game.dart";
import "package:open_wearable/apps/pixelated_games/games/snake_game.dart";
import "package:open_wearable/apps/pixelated_games/model/game_info.dart";
import "package:open_wearable/apps/pixelated_games/model/game_posture_tracker.dart";
import "package:open_wearable/apps/pixelated_games/model/pixelated_game_model.dart";
import "package:open_wearable/apps/pixelated_games/view/control_stick_view.dart";
import "package:open_wearable/apps/pixelated_games/view/matrix_view.dart";
import "package:open_wearable/apps/posture_tracker/model/attitude_tracker.dart";
import "package:provider/provider.dart";

/// Main view for the pixelated games application
/// Manages game selection, rendering, and user interaction through head gestures
class PixelatedGamesView extends StatefulWidget {
  final AttitudeTracker _tracker;

  const PixelatedGamesView(this._tracker, {super.key});

  @override
  State<PixelatedGamesView> createState() => _PixelatedGamesViewState();
}

class _PixelatedGamesViewState extends State<PixelatedGamesView> {
  /// Key to access the matrix view state for rendering
  final GlobalKey<MatrixViewState> matrixKey = GlobalKey();

  /// The current active game model
  late PixelatedGameModel currGameModel;

  /// Whether the game is currently running
  bool running = false;

  /// Whether the app is in calibration mode
  bool calibrating = false;

  /// Timer for the game loop
  Timer? _gameTimer;

  List<GameInfo> availableGames = [
    GameInfo(
      "Snake",
      "lib/apps/pixelated_games/assets/snake_icon.png",
      "Turn your head up, down, left, or right to control the snake and eat the food.",
      SnakeGame,
      SnakeGame.new,
    ),
    GameInfo(
      "Pong",
      "lib/apps/pixelated_games/assets/pong_icon.png",
      "Control the paddle by tilting your head left and right. Keep the ball from touching the edges!",
      PongGame,
      PongGame.new,
    ),
  ];

  @override
  void initState() {
    super.initState();
    currGameModel = availableGames[0].constructor();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _switchToGame(
          availableGames[0].gameType, GamePostureTracker(widget._tracker));
    });
  }

  @override
  void dispose() {
    running = false;
    _gameTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<GamePostureTracker>(
      create: (context) => GamePostureTracker(widget._tracker),
      builder: (context, child) => Consumer<GamePostureTracker>(
        builder: (context, gamePostureTracker, child) => Scaffold(
          appBar: AppBar(
            title: Text("Pixelated Games"),
          ),
          body: Column(
            children: [
              _buildGameSelection(gamePostureTracker),
              Center(child: _buildContentView(gamePostureTracker)),
              running ? _buildControlStick(gamePostureTracker) : SizedBox(),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.surface,
        ),
      ),
    );
  }

  /// Builds the main game display area with matrix view and overlays
  Widget _buildContentView(GamePostureTracker gameTracker) {
    return Container(
      width: 400,
      height: 400,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Color.fromARGB(255, 30, 30, 30),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          MatrixView(key: matrixKey),
          !running
              ? Container(
                  color: Colors.black.withAlpha(100),
                )
              : SizedBox(),
          calibrating
              ? _buildCalibrationOverlay(gameTracker)
              : !running
                  ? _buildPlayOverview(gameTracker)
                  : SizedBox(),
        ],
      ),
    );
  }

  /// Displays a control stick showing the current head movement input
  Widget _buildControlStick(GamePostureTracker gamePostureTracker) {
    return Padding(
      padding: const EdgeInsets.only(top: 30),
      child: SizedBox(
        width: 150,
        height: 150,
        child: CustomPaint(
          painter: ControlStickPainter(
            roll: gamePostureTracker.attitude.roll,
            pitch: gamePostureTracker.attitude.pitch,
            rollThreshold: GamePostureTracker.rollThreshold,
            pitchThreshold: GamePostureTracker.pitchThreshold,
          ),
        ),
      ),
    );
  }

  /// Shows the game preview screen with title and description before play
  Widget _buildPlayOverview(GamePostureTracker gameTracker) {
    GameInfo gameInfo = _getGameInfo(currGameModel.runtimeType);
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 30),
          child: Text(
            gameInfo.name,
            style: TextStyle(
                color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(child: _buildPlayButton(gameTracker)),
        Padding(
          padding: const EdgeInsets.fromLTRB(30, 0, 30, 30),
          child: Text(
            gameInfo.description,
            style: TextStyle(
                color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }

  /// Builds the play button that starts calibration and preview
  Widget _buildPlayButton(GamePostureTracker gameTracker) {
    return GestureDetector(
      onTap: () {
        _startCalibration(gameTracker);
        _previewGame(gameTracker);
      },
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          color: Color(0xaaffffff),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Image.asset(
            "lib/apps/pixelated_games/assets/play_icon.png",
            width: 50,
            height: 50,
          ),
        ),
      ),
    );
  }

  /// Shows the calibration screen where user sets neutral head position
  Widget _buildCalibrationOverlay(GamePostureTracker gameTracker) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(30, 30, 30, 0),
          child: Text(
            "Adjust your posture to a neutral position and press continue",
            style: TextStyle(
                color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ),
        Expanded(
          child: Image.asset(
            "lib/apps/posture_tracker/assets/Head_Front.png",
            width: 200,
            height: 200,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 30),
          child: ElevatedButton(
            onPressed: () {
              _finishCalibration(gameTracker);
              _startGame(gameTracker);
            },
            child: Text("Continue"),
          ),
        ),
      ],
    );
  }

  /// Builds the game selection row with icons for each available game
  Widget _buildGameSelection(GamePostureTracker gameTracker) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(availableGames.length, (index) {
        var gameInfo = availableGames[index];
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: GestureDetector(
            onTap: () => _switchToGame(gameInfo.gameType, gameTracker),
            child: Column(
              children: [
                AnimatedOpacity(
                  opacity: gameInfo.gameType == currGameModel.runtimeType
                      ? 1.0
                      : 0.5,
                  duration: Duration(milliseconds: 200),
                  child: AnimatedScale(
                    scale: gameInfo.gameType == currGameModel.runtimeType
                        ? 1.0
                        : 0.8,
                    duration: Duration(milliseconds: 200),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.asset(
                        gameInfo.assetPath,
                        width: 100,
                        height: 100,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 5),
                Text(gameInfo.name),
              ],
            ),
          ),
        );
      }),
    );
  }

  /// Switches to a different game and initializes it
  /// Stops current game if running and resets the matrix
  void _switchToGame(Type gameType, GamePostureTracker gameTracker) {
    if (running) {
      _stopGame(gameTracker);
      matrixKey.currentState?.reset();
    }

    setState(() {
      calibrating = false;
      currGameModel = _getGameInfo(gameType).constructor();

      currGameModel.initGame();
      _previewGame(gameTracker);
    });
  }

  /// Starts the game loop and tracking
  /// Adds a delay before starting the game timer
  void _startGame(GamePostureTracker gameTracker) async {
    if (!gameTracker.isTracking) {
      gameTracker.startTracking();
    }

    setState(() {
      running = true;
    });

    await Future.delayed(Duration(milliseconds: 500));
    _startGameClock(gameTracker);
  }

  /// Stops the game loop and tracking
  void _stopGame(GamePostureTracker gameTracker) {
    if (gameTracker.isTracking) {
      gameTracker.stopTracking();
    }

    setState(() {
      running = false;
    });
  }

  /// Begins the calibration process by starting tracking and showing overlay
  void _startCalibration(GamePostureTracker gameTracker) {
    if (!gameTracker.isTracking) {
      gameTracker.startTracking();
    }

    // Display calibration overlay
    setState(() {
      calibrating = true;
    });
  }

  /// Completes calibration by setting the current head position as neutral
  void _finishCalibration(GamePostureTracker gameTracker) {
    gameTracker.calibrate();
    setState(() {
      calibrating = false;
    });
  }

  /// Starts the game update timer that renders at 20 FPS
  /// Calls game render method and handles game over
  void _startGameClock(GamePostureTracker gameTracker) {
    _gameTimer = Timer.periodic(Duration(milliseconds: 50), (timer) {
      if (!running || matrixKey.currentState == null) {
        timer.cancel();
      } else {
        currGameModel
            .render(gameTracker.currentControl, matrixKey.currentState!, () {
          _stopGame(gameTracker);
          currGameModel = _getGameInfo(currGameModel.runtimeType).constructor();
          currGameModel.initGame();
        });
      }
    });
  }

  /// Retrieves game information for the specified game type
  GameInfo _getGameInfo(Type gameType) {
    return availableGames.firstWhere(
      (element) => element.gameType == gameType,
    );
  }

  /// Renders a preview of the current game on the matrix
  void _previewGame(GamePostureTracker gameTracker) {
    if (matrixKey.currentState != null) {
      currGameModel.previewRender(
        gameTracker.currentControl,
        matrixKey.currentState!,
      );
    }
  }
}
