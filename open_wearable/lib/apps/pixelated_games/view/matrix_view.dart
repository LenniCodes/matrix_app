import 'package:flutter/material.dart';

const matrixWidth = 10;

class MatrixView extends StatefulWidget {
  const MatrixView({super.key});

  @override
  State<MatrixView> createState() => MatrixViewState();
}

class MatrixViewState extends State<MatrixView> {
  List<List<Color>> oldPixels = [];
  late List<List<Color>> pixels;
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

  void reset() {
    clear();
    repaint();
  }

  void clear() {
    for (int x = 0; x < pixels.length; x++) {
      for (int y = 0; y < pixels[x].length; y++) {
        pixels[x][y] = Colors.transparent;
      }
    }
  }

  void drawPixel(int x, int y, Color color) {
    pixels[x][y] = color;
  }

  void drawPixelFromOffset(Offset pos, Color color) {
    pixels[pos.dx.toInt()][pos.dy.toInt()] = color;
  }

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

class MatrixPainter extends CustomPainter {
  final List<List<Color>> pixels;
  final List<List<Color>> oldPixels;
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
