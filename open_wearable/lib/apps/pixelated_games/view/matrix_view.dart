import 'package:flutter/material.dart';

/// Width and height of the pixel matrix grid
const matrixWidth = 10;

/// Widget that displays a 10x10 pixel matrix for game rendering
class MatrixView extends StatefulWidget {
  const MatrixView({super.key});

  @override
  State<MatrixView> createState() => MatrixViewState();
}

class MatrixViewState extends State<MatrixView> {
  /// Previous frame pixels for diff-based rendering
  List<List<Color>> oldPixels = [];
  /// Current frame pixels to be rendered
  late List<List<Color>> pixels;
  /// Flag to trigger repaint on next frame
  bool shouldRepaint = false;

  @override
  void initState() {
    pixels = List.generate(
      matrixWidth,
      (i) => List.generate(
        matrixWidth,
        (j) => Colors.transparent,
      ),
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: MatrixPainter(pixels, oldPixels, repaint: shouldRepaint),
      child: Container(),
    );
  }

  /// Resets and clears the pixel matrix
  void reset() {
    clear();
    repaint();
  }

  /// Clears all pixels to transparent
  void clear() {
    for (int x = 0; x < pixels.length; x++) {
      for (int y = 0; y < pixels[x].length; y++) {
        pixels[x][y] = Colors.transparent;
      }
    }
  }

  /// Draws a pixel at the specified coordinates with the given color
  void drawPixel(int x, int y, Color color) {
    pixels[x][y] = color;
  }

  /// Draws a pixel from an offset position with the given color
  void drawPixelFromOffset(Offset pos, Color color) {
    pixels[pos.dx.toInt()][pos.dy.toInt()] = color;
  }

  /// Triggers a repaint and swaps the old pixels with current pixels
  void repaint() {
    setState(() {
      shouldRepaint = true;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (shouldRepaint) {
        oldPixels = List.generate(
          matrixWidth,
          (i) => List.generate(
            matrixWidth,
            (j) => pixels[i][j],
          ),
        );
        clear();
        setState(() {
        shouldRepaint = false;
        });
      }
    });
  }
}

/// Custom painter for rendering the pixel matrix
class MatrixPainter extends CustomPainter {
  /// Current frame pixels to draw
  final List<List<Color>> pixels;
  /// Previous frame pixels for comparison
  final List<List<Color>> oldPixels;
  /// Whether to repaint the matrix
  final bool repaint;

  MatrixPainter(this.pixels, this.oldPixels, {this.repaint = false});

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;

    List<List<Color>> pixelsToDraw = repaint ? pixels : oldPixels;

    for (int x = 0; x < pixelsToDraw.length; x++) {
      for (int y = 0; y < pixelsToDraw[x].length; y++) {
        paint.color = pixelsToDraw[x][y];
        if (paint.color != Colors.transparent) {
          final cellWidth = size.width / matrixWidth;
          final cellHeight = size.height / matrixWidth;
          final rect = Rect.fromLTWH(
              x * cellWidth, y * cellHeight, cellWidth, cellHeight);
          canvas.drawRect(rect, paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(MatrixPainter oldDelegate) => repaint && !oldDelegate.repaint;
}
