import 'package:open_wearable/apps/pixelated_games/model/game_posture_tracker.dart';
import 'package:open_wearable/apps/pixelated_games/view/matrix_view.dart';

abstract class PixelatedGameModel {

  PixelatedGameModel();

  void render(GameControl currentControl, MatrixViewState matrixState, Function() onStop);

  void initGame();

  void previewRender(GameControl currentControl, MatrixViewState matrixState) {
  }

}
