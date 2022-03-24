///
/// [Author] Alex (https://github.com/AlexV525)
/// [Date] 1/6/21 10:04 PM
///
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

double get _screenWidth => MediaQueryData.fromWindow(ui.window).size.width;

/// 使用非零填充环绕实现的矩形镂空
///
/// [height] 镂空的高度
/// [paddingOffset] 镂空区域距离起始点的偏移量，且作为边距
class ScanRectPainter extends CustomPainter {
  const ScanRectPainter({
    required this.height,
    required this.padding,
    this.backgroundColor = Colors.black45,
    this.color = const Color(0xff3271f6),
  });

  final double height;
  final EdgeInsets padding;
  final Color backgroundColor;
  final Color color;

  void drawInnerRect(Canvas canvas, Size size) {
    final Path path = Path()..fillType = PathFillType.evenOdd;
    // 先画外部矩形
    path
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    // 再画内部矩形
    path
      ..moveTo(padding.left, padding.top)
      ..lineTo(size.width - padding.right, padding.top)
      ..lineTo(size.width - padding.right, padding.top + height)
      ..lineTo(padding.left, padding.top + height)
      ..close();
    // Canvas 绘制路径
    canvas.drawPath(
      path,
      Paint()
        ..color = backgroundColor
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.fill,
    );
  }

  void drawBorder(Canvas canvas, Size size) {
    // 绘制外框
    canvas.drawRect(
      Rect.fromLTWH(
        padding.left,
        padding.top,
        size.width - padding.left - padding.right,
        height,
      ),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
  }

  void drawCorners(Canvas canvas, Size size) {
    const double strokeLength = 18;
    const double strokeThickness = 5;
    final Offset offset = Offset(padding.left, padding.top) -
        const Offset(strokeThickness / 2, strokeThickness / 2);
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeThickness
      ..style = PaintingStyle.fill;
    final List<List<Offset>> cornersRectStartPoints = <List<Offset>>[
      <Offset>[offset, offset],
      <Offset>[
        Offset(_screenWidth - offset.dx - strokeLength, offset.dy),
        Offset(_screenWidth - offset.dx - strokeThickness, offset.dy),
      ],
      <Offset>[
        Offset(
          _screenWidth - offset.dx - strokeLength,
          offset.dy + height,
        ),
        Offset(
          _screenWidth - offset.dx - strokeThickness,
          offset.dy + height - strokeLength + strokeThickness,
        ),
      ],
      <Offset>[
        offset + Offset(0, height),
        offset + Offset(0, height - strokeLength + strokeThickness),
      ],
    ];
    for (final List<Offset> points in cornersRectStartPoints) {
      canvas.drawRect(
        Rect.fromLTWH(
          points[0].dx,
          points[0].dy,
          strokeLength,
          strokeThickness,
        ),
        paint,
      );
      canvas.drawRect(
        Rect.fromLTWH(
          points[1].dx,
          points[1].dy,
          strokeThickness,
          strokeLength,
        ),
        paint,
      );
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    drawInnerRect(canvas, size);
    drawBorder(canvas, size);
    drawCorners(canvas, size);
  }

  @override
  bool shouldRepaint(ScanRectPainter oldDelegate) =>
      height != oldDelegate.height;
}
