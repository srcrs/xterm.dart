import 'dart:math' as math;
import 'dart:ui';

/// Whether [codePoint] is a Box Drawing character drawn by
/// [paintBoxDrawing] rather than from a font.
///
/// The diagonals of the block are left to the font; every character a frame,
/// a table or a meter is drawn with is here.
bool isBoxDrawingRendered(int codePoint) =>
    _arms.containsKey(codePoint) ||
    _dashes.containsKey(codePoint) ||
    (codePoint >= 0x256D && codePoint <= 0x2570);

/// Draws one Box Drawing character (`U+2500`..`U+257F`) into [cell].
///
/// A terminal cell is as tall as the line height the style asks for. A font's
/// `│` is not: it is drawn inside the font's own line box, which is shorter,
/// so the cell after it starts a little below where the glyph stopped — and a
/// border comes out as a dashed line that nobody asked for, one gap per row.
/// Terminals that care draw these characters themselves, in the cell's
/// foreground colour and to the cell's own measurements; so does this. The
/// line height then cannot break a border, and neither can the font that
/// would have drawn it.
///
/// Everything is in cell-local coordinates. Arms meet at the cell's centre —
/// or at the arm they run into — and reach the cell's edge in the directions
/// they go, which is what makes one cell's line join the next one's. See
/// [_paintArms] for the one case that needs more than that.
void paintBoxDrawing(
  Canvas canvas,
  Rect cell,
  int codePoint,
  Color color,
  double devicePixelRatio,
) {
  final arms = _arms[codePoint];
  if (arms != null) {
    _paintArms(canvas, cell, arms, color, devicePixelRatio);
    return;
  }

  final dashes = _dashes[codePoint];
  if (dashes != null) {
    _paintDashes(canvas, cell, dashes, color, devicePixelRatio);
    return;
  }

  _paintArc(canvas, cell, codePoint, color, devicePixelRatio);
}

/// The four arms of one character, as what each of them is drawn with: one of
/// [_none], [_light], [_heavy] and [_double].
final class BoxArms {
  const BoxArms(this.left, this.right, this.up, this.down);

  final int left;
  final int right;
  final int up;
  final int down;
}

/// One dashed line: how many dashes, how heavy, and which way it runs.
final class BoxDashes {
  const BoxDashes(this.count, {required this.heavy, required this.vertical});

  final int count;
  final bool heavy;
  final bool vertical;
}

const _none = 0;
const _light = 1;
const _heavy = 2;

/// Two light lines with a gap the width of one between them.
const _double = 3;

/// Every character of the block drawn as arms, by the character's own name:
/// (`left`, `right`, `up`, `down`).
const _arms = <int, BoxArms>{
  0x2500: BoxArms(_light, _light, _none, _none),
  0x2501: BoxArms(_heavy, _heavy, _none, _none),
  0x2502: BoxArms(_none, _none, _light, _light),
  0x2503: BoxArms(_none, _none, _heavy, _heavy),
  0x250C: BoxArms(_none, _light, _none, _light),
  0x250D: BoxArms(_none, _heavy, _none, _light),
  0x250E: BoxArms(_none, _light, _none, _heavy),
  0x250F: BoxArms(_none, _heavy, _none, _heavy),
  0x2510: BoxArms(_light, _none, _none, _light),
  0x2511: BoxArms(_heavy, _none, _none, _light),
  0x2512: BoxArms(_light, _none, _none, _heavy),
  0x2513: BoxArms(_heavy, _none, _none, _heavy),
  0x2514: BoxArms(_none, _light, _light, _none),
  0x2515: BoxArms(_none, _heavy, _light, _none),
  0x2516: BoxArms(_none, _light, _heavy, _none),
  0x2517: BoxArms(_none, _heavy, _heavy, _none),
  0x2518: BoxArms(_light, _none, _light, _none),
  0x2519: BoxArms(_heavy, _none, _light, _none),
  0x251A: BoxArms(_light, _none, _heavy, _none),
  0x251B: BoxArms(_heavy, _none, _heavy, _none),
  0x251C: BoxArms(_none, _light, _light, _light),
  0x251D: BoxArms(_none, _heavy, _light, _light),
  0x251E: BoxArms(_none, _light, _heavy, _light),
  0x251F: BoxArms(_none, _light, _light, _heavy),
  0x2520: BoxArms(_none, _light, _heavy, _heavy),
  0x2521: BoxArms(_none, _heavy, _heavy, _light),
  0x2522: BoxArms(_none, _heavy, _light, _heavy),
  0x2523: BoxArms(_none, _heavy, _heavy, _heavy),
  0x2524: BoxArms(_light, _none, _light, _light),
  0x2525: BoxArms(_heavy, _none, _light, _light),
  0x2526: BoxArms(_light, _none, _heavy, _light),
  0x2527: BoxArms(_light, _none, _light, _heavy),
  0x2528: BoxArms(_light, _none, _heavy, _heavy),
  0x2529: BoxArms(_heavy, _none, _heavy, _light),
  0x252A: BoxArms(_heavy, _none, _light, _heavy),
  0x252B: BoxArms(_heavy, _none, _heavy, _heavy),
  0x252C: BoxArms(_light, _light, _none, _light),
  0x252D: BoxArms(_heavy, _light, _none, _light),
  0x252E: BoxArms(_light, _heavy, _none, _light),
  0x252F: BoxArms(_heavy, _heavy, _none, _light),
  0x2530: BoxArms(_light, _light, _none, _heavy),
  0x2531: BoxArms(_heavy, _light, _none, _heavy),
  0x2532: BoxArms(_light, _heavy, _none, _heavy),
  0x2533: BoxArms(_heavy, _heavy, _none, _heavy),
  0x2534: BoxArms(_light, _light, _light, _none),
  0x2535: BoxArms(_heavy, _light, _light, _none),
  0x2536: BoxArms(_light, _heavy, _light, _none),
  0x2537: BoxArms(_heavy, _heavy, _light, _none),
  0x2538: BoxArms(_light, _light, _heavy, _none),
  0x2539: BoxArms(_heavy, _light, _heavy, _none),
  0x253A: BoxArms(_light, _heavy, _heavy, _none),
  0x253B: BoxArms(_heavy, _heavy, _heavy, _none),
  0x253C: BoxArms(_light, _light, _light, _light),
  0x253D: BoxArms(_heavy, _light, _light, _light),
  0x253E: BoxArms(_light, _heavy, _light, _light),
  0x253F: BoxArms(_heavy, _heavy, _light, _light),
  0x2540: BoxArms(_light, _light, _heavy, _light),
  0x2541: BoxArms(_light, _light, _light, _heavy),
  0x2542: BoxArms(_light, _light, _heavy, _heavy),
  0x2543: BoxArms(_heavy, _light, _heavy, _light),
  0x2544: BoxArms(_light, _heavy, _heavy, _light),
  0x2545: BoxArms(_heavy, _light, _light, _heavy),
  0x2546: BoxArms(_light, _heavy, _light, _heavy),
  0x2547: BoxArms(_heavy, _heavy, _heavy, _light),
  0x2548: BoxArms(_heavy, _heavy, _light, _heavy),
  0x2549: BoxArms(_heavy, _light, _heavy, _heavy),
  0x254A: BoxArms(_light, _heavy, _heavy, _heavy),
  0x254B: BoxArms(_heavy, _heavy, _heavy, _heavy),
  0x2550: BoxArms(_double, _double, _none, _none),
  0x2551: BoxArms(_none, _none, _double, _double),
  0x2552: BoxArms(_none, _double, _none, _light),
  0x2553: BoxArms(_none, _light, _none, _double),
  0x2554: BoxArms(_none, _double, _none, _double),
  0x2555: BoxArms(_double, _none, _none, _light),
  0x2556: BoxArms(_light, _none, _none, _double),
  0x2557: BoxArms(_double, _none, _none, _double),
  0x2558: BoxArms(_none, _double, _light, _none),
  0x2559: BoxArms(_none, _light, _double, _none),
  0x255A: BoxArms(_none, _double, _double, _none),
  0x255B: BoxArms(_double, _none, _light, _none),
  0x255C: BoxArms(_light, _none, _double, _none),
  0x255D: BoxArms(_double, _none, _double, _none),
  0x255E: BoxArms(_none, _double, _light, _light),
  0x255F: BoxArms(_none, _light, _double, _double),
  0x2560: BoxArms(_none, _double, _double, _double),
  0x2561: BoxArms(_double, _none, _light, _light),
  0x2562: BoxArms(_light, _none, _double, _double),
  0x2563: BoxArms(_double, _none, _double, _double),
  0x2564: BoxArms(_double, _double, _none, _light),
  0x2565: BoxArms(_light, _light, _none, _double),
  0x2566: BoxArms(_double, _double, _none, _double),
  0x2567: BoxArms(_double, _double, _light, _none),
  0x2568: BoxArms(_light, _light, _double, _none),
  0x2569: BoxArms(_double, _double, _double, _none),
  0x256A: BoxArms(_double, _double, _light, _light),
  0x256B: BoxArms(_light, _light, _double, _double),
  0x256C: BoxArms(_double, _double, _double, _double),
  0x2574: BoxArms(_light, _none, _none, _none),
  0x2575: BoxArms(_none, _none, _light, _none),
  0x2576: BoxArms(_none, _light, _none, _none),
  0x2577: BoxArms(_none, _none, _none, _light),
  0x2578: BoxArms(_heavy, _none, _none, _none),
  0x2579: BoxArms(_none, _none, _heavy, _none),
  0x257A: BoxArms(_none, _heavy, _none, _none),
  0x257B: BoxArms(_none, _none, _none, _heavy),
  0x257C: BoxArms(_light, _heavy, _none, _none),
  0x257D: BoxArms(_none, _none, _light, _heavy),
  0x257E: BoxArms(_heavy, _light, _none, _none),
  0x257F: BoxArms(_none, _none, _heavy, _light),
};

const _dashes = <int, BoxDashes>{
  0x2504: BoxDashes(3, heavy: false, vertical: false),
  0x2505: BoxDashes(3, heavy: true, vertical: false),
  0x2506: BoxDashes(3, heavy: false, vertical: true),
  0x2507: BoxDashes(3, heavy: true, vertical: true),
  0x2508: BoxDashes(4, heavy: false, vertical: false),
  0x2509: BoxDashes(4, heavy: true, vertical: false),
  0x250A: BoxDashes(4, heavy: false, vertical: true),
  0x250B: BoxDashes(4, heavy: true, vertical: true),
  0x254C: BoxDashes(2, heavy: false, vertical: false),
  0x254D: BoxDashes(2, heavy: true, vertical: false),
  0x254E: BoxDashes(2, heavy: false, vertical: true),
  0x254F: BoxDashes(2, heavy: true, vertical: true),
};

/// Draws [arms] into [cell].
///
/// Each arm reaches the cell's edge — that is what joins it to the cell beside
/// it — and stops where it meets another arm: at the centre when it meets
/// nothing, and at the other arm's stroke when it does. The stop is what keeps
/// a double line's corner a corner: of the two strokes in `╔`, the outer one
/// turns and the inner one does too, so the corner is two Ls rather than a
/// filled block.
void _paintArms(
  Canvas canvas,
  Rect cell,
  BoxArms arms,
  Color color,
  double devicePixelRatio,
) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.fill
    ..isAntiAlias = false;
  final t = _strokeWidth(devicePixelRatio);
  final cx = cell.center.dx;
  final cy = cell.center.dy;

  // Where each axis' strokes run on the other one: a double line is two, a
  // single one is one.
  final verticals = arms.up == _double || arms.down == _double
      ? [cx - t, cx + t]
      : [cx];
  final horizontals = arms.left == _double || arms.right == _double
      ? [cy - t, cy + t]
      : [cy];

  // Both ways with one style is one stroke rather than two that meet at the
  // centre: the halves cover the cell between them either way, and one
  // rectangle is one draw.
  if (arms.up != _none && arms.up == arms.down) {
    _paintThrough(
      canvas,
      paint,
      devicePixelRatio,
      style: arms.up,
      t: t,
      strokes: verticals,
      vertical: true,
      from: cell.top,
      to: cell.bottom,
    );
  } else {
    _paintArm(
      canvas,
      paint,
      devicePixelRatio,
      style: arms.up,
      t: t,
      strokes: verticals,
      cross: horizontals,
      edge: cell.top,
      centre: cy,
      vertical: true,
      positive: false,
    );
    _paintArm(
      canvas,
      paint,
      devicePixelRatio,
      style: arms.down,
      t: t,
      strokes: verticals,
      cross: horizontals,
      edge: cell.bottom,
      centre: cy,
      vertical: true,
      positive: true,
    );
  }

  if (arms.left != _none && arms.left == arms.right) {
    _paintThrough(
      canvas,
      paint,
      devicePixelRatio,
      style: arms.left,
      t: t,
      strokes: horizontals,
      vertical: false,
      from: cell.left,
      to: cell.right,
    );
  } else {
    _paintArm(
      canvas,
      paint,
      devicePixelRatio,
      style: arms.left,
      t: t,
      strokes: horizontals,
      cross: verticals,
      edge: cell.left,
      centre: cx,
      vertical: false,
      positive: false,
    );
    _paintArm(
      canvas,
      paint,
      devicePixelRatio,
      style: arms.right,
      t: t,
      strokes: horizontals,
      cross: verticals,
      edge: cell.right,
      centre: cx,
      vertical: false,
      positive: true,
    );
  }
}

/// Draws one direction's arm the whole way across the cell: the two arms of a
/// line that runs both ways, as one stroke.
void _paintThrough(
  Canvas canvas,
  Paint paint,
  double devicePixelRatio, {
  required int style,
  required double t,
  required List<double> strokes,
  required bool vertical,
  required double from,
  required double to,
}) {
  final thickness = style == _heavy ? t * 2 : t;
  final positions = style == _double
      ? strokes
      : [(strokes.first + strokes.last) / 2];

  for (final position in positions) {
    canvas.drawRect(
      _strokeRect(position, thickness, from, to, vertical, devicePixelRatio),
      paint,
    );
  }
}

/// Draws one direction's arm: [style] decides the thickness, [strokes] where
/// it sits, and [cross] — the perpendicular arms' strokes, empty when there
/// are none — where it stops.
void _paintArm(
  Canvas canvas,
  Paint paint,
  double devicePixelRatio, {
  required int style,
  required double t,
  required List<double> strokes,
  required List<double> cross,
  required double edge,
  required double centre,
  required bool vertical,
  required bool positive,
}) {
  if (style == _none) return;

  final thickness = style == _heavy ? t * 2 : t;
  final positions = style == _double
      ? strokes
      : [(strokes.first + strokes.last) / 2];

  for (var i = 0; i < positions.length; i++) {
    final position = positions[i];
    final stop = cross.isEmpty
        ? centre
        : cross.length == 1
        ? cross.first
        // Two strokes to meet: this stroke stops at the one it belongs with.
        // A single line crossing a double one goes past the near stroke and
        // stops at the far one, the way the single arm of `╢` does.
        : style == _double
        ? cross[i]
        : positive
        ? cross.first
        : cross.last;

    canvas.drawRect(
      _strokeRect(position, thickness, stop, edge, vertical, devicePixelRatio),
      paint,
    );
  }
}

/// One stroke of an arm: [thickness] wide at [position] on the cross axis, and
/// running from [a] to [b] along it, all on the device pixel grid.
Rect _strokeRect(
  double position,
  double thickness,
  double a,
  double b,
  bool vertical,
  double devicePixelRatio,
) {
  final near = _align(position - thickness / 2, devicePixelRatio);
  final far = _align(position + thickness / 2, devicePixelRatio);
  final low = _align(math.min(a, b), devicePixelRatio);
  final high = _align(math.max(a, b), devicePixelRatio);
  return vertical
      ? Rect.fromLTRB(near, low, far, high)
      : Rect.fromLTRB(low, near, high, far);
}

/// Draws one dashed line: even dashes and gaps, starting and ending on a
/// dash, the way the font would have.
void _paintDashes(
  Canvas canvas,
  Rect cell,
  BoxDashes dashes,
  Color color,
  double devicePixelRatio,
) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.fill
    ..isAntiAlias = false;
  final t = _strokeWidth(devicePixelRatio) * (dashes.heavy ? 2 : 1);
  final vertical = dashes.vertical;
  final from = vertical ? cell.top : cell.left;
  final span = vertical ? cell.height : cell.width;
  final cross = vertical ? cell.center.dx : cell.center.dy;
  final part = span / (2 * dashes.count - 1);

  for (var i = 0; i < dashes.count; i++) {
    final a = _align(from + i * 2 * part, devicePixelRatio);
    final b = _align(a + part, devicePixelRatio);
    final near = _align(cross - t / 2, devicePixelRatio);
    final far = _align(cross + t / 2, devicePixelRatio);
    canvas.drawRect(
      vertical
          ? Rect.fromLTRB(near, a, far, b)
          : Rect.fromLTRB(a, near, b, far),
      paint,
    );
  }
}

/// Draws one of the block's four arcs (`╭ ╮ ╯ ╰`): a quarter ellipse across
/// the cell, from the edge one arm leaves by to the edge the other one leaves
/// by, so it joins both.
void _paintArc(
  Canvas canvas,
  Rect cell,
  int codePoint,
  Color color,
  double devicePixelRatio,
) {
  final paint = Paint()
    ..color = color
    ..style = PaintingStyle.stroke
    ..strokeWidth = _strokeWidth(devicePixelRatio);
  final (start, sweep) = switch (codePoint) {
    // Down and right: the right edge's middle to the bottom edge's.
    0x256D => (0.0, math.pi / 2),
    // Down and left.
    0x256E => (math.pi / 2, math.pi / 2),
    // Up and left.
    0x256F => (math.pi, math.pi / 2),
    // Up and right.
    _ => (math.pi * 1.5, math.pi / 2),
  };
  canvas.drawPath(Path()..addArc(cell, start, sweep), paint);
}

/// A light line's width: one logical pixel, rounded to a whole number of
/// device pixels so that it is a line rather than a grey smear.
double _strokeWidth(double devicePixelRatio) =>
    devicePixelRatio.round().clamp(1, 8) / devicePixelRatio;

/// [value] on the device pixel grid, so that a one-device-pixel line is one.
double _align(double value, double devicePixelRatio) =>
    (value * devicePixelRatio).roundToDouble() / devicePixelRatio;
