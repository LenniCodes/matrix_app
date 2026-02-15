import 'package:open_wearable/apps/pixelated_games/model/game_posture_tracker.dart';
import 'package:open_wearable/apps/pixelated_games/view/matrix_view.dart';

/// Abstract base class for pixelated games
/// Defines the interface for game rendering and initialization
abstract class PixelatedGameModel {
  PixelatedGameModel();

  /// Renders the current frame of the game
  /// Updates game state based on player control input
  void render(GameControl currentControl, MatrixViewState matrixState,
      Function() onStop,);

  /// Initializes the game state
  void initGame();

  /// Renders a preview of the game before it starts
  void previewRender(GameControl currentControl, MatrixViewState matrixState) {}
}
