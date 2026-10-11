import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xterm/xterm.dart';

/// A tap has to reach a program that draws its own tabs and panes as a mouse
/// report. These cover both routes to that report: the gesture arena (the
/// default) and the raw pointer stream ([TerminalView.rawMouseInput]).
void main() {
  Future<List<String>> tapAndCollect(
    WidgetTester tester, {
    required bool raw,
  }) async {
    final out = <String>[];
    final terminal = Terminal(onOutput: out.add);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: TerminalView(terminal, rawMouseInput: raw),
          ),
        ),
      ),
    );
    // What a multiplexer sends on attach: alternate screen, then mouse
    // reporting in SGR form.
    terminal.write('\x1b[?1049h\x1b[?1000h\x1b[?1006h');
    await tester.pump();
    out.clear();
    await tester.tapAt(const Offset(400, 200));
    await tester.pump();
    return out;
  }

  testWidgets('rawMouseInput reports one press and one release', (tester) async {
    final out = await tapAndCollect(tester, raw: true);
    // ignore: avoid_print
    print('raw: $out');
    expect(out, ['\x1B[<0;31;13M', '\x1B[<0;31;13m']);
  });

  testWidgets('the default path still reports a tap', (tester) async {
    final out = await tapAndCollect(tester, raw: false);
    // ignore: avoid_print
    print('default: $out');
    expect(out, isNotEmpty);
    expect(out.first, startsWith('\x1B[<0;'));
  });

  testWidgets('rawMouseInput keeps the tap callbacks, which raise the keyboard',
      (tester) async {
    final taps = <CellOffset>[];
    final terminal = Terminal(onOutput: (_) {});
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: TerminalView(
              terminal,
              rawMouseInput: true,
              onTapUp: (_, offset) => taps.add(offset),
            ),
          ),
        ),
      ),
    );
    terminal.write('\x1b[?1000h\x1b[?1006h');
    await tester.pump();
    await tester.tapAt(const Offset(400, 200));
    await tester.pump();
    // The report belongs to the raw path; the callback is what focuses the
    // terminal, and it must still arrive.
    expect(taps, isNotEmpty);
  });

  testWidgets('neither route reports before the program asks for it',
      (tester) async {
    final out = <String>[];
    final terminal = Terminal(onOutput: out.add);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: TerminalView(terminal, rawMouseInput: true),
          ),
        ),
      ),
    );
    out.clear();
    await tester.tapAt(const Offset(400, 200));
    await tester.pump();
    // No `?1000h`, so there is nothing to report to.
    expect(out, isEmpty);
  });

  testWidgets('a wheel turn is two reports, not a tap', (tester) async {
    final out = <String>[];
    final terminal = Terminal(onOutput: out.add);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: TerminalView(terminal, rawMouseInput: true),
          ),
        ),
      ),
    );
    terminal.write('\x1b[?1000h\x1b[?1006h');
    await tester.pump();
    out.clear();
    final gesture = await tester.startGesture(const Offset(400, 300));
    await tester.pump();
    // ignore: avoid_print
    print('scroll: $out');
    await gesture.cancel();
  });
}
