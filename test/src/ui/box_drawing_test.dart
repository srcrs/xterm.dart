import 'dart:ui';

import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xterm/src/terminal.dart';
import 'package:xterm/src/ui/box_drawing.dart';
import 'package:xterm/src/ui/painter.dart';
import 'package:xterm/src/ui/terminal_text_style.dart';
import 'package:xterm/src/ui/themes.dart';

/// The Box Drawing block, drawn as line work instead of from a font.
///
/// The reason this pass exists is the ends: a cell is as tall as the line
/// height, a font's `│` is not, and the gap that left on every row is what made
/// a border look dashed. So what is pinned here is where a line stops — at the
/// cell's edge when it goes on, at the arm it meets when it turns — and how
/// many strokes a double line has, because a corner that ignored that would be
/// a filled block.
void main() {
  late Size cell;

  setUpAll(() => cell = _painter(1).cellSize);

  test('a light vertical spans the cell, edge to edge', () {
    final rects = _paint('\u2502').rects;

    expect(rects, hasLength(1));
    final rect = rects.single;
    expect(rect.top, 0);
    expect(rect.bottom, closeTo(cell.height, 0.001));
    expect(rect.width, 1);
    expect(rect.center.dx, closeTo(cell.width / 2, 0.5));
  });

  test('a vertical in the next row starts where this one stopped', () {
    // The whole point. Two rows of `│` may not leave a gap between them, which
    // is exactly what a font glyph did whenever the line height was larger
    // than the font's own line box.
    final first = _paint('\u2502').rects.single;
    final second = _paint(
      '\u2502',
      offset: Offset(0, cell.height),
    ).rects.single;

    expect(first.bottom, closeTo(second.top, 0.001));
  });

  test('a light horizontal spans the cell, edge to edge', () {
    final rects = _paint('\u2500').rects;

    expect(rects, hasLength(1));
    final rect = rects.single;
    expect(rect.left, 0);
    expect(rect.right, closeTo(cell.width, 0.001));
    expect(rect.height, 1);
    expect(rect.center.dy, closeTo(cell.height / 2, 0.5));
  });

  test('a heavy line is twice a light one', () {
    final light = _paint('\u2502').rects.single;
    final heavy = _paint('\u2503').rects.single;

    expect(heavy.width, light.width * 2);
  });

  test('a corner turns at the cell centre', () {
    // `┌`, down and right: the vertical half runs from the corner down and the
    // horizontal half from the corner right.
    final rects = _paint('\u250C').rects;

    expect(rects, hasLength(2));
    final vertical = rects.firstWhere((rect) => rect.height > rect.width);
    final horizontal = rects.firstWhere((rect) => rect.width > rect.height);
    expect(vertical.top, closeTo(cell.height / 2, 0.5));
    expect(vertical.bottom, closeTo(cell.height, 0.001));
    expect(horizontal.left, closeTo(cell.width / 2, 0.5));
    expect(horizontal.right, closeTo(cell.width, 0.001));
  });

  test('a half line stops at the centre', () {
    // `╵`, an up half line: it has nothing to meet, so it ends in the middle
    // rather than at the far edge.
    final rects = _paint('\u2575').rects;

    expect(rects, hasLength(1));
    expect(rects.single.top, 0);
    expect(rects.single.bottom, closeTo(cell.height / 2, 0.5));
  });

  test('a double line is two strokes one apart', () {
    final rects = _paint('\u2551').rects;

    expect(rects, hasLength(2));
    expect(rects[0].width, 1);
    expect(rects[1].left - rects[0].right, closeTo(rects[0].width, 0.001));
  });

  test('a double corner is two corners, not a block', () {
    // `╔`: the outer strokes meet at the corner and the inner ones meet each
    // other, so each horizontal stroke stops at the vertical stroke beside it.
    final rects = _paint('\u2554').rects;

    expect(rects, hasLength(4));
    final horizontals = rects
        .where((rect) => rect.width > rect.height)
        .toList();
    final verticals = rects.where((rect) => rect.height > rect.width).toList();
    expect(horizontals, hasLength(2));
    expect(verticals, hasLength(2));

    final top = horizontals.reduce((a, b) => a.top < b.top ? a : b);
    final outerLeft = verticals.reduce((a, b) => a.left < b.left ? a : b);
    expect(top.left, closeTo(outerLeft.center.dx, 1));

    final inner = horizontals.reduce((a, b) => a.top > b.top ? a : b);
    final innerRight = verticals.reduce((a, b) => a.left > b.left ? a : b);
    expect(inner.left, closeTo(innerRight.center.dx, 1));
  });

  test('a dash line has the number of dashes its name says', () {
    // `┄`, light triple dash horizontal.
    expect(_paint('\u2504').rects, hasLength(3));
    // `╎`, light double dash vertical.
    expect(_paint('\u254E').rects, hasLength(2));
  });

  test('an arc is a path rather than a rectangle', () {
    final painted = _paint('\u256D');

    expect(painted.rects, isEmpty);
    expect(painted.paths, hasLength(1));
  });

  test('the diagonals are still the font\'s', () {
    expect(isBoxDrawingRendered(0x2571), isFalse);
    expect(isBoxDrawingRendered(0x41), isFalse);
    expect(isBoxDrawingRendered(0x2502), isTrue);
    expect(isBoxDrawingRendered(0x2504), isTrue);
    expect(isBoxDrawingRendered(0x256D), isTrue);
  });
}

TerminalPainter _painter(double dpr) => TerminalPainter(
  theme: TerminalThemes.defaultTheme,
  textStyle: const TerminalStyle(),
  textScaler: TextScaler.noScaling,
  devicePixelRatio: dpr,
);

_Painted _paint(String text, {int width = 4, Offset offset = Offset.zero}) {
  final terminal = Terminal(maxLines: 2);
  terminal.resize(width, 1);
  terminal.write(text);

  final recorder = PictureRecorder();
  final canvas = _RecordingCanvas(Canvas(recorder));
  _painter(1).paintLine(canvas, offset, terminal.buffer.lines[0]);
  recorder.endRecording().dispose();
  return _Painted(canvas.rects, canvas.paths);
}

class _Painted {
  const _Painted(this.rects, this.paths);

  final List<Rect> rects;
  final List<Path> paths;
}

/// Records the two primitives the box-drawing pass draws, and nothing else:
/// a pass that starts drawing something new should fail here rather than have
/// it go unrecorded.
class _RecordingCanvas implements Canvas {
  _RecordingCanvas(this._inner);

  final Canvas _inner;

  final rects = <Rect>[];
  final paths = <Path>[];

  @override
  void drawRect(Rect rect, Paint paint) {
    rects.add(rect);
    _inner.drawRect(rect, paint);
  }

  @override
  void drawPath(Path path, Paint paint) {
    paths.add(path);
    _inner.drawPath(path, paint);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    throw UnsupportedError(
      'box drawing test: unexpected canvas call ${invocation.memberName}',
    );
  }
}
