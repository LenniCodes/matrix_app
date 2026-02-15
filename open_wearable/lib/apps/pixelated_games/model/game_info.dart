class GameInfo {
  final String name;
  final String assetPath;
  final String description;
  final Type gameType;
  final Function() constructor;

  GameInfo(this.name,this.assetPath, this.description, this.gameType, this.constructor);
}
