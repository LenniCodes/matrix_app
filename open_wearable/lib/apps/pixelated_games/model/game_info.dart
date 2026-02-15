/// Contains metadata about a pixelated game
class GameInfo {
  /// The name of the game
  final String name;

  /// Path to the game icon asset
  final String assetPath;

  /// Brief description of the game and controls
  final String description;

  /// The game class type
  final Type gameType;

  /// Factory function to create a new game instance
  final Function() constructor;

  GameInfo(this.name, this.assetPath, this.description, this.gameType,
      this.constructor);
}
